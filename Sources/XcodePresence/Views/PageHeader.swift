import AppKit
import PresenceCore
import SwiftUI

struct PageHeader: View {
    @ObservedObject var model: PresenceModel
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(pageTitle).font(.system(size: 27, weight: .bold)).tracking(-0.6)
                Spacer(minLength: 12)
                if model.page == .activity {
                    Button {
                        model.paused.toggle()
                    } label: {
                        Label(
                            model.paused ? model.text(.resume) : model.text(.pause),
                            systemImage: model.paused ? "play.fill" : "pause.fill"
                        )
                        .font(.system(size: 14)).padding(.horizontal, 4).padding(.vertical, 3)
                    }.buttonStyle(.bordered)
                }
            }
            Text(pageSubtitle).font(.system(size: 14)).foregroundStyle(.secondary)
        }.padding(.bottom, model.page == .activity ? 5 : 0)
    }
    private var pageTitle: String {
        switch model.page {
        case .activity: return model.text(.yourCodeOnDiscord)
        case .sharing: return model.text(.shareYourWay)
        case .connection: return model.text(.connectToDiscord)
        case .settings: return model.text(.makeItYours)
        }
    }
    private var pageSubtitle: String {
        switch model.page {
        case .activity: return model.text(.aLiveViewOfYourCodingSession)
        case .sharing: return model.text(.chooseWhatOthersCanSee)
        case .connection: return model.text(.settingsAndStatusForEachConnection)
        case .settings: return model.text(.theLanguageOfYourAppAndDiscordActivity)
        }
    }
}
