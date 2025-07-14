//
//  SocialAuthButton.swift
//  Core
//
//  Created by Eugene Yatsenko on 10.10.2023.
//

import SwiftUI
import Theme

public struct SocialAuthButton: View {

    // MARK: - Properties

    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    private var image: Image
    private var text: String
    private var accessibilityLabel: String
    private var accessibilityIdentifier: String
    private var action: () -> Void

    public init(
        image: Image,
        text: String,
        accessibilityLabel: String,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) {
        self.image = image
        self.text = text
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    // MARK: - Views

    public var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Text(text)
                    .font(Theme.Fonts.labelLarge)
                    .foregroundColor(Color.black.opacity(0.8))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(width: 280)
        }
        .background(Color.white)
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#if DEBUG
struct LabelButton_Previews: PreviewProvider {
    static var previews: some View {
        SocialAuthButton(
            image: CoreAssets.iconApple.swiftUIImage,
            text: "Continue with Apple",
            accessibilityLabel: "social auth button",
            accessibilityIdentifier: "some_identifier",
            action: {  }
        )
        .padding()
    }
}
#endif
