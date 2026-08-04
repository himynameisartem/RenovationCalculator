# Renovation Calculator iOS

Commercial iOS application for estimating apartment renovation costs, saving estimates, requesting a callback, downloading the current price list, and using an AI assistant for renovation-related questions.

App Store: [Калькулятор ремонта](https://apps.apple.com/us/app/%D0%BA%D0%B0%D0%BB%D1%8C%D0%BA%D1%83%D0%BB%D1%8F%D1%82%D0%BE%D1%80-%D1%80%D0%B5%D0%BC%D0%BE%D0%BD%D1%82%D0%B0/id6761184107)

## Table of Contents

- [Русский](#русский)
- [English](#english)

## Русский

### О проекте

**Калькулятор ремонта** - это iOS-приложение для расчета стоимости ремонта квартиры. Пользователь выбирает помещения, площади и виды работ, получает предварительную смету, может сохранить расчет, отправить заявку на ремонт или задать вопрос AI-помощнику.

Проект построен как реальное мобильное приложение, а не учебный прототип: есть навигация, сохранение пользовательских расчетов, загрузка актуального каталога работ, onboarding, аналитика и интеграция с backend-сервисом для AI-чата.

### Возможности

- Расчет стоимости ремонта по помещениям, площадям и выбранным работам.
- Загрузка каталога работ и цен с кешированием на устройстве.
- Сохранение, просмотр, редактирование и удаление смет.
- Форма заявки на ремонт.
- Загрузка актуального прайса в PDF.
- Onboarding-подсказки для основных экранов приложения.
- AI-помощник по вопросам ремонта и услуг компании.
- Ограничение длины пользовательского сообщения в AI-чате.
- Интеграция с AppMetrica для аналитики и обработки deeplink-открытий.

### AI-Помощник

AI-чат встроен в главный экран приложения как отдельный floating-компонент. Приложение отправляет вопрос пользователя на backend по HTTPS, получает готовый ответ и отображает его в интерфейсе.

Мобильное приложение не хранит историю AI-диалога между запусками. Сообщения живут только в текущей сессии экрана. Backend-часть RAG-системы вынесена отдельно: она отвечает за retrieval, работу с векторной базой и генерацию ответа.

### Архитектура

Приложение использует SwiftUI и MVVM-подход:

```text
Views -> ViewModels -> Services -> Models
```

Основной поток данных:

```text
User Input
  -> SwiftUI View
  -> ViewModel
  -> Service
  -> Local Storage / Remote API
  -> ViewModel State
  -> SwiftUI UI Update
```

AI-чат:

```text
ChatBubbleView
  -> ChatViewModel
  -> ChatAPIClient
  -> FastAPI RAG Backend
  -> AI Answer
```

### Структура проекта

```text
App/
  RootView.swift
  AppRouter.swift
  RenovationCalculatorApp.swift
  AppMetricaBridge.swift

Views/
  HomeLandingView.swift
  RoomsInputView.swift
  MainEstimateView.swift
  FinalEstimateView.swift
  SavedEstimatesView.swift
  ChatBubbleView.swift
  OnboardingOverlayView.swift

ViewModels/
  RoomsInputViewModel.swift
  MainEstimateViewModel.swift
  FinalEstimateViewModel.swift
  SavedEstimatesViewModel.swift
  ChatViewModel.swift

Services/
  CatalogService.swift
  EstimateStorage.swift
  SavedEstimatesStore.swift
  EstimateSaveService.swift
  ChatAPIClient.swift

Models/
  Catalog.swift
  Category.swift
  WorkSection.swift
  WorkItem.swift
  RoomInput.swift
  EstimateSummaryLine.swift
  ChatMessage.swift

DataManager/
  CatalogLoader.swift
  NetworkManager.swift

Resources/
  PrivacyInfo.xcprivacy
```

### Технологии

- Swift
- SwiftUI
- Combine
- MVVM
- URLSession
- Local JSON storage
- AppMetrica
- FastAPI backend integration
- RAG backend integration

### Запуск

1. Открыть проект в Xcode.
2. Выбрать схему `RenovationCalculator`.
3. Выбрать iOS Simulator или физическое устройство.
4. Запустить приложение через `Run`.

Для AI-чата нужен доступ к backend endpoint, указанный в `Services/ChatAPIClient.swift`.

### Связанные Проекты

Backend и RAG-пайплайн вынесены в отдельный проект:

- Парсинг сайта и прайса.
- Подготовка документов.
- Chunking.
- Embeddings.
- Qdrant vector store.
- FastAPI endpoint для мобильного приложения.
- Интеграция с LLM.

## English

### Overview

**Renovation Calculator** is iOS application for estimating apartment renovation costs. Users can select rooms, areas, and renovation work items, generate a preliminary estimate, save it locally, request a callback, download the current price list, or ask the built-in AI assistant renovation-related questions.

The project is built as a production-oriented mobile application rather than a learning prototype. It includes navigation, local estimate storage, remote catalog loading with cache fallback, onboarding screens, analytics, and backend integration for the AI chat.

### Features

- Renovation cost estimation based on rooms, areas, and selected work items.
- Remote work catalog and price loading with local cache fallback.
- Saved estimates with viewing, editing, and deletion.
- Renovation request form.
- Current price list PDF download.
- Onboarding hints for main application flows.
- AI assistant for renovation and company service questions.
- User message length limit for AI chat.
- AppMetrica integration for analytics and deeplink handling.

### AI Assistant

The AI chat is integrated into the home screen as a floating component. The app sends the user's question to a HTTPS backend, receives the generated answer, and renders it in the chat UI.

The mobile app does not persist AI conversation history between launches. Chat messages are kept only in the current screen session. The RAG backend is implemented separately and handles retrieval, vector search, and answer generation.

### Architecture

The application follows a SwiftUI + MVVM structure:

```text
Views -> ViewModels -> Services -> Models
```

Main data flow:

```text
User Input
  -> SwiftUI View
  -> ViewModel
  -> Service
  -> Local Storage / Remote API
  -> ViewModel State
  -> SwiftUI UI Update
```

AI chat flow:

```text
ChatBubbleView
  -> ChatViewModel
  -> ChatAPIClient
  -> FastAPI RAG Backend
  -> AI Answer
```

### Project Structure

```text
App/
  RootView.swift
  AppRouter.swift
  RenovationCalculatorApp.swift
  AppMetricaBridge.swift

Views/
  HomeLandingView.swift
  RoomsInputView.swift
  MainEstimateView.swift
  FinalEstimateView.swift
  SavedEstimatesView.swift
  ChatBubbleView.swift
  OnboardingOverlayView.swift

ViewModels/
  RoomsInputViewModel.swift
  MainEstimateViewModel.swift
  FinalEstimateViewModel.swift
  SavedEstimatesViewModel.swift
  ChatViewModel.swift

Services/
  CatalogService.swift
  EstimateStorage.swift
  SavedEstimatesStore.swift
  EstimateSaveService.swift
  ChatAPIClient.swift

Models/
  Catalog.swift
  Category.swift
  WorkSection.swift
  WorkItem.swift
  RoomInput.swift
  EstimateSummaryLine.swift
  ChatMessage.swift

DataManager/
  CatalogLoader.swift
  NetworkManager.swift

Resources/
  PrivacyInfo.xcprivacy
```

### Tech Stack

- Swift
- SwiftUI
- Combine
- MVVM
- URLSession
- Local JSON storage
- AppMetrica
- FastAPI backend integration
- RAG backend integration

### Running Locally

1. Open the project in Xcode.
2. Select the `RenovationCalculator` scheme.
3. Select an iOS Simulator or a physical device.
4. Run the app.

The AI chat requires access to the backend endpoint configured in `Services/ChatAPIClient.swift`.

### Related Projects

The backend and RAG pipeline are implemented as a separate project:

- Website and price list parsing.
- Document preparation.
- Chunking.
- Embedding generation.
- Qdrant vector store.
- FastAPI endpoint for the mobile app.
- LLM integration.
