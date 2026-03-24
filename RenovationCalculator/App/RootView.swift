//
//  RootView.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 19.02.2026.
//

import SwiftUI

struct RootView: View {
    @StateObject private var store = SavedEstimatesStore()
    @StateObject private var router = AppRouter()
    @State private var initialized = false

    var body: some View {
        Group {
            switch router.rootScreen {
            case .savedEstimates:
                SavedEstimatesView()
            case .rooms:
                RoomsInputView()
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
