import AppKit
import PresenceCore
import SwiftUI

struct PresenceView: View {
    @ObservedObject var model: PresenceModel
    var body: some View {
        HStack(spacing: 0) {
            SidebarView(model: model).frame(width: 192)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PageHeader(model: model)
                    switch model.page {
                    case .activity: ActivityView(model: model)
                    case .sharing: SharingView(model: model)
                    case .connection: ConnectionView(model: model)
                    case .settings: SettingsView(model: model)
                    }
                    Spacer(minLength: 16)
                }.padding(30).frame(maxWidth: .infinity, alignment: .topLeading)
            }.background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 840, minHeight: 660)
        .accentColor(presenceAccent)
    }
}
