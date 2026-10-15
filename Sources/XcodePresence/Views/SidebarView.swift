import AppKit
import PresenceCore
import SwiftUI

struct SidebarView: View {
    @ObservedObject var model: PresenceModel
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                resourceImage("PresenceApp", ext: "icns").resizable().frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Xcode").font(.system(size: 16, weight: .bold))
                    Text("Presence").font(.system(size: 13)).foregroundStyle(.secondary)
                }
            }.padding(.top, 24).padding(.bottom, 36).padding(.leading, 22)
            VStack(spacing: 7) {
                navigation(.activity, "square.stack", .yourActivity)
                navigation(.sharing, "slider.horizontal.3", .sharing)
                navigation(.connection, "link", .connection)
                navigation(.settings, "gearshape", .settingsLabel)
            }.padding(.horizontal, 22)
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 7) {
                    Circle().fill(model.statusColor).frame(width: 7, height: 7)
                    Text(model.shortStatus).font(.system(size: 13))
                }
                Text(model.text(.inYourMenuBarNAlwaysAClickAway)).font(.system(size: 11)).lineSpacing(4)
                    .foregroundStyle(.secondary)
                Divider().padding(.vertical, 5)
                HStack {
                    Text("Version " + AppMetadata.version).font(.system(size: 10)).foregroundStyle(.tertiary)
                    Spacer()
                    Button {
                        NSApp.terminate(nil)
                    } label: {
                        Image(systemName: "power").font(.system(size: 14))
                    }
                    .buttonStyle(.plain).foregroundStyle(.secondary).help(model.text(.quitXcodePresence))
                }
            }.padding(22)
        }.background(Color(nsColor: .controlBackgroundColor).opacity(0.75))
    }
    private func navigation(_ page: SettingsPage, _ symbol: String, _ title: AppText) -> some View {
        Button {
            model.page = page
        } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 15)).frame(width: 16)
                Text(model.text(title)).font(
                    .system(size: 13, weight: model.page == page ? .semibold : .regular)
                ).lineLimit(1)
                Spacer(minLength: 0)
            }.padding(.horizontal, 15).frame(height: 40)
                .foregroundStyle(model.page == page ? presenceAccent : Color.primary.opacity(0.75))
                .background(
                    model.page == page ? presenceAccent.opacity(0.10) : .clear,
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}
