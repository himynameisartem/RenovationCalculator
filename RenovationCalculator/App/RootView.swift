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
    @State private var initialized = false

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
        .id(router.rootViewID)
        .environmentObject(store)
        .environmentObject(router)
        .onAppear {
            guard !initialized else { return }
            initialized = true
            router.show(store.hasSavedEstimates ? .savedEstimates : .rooms)
        }
    }
}
