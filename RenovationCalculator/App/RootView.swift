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
    @AppStorage("hasSeenHomeOnboarding") private var hasSeenHomeOnboarding = false
    @AppStorage("hasSeenCalculatorOnboarding") private var hasSeenCalculatorOnboarding = false
    @AppStorage("hasSeenEstimatesOnboarding") private var hasSeenEstimatesOnboarding = false

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
    @State private var activeOnboardingTab: RootTab?

    private let homeOnboardingSteps: [OnboardingStep] = [
        OnboardingStep(
            title: "Добро пожаловать",
            subtitle: "Это заготовка подсказки. Добавь сюда свой текст и картинку.",
            imageName: nil
        ),
        OnboardingStep(
            title: "Выбор помещений",
            subtitle: "Покажи пользователю, как заполнить комнаты и перейти к работам.",
            imageName: nil
        ),
        OnboardingStep(
            title: "Финальная смета",
            subtitle: "Расскажи, как сохранить смету и где посмотреть сохраненные расчеты.",
            imageName: nil
        )
    ]
    private let calculatorOnboardingSteps: [OnboardingStep] = [
        OnboardingStep(
            title: "Калькулятор",
            subtitle: "Здесь выбери помещения и задай параметры для расчета стоимости.",
            imageName: nil
        ),
        OnboardingStep(
            title: "Далее к работам",
            subtitle: "После заполнения нажми «Продолжить», чтобы перейти к списку работ.",
            imageName: nil
        )
    ]
    private let estimatesOnboardingSteps: [OnboardingStep] = [
        OnboardingStep(
            title: "Сохраненные сметы",
            subtitle: "Здесь хранятся сохраненные расчеты. Можно открыть детали и удалить свайпом.",
            imageName: nil
        )
    ]

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
                    showOnboardingIfNeeded(for: newTab)
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
        .overlay {
            if let tab = activeOnboardingTab {
                OnboardingOverlayView(
                    steps: onboardingSteps(for: tab),
                    onFinish: {
                        markOnboardingSeen(for: tab)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeOnboardingTab = nil
                        }
                    },
                    onSkip: {
                        markOnboardingSeen(for: tab)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeOnboardingTab = nil
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
        .environmentObject(store)
        .environmentObject(router)
        .onChange(of: isShowingLaunchScreen) { _, isVisible in
            if !isVisible {
                showOnboardingIfNeeded(for: selectedTab)
            }
        }
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

    private func showOnboardingIfNeeded(for tab: RootTab) {
        guard !isShowingLaunchScreen else { return }
        guard activeOnboardingTab == nil else { return }
        guard shouldShowOnboarding(for: tab) else { return }
        activeOnboardingTab = tab
    }

    private func shouldShowOnboarding(for tab: RootTab) -> Bool {
        switch tab {
        case .home:
            return !hasSeenHomeOnboarding
        case .calculator:
            return !hasSeenCalculatorOnboarding
        case .estimates:
            return !hasSeenEstimatesOnboarding
        }
    }

    private func markOnboardingSeen(for tab: RootTab) {
        switch tab {
        case .home:
            hasSeenHomeOnboarding = true
        case .calculator:
            hasSeenCalculatorOnboarding = true
        case .estimates:
            hasSeenEstimatesOnboarding = true
        }
    }

    private func onboardingSteps(for tab: RootTab) -> [OnboardingStep] {
        switch tab {
        case .home:
            return homeOnboardingSteps
        case .calculator:
            return calculatorOnboardingSteps
        case .estimates:
            return estimatesOnboardingSteps
        }
    }
}
