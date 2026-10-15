import AppKit
import PresenceCore
import SwiftUI

struct ConnectionView: View {
    @ObservedObject var model: PresenceModel
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 16) {
                Label(model.text(.discordApplication), systemImage: "bubble.left.and.bubble.right").font(
                    .system(size: 16, weight: .semibold))
                Text(model.text(.applicationIDExplanation))
                    .foregroundStyle(.secondary).font(.system(size: 13))
                HStack(spacing: 10) {
                    TextField("Application ID", text: $model.clientIDDraft).textFieldStyle(.roundedBorder)
                        .font(.system(size: 14, design: .monospaced)).onSubmit { model.saveClientID() }
                    Button(model.text(.save)) { model.saveClientID() }.controlSize(.large)
                }
                Link(
                    model.text(.openDeveloperPortal),
                    destination: URL(string: "https://discord.com/developers/applications")!
                ).font(.system(size: 12, weight: .medium))
                Text(model.text(.noDiscordTokenOrPasswordIsRequired)).font(.system(size: 11)).foregroundStyle(
                    .secondary)
                if !model.saveMessage.isEmpty {
                    Text(model.saveMessage).foregroundStyle(model.saveFailed ? Color.orange : Color.green)
                        .font(.system(size: 12))
                }
            }.card()
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Label(model.text(.xcodeAccess), systemImage: "hand.raised").font(
                        .system(size: 16, weight: .semibold))
                    Spacer()
                    Label(
                        model.trusted ? model.text(.allowed) : model.text(.permissionNeeded),
                        systemImage: model.trusted ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                    )
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(
                        model.trusted ? Color.green : Color.orange)
                }
                Text(model.text(.accessibilityExplanation))
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                Button(model.text(.openMacOSPermissions)) { model.openPermissions() }
                if !model.trusted {
                    Text(
                        model.text(
                            .permissionMigrationExplanation
                        )
                    ).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }.card()
            VStack(alignment: .leading, spacing: 14) {
                Label(model.text(.nothingShowingOnYourProfile), systemImage: "questionmark.circle").font(
                    .system(size: 14, weight: .semibold))
                Text(
                    model.text(
                        .discordVisibilityExplanation
                    )
                ).font(.system(size: 12)).foregroundStyle(.secondary)
                Button(model.text(.checkNow)) { model.refresh(force: true) }.buttonStyle(.link)
            }.padding(.top, 2)
        }
    }
}
