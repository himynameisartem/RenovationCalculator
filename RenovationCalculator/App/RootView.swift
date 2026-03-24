//
//  RootView.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 19.02.2026.
//

import SwiftUI

struct RootView: View {
    @State private var showSavedEstimates = EstimateStorage.hasSavedEstimates()

    var body: some View {
        if showSavedEstimates {
            SavedEstimatesView(
                onNewCalculation: {
                    showSavedEstimates = false
                },
                onBecomeEmpty: {
                    showSavedEstimates = false
                }
            )
        } else {
            RoomsInputView()
        }
    }
}
