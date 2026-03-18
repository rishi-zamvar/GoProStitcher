import AppKit
import AVFoundation
import ComposableArchitecture
import GoProStitcherKit

@Reducer
struct AudioExtractionFeature {
    @ObservableState
    struct State: Equatable {
        var sourceURL: URL
        var filename: String
        var durationSeconds: Double? = nil
        var fileSizeBytes: Int64? = nil
        var audioBitrateKbps: Int? = nil
        var isExtracting: Bool = false
        var isComplete: Bool = false
        var outputURL: URL? = nil
        var errorMessage: String? = nil
    }

    enum Action {
        case startExtraction
        case metadataLoaded(duration: Double?, fileSize: Int64?, audioBitrate: Int?)
        case extractionCompleted(URL)
        case extractionFailed(String)
        case revealInFinder
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startExtraction:
                state.isExtracting = true
                let url = state.sourceURL
                return .run { send in
                    // Load metadata concurrently with extraction
                    async let duration = AVMetadataReader.duration(url: url)
                    let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? nil
                    // Read audio bitrate from first audio track
                    let asset = AVURLAsset(url: url)
                    let audioBitrate: Int?
                    if let tracks = try? await asset.loadTracks(withMediaType: .audio),
                       let track = tracks.first,
                       let estimatedDataRate = try? await track.load(.estimatedDataRate) {
                        audioBitrate = Int(estimatedDataRate / 1000)
                    } else {
                        audioBitrate = nil
                    }
                    let dur = await duration
                    await send(.metadataLoaded(duration: dur, fileSize: fileSize, audioBitrate: audioBitrate))

                    // Run extraction (synchronous ffmpeg call — must not block main actor)
                    do {
                        let outputURL = try AudioExtractor.extract(url: url)
                        await send(.extractionCompleted(outputURL))
                    } catch {
                        await send(.extractionFailed(error.localizedDescription))
                    }
                }

            case let .metadataLoaded(duration, fileSize, audioBitrate):
                state.durationSeconds = duration
                state.fileSizeBytes = fileSize
                state.audioBitrateKbps = audioBitrate
                return .none

            case let .extractionCompleted(url):
                state.isExtracting = false
                state.isComplete = true
                state.outputURL = url
                return .send(.revealInFinder)

            case let .extractionFailed(message):
                state.isExtracting = false
                state.errorMessage = message
                return .none

            case .revealInFinder:
                guard let outputURL = state.outputURL else { return .none }
                return .run { _ in
                    await MainActor.run {
                        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                    }
                }
            }
        }
    }
}
