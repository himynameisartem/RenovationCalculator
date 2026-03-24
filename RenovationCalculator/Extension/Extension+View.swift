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
                uiColor: UIColor { trait in
                    if trait.userInterfaceStyle == .dark {
                        return UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
                    } else {
                        return UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
                    }
                }
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
