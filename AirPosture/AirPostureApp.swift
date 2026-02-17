import SwiftUI
import AVFoundation

@main
struct AirPostureApp: App {
    @StateObject private var motionManager = HeadphoneMotionManager()
    @StateObject private var audioManager = AudioManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(motionManager)
                .environmentObject(audioManager)
        }
    }
}
