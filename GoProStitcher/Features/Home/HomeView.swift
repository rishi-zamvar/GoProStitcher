import ComposableArchitecture
import SwiftUI

struct ToolDescriptor {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: AppFeature.Action
}

struct HomeView: View {
    let store: StoreOf<AppFeature>

    private let tools: [ToolDescriptor] = [
        ToolDescriptor(
            title: "Stitch Video",
            subtitle: "Combine GoPro chapter files into one",
            systemImage: "film.stack",
            action: .home(.stitchVideoTapped)
        ),
        ToolDescriptor(
            title: "Extract Audio",
            subtitle: "Pull audio track from any MP4",
            systemImage: "waveform",
            action: .home(.extractAudioTapped)
        ),
    ]

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                // Black header bar — retro game title screen
                RetroInvertedCard {
                    HStack {
                        Text("GoPro Toolkit")
                            .font(RetroFont.bold(22))
                            .foregroundColor(RetroColor.beigeBackground)
                        Spacer()
                        Text("v1.1")
                            .font(RetroFont.regular(11))
                            .foregroundColor(RetroColor.beigeSecondary)
                    }
                    .padding(.horizontal, RetroSpacing.md)
                    .padding(.vertical, RetroSpacing.sm)
                }

                // Tool rows
                VStack(spacing: RetroSpacing.sm) {
                    ForEach(tools, id: \.title) { tool in
                        ToolRowView(tool: tool) {
                            store.send(tool.action)
                        }
                    }
                }
                .padding(RetroSpacing.md)

                Spacer()
            }
            .background(RetroColor.beigeBackground)
            .frame(minWidth: 400, minHeight: 300)
        }
    }
}

// MARK: - ToolRowView

private struct ToolRowView: View {
    let tool: ToolDescriptor
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: RetroSpacing.md) {
                VStack(alignment: .leading, spacing: RetroSpacing.xs) {
                    Text("▶ \(tool.title.uppercased())")
                        .font(RetroFont.bold(16))
                        .foregroundColor(isHovered ? RetroColor.beigeBackground : RetroColor.black)
                    Text(tool.subtitle)
                        .font(RetroFont.regular(12))
                        .foregroundColor(isHovered ? RetroColor.beigeSecondary : RetroColor.muted)
                }
                Spacer()
                Text("[ SELECT ]")
                    .font(RetroFont.bold(11))
                    .foregroundColor(isHovered ? RetroColor.beigeBackground : RetroColor.black)
            }
            .padding(RetroSpacing.md)
            .background(isHovered ? RetroColor.black : RetroColor.white)
            .overlay(Rectangle().stroke(RetroColor.black, lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.linear(duration: 0.1), value: isHovered)
    }
}
