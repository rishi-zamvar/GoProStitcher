import ComposableArchitecture
import GoProStitcherKit
import Perception
import SwiftUI

// MARK: - File Picker Screen

struct AudioFilePickerView: View {
    @Perception.Bindable var store: StoreOf<AudioFilePickerFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: RetroSpacing.lg) {
                Text("EXTRACT AUDIO")
                    .font(RetroFont.bold(18))
                    .foregroundColor(RetroColor.black)
                Text("Select an MP4 file to extract a 320 kbps MP3.")
                    .font(RetroFont.regular(13))
                    .foregroundColor(RetroColor.muted)
                    .multilineTextAlignment(.center)
                RetroButton(
                    title: "SELECT MP4 FILE",
                    action: { store.send(.selectFileButtonTapped) },
                    isDisabled: store.isLoading
                )
                if store.isLoading {
                    Text("[ LOADING... ]")
                        .font(RetroFont.regular(12))
                        .foregroundColor(RetroColor.muted)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(RetroSpacing.xxl)
            .background(RetroColor.beigeBackground)
        }
    }
}

// MARK: - Extraction Progress Screen

struct AudioExtractionView: View {
    @Perception.Bindable var store: StoreOf<AudioExtractionFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: RetroSpacing.lg) {
                Text("EXTRACT AUDIO")
                    .font(RetroFont.bold(18))
                    .foregroundColor(RetroColor.black)

                // Metadata — inverted header + white body card
                VStack(spacing: 0) {
                    RetroInvertedCard {
                        HStack {
                            Text("FILE")
                                .font(RetroFont.bold(11))
                                .foregroundColor(RetroColor.beigeSecondary)
                            Spacer()
                            Text(store.filename)
                                .font(RetroFont.regular(13))
                                .foregroundColor(RetroColor.beigeBackground)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(.horizontal, RetroSpacing.md)
                        .padding(.vertical, RetroSpacing.sm)
                    }

                    RetroCard {
                        VStack(spacing: RetroSpacing.xs) {
                            if let dur = store.durationSeconds {
                                metadataRow(label: "DURATION", value: formatDuration(dur))
                            }
                            if let bytes = store.fileSizeBytes {
                                metadataRow(label: "SIZE", value: formatSize(bytes))
                            }
                            if let kbps = store.audioBitrateKbps {
                                metadataRow(label: "AUDIO BITRATE", value: "\(kbps) kbps")
                            }
                        }
                        .padding(RetroSpacing.sm)
                    }
                }
                .frame(maxWidth: 400)

                if store.isComplete {
                    RetroCard {
                        VStack(spacing: RetroSpacing.sm) {
                            Text("[✓ MP3 SAVED]")
                                .font(RetroFont.bold(16))
                                .foregroundColor(RetroColor.black)
                            Text("MP3 saved and revealed in Finder.")
                                .font(RetroFont.regular(13))
                                .foregroundColor(RetroColor.muted)
                            if let out = store.outputURL {
                                Text(out.lastPathComponent)
                                    .font(RetroFont.regular(12))
                                    .foregroundColor(RetroColor.muted)
                            }
                        }
                        .padding(RetroSpacing.md)
                    }
                } else if let errMsg = store.errorMessage {
                    RetroCard {
                        VStack(spacing: RetroSpacing.sm) {
                            Text("[✗ FAILED]")
                                .font(RetroFont.bold(16))
                                .foregroundColor(RetroColor.accentRed)
                            Text(errMsg)
                                .font(RetroFont.regular(12))
                                .foregroundColor(RetroColor.accentRed)
                                .multilineTextAlignment(.center)
                        }
                        .padding(RetroSpacing.md)
                    }
                } else if store.isExtracting {
                    RetroCard {
                        VStack(spacing: RetroSpacing.sm) {
                            if store.progressFraction > 0 {
                                RetroProgressBar(fraction: store.progressFraction, blockCount: 16)
                                HStack {
                                    Text("\(Int(store.progressFraction * 100))%")
                                        .font(RetroFont.regular(12))
                                        .foregroundColor(RetroColor.muted)
                                    Spacer()
                                    if let total = store.durationSeconds {
                                        Text("\(formatDuration(store.secondsProcessed)) / \(formatDuration(total))")
                                            .font(RetroFont.regular(12))
                                            .foregroundColor(RetroColor.muted)
                                    }
                                }
                            } else {
                                RetroProgressBar(fraction: 0.0, blockCount: 8)
                                Text("STARTING...")
                                    .font(RetroFont.regular(12))
                                    .foregroundColor(RetroColor.muted)
                            }
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

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(RetroFont.bold(11))
                .foregroundColor(RetroColor.muted)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(RetroFont.regular(13))
                .foregroundColor(RetroColor.black)
            Spacer()
        }
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
