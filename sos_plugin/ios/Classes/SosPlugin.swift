import Flutter
import UIKit
import CoreMotion
import CoreLocation

public class SosPlugin: NSObject, FlutterPlugin {
    private let internetChecker = InternetChecker()
    private let motionChecker = MotionChecker()
    private let locationChecker = LocationChecker()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "sos_plugin", binaryMessenger: registrar.messenger())
        let instance = SosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Setup Event Channels
        let internetChannel = FlutterEventChannel(name: "sos_plugin/internet", binaryMessenger: registrar.messenger())
        internetChannel.setStreamHandler(instance.internetChecker)

        let motionlessChannel = FlutterEventChannel(name: "sos_plugin/motionless", binaryMessenger: registrar.messenger())
        motionlessChannel.setStreamHandler(instance.motionChecker.getMotionlessStreamHandler())

        let fallChannel = FlutterEventChannel(name: "sos_plugin/fall", binaryMessenger: registrar.messenger())
        fallChannel.setStreamHandler(instance.motionChecker.getFallStreamHandler())

        let locationChannel = FlutterEventChannel(name: "sos_plugin/location", binaryMessenger: registrar.messenger())
        locationChannel.setStreamHandler(instance.locationChecker)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setHomeLocation":
            if let args = call.arguments as? [String: Double],
               let latitude = args["latitude"],
               let longitude = args["longitude"] {
                locationChecker.setHomeLocation(latitude: latitude, longitude: longitude)
                result("Home location set")
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Latitude or Longitude missing", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}