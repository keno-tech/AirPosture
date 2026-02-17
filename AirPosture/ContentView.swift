import SwiftUI

struct ContentView: View {
    @EnvironmentObject var motionManager: HeadphoneMotionManager
    @EnvironmentObject var audioManager: AudioManager
    
    @State private var isMonitoring = false
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Header
            VStack {
                Image(systemName: "earpods")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
                    .foregroundColor(motionManager.isConnected ? .green : .gray)
                
                Text(motionManager.isConnected ? "AirPods Connected" : "Connect AirPods")
                    .font(.headline)
                    .foregroundColor(motionManager.isConnected ? .primary : .secondary)
            }
            
            // Posture Data Visualization
            if isMonitoring {
                VStack(spacing: 15) {
                    Text("Posture Monitoring Active")
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Spacer()
                        PostureMetricView(label: "Pitch", value: motionManager.pitch)
                        Spacer()
                        PostureMetricView(label: "Roll", value: motionManager.roll)
                        Spacer()
                    }
                    
                    // Simple "Bad Posture" Indicator
                    // Assuming positive pitch is looking down (depends on reference frame)
                    // Usually looking down increases pitch in default ref frame? Need to verify.
                    // For now, just show the raw values.
                    
                    if abs(motionManager.pitch) > 0.5 { // Arbitrary threshold
                        Text("BAD POSTURE DETECTED")
                            .font(.title3)
                            .fontWeight(.heavy)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    } else {
                        Text("Good Posture")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            } else {
                Text("Press Start to begin monitoring")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Controls
            Button(action: toggleMonitoring) {
                Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isMonitoring ? Color.red : Color.blue)
                    .cornerRadius(15)
            }
            .disabled(!motionManager.isConnected)
            .opacity(motionManager.isConnected ? 1.0 : 0.6)
            
        }
        .padding()
        .onAppear {
            // Start motion updates immediately to detect connection status
            // This will trigger the permission prompt
            motionManager.startUpdates()
        }
    }
    
    func toggleMonitoring() {
        if isMonitoring {
            // Stop "Monitoring"
            motionManager.onBadPosture = nil
            motionManager.onGoodPosture = nil
            audioManager.stopDucking() // Ensure we don't leave it dimmed
            isMonitoring = false
        } else {
            audioManager.startBackgroundTask()
            
            // Setup Logic
            var isDucked = false
            
            motionManager.onBadPosture = {
                if !isDucked {
                    audioManager.startDucking()
                    audioManager.playPostureWarning()
                    isDucked = true
                }
            }
            
            motionManager.onGoodPosture = {
                if isDucked {
                    audioManager.stopDucking()
                    isDucked = false
                }
            }
            
            isMonitoring = true
        }
    }
}

struct PostureMetricView: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.2f", value))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
        }
        .frame(width: 80)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
