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
            VStack(spacing: 24) {
                Text("GoPro Toolkit")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 32)

                ForEach(tools, id: \.title) { tool in
                    Button {
                        store.send(tool.action)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: tool.systemImage)
                                .font(.system(size: 28))
                                .frame(width: 44)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tool.title)
                                    .font(.headline)
                                Text(tool.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(minWidth: 400, minHeight: 300)
        }
    }
}
