//
//  ThemeSelectionView.swift
//  Profile
//
//  Created for in-app theme selection
//

import SwiftUI
import Core
import Theme

public struct ThemeSelectionView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isHorizontal) private var isHorizontal
    
    private let router: ProfileRouter
    
    public init(router: ProfileRouter) {
        self.router = router
    }
    
    public var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .top) {
                VStack {
                    ThemeAssets.headerBackground.swiftUIImage
                        .resizable()
                        .edgesIgnoringSafeArea(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: 110)
                .accessibilityIdentifier("auth_bg_image")
                
                VStack(alignment: .center) {
                    ZStack {
                        HStack {
                            Text("Theme")
                                .titleSettings(color: Theme.Colors.loginNavigationText)
                                .accessibilityIdentifier("theme_title")
                        }
                        VStack {
                            BackNavigationButton(
                                color: Theme.Colors.loginNavigationText,
                                action: {
                                    router.back()
                                }
                            )
                            .backViewStyle()
                            .padding(.leading, isHorizontal ? 48 : 0)
                            .accessibilityIdentifier("back_button")
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
                    }
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(ThemeMode.allCases, id: \.self) { mode in
                                Button(action: {
                                    themeManager.setMode(mode)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        router.back()
                                    }
                                }) {
                                    HStack {
                                        Text(mode.displayName)
                                            .font(Theme.Fonts.titleMedium)
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if themeManager.currentMode == mode {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Theme.Colors.accentColor)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                }
                                .accessibilityIdentifier("theme_\(mode.rawValue)_button")
                                
                                if mode != ThemeMode.allCases.last {
                                    Divider()
                                        .padding(.horizontal, 24)
                                }
                            }
                        }
                        .cardStyle(
                            bgColor: Theme.Colors.textInputUnfocusedBackground,
                            strokeColor: .clear
                        )
                        .padding(.top, 24)
                        .padding(.horizontal, isHorizontal ? 24 : 0)
                    }
                    .roundedBackground(Theme.Colors.background)
                }
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
            }
        }
        .background(
            Theme.Colors.background
                .ignoresSafeArea()
        )
        .ignoresSafeArea(.all, edges: .horizontal)
    }
}

#if DEBUG
#Preview {
    let router = ProfileRouterMock()
    ThemeSelectionView(router: router)
}
#endif
