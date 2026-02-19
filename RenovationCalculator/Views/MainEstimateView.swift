//
//  ContentView.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 19.02.2026.
//

import SwiftUI

struct MainEstimateView: View {
    @StateObject private var vm = MainEstimateViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if vm.categories.isEmpty {
                Text("Нет данных")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.categories.indices, id: \.self) { i in
                            let selected = i == vm.selectedCategoryIndex
                            Button(vm.categories[i].title) {
                                vm.selectedCategoryIndex = i
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selected ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selected ? .white : .primary)
                            .clipShape(Capsule())
                        }
                    }
                    .padding()
                }
            }
        }
    
        List {
            ForEach(vm.currentSections) { section in
                DisclosureGroup(section.title) {
                    ForEach(section.items) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                Text("\(item.price, specifier: "%.0f") ₽ / \(item.unit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button("Инфо") { vm.showInfo(item) }
                            Button("Добавить") { vm.showQuantity(item) }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .onAppear {
            vm.load()
        }
    }
}

#Preview {
    MainEstimateView()
}
