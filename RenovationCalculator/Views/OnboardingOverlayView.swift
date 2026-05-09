import SwiftUI

struct OnboardingStep: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String?
}

struct OnboardingOverlayView: View {
    let steps: [OnboardingStep]
    let onFinish: () -> Void
    let onSkip: () -> Void

    @State private var currentIndex = 0

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = min(proxy.size.width - 24, 560)
            let cardHeight = min(max(proxy.size.height * 0.84, 560), proxy.size.height - 16)
            let imageHeight = max(200, cardHeight * 0.50)

            ZStack {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    HStack {
                        Spacer()
                        Button(action: onSkip) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color.white.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }

                    imageBlock(for: steps[currentIndex], imageHeight: imageHeight)

                    VStack(spacing: 12) {
                        Text(steps[currentIndex].title)
                            .font(.system(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(steps[currentIndex].subtitle)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    TabView(selection: $currentIndex) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, _ in
                            Color.clear.tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                    .frame(height: 18)

                    Button {
                        if currentIndex < steps.count - 1 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentIndex += 1
                            }
                        } else {
                            onFinish()
                        }
                    } label: {
                        Text(currentIndex == steps.count - 1 ? "Начать" : "Далее")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.blue)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(22)
                .frame(width: cardWidth, height: cardHeight)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(white: 0.14, opacity: 0.92))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func imageBlock(for step: OnboardingStep, imageHeight: CGFloat) -> some View {
        if let imageName = step.imageName, !imageName.isEmpty {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(height: imageHeight)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 26))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Место для картинки")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
        }
    }
}
