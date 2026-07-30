import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// Shared contract between the app (Runner) and the Live Activity widget
/// (TimerWidget). Both targets compile this file — that shared type is how
/// ActivityKit carries the session data across the process boundary, which is
/// why no App Group is needed here.
///
/// The content state stays deliberately small. While a session runs, the widget
/// renders the countdown with `Text(timerInterval:countsDown:)`, which the
/// system ticks itself — so `endDate` alone is enough and the app pushes no
/// per-second updates. `remainingSeconds` is only read while paused, where
/// there is no end date to count towards.
@available(iOS 16.2, *)
struct TimerActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var endDate: Date
    var isPaused: Bool
    var remainingSeconds: Int
  }

  /// Name of the preset timer, e.g. "Meditation".
  var sessionName: String
  /// Full session length, used for the progress readout.
  var totalSeconds: Int
}
#endif
