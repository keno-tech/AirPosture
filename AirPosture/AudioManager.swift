import AVFoundation

class AudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            // Configure the audio session to allow background playback and mixing with other apps
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers, .allowBluetoothHFP])
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private var silentEngine: AVAudioEngine?
    private var silentPlayer: AVAudioPlayerNode?
    
    func startSilentLoop() {
        print("Starting silent loop...")
        
        if silentEngine != nil {
             print("Silent loop already running")
             return
        }
        
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        // Create a monophonic format for efficiency, or match output
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.0 // Ensure it is silent at the mixer level too
        
        // Generate buffer of silence
        let frameCount = AVAudioFrameCount(44100) // 1 second
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("Failed to create buffer")
            return
        }
        buffer.frameLength = frameCount
        // buffer is initialized to zero (silence)
        
        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        
        do {
            try engine.start()
            player.play()
            self.silentEngine = engine
            self.silentPlayer = player
            print("Silent loop started successfully")
        } catch {
            print("Failed to start silent loop: \(error)")
        }
    }
    
    func stopSilentLoop() {
        if let player = silentPlayer {
            player.stop()
        }
        if let engine = silentEngine {
            engine.stop()
        }
        silentPlayer = nil
        silentEngine = nil
        print("Silent loop stopped")
    }
    
    // MARK: - Posture Feedback
    
    private let synthesizer = AVSpeechSynthesizer()
    
    func startDucking() {
        print("Ducking audio...")
        do {
            // Try setting category directly
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to start ducking (direct): \(error)")
            // Fallback: Deactivate and retry
            do {
                try AVAudioSession.sharedInstance().setActive(false)
                try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
                print("Ducking started via fallback")
            } catch {
                print("Failed to start ducking (fallback): \(error)")
            }
        }
    }
    
    func stopDucking() {
        print("Restoring audio...")
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to stop ducking (direct): \(error)")
             // Fallback: Deactivate and retry
             do {
                 try AVAudioSession.sharedInstance().setActive(false)
                 try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
                 try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                 print("Audio restored via fallback")
             } catch {
                 print("Failed to stop ducking (fallback): \(error)")
             }
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
