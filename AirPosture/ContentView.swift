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
            
            // Settings Section (Always Visible)
            VStack(spacing: 20) {
                // Sensitivity / Threshold Slider
                VStack {
                    Text("Sensitivity: \(Int(motionManager.badPostureThreshold * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Strict")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Slider(value: $motionManager.badPostureThreshold, in: 0.1...1.5)
                        Text("Relaxed")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                // Volume Slider
                VStack {
                    Text("Voice Volume: \(Int(audioManager.warningVolume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.secondary)
                        Slider(value: $audioManager.warningVolume, in: 0.0...1.0)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            
            // Posture Data Visualization
            if isMonitoring {
                
                Text("Posture Monitoring Active")
                    .font(.title2)
                    .bold()
                
                // Man Figure Visualization
                ManFigureView(angle: motionManager.badPostureThreshold)
                    .frame(height: 150)
                    .padding()
                
                HStack {
                    Spacer()
                    PostureMetricView(label: "Pitch", value: motionManager.pitch)
                    Spacer()
                    PostureMetricView(label: "Roll", value: motionManager.roll)
                    Spacer()
                }
                
                if abs(motionManager.pitch) > motionManager.badPostureThreshold {
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
            audioManager.stopSilentLoop()
            isMonitoring = false
        } else {
            audioManager.startBackgroundTask()
            audioManager.startSilentLoop()
            audioManager.playStartSound()
            
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

struct ManFigureView: View {
    // Angle in radians (pitch)
    var angle: Double
    
    var body: some View {
        Canvas { context, size in
            // Coordinates
            let centerX = size.width / 2
            let bottomY = size.height * 0.9
            let headRadius: CGFloat = 15
            let spineLength: CGFloat = 80
            
            // Draw Base/Hips (Fixed point)
            let hipsPoint = CGPoint(x: centerX, y: bottomY)
            
            // Calculate Head Position based on angle
            // 0 angle = upright (vertical)
            // positive angle = leaning forward
            // standard unit circle: 0 is right, -pi/2 is up.
            // visual angle = -pi/2 + angle
            
            let visualAngle = -CGFloat.pi / 2 + CGFloat(angle)
            
            let headX = hipsPoint.x + cos(visualAngle) * spineLength
            let headY = hipsPoint.y + sin(visualAngle) * spineLength
            
            let headCenter = CGPoint(x: headX, y: headY)
            
            // Draw Spine
            var spinePath = Path()
            spinePath.move(to: hipsPoint)
            spinePath.addLine(to: headCenter)
            context.stroke(spinePath, with: .color(.blue), lineWidth: 4)
            
            // Draw Head
            let headRect = CGRect(x: headCenter.x - headRadius, y: headCenter.y - headRadius, width: headRadius * 2, height: headRadius * 2)
            context.fill(Path(ellipseIn: headRect), with: .color(.blue))
            
            // Draw "Reference" Vertical Line (Good Posture)
            var refPath = Path()
            refPath.move(to: hipsPoint)
            refPath.addLine(to: CGPoint(x: centerX, y: bottomY - spineLength))
            context.stroke(refPath, with: .color(.gray.opacity(0.3)), style: StrokeStyle(lineWidth: 2, dash: [5]))
            
        }
    }
}
