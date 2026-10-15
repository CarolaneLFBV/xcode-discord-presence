import AppKit
import PresenceCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: PresenceModel
    var body: some View {
        Group {
            sectionLabel(model.text(.language))
            VStack(alignment: .leading, spacing: 16) {
                Picker(model.text(.appLanguage), selection: $model.language) {
                    Text(model.text(.automaticMacOS)).tag(AppLanguage.system)
                    Text("Français").tag(AppLanguage.fr)
                    Text("English").tag(AppLanguage.en)
                }.font(.system(size: 14))
                Text(model.text(.alsoAppliesToTextSharedOnDiscord)).foregroundStyle(.secondary).font(
                    .system(size: 12))
            }.card()
            Text(model.text(.languageChangeExplanation)).font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}
