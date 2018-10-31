import CoreMotion
import UIKit

class myCoreMotion {
    
    var mManager = CMMotionManager()
    var blockMotion = false
    var previousPitch = 0.0
    var previousYaw = 0.0
    var previousRoll = 0.0
    var previousZ = -1.0
    var blockMotionTimer : Timer?
    
    init() {
        mManager.accelerometerUpdateInterval = 1/10
        mManager.deviceMotionUpdateInterval = 1/10
        mManager.startAccelerometerUpdates()
        mManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
    }
    
    func stopMotionUpdate() {
        mManager.stopDeviceMotionUpdates()
        mManager.stopAccelerometerUpdates()
    }
    
    func motionBlockTimer() {
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(motionOn), userInfo: nil, repeats: false)
    }
    
    @objc func motionOn() {
        if let data = mManager.deviceMotion {
            let attitude = data.attitude
            previousPitch = attitude.pitch
            previousRoll = attitude.roll
        }
        blockMotion = false
    }
    
    @objc func updateDeviceMotion() -> String{
        if (!blockMotion) {
            if let data = mManager.deviceMotion {
                //print("Previous: Pitch: \(previousPitch)\t\tRoll: \(previousRoll)\t\tYaw: \(previousYaw)")
                let attitude = data.attitude
                let pitch = attitude.pitch
                let roll = attitude.roll

                if (roll - previousRoll > 0.4) {
                    print("Roll to the right")
                    blockMotion = true
                    motionBlockTimer()
                    return "R"
                }
                if (previousRoll - roll > 0.4) {
                    print("Roll to the left")
                    blockMotion = true
                    motionBlockTimer()
                    return "L"
                }
                if (pitch - previousPitch > 0.3) {
                    print("Pitch up")
                    blockMotion = true
                    motionBlockTimer()
                    return "U"
                }
                if (previousPitch - pitch > 0.3) {
                    print("Pitch down")
                    blockMotion = true
                    motionBlockTimer()
                    return "D"
                }
                previousRoll = roll
                previousPitch = pitch
            }
            
            if let data = mManager.accelerometerData {
                let accel = data.acceleration
                let z = accel.z
                if (z - previousZ > 1) {
                    print("Submit answer")
                    blockMotion = true
                    motionBlockTimer()
                    return "S"
                }
            }
        }
        return ""
    }
}
