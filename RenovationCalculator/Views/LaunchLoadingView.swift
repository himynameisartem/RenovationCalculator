import SwiftUI

struct LaunchLoadingView: View {
    let showProgress: Bool

    @State private var isLogoVisible = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .opacity(isLogoVisible ? 1 : 0)
                .scaleEffect(isLogoVisible ? 1 : 0.94)

            if showProgress {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.blue)
                    .transition(.opacity)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreenBackground()
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0)) {
                isLogoVisible = true
            }
        }
    }
}

#Preview {
    LaunchLoadingView(showProgress: true)
}
