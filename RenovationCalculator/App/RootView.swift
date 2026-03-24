//
//  RootView.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 19.02.2026.
//

import SwiftUI

struct RootView: View {
    @StateObject private var store: SavedEstimatesStore
    @StateObject private var router: AppRouter
    @StateObject private var savedEstimatesViewModel: SavedEstimatesViewModel
    @State private var isShowingLaunchScreen = true
    @State private var showLaunchProgress = false
    @State private var isAppReady = false
    @State private var didFinishLaunchIntro = false

    init() {
        let store = SavedEstimatesStore()
        let router = AppRouter()

        _store = StateObject(wrappedValue: store)
        _router = StateObject(wrappedValue: router)
        _savedEstimatesViewModel = StateObject(
            wrappedValue: SavedEstimatesViewModel(store: store, router: router)
        )
    }

    var body: some View {
        Group {
            if isShowingLaunchScreen {
                LaunchLoadingView(showProgress: showLaunchProgress)
            } else {
                switch router.rootScreen {
                case .savedEstimates:
                    SavedEstimatesView(viewModel: savedEstimatesViewModel)
                case .rooms:
                    RoomsInputView(
                        viewModel: RoomsInputViewModel(
                            store: store,
                            router: router
                        )
                    )
                }
            }
        }
        .id(router.rootViewID)
        .environmentObject(store)
        .environmentObject(router)
        .task {
            guard isShowingLaunchScreen else { return }

            router.show(store.hasSavedEstimates ? .savedEstimates : .rooms)
            isAppReady = true

            if didFinishLaunchIntro {
                isShowingLaunchScreen = false
            }
        }
        .task {
            guard isShowingLaunchScreen else { return }

            try? await Task.sleep(for: .seconds(3))
            didFinishLaunchIntro = true

            if isAppReady {
                isShowingLaunchScreen = false
            } else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showLaunchProgress = true
                }
            }
        }
    }
}
