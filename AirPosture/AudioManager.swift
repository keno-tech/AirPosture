import AVFoundation

class AudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            // Configure the audio session to allow background playback and mixing with other apps
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    func playSilentLoop() {
        // Create a silent audio buffer to play
        // Valid MP3 header + silence or just simple PCM data
        // For simplicity, we'll try to just activate the session, but for robustness
        // we might need to play an actual sound.
        // A common trick is to play a file with 0 volume or silence.
        
        print("Activating audio session...")
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate session: \(error)")
        }
    }
    
    // MARK: - Posture Feedback
    
    private let synthesizer = AVSpeechSynthesizer()
    
    func startDucking() {
        print("Ducking audio...")
        do {
            // .duckOthers will lower the volume of other audio apps
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to start ducking: \(error)")
        }
    }
    
    func stopDucking() {
        print("Restoring audio...")
        do {
            // .mixWithOthers allows other audio to play at full volume (along with our silence)
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to stop ducking: \(error)")
        }
    }
    
    // Alias for starting the session in a mixable state
    func startBackgroundTask() {
        stopDucking()
    }
    
    func playPostureWarning() {
        let utterance = AVSpeechUtterance(string: "Posture")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}
