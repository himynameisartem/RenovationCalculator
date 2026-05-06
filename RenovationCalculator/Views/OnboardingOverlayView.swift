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

                TabView(selection: $currentIndex) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        VStack(spacing: 16) {
                            imageBlock(for: step)

                            Text(step.title)
                                .font(.system(size: 22, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)

                            Text(step.subtitle)
                                .font(.system(size: 15))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.white.opacity(0.9))
                                .padding(.horizontal, 12)
                        }
                        .padding(.horizontal, 10)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                .frame(height: 430)

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
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.blue)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(white: 0.14, opacity: 0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func imageBlock(for step: OnboardingStep) -> some View {
        if let imageName = step.imageName, !imageName.isEmpty {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(height: 220)
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
