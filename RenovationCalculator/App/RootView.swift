//
//  RootView.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 19.02.2026.
//

import SwiftUI
import Combine

private enum RootTab: Hashable {
    case home
    case calculator
    case estimates
}

struct RootView: View {
    @StateObject private var store: SavedEstimatesStore
    @StateObject private var router: AppRouter
    @StateObject private var savedEstimatesViewModel: SavedEstimatesViewModel

    @State private var selectedTab: RootTab

    // Recreate stack by id to always return to parent view on tab switch.
    @State private var homeStackID = UUID()
    @State private var calculatorStackID = UUID()
    @State private var estimatesStackID = UUID()

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

        _selectedTab = State(initialValue: .home)
    }

    var body: some View {
        Group {
            if isShowingLaunchScreen {
                LaunchLoadingView(showProgress: showLaunchProgress)
            } else {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        HomeLandingView(
                            onOpenCalculator: {
                                openRootTab(.calculator)
                            }
                        )
                    }
                    .id(homeStackID)
                    .tabItem {
                        Label("Главная", systemImage: "house")
                    }
                    .tag(RootTab.home)

                    NavigationStack {
                        RoomsInputView(
                            viewModel: RoomsInputViewModel(
                                store: store,
                                router: router
                            )
                        )
                    }
                    .id(calculatorStackID)
                    .tabItem {
                        Label("Расчет", systemImage: "compass.drawing")
                    }
                    .tag(RootTab.calculator)

                    NavigationStack {
                        SavedEstimatesView(viewModel: savedEstimatesViewModel)
                    }
                    .id(estimatesStackID)
                    .tabItem {
                        Label("Сметы", systemImage: "checklist")
                    }
                    .tag(RootTab.estimates)
                }
                .tint(Color(red: 88/255, green: 154/255, blue: 244/255))
                .onChange(of: selectedTab) { _, newTab in
                    resetStack(for: newTab)
                }
                .onReceive(router.$rootScreen.dropFirst()) { screen in
                    switch screen {
                    case .rooms:
                        openRootTab(.calculator)
                    case .savedEstimates:
                        openRootTab(.estimates)
                    }
                }
                .id(router.rootViewID)
            }
        }
        .environmentObject(store)
        .environmentObject(router)
        .task {
            guard isShowingLaunchScreen else { return }
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

    private func openRootTab(_ tab: RootTab) {
        selectedTab = tab
        resetStack(for: tab)
    }

    private func resetStack(for tab: RootTab) {
        switch tab {
        case .home:
            homeStackID = UUID()
        case .calculator:
            calculatorStackID = UUID()
        case .estimates:
            estimatesStackID = UUID()
        }
    }
}
