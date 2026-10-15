import AppKit
import PresenceCore
import SwiftUI

struct ActivityView: View {
    @ObservedObject var model: PresenceModel
    var body: some View {
        Group {
            HStack(alignment: .top, spacing: 14) {
                Image(
                    systemName: model.phase == .live ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                )
                .font(.system(size: 22)).foregroundStyle(model.statusColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.title).font(.system(size: 15, weight: .semibold))
                    Text(model.subtitle).font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(
                        horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }.card(padding: 18)
            discordPreview
            HStack(spacing: 12) {
                diagnostic(
                    "hand.raised", model.text(.macosAccess),
                    model.trusted ? model.text(.allowed) : model.text(.permissionNeeded), model.trusted)
                diagnostic(
                    "hammer", "Xcode",
                    model.file != nil
                        ? (model.retainingFile ? model.text(.lastFileRetained) : model.text(.fileDetected))
                        : model.text(.waiting), model.file != nil)
                diagnostic(
                    "bubble.left.and.bubble.right", "Discord",
                    model.phase == .live ? model.text(.activityReceived) : model.text(.waiting),
                    model.phase == .live)
            }
            HStack {
                Text(
                    model.lastConfirmed.map {
                        model.text(.confirmedByDiscordAt) + $0.formatted(date: .omitted, time: .standard)
                    } ?? model.text(.updatesAutomaticallyEvery5Seconds)
                )
                .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button(model.text(.refresh)) { model.refresh(force: true) }.buttonStyle(.plain)
                    .foregroundStyle(.secondary).font(.system(size: 11))
            }.padding(.top, 2)
            if model.phase == .permission {
                Button(model.text(.openMacOSPermissions)) { model.openPermissions() }
            } else if model.phase == .setup {
                Button(model.text(.openConnection)) { model.page = .connection }
            }
        }
    }
    private var discordPreview: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("DISCORD PREVIEW").font(.system(size: 11, weight: .heavy)).tracking(1.5)
                Spacer()
                HStack(spacing: 5) {
                    Circle().fill(model.statusColor).frame(width: 6, height: 6)
                    Text(model.shortStatus.uppercased()).font(.system(size: 10, weight: .heavy)).tracking(0.5)
                }
            }.foregroundStyle(Color.white.opacity(0.53))
            if let activity = model.activity, [.live, .connecting, .preview].contains(model.phase) {
                HStack(alignment: .top, spacing: 17) {
                    ZStack(alignment: .bottomTrailing) {
                        resourceImage("LanguageIcons/xcode").resizable().scaledToFit().padding(10).frame(
                            width: 74, height: 74
                        )
                        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 17))
                        if activity.showLanguage, let icon = activity.language.icon {
                            resourceImage("LanguageIcons/" + icon).resizable().scaledToFit().frame(
                                width: 22, height: 22
                            ).clipShape(Circle())
                                .padding(2).background(
                                    Color(red: 0.13, green: 0.13, blue: 0.19), in: Circle()
                                ).offset(x: 4, y: 4)
                        }
                    }.accessibilityLabel(activity.title)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(activity.title).font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                        Text(activity.details).font(.system(size: 13, weight: .medium)).foregroundStyle(
                            Color.white.opacity(0.76)
                        ).lineLimit(2)
                        if !activity.state.isEmpty {
                            Text(activity.state).font(.system(size: 12, weight: .medium)).foregroundStyle(
                                Color.white.opacity(0.76))
                        }
                        if let start = activity.start {
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                Label(elapsed(from: start, to: context.date), systemImage: "clock").font(
                                    .system(size: 11)
                                ).foregroundStyle(Color.white.opacity(0.48))
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(spacing: 18) {
                    resourceImage("LanguageIcons/xcode").resizable().scaledToFit().frame(
                        width: 54, height: 54
                    ).opacity(0.5)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.text(.noActivityShared)).font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        Text(model.text(.yourNextFileWillAppearHere)).foregroundStyle(
                            Color.white.opacity(0.6)
                        ).font(.system(size: 12))
                    }
                    Spacer()
                }.frame(minHeight: 74)
            }
        }.padding(23).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.125, green: 0.13, blue: 0.19), in: RoundedRectangle(cornerRadius: 17))
    }
    private func elapsed(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start)))
        return seconds >= 3600
            ? String(format: "%d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
            : String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
    private func diagnostic(_ symbol: String, _ title: String, _ detail: String, _ good: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: symbol).font(.system(size: 16)).foregroundStyle(.secondary)
                Spacer()
                Circle().fill(good ? Color.green : Color.orange).frame(width: 6, height: 6)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 12, weight: .semibold))
                Text(detail).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).card(padding: 15)
    }
}
