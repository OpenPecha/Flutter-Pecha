import ActivityKit
import SwiftUI
import WidgetKit

/// Lock-screen and Dynamic Island presentation for a running meditation timer.
///
/// While the session runs the countdown is a `Text(timerInterval:countsDown:)`,
/// which the system ticks on its own — the app pushes no updates, so the
/// display stays correct even while the app is suspended or killed. Only
/// pause/resume changes the content state, and a paused session shows a static
/// time because there is no end date to count towards.
@available(iOS 16.2, *)
struct TimerLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TimerActivityAttributes.self) { context in
      LockScreenView(context: context)
        .activityBackgroundTint(Color.black.opacity(0.55))
        .activitySystemActionForegroundColor(Color.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          AppLogoView(size: 20)
            .padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          CountdownText(context: context)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 90, alignment: .trailing)
            .padding(.trailing, 4)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.attributes.sessionName)
            .font(.headline)
            .lineLimit(1)
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(subtitle(for: context))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      } compactLeading: {
        AppLogoView(size: 16)
      } compactTrailing: {
        CountdownText(context: context)
          .monospacedDigit()
          .frame(maxWidth: 54)
      } minimal: {
        AppLogoView(size: 14)
      }
    }
  }

  private func subtitle(for context: ActivityViewContext<TimerActivityAttributes>) -> String {
    context.state.isPaused ? "Paused" : "Meditation in progress"
  }
}

@available(iOS 16.2, *)
private struct LockScreenView: View {
  let context: ActivityViewContext<TimerActivityAttributes>

  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 4) {
        Text(context.attributes.sessionName)
          .font(.headline)
          .lineLimit(1)
        Text(context.state.isPaused ? "Paused" : "Meditation in progress")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)

      CountdownText(context: context)
        .font(.system(size: 34, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .multilineTextAlignment(.trailing)
        .padding(.trailing, 12)

      AppLogoView(size: 28)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
  }
}

@available(iOS 16.2, *)
private struct AppLogoView: View {
  let size: CGFloat

  var body: some View {
    Image("AppLogo")
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
      .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
  }
}

/// The countdown itself. Running uses the system-ticked timer text; paused
/// falls back to the frozen `remainingSeconds` carried in the content state.
@available(iOS 16.2, *)
private struct CountdownText: View {
  let context: ActivityViewContext<TimerActivityAttributes>

  var body: some View {
    if context.state.isPaused {
      Text(formatted(context.state.remainingSeconds))
    } else {
      Text(timerInterval: Date()...context.state.endDate, countsDown: true)
    }
  }

  private func formatted(_ seconds: Int) -> String {
    let clamped = max(0, seconds)
    return String(format: "%02d:%02d", clamped / 60, clamped % 60)
  }
}
