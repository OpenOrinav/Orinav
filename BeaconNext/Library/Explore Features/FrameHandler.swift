import AVFoundation
import CoreImage
import CoreML
import Vision
import SwiftUI

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    @Published var minDepth: Float? = nil
    
    // MARK: - Basic Data
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private var captureDevice: AVCaptureDevice? = nil
    private var captureSessionReady = false
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()
    
    var running: Bool {
        get {
            return captureSession.isRunning
        }
    }
    
    var latestDepthData: AVDepthData?
    var lastDepth: Float?
    private var depthDataOutput = AVCaptureDepthDataOutput()
    
    // MARK: - Camera Permission
    // ------------------------------------------------------------
    func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                
                if !self.captureSessionReady {
                    self.setupCaptureSession()
                }
                self.captureSession.startRunning()
                print("Capture session started")
            }
            
        case .notDetermined:
            requestPermissionAndStart()
            
        default:
            permissionGranted = false
        }
    }
    
    func requestPermissionAndStart() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self = self else { return }
            
            self.permissionGranted = granted
            if granted {
                self.sessionQueue.async { [weak self] in
                    guard let self = self else { return }
                    
                    if !self.captureSessionReady {
                        self.setupCaptureSession()
                    }
                    self.captureSession.startRunning()
                }
            }
        }
    }
    
    func stop() {
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
        captureDevice = nil
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Capture Session Setup
    // ------------------------------------------------------------
    func setupCaptureSession() {
        guard permissionGranted else { return }
        
        guard let videoDevice = AVCaptureDevice.default(.builtInLiDARDepthCamera,
                                                        for: .video,
                                                        position: .back)
                ?? AVCaptureDevice.default(.builtInDualWideCamera,
                                           for: .video,
                                           position: .back) else { return }
        captureDevice = videoDevice
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else { return }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        captureSession.addInput(videoDeviceInput)
        
        // Video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        guard captureSession.canAddOutput(videoOutput) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(videoOutput)
        
        // Rotate video if needed
        videoOutput.connection(with: .video)?.videoRotationAngle = 90
        
        // Depth output
        if captureSession.canAddOutput(depthDataOutput) {
            depthDataOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depthDataQueue"))
            depthDataOutput.isFilteringEnabled = true
            captureSession.addOutput(depthDataOutput)
            
            // Rotate depth if supported
            if let connection = depthDataOutput.connection(with: .depthData),
               connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            // Match rotation with the video
            if let depthConnection = depthDataOutput.connection(with: .depthData),
               let videoConnection = videoOutput.connection(with: .video) {
                depthConnection.videoRotationAngle = videoConnection.videoRotationAngle
            }
        }
        
        captureSession.commitConfiguration()
        captureSessionReady = true
    }
    
    func zoom(_ factor: CGFloat) {
        guard let captureDevice = captureDevice else { return }
        do {
            try captureDevice.lockForConfiguration()
            let zoomFactor = max(1.0, min(factor, captureDevice.activeFormat.videoMaxZoomFactor))
            captureDevice.videoZoomFactor = zoomFactor
            captureDevice.unlockForConfiguration()
        } catch {
            print("Could not lock device for configuration: \(error)")
        }
    }
    
    func focus(x: Double, y: Double) { // x, y w.r.t. frame
        guard let captureDevice = captureDevice else { return }
        guard let frame = frame else { return }
        
        let focusPoint = CGPoint(x: y / Double(frame.height), y: 1.0 - x / Double(frame.width))
        
        do {
            try captureDevice.lockForConfiguration()
            
            if captureDevice.isFocusModeSupported(.autoFocus) && captureDevice.isFocusPointOfInterestSupported {
                captureDevice.focusPointOfInterest = focusPoint
                captureDevice.focusMode = .autoFocus
            }
            
            if captureDevice.isExposureModeSupported(.autoExpose) && captureDevice.isExposurePointOfInterestSupported {
                captureDevice.exposurePointOfInterest = focusPoint
                captureDevice.exposureMode = .autoExpose
            }
            
            captureDevice.unlockForConfiguration()
        } catch {
            print("Could not lock device for configuration: \(error)")
        }
    }
    
    func cancelFocus() {
        guard let captureDevice = captureDevice else { return }
        do {
            try captureDevice.lockForConfiguration()
            if captureDevice.isFocusModeSupported(.autoFocus) && captureDevice.isFocusPointOfInterestSupported {
                captureDevice.focusMode = .continuousAutoFocus
            }
            
            if captureDevice.isExposureModeSupported(.autoExpose) && captureDevice.isExposurePointOfInterestSupported {
                captureDevice.exposureMode = .continuousAutoExposure
            }
        } catch {
            print("Could not lock device for configuration: \(error)")
        }

    }
}

// MARK: - CGRect Helper
extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        // Use [weak self] to avoid referencing a deallocated self
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.frame = cgImage
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return cgImage
    }
}

// MARK: - AVCaptureDepthDataOutputDelegate
extension FrameHandler: AVCaptureDepthDataOutputDelegate {
    func updateDepths(with depthData: AVDepthData) {
        // Processing min depth for path clearance detection
        let depthConverted = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        let depthBuffer = depthConverted.depthDataMap
        
        CVPixelBufferLockBaseAddress(depthBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(depthBuffer)
        let height = CVPixelBufferGetHeight(depthBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthBuffer)?
            .assumingMemoryBound(to: Float.self) else {
            DispatchQueue.main.async { [weak self] in
                self?.minDepth = nil
            }
            return
        }
        
        let regionSize = Int(SettingsManager.shared.obstacleRegionSize)
        let centerX = width / 2
        let centerY = height / 2
        
        var minDepthValue: Float = Float.greatestFiniteMagnitude
        
        let startX = max(0, centerX - regionSize)
        let endX   = min(width - 1, centerX + regionSize)
        let startY = max(0, centerY - regionSize)
        let endY   = min(height - 1, centerY + regionSize)
        
        for y in startY..<endY {
            for x in startX..<endX {
                let index = y * width + x
                let depth = baseAddress[index]
                if depth > 0 && (1 / depth) < minDepthValue {
                    minDepthValue = 1 / depth
                }
            }
        }
        
        // Update minDepth on main thread
        if minDepthValue == Float.greatestFiniteMagnitude {
            DispatchQueue.main.async { [weak self] in
                self?.minDepth = nil
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.minDepth = minDepthValue
        }
    }
    
    func depthDataOutput(_ output: AVCaptureDepthDataOutput,
                         didOutput depthData: AVDepthData,
                         timestamp: CMTime,
                         connection: AVCaptureConnection) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.latestDepthData = depthData
            self.updateDepths(with: depthData)
        }
    }
}
