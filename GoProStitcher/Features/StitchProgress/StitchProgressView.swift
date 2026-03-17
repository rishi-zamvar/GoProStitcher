import ComposableArchitecture
import GoProStitcherKit
import Perception
import SwiftUI

struct StitchProgressView: View {
    @Perception.Bindable var store: StoreOf<StitchProgressFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 24) {
                Text("GoProStitcher")
                    .font(.title2).bold()

                if store.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("Done! Your video is ready.")
                        .font(.headline)
                    Text("Stitched file: \(store.chunks.first?.url.lastPathComponent ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("A manifest was saved so you can split it back into chunks later.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if let errMsg = store.errorMessage {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text("Error")
                        .font(.headline)
                    Text(errMsg)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    ProgressView(value: progressValue)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 400)

                    Text(phaseLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
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
