import Flutter
import UIKit
// This is required for calling FlutterLocalNotificationsPlugin.setPluginRegistrantCallback method.
import flutter_local_notifications
import airbridge_flutter_sdk


@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Retained for the app's lifetime — it owns the running Live Activity.
  private let timerLiveActivityBridge = TimerLiveActivityBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // This is required to make any communication available in the action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      timerLiveActivityBridge.register(with: controller.binaryMessenger)
    }

    let airbridgeAppName = Bundle.main.object(forInfoDictionaryKey: "AIRBRIDGE_APP_NAME") as? String ?? ""
    let airbridgeSdkToken = Bundle.main.object(forInfoDictionaryKey: "AIRBRIDGE_SDK_TOKEN") as? String ?? ""
    AirbridgeFlutter.initializeSDK(name: airbridgeAppName, token: airbridgeSdkToken)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if shouldHandleWithAirbridge(url) {
      AirbridgeFlutter.trackDeeplink(url: url)
      return true
    }
    return super.application(app, open: url, options: options)
  }
  
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let url = userActivity.webpageURL, shouldHandleWithAirbridge(url) {
      AirbridgeFlutter.trackDeeplink(userActivity: userActivity)
      return true
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  private func shouldHandleWithAirbridge(_ url: URL) -> Bool {
    let scheme = url.scheme?.lowercased() ?? ""
    let host = url.host?.lowercased() ?? ""
    return scheme == "webuddhist"
      || host == "join.webuddhist.com"
      || host.hasSuffix(".airbridge.io")
      || host.hasSuffix(".abr.ge")
  }
}
