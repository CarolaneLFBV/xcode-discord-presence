import AppKit
import PresenceCore
import SwiftUI

struct SharingView: View {
    @ObservedObject var model: PresenceModel
    var body: some View {
        Group {
            sectionLabel(model.text(.onYOURPROFILE))
            VStack(spacing: 0) {
                toggleRow("doc.text", .fileName, .fileNameExample, $model.showFile)
                rowDivider
                toggleRow("folder", .projectName, .theProjectOrPackageContainingTheFile, $model.showProject)
                rowDivider
                toggleRow(
                    "chevron.left.forwardslash.chevron.right", .languageAndIcon,
                    .theIconAutomaticallyMatchesTheFileType, $model.showLanguage)
                rowDivider
                toggleRow(
                    "clock", .sessionDuration, .sessionDurationExplanation,
                    $model.showElapsed)
            }.card(padding: 0)
            sectionLabel(model.text(.whenTOSHARE))
            VStack(spacing: 0) {
                toggleRow(
                    "macwindow", .onlyWhenXcodeIsInTheForeground, .otherwiseSharingContinuesInTheBackground,
                    $model.focusOnly)
                rowDivider
                HStack(spacing: 16) {
                    Image(systemName: "moon.zzz").foregroundStyle(presenceAccent).frame(width: 16)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.text(.pauseWhenInactive)).font(.system(size: 14, weight: .semibold))
                        Text(model.text(.neverByDefaultPausingKeepsTheSessionTimer)).font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker(model.text(.inactivity), selection: $model.idleMinutes) {
                        Text(model.text(.never)).tag(0)
                        ForEach([5, 15, 30], id: \.self) { Text("\($0) min").tag($0) }
                    }.labelsHidden().frame(width: 100)
                }.padding(.horizontal, 20).padding(.vertical, 14)
            }.card(padding: 0)
            Label(
                model.text(.sharingPrivacyExplanation),
                systemImage: "lock.shield"
            )
            .font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }
    private var rowDivider: some View { Divider().padding(.leading, 66).padding(.trailing, 16) }
    private func toggleRow(_ symbol: String, _ title: AppText, _ subtitle: AppText, _ binding: Binding<Bool>)
        -> some View
    {
        HStack(spacing: 16) {
            Image(systemName: symbol).font(.system(size: 15)).foregroundStyle(presenceAccent).frame(width: 16)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.text(title)).font(.system(size: 13, weight: .semibold))
                Text(model.text(subtitle)).font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(
                    horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle(model.text(title), isOn: binding).labelsHidden().toggleStyle(.switch).controlSize(.small)
                .accessibilityLabel(model.text(title))
        }.padding(.horizontal, 20).padding(.vertical, 14)
    }
}
