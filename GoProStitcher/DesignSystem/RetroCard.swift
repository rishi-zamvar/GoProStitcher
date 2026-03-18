import SwiftUI

/// White card on beige background with 2px black border. No corner radius.
struct RetroCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .background(RetroColor.white)
            .overlay(Rectangle().stroke(RetroColor.black, lineWidth: 2))
    }
}

/// Inverted card: black background with beige text. Used for metadata headers.
struct RetroInvertedCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .background(RetroColor.black)
            .overlay(Rectangle().stroke(RetroColor.black, lineWidth: 2))
    }
}
