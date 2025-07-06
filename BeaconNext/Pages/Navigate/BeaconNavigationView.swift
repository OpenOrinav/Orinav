import TencentNavKit
import SwiftUI

struct BeaconNavigationView: View {
    @EnvironmentObject private var globalState: BeaconMappingCoordinator
    @EnvironmentObject private var globalUIState: BeaconGlobalUIState

    var body: some View {
        if let data = globalUIState.navigationStatus {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        Text("In \(formattedDistance(data.bDistanceToNextSegmentMeters))")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        if data.bTurnType == .stop || data.bNextRoad == nil {
                            Text("Arrive at your destination")
                                .font(.title)
                                .bold()
                        } else {
                            Text("\(Text(data.bTurnType.localizedName)) onto \(data.bNextRoad!)")
                                .font(.title)
                                .bold()
                        }
                    }
                    .accessibilityElement(children: .combine)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .accessibilityHidden(true)
                        if let name = globalState.locationDelegate.currentLocation?.bName {
                            Text(name) // Current Location
                                .accessibilityLabel("Current location")
                                .accessibilityValue(name)
                        } else {
                            Text("Loading...")
                                .accessibilityLabel("Current location")
                                .accessibilityValue("Loading...")
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "location.north.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .accessibilityHidden(true)
                        if let heading = globalState.locationDelegate.currentHeading {
                            Text(globalState.locationDelegate.name(forDegrees: heading)) // Current Location
                                .accessibilityLabel("Current heading")
                                .accessibilityValue(globalState.locationDelegate.name(forDegrees: heading))
                        } else {
                            Text("Loading...")
                                .accessibilityLabel("Current heading")
                                .accessibilityValue("Loading...")
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .accessibilityHidden(true)
                        if let heading = globalState.locationDelegate.currentHeading,
                           let correct = globalState.navigationDelegate.correctHeading {
                            let signedDiff = (heading - correct + 540).truncatingRemainder(dividingBy: 360) - 180
                            
                            if abs(signedDiff) < AngleDeviationFeature.correctHeadingLimit {
                                Text("Heading aligned")
                            } else {
                                Text("Turn \(AngleDeviationFeature.oClockRepresentation(from: signedDiff)) o'clock to align")
                            }
                        } else {
                            Text("Loading...")
                                .font(.headline)
                        }
                    }
                }
                
                HStack(spacing: 16) {
                    // Arrival Time
                    VStack {
                        Text(formattedArrivalTime(data.bTimeRemainingSeconds))
                            .font(.title2)
                            .bold()
                            .accessibilityLabel("Estimated arrival time")
                            .accessibilityValue(formattedArrivalTime(data.bTimeRemainingSeconds))
                        Text("Arrival")
                            .font(.subheadline)
                            .accessibilityHidden(true)
                    }
                    
                    // Time Remaining
                    VStack {
                        Text(formattedTimeRemaining(data.bTimeRemainingSeconds))
                            .font(.title2)
                            .bold()
                            .accessibilityLabel("Time remaining")
                            .accessibilityValue(formattedTimeRemaining(data.bTimeRemainingSeconds))
                        Text("Time")
                            .font(.subheadline)
                            .accessibilityHidden(true)
                    }
                    
                    // Distance Remaining
                    VStack {
                        Text(formattedDistance(data.bTotalDistanceRemainingMeters))
                            .font(.title2)
                            .bold()
                            .accessibilityLabel("Distance remaining")
                            .accessibilityValue(formattedDistance(data.bTotalDistanceRemainingMeters))
                        Text("Distance")
                            .font(.subheadline)
                            .accessibilityHidden(true)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color(.systemBackground))
                .clipShape(.rect(cornerRadius: 9999))
                
                Button(action: {
                    globalState.navigationProvider.clearState()
                    globalState.navigationDelegate.shouldEndNavigation()
                }) {
                    Text("End Navigation")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
        }
    }
    
    // Utilities
    private func formattedDistance(_ meters: Int) -> String {
        if meters >= 1000 {
            let kmValue = Double(meters) / 1000.0
            let unit = NSLocalizedString("km", comment: "Kilometer unit")
            return String(format: "%.1f %@", kmValue, unit)
        } else {
            let unit = NSLocalizedString("m", comment: "Meter unit")
            return String(format: "%lld %@", meters, unit)
        }
    }
    
    private func formattedArrivalTime(_ secondsRemaining: Int) -> String {
        let arrivalDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: arrivalDate)
    }
    
    private func formattedTimeRemaining(_ secondsRemaining: Int) -> String {
        let hours = secondsRemaining / 3600
        let minutes = (secondsRemaining % 3600) / 60
        let hrUnit = NSLocalizedString("hr", comment: "Hour unit abbreviation")
        let minUnit = NSLocalizedString("min", comment: "Minute unit abbreviation")
        
        if hours > 0 {
            return String(format: "%d %@ %d %@", hours, hrUnit, minutes, minUnit)
        } else {
            return String(format: "%d %@", minutes, minUnit)
        }
    }
}
