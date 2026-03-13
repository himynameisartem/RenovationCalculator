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
}

