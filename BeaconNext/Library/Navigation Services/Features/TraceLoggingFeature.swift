import CoreLocation

// Special feature for debugging and testing: record GPS trace
// Remember to turn off UIFileSharingEnabled and LSSupportsOpeningDocumentsInPlace in production
final class TraceLoggingFeature {
    static let shared = TraceLoggingFeature()
    private init() {}

    private let fm = FileManager.default
    private var lastWrite: Date?

    private lazy var dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .init(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func tracesFolder() throws -> URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = docs.appendingPathComponent("Traces", isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    private func fileURL(for date: Date) throws -> URL {
        let name = dayFormatter.string(from: date) + ".csv"
        return try tracesFolder().appendingPathComponent(name, isDirectory: false)
    }

    func log(_ loc: CLLocationCoordinate2D) {
        let now = Date()
        if let last = lastWrite, now.timeIntervalSince(last) < 30 { return }
        lastWrite = now

        let lat = loc.latitude
        let lon = loc.longitude
        let epoch = Int(now.timeIntervalSince1970)
        let line = "\(lat),\(lon),\(epoch)\n"
        let data = Data(line.utf8)

        do {
            let url = try fileURL(for: now)
            if !fm.fileExists(atPath: url.path) {
                try data.write(to: url, options: .atomic)
            } else {
                let handle = try FileHandle(forWritingTo: url)
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            }
        } catch {
            // Optional: handle error (e.g., print or os_log)
            print("TraceLogger error: \(error)")
        }
    }
}
