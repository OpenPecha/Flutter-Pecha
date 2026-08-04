import Flutter
import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

/// Bridges `TimerLiveActivity` (Dart) to ActivityKit.
///
/// Method channel `org.pecha.app/timer_activity`:
///   - `start`  { sessionName: String, endTimestamp: Double (epoch seconds),
///                totalSeconds: Int }
///   - `update` { endTimestamp: Double, isPaused: Bool, remainingSeconds: Int }
///   - `end`    {}
///
/// Every path fails soft: Live Activities are unavailable before iOS 16.2 and
/// can be switched off system-wide or per-app in Settings. A missing Live
/// Activity must never break a meditation session, so nothing here throws back
/// into Dart.
final class TimerLiveActivityBridge {
  private static let channelName = "org.pecha.app/timer_activity"

  private var channel: FlutterMethodChannel?

  /// Held as `Any` so the property itself needs no availability annotation.
  private var currentActivity: Any?

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    self.channel = channel
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    #if canImport(ActivityKit)
    guard #available(iOS 16.2, *) else {
      result(nil)
      return
    }

    let args = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "start":
      start(args)
    case "update":
      update(args)
    case "end":
      end()
    default:
      result(FlutterMethodNotImplemented)
      return
    }
    #endif

    result(nil)
  }

  #if canImport(ActivityKit)
  @available(iOS 16.2, *)
  private func start(_ args: [String: Any]) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

    // The app can be killed mid-session, and a dead process cannot end its own
    // activity — so clear any orphan left over from a previous run before
    // starting a new one. Ending here is the only recovery point we get.
    endAllActivities()

    let sessionName = args["sessionName"] as? String ?? ""
    let totalSeconds = args["totalSeconds"] as? Int ?? 0
    let endDate = date(from: args["endTimestamp"])

    let attributes = TimerActivityAttributes(
      sessionName: sessionName,
      totalSeconds: totalSeconds
    )
    let state = TimerActivityAttributes.ContentState(
      endDate: endDate,
      isPaused: false,
      remainingSeconds: args["remainingSeconds"] as? Int ?? totalSeconds
    )

    do {
      currentActivity = try Activity.request(
        attributes: attributes,
        content: .init(state: state, staleDate: endDate),
        pushType: nil
      )
    } catch {
      NSLog("[TimerLiveActivity] start failed: \(error.localizedDescription)")
    }
  }

  @available(iOS 16.2, *)
  private func update(_ args: [String: Any]) {
    guard let activity = currentActivity as? Activity<TimerActivityAttributes> else { return }

    let isPaused = args["isPaused"] as? Bool ?? false
    let endDate = date(from: args["endTimestamp"])
    let state = TimerActivityAttributes.ContentState(
      endDate: endDate,
      isPaused: isPaused,
      remainingSeconds: args["remainingSeconds"] as? Int ?? 0
    )

    Task {
      // A paused session has no end to go stale at, so it stays fresh until the
      // next update.
      await activity.update(.init(state: state, staleDate: isPaused ? nil : endDate))
    }
  }

  @available(iOS 16.2, *)
  private func end() {
    currentActivity = nil
    endAllActivities()
  }

  /// Ends every activity of this type, not just the tracked one, so an orphan
  /// from a previous process is cleaned up too.
  @available(iOS 16.2, *)
  private func endAllActivities() {
    for activity in Activity<TimerActivityAttributes>.activities {
      Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
  }

  private func date(from value: Any?) -> Date {
    guard let seconds = value as? Double else { return Date() }
    return Date(timeIntervalSince1970: seconds)
  }
  #endif
}
