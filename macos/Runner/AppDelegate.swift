import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var deepLinkChannel: FlutterMethodChannel?
  private var pendingDeepLink: String?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Register for URL events (alpha:// scheme).
    NSAppleEventManager.shared().setEventHandler(
      self,
      andSelector: #selector(handleURLEvent(_:withReply:)),
      forEventClass: AEEventClass(kInternetEventClass),
      andEventID: AEEventID(kAEGetURL)
    )

    // Set up the Flutter method channel for deep links.
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      deepLinkChannel = FlutterMethodChannel(
        name: "app.channel/deeplink",
        binaryMessenger: controller.engine.binaryMessenger
      )

      deepLinkChannel?.setMethodCallHandler { [weak self] call, result in
        if call.method == "getInitialLink" {
          result(self?.pendingDeepLink)
          self?.pendingDeepLink = nil
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    super.applicationDidFinishLaunching(notification)
  }

  @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
    guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue else {
      return
    }

    if let channel = deepLinkChannel {
      channel.invokeMethod("onDeepLink", arguments: urlString)
    } else {
      // Flutter engine not ready yet — store for getInitialLink.
      pendingDeepLink = urlString
    }
  }
}
