import AVFoundation
import AVKit
import AppKit
import SwiftUI

// MARK: - AVPlayerViewRepresentable

private struct AVPlayerViewRepresentable: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        let item = AVPlayerItem(url: url)
        item.forwardPlaybackEndTime = CMTime(seconds: 3, preferredTimescale: 600)
        let player = AVPlayer(playerItem: item)
        view.player = player
        view.controlsStyle = .default
        player.play()
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {}
}

// MARK: - ChunkPreviewModal

struct ChunkPreviewModal: View {
    let url: URL
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: RetroSpacing.md) {
            // Inverted title bar
            RetroInvertedCard {
                HStack {
                    Text("PREVIEW")
                        .font(RetroFont.bold(14))
                        .foregroundColor(RetroColor.beigeBackground)
                    Spacer()
                }
                .padding(.horizontal, RetroSpacing.md)
                .padding(.vertical, RetroSpacing.sm)
            }

            // Video player — 16:9 at 480pt wide, hard edge
            AVPlayerViewRepresentable(url: url)
                .frame(width: 480, height: 270)
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(RetroColor.black, lineWidth: 2))

            // Filename label
            Text(url.lastPathComponent)
                .font(RetroFont.regular(12))
                .foregroundColor(RetroColor.muted)
                .lineLimit(1)
                .truncationMode(.middle)

            // Close button
            RetroButton(title: "CLOSE") {
                onDismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(RetroSpacing.lg)
        .background(RetroColor.black)
        .frame(width: 528, height: 420)
    }
}
