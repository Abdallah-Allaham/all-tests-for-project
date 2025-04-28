import Network

class InternetChecker: NSObject, FlutterStreamHandler {
    private var monitor: NWPathMonitor?
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { path in
            let isConnected = path.status == .satisfied
            events(isConnected)
        }
        monitor?.start(queue: .main)

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        monitor?.cancel()
        monitor = nil
        eventSink = nil
        return nil
    }

    func isInternetConnected() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false

        monitor.pathUpdateHandler = { path in
            isConnected = path.status == .satisfied
            semaphore.signal()
        }
        monitor.start(queue: .main)
        semaphore.wait()
        monitor.cancel()

        return isConnected
    }
}