import CoreLocation

class LocationChecker: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
    private var homeLocation: CLLocation?
    private var locationManager: CLLocationManager?
    private var eventSink: FlutterEventSink?

    func setHomeLocation(latitude: Double, longitude: Double) {
        self.homeLocation = CLLocation(latitude: latitude, longitude: longitude)
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        locationManager?.stopUpdatingLocation()
        locationManager = nil
        eventSink = nil
        return nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        guard let homeLocation = homeLocation else {
            eventSink?(false)
            return
        }

        let distance = currentLocation.distance(from: homeLocation)
        let isOutsideHome = distance > 5 // أكثر من 50 متر
        eventSink?(isOutsideHome)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        eventSink?(FlutterError(code: "LOCATION_ERROR", message: "Failed to get location", details: error.localizedDescription))
    }
}