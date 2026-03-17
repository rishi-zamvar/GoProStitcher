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
        VStack(spacing: 16) {
            // Video player — 16:9 at 480pt wide
            AVPlayerViewRepresentable(url: url)
                .frame(width: 480, height: 270)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Filename label
            Text(url.lastPathComponent)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            // Close button
            Button("Close") {
                onDismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(width: 528, height: 380)
    }
}
