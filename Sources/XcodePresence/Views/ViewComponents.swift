import AppKit
import PresenceCore
import SwiftUI

let presenceAccent = Color(red: 0.41, green: 0.38, blue: 0.88)

struct CardModifier: ViewModifier {
    var padding: CGFloat
    func body(content: Content) -> some View {
        content.padding(padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.primary.opacity(0.025), lineWidth: 1))
    }
}
extension View { func card(padding: CGFloat = 20) -> some View { modifier(CardModifier(padding: padding)) } }

func resourceImage(_ name: String, ext: String = "png") -> Image {
    if name == "LanguageIcons/xcode" {
        return Image(nsImage: XcodeArtwork.image)
    }
    let url = Bundle.main.resourceURL?.appendingPathComponent(name + "." + ext)
    if let url, let image = NSImage(contentsOf: url) { return Image(nsImage: image) }
    return Image(systemName: "chevron.left.forwardslash.chevron.right")
}

func sectionLabel(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 11, weight: .semibold))
        .tracking(1.5)
        .foregroundStyle(.secondary)
        .padding(.vertical, 1)
}
