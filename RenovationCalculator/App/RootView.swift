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
            title: "Добро пожаловать в Калькулятор ремонта.",
            subtitle: "Калькулятор ремонта — это профессиональный инструмент для расчета сметы, который стал доступен всем потребителям.",
            imageName: "home4"
        ),
        OnboardingStep(
            title: "Рассчитайте стоимость.",
            subtitle: "Нажмите на Калькулятор и самостоятельно рассчитайте стоимость своего ремонта, не прибегая к помощи инженеров-сметчиков, в легком и интуитивно понятном интерфейсе.",
            imageName: "home1"
        ),
        OnboardingStep(
            title: "Закажите звонок.",
            subtitle: "Если вы не хотите тратить время на расчеты, вы всегда можете оставить свои контакты, и наши менеджеры аккредитованных строительных компаний свяжутся с вами, чтобы сделать всю работу за вас.",
            imageName: "home3"
        ),
        OnboardingStep(
            title: "Получите актуальный прайс.",
            subtitle: "Для вашего удобства наш искусственный интеллект провел анализ цен огромного количества строительных компаний и готов предоставить вам самые актуальные данные.",
            imageName: "home2"
        )
    ]
    private let calculatorOnboardingSteps: [OnboardingStep] = [
        OnboardingStep(
            title: "Выбор комнат.",
            subtitle: "Здесь вы можете выбрать количество комнат и их площадь, чтобы калькулятор посчитал все за вас. Так же вы можете пропустить этот шаг, если хотите рассчитать все самостоятельно.",
            imageName: "calc1"
        ),
        OnboardingStep(
            title: "Выбор работ.",
            subtitle: "Выберите вид работы, который вам необходим, и просто добавьте его в смету.",
            imageName: "calc2"
        ),
        OnboardingStep(
            title: "Смета.",
            subtitle: "Вы выбрали нужные вам работы, пора переходить к ремонту. Выберите подходящую компанию и закажите звонок либо самостоятельно обратитесь по предоставленным контактам.",
            imageName: "calc3"
        )
    ]
    private let estimatesOnboardingSteps: [OnboardingStep] = [
        OnboardingStep(
            title: "Сохраненные сметы",
            subtitle: "Здесь хранятся ваши сохраненные расчеты. Можно открыть детали, что-то изменить, заказать звонок или удалить.",
            imageName: "estimate"
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
                            },
                            onShowHelp: {
                                forceShowOnboarding(for: .home)
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
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    forceShowOnboarding(for: .calculator)
                                } label: {
                                    Image(systemName: "questionmark")
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                    }
                    .id(calculatorStackID)
                    .tabItem {
                        Label("Расчет", systemImage: "compass.drawing")
                    }
                    .tag(RootTab.calculator)

                    NavigationStack {
                        SavedEstimatesView(viewModel: savedEstimatesViewModel)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button {
                                        forceShowOnboarding(for: .estimates)
                                    } label: {
                                        Image(systemName: "questionmark")
                                            .foregroundStyle(.black)
                                    }
                                }
                            }
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

    private func forceShowOnboarding(for tab: RootTab) {
        guard !isShowingLaunchScreen else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            activeOnboardingTab = tab
        }
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
