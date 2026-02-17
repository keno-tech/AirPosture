import CoreMotion
import Combine

class HeadphoneMotionManager: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate {
    private let motionManager = CMHeadphoneMotionManager()
    
    @Published var isDeviceSupported: Bool = false // Tracks if device *can* support it
    @Published var isConnected: Bool = false       // Tracks if headphones are actually connected
    @Published var isActive: Bool = false
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    @Published var yaw: Double = 0.0
    @Published var badPostureThreshold: Double = 0.6
    
    override init() {
        super.init()
        self.isDeviceSupported = motionManager.isDeviceMotionAvailable
        self.motionManager.delegate = self
    }
    
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        DispatchQueue.main.async {
            self.isConnected = true
            print("Headphones connected")
        }
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        DispatchQueue.main.async {
            self.isConnected = false
            print("Headphones disconnected")
        }
    }
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Headphone motion is not available on this device")
            return
        }
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else { return }
            
            self.pitch = motion.attitude.pitch
            self.roll = motion.attitude.roll
            self.yaw = motion.attitude.yaw
            self.isActive = true
            
            // If we are receiving data, we are definitely connected
            if !self.isConnected {
                self.isConnected = true
            }
            
            // Posture Check Logic
            // Positive pitch usually means looking down. 
            // Threshold can be adjusted.
            if abs(self.pitch) > self.badPostureThreshold {
                self.onBadPosture?()
            } else {
                self.onGoodPosture?()
            }
        }
    }
    
    var onBadPosture: (() -> Void)?
    var onGoodPosture: (() -> Void)?
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        self.isActive = false
    }
}
