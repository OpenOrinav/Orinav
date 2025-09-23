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
                        if data.bDistanceToNextSegmentMeters < 5 {
                            Text("Now")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("In \(BeaconUIUtils.formattedDistance(Double(data.bDistanceToNextSegmentMeters)))")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if data.bTurnType == .stop || data.bNextRoad == nil {
                            Text("Arrive at your destination")
                                .font(.title)
                                .bold()
                        } else if data.bTurnType == .unnavigable {
                            Text(data.bTurnType.localizedName)
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
                        Text(BeaconUIUtils.formattedArrivalTime(data.bTimeRemainingSeconds))
                            .font(.title2)
                            .bold()
                            .accessibilityLabel("Estimated arrival time")
                            .accessibilityValue(BeaconUIUtils.formattedArrivalTime(data.bTimeRemainingSeconds))
                        Text("Arrival")
                            .font(.subheadline)
                            .accessibilityHidden(true)
                    }
                    
                    // Time Remaining
                    VStack {
                        Text(BeaconUIUtils.formattedTimeRemaining(data.bTimeRemainingSeconds))
                            .font(.title2)
                            .bold()
                            .accessibilityLabel("Time remaining")
                            .accessibilityValue(BeaconUIUtils.formattedTimeRemaining(data.bTimeRemainingSeconds))
                        Text("Time")
                            .font(.subheadline)
                            .accessibilityHidden(true)
                    }
                    
                    // Distance Remaining
                    VStack {
                        Text(BeaconUIUtils.formattedDistance(Double(data.bTotalDistanceRemainingMeters)))
                            .font(.title2)
                            .bold()
                            .accessibilityLabel("Distance remaining")
                            .accessibilityValue(BeaconUIUtils.formattedDistance(Double(data.bTotalDistanceRemainingMeters)))
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
                    globalState.navigationDelegate.didEndNavigation()
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
}
