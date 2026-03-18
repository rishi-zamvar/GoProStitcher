import ComposableArchitecture

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {}

    enum Action {
        case stitchVideoTapped
        case extractAudioTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            .none  // Navigation handled by parent AppFeature
        }
    }
}
