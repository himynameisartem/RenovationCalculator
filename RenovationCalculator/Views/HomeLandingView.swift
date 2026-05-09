import SwiftUI
import UIKit

struct HomeLandingView: View {
    let onOpenCalculator: () -> Void
    let onOpenRequest: () -> Void
    let onOpenPrice: () -> Void
    let onShowHelp: () -> Void
    @State private var showRequestForm = false
    @State private var showPriceConfirm = false
    @State private var isDownloadingPrice = false
    @State private var downloadedPriceURL: URL?
    @State private var showShareSheet = false
    @State private var downloadErrorText: String?
    @State private var showDownloadError = false
    private let pricePDFURL = URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!

    init(
        onOpenCalculator: @escaping () -> Void = {},
        onOpenRequest: @escaping () -> Void = {},
        onOpenPrice: @escaping () -> Void = {},
        onShowHelp: @escaping () -> Void = {}
    ) {
        self.onOpenCalculator = onOpenCalculator
        self.onOpenRequest = onOpenRequest
        self.onOpenPrice = onOpenPrice
        self.onShowHelp = onShowHelp
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    heroSection
                    cardsSection
                        .padding(.horizontal, 18)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            Button(action: onShowHelp) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.38))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 1)
                    Image(systemName: "questionmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 32)
            .padding(.trailing, 16)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showRequestForm) {
            RequestFormSheet(estimateLinesText: nil) { name, phone, email, comment, estimate in
                print("REQUEST_FROM_HOME")
                print("name: \(name)")
                print("phone: \(phone)")
                print("email: \(email)")
                print("comment: \(comment)")
                print("estimate: \(estimate ?? "none")")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = downloadedPriceURL {
                ShareSheetView(items: [url])
            }
        }
        .alert("Скачать прайс?", isPresented: $showPriceConfirm) {
            Button("Скачать") {
                Task { await downloadPricePDF() }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Будет загружен актуальный прайс в PDF.")
        }
        .alert("Ошибка загрузки", isPresented: $showDownloadError) {
            Button("Ок", role: .cancel) {}
        } message: {
            Text(downloadErrorText ?? "Не удалось скачать файл.")
        }
        .overlay {
            if isDownloadingPrice {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Загрузка прайса...")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
            }
        }
    }
 
    // MARK: - Hero
 
    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            HomeAssetImage(
                assetName: "landingImage",
                placeholder: AnyView(heroPlaceholder)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [
                        Color(UIColor.systemGroupedBackground),
                        Color(UIColor.systemGroupedBackground).opacity(0.85),
                        Color(UIColor.systemGroupedBackground).opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
 
            VStack(alignment: .leading, spacing: 12) {
                Text("Ремонт\nквартир")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
 
                Text("Рассчитайте стоимость\nи выберите подходящий\nвариант ремонта")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.black.opacity(0.5))
                    .multilineTextAlignment(.leading)
            }
            .padding(.top, 14)
            .padding(.leading, 18)
            .frame(maxWidth: 210, alignment: .leading)
        }
    }
 
    // MARK: - Cards
 
    private var cardsSection: some View {
        VStack(spacing: 14) {
            HomeActionCard(
                title: "Калькулятор",
                subtitle: "Рассчитайте стоимость\nремонта квартиры",
                icon: "plus.forwardslash.minus",
                accentColor: Color(red: 150/255, green: 200/255, blue: 255/255),
                foregroundColor: .white,
                isPrimaryStyle: true,
                background: AnyView(
                    LinearGradient(
                        colors: [
                            Color(red: 63/255, green: 123/255, blue: 227/255),
                            Color(red: 91/255, green: 166/255, blue: 242/255)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                ),
                decorativeContent: AnyView(
                    HomeAssetImage(
                        assetName: "calculatorImg",
                        placeholder: AnyView(calculatorCardPlaceholder)
                    )
                    .frame(width: 120, height: 100)
                    .offset(x: 50, y: 0)
                    .mask(
                        LinearGradient(
                            colors: [
                                .black.opacity(0.35),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                ),
                arrowColor: Color(red: 63/255, green: 123/255, blue: 227/255),
                action: onOpenCalculator
            )
 
            HomeActionCard(
                title: "Заявка на ремонт",
                subtitle: "Оставьте заявку и мы\nсвяжемся с вами",
                icon: "checklist",
                accentColor: Color(red: 42/255, green: 111/255, blue: 243/255),
                foregroundColor: .black,
                isPrimaryStyle: false,
                background: AnyView(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white)
                ),
                decorativeContent: AnyView(
                    HomeAssetImage(
                        assetName: "docsImg",
                        placeholder: AnyView(requestCardPlaceholder)
                    )
                    .frame(width: 112, height: 100)
                    .offset(x: 30, y: 0)
                    .mask(
                        LinearGradient(
                            colors: [
                                .black.opacity(0.35),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                ),
                arrowColor: Color(red: 42/255, green: 111/255, blue: 243/255),
                action: {
                    onOpenRequest()
                    showRequestForm = true
                }
            )
 
            HomeActionCard(
                title: "Актуальный прайс",
                subtitle: "Посмотрите актуальные\nцены на работы",
                icon: "banknote",
                accentColor: Color(red: 108/255, green: 174/255, blue: 95/255),
                foregroundColor: .black,
                isPrimaryStyle: false,
                background: AnyView(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white)
                ),
                decorativeContent: AnyView(
                    HomeAssetImage(
                        assetName: "coinsImg",
                        placeholder: AnyView(priceCardPlaceholder)
                    )
                    .scaledToFit()
                    .frame(width: 112, height: 120)
                    .offset(x: 40, y: 0)
                    .mask(
                        LinearGradient(
                            colors: [
                                .black.opacity(0.55),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                ),
                arrowColor: Color(red: 108/255, green: 174/255, blue: 95/255),
                action: {
                    onOpenPrice()
                    showPriceConfirm = true
                }
            )
        }
    }
    
    private func downloadPricePDF() async {
        isDownloadingPrice = true
        defer { isDownloadingPrice = false }

        do {
            let (tempURL, response) = try await URLSession.shared.download(from: pricePDFURL)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let fileName = "Актуальный_прайс.pdf"
            let destination = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: tempURL, to: destination)

            downloadedPriceURL = destination
            showShareSheet = true
        } catch {
            downloadErrorText = error.localizedDescription
            showDownloadError = true
        }
    }
 
    // MARK: - Placeholders
 
    private var heroPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 245/255, green: 238/255, blue: 230/255),
                    Color(red: 232/255, green: 222/255, blue: 210/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.65))
                    .frame(width: 85, height: 100)
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 110, height: 11)
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 90, height: 11)
            }
        }
    }
 
    private var calculatorCardPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
            Image(systemName: "ruler")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Color.white.opacity(0.18))
                .rotationEffect(.degrees(-20))
        }
    }
 
    private var requestCardPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.04))
                .frame(width: 70, height: 70)
                .offset(x: 16, y: -4)
            Image(systemName: "paintbrush")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Color.black.opacity(0.07))
                .offset(x: 14, y: -4)
        }
    }
 
    private var priceCardPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.04))
                .frame(width: 68, height: 68)
                .offset(x: 16, y: -4)
            Image(systemName: "rublesign.circle")
                .font(.system(size: 34, weight: .light))
                .foregroundColor(Color.black.opacity(0.07))
                .offset(x: 14, y: -4)
        }
    }
}
 
