//
//  Extension+View.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 13.03.2026.
//

import SwiftUI
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    func appScreenBackground() -> some View {
        background(
            Color(
                red: 242.0 / 255.0,
                green: 242.0 / 255.0,
                blue: 247.0 / 255.0
            )
            .ignoresSafeArea()
        )
    }

    func transparentListContent() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    func appListCardBackground() -> some View {
        listRowBackground(Color(.secondarySystemGroupedBackground))
    }
}
