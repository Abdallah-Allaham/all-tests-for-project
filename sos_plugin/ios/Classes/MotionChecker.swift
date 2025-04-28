import CoreMotion

class MotionChecker {
    private let motionManager = CMMotionManager()

    func getMotionlessStreamHandler() -> FlutterStreamHandler {
        return MotionlessStreamHandler(motionManager: motionManager)
    }

    func getFallStreamHandler() -> FlutterStreamHandler {
        return FallStreamHandler(motionManager: motionManager, lastAcceleration: 0)
    }
}

class MotionlessStreamHandler: NSObject, FlutterStreamHandler {
    private let motionManager: CMMotionManager
    private var eventSink: FlutterEventSink?
    private var motionlessStartTime: Date?
    private var isMotionless = false
    private var lastAcceleration: Double = 0

    init(motionManager: CMMotionManager) {
        self.motionManager = motionManager
        super.init()
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        guard motionManager.isAccelerometerAvailable else {
            events(false)
            return nil
        }

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data, error == nil else { return }

            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            let acceleration = sqrt(x * x + y * y + z * z)

            // احسب التغير في التسارع
            let accelerationChange = self.lastAcceleration == 0 ? 0 : abs(acceleration - self.lastAcceleration)
            self.lastAcceleration = acceleration

            print("Acceleration: \(acceleration), Change: \(accelerationChange)")

            let currentTime = Date()

            if accelerationChange < 0.1 {
                if self.motionlessStartTime == nil {
                    self.motionlessStartTime = currentTime
                    print("Started counting motionless time")
                }
                if currentTime.timeIntervalSince(self.motionlessStartTime!) >= 8 {
                    if !self.isMotionless {
                        self.isMotionless = true
                        print("Motionless for 8 seconds, sending true")
                        events(true)
                    }
                } else {
                    if !self.isMotionless {
                        events(false)
                    }
                }
            } else {
                if self.motionlessStartTime != nil {
                    print("Device moved, resetting timer")
                }
                self.motionlessStartTime = nil
                if !self.isMotionless {
                    events(false)
                }
            }
        }

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopAccelerometerUpdates()
        eventSink = nil
        motionlessStartTime = nil
        isMotionless = false
        lastAcceleration = 0
        return nil
    }
}

class FallStreamHandler: NSObject, FlutterStreamHandler {
    private let motionManager: CMMotionManager
    private var lastAcceleration: Double
    private var eventSink: FlutterEventSink?
    private var fallDetected = false

    init(motionManager: CMMotionManager, lastAcceleration: Double) {
        self.motionManager = motionManager
        self.lastAcceleration = lastAcceleration
        super.init()
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        guard motionManager.isAccelerometerAvailable else {
            events(false)
            return nil
        }

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data, error == nil else { return }

            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            let acceleration = sqrt(x * x + y * y + z * z)

            if self.lastAcceleration > 0 && abs(acceleration - self.lastAcceleration) > 0.5 {
                if !self.fallDetected {
                    self.fallDetected = true
                    events(true)
                }
            } else {
                if !self.fallDetected {
                    events(false)
                }
            }

            self.lastAcceleration = acceleration
        }

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopAccelerometerUpdates()
        eventSink = nil
        fallDetected = false
        return nil
    }
}