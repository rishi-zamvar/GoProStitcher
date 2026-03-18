import ComposableArchitecture
import GoProStitcherKit
import Perception
import SwiftUI

// MARK: - File Picker Screen

struct AudioFilePickerView: View {
    @Perception.Bindable var store: StoreOf<AudioFilePickerFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 24) {
                Text("Extract Audio")
                    .font(.title2).bold()
                Text("Select an MP4 file to extract a 320 kbps MP3.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: { store.send(.selectFileButtonTapped) }) {
                    Label("Select MP4 File", systemImage: "doc.badge.plus")
                }
                .disabled(store.isLoading)
                if store.isLoading {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        }
    }
}

// MARK: - Extraction Progress Screen

struct AudioExtractionView: View {
    @Perception.Bindable var store: StoreOf<AudioExtractionFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 24) {
                Text("Extract Audio")
                    .font(.title2).bold()

                // Metadata card
                VStack(alignment: .leading, spacing: 8) {
                    metadataRow(label: "File", value: store.filename)
                    if let dur = store.durationSeconds {
                        metadataRow(label: "Duration", value: formatDuration(dur))
                    }
                    if let bytes = store.fileSizeBytes {
                        metadataRow(label: "Size", value: formatSize(bytes))
                    }
                    if let kbps = store.audioBitrateKbps {
                        metadataRow(label: "Audio Bitrate", value: "\(kbps) kbps")
                    }
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))
                .cornerRadius(8)
                .frame(maxWidth: 400)

                if store.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("MP3 saved and revealed in Finder.")
                        .font(.headline)
                    if let out = store.outputURL {
                        Text(out.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let errMsg = store.errorMessage {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text("Extraction Failed")
                        .font(.headline)
                    Text(errMsg)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else if store.isExtracting {
                    VStack(spacing: 12) {
                        if store.progressFraction > 0 {
                            ProgressView(value: store.progressFraction)
                                .progressViewStyle(.linear)
                                .frame(maxWidth: 400)
                            HStack {
                                Text("\(Int(store.progressFraction * 100))%")
                                    .monospacedDigit()
                                Spacer()
                                if let total = store.durationSeconds {
                                    Text("\(formatDuration(store.secondsProcessed)) / \(formatDuration(total))")
                                        .monospacedDigit()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: 400)
                        } else {
                            ProgressView()
                                .progressViewStyle(.linear)
                                .frame(maxWidth: 400)
                            Text("Starting extraction\u{2026}")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary).frame(width: 110, alignment: .leading)
            Text(value).fontWeight(.medium)
            Spacer()
        }
        .font(.subheadline)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        return String(format: "%.1f MB", mb)
    }
}