// MARK: - HomeActionCard
 
private struct HomeActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let foregroundColor: Color
    let isPrimaryStyle: Bool
    let background: AnyView
    let decorativeContent: AnyView
    let arrowColor: Color
    let action: () -> Void
 
    var body: some View {
        Button(action: action) {
            ZStack {
                background
 
                decorativeContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.trailing, 72)
                    .clipped()
 
                HStack(alignment: .center, spacing: 14) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentColor.opacity(isPrimaryStyle ? 0.22 : 0.11))
                        .frame(width: 58, height: 58)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(accentColor)
                        )
 
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(foregroundColor)
 
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(foregroundColor.opacity(isPrimaryStyle ? 0.72 : 0.5))
                            .fixedSize(horizontal: false, vertical: true)
                    }
 
                    Spacer(minLength: 8)
 
                    Circle()
                        .fill(Color.white)
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
                        .overlay(
                            Image(systemName: "arrow.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(arrowColor)
                        )
                }
                .padding(.horizontal, 14)
            }
        }
        .buttonStyle(CardButtonStyle())
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 14, y: 5)
    }
}
 
// MARK: - CardButtonStyle
 
private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
 
// MARK: - HomeAssetImage
 
private struct HomeAssetImage: View {
    let assetName: String
    let placeholder: AnyView
 
    var body: some View {
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }
}
 
// MARK: - Preview
 
#Preview("Root") {
    RootView()
}
 
#Preview("Home only") {
    NavigationStack {
        HomeLandingView()
    }
}
