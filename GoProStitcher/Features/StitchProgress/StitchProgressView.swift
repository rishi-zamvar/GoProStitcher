import ComposableArchitecture
import GoProStitcherKit
import Perception
import SwiftUI

struct StitchProgressView: View {
    @Perception.Bindable var store: StoreOf<StitchProgressFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: RetroSpacing.lg) {
                Text("GoPro Toolkit")
                    .font(RetroFont.bold(18))
                    .foregroundColor(RetroColor.black)

                if store.isComplete {
                    RetroCard {
                        VStack(spacing: RetroSpacing.sm) {
                            Text("[✓ COMPLETE]")
                                .font(RetroFont.bold(16))
                                .foregroundColor(RetroColor.black)
                            Text("Stitched file: \(store.chunks.first?.url.lastPathComponent ?? "")")
                                .font(RetroFont.regular(12))
                                .foregroundColor(RetroColor.muted)
                                .multilineTextAlignment(.center)
                            Text("A manifest was saved so you can split it back into chunks later.")
                                .font(RetroFont.regular(11))
                                .foregroundColor(RetroColor.muted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(RetroSpacing.md)
                    }
                } else if let errMsg = store.errorMessage {
                    RetroCard {
                        VStack(spacing: RetroSpacing.sm) {
                            Text("[✗ ERROR]")
                                .font(RetroFont.bold(16))
                                .foregroundColor(RetroColor.accentRed)
                            Text(errMsg)
                                .font(RetroFont.regular(12))
                                .foregroundColor(RetroColor.accentRed)
                                .multilineTextAlignment(.center)
                        }
                        .padding(RetroSpacing.md)
                    }
                } else {
                    RetroCard {
                        VStack(spacing: RetroSpacing.sm) {
                            RetroProgressBar(fraction: progressValue, blockCount: 16)
                            Text(phaseLabel)
                                .font(RetroFont.regular(13))
                                .foregroundColor(RetroColor.muted)
                        }
                        .padding(RetroSpacing.md)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(RetroSpacing.xxl)
            .background(RetroColor.beigeBackground)
        }
    }

    private var progressValue: Double {
        let total = Double(store.chunks.count)
        guard total > 0 else { return 0 }
        switch store.phase {
        case .savingManifest:
            return 0.05
        case .stitching(let idx, _):
            return 0.1 + 0.9 * Double(idx) / total
        case .complete: return 1.0
        case .failed: return 0.0
        }
    }

    private var phaseLabel: String {
        let total = store.chunks.count
        switch store.phase {
        case .savingManifest:
            return "Saving manifest..."
        case .stitching(let idx, let name):
            return "Stitching \(idx)/\(total): \(name)"
        case .complete: return "Complete"
        case .failed(let msg): return "Failed: \(msg)"
        }
    }
}

#Preview {
    StitchProgressView(
        store: Store(
            initialState: StitchProgressFeature.State(chunks: [])
        ) {
            StitchProgressFeature()
        }
    )
}
