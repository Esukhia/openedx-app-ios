import SwiftUI
import Core
import Theme

struct PurchaseConfirmationView: View {

    let purchaseURL: String
    let onDismiss: () -> Void

    private var validURL: URL? {
        guard let url = URL(string: purchaseURL),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else {
            return nil
        }
        return url
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .padding(8)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("purchase_dismiss_button")
                }

                Image(systemName: "cart.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(DiscoveryLocalization.Details.completePurchase)
                    .font(Theme.Fonts.headlineMedium)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(DiscoveryLocalization.Details.purchaseRedirectMessage)
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                StyledButton(
                    DiscoveryLocalization.Details.continue,
                    action: {
                        if let url = validURL {
                            UIApplication.shared.open(url)
                        }
                        onDismiss()
                    },
                    isActive: validURL != nil
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .accessibilityIdentifier("purchase_continue_button")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.Colors.background)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            )
            .padding(.horizontal, 40)
        }
    }
}
