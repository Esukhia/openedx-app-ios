//
//  LanguageSelectionView.swift
//  Profile
//
//  Created for in-app language selection
//

import SwiftUI
import Core
import Theme

public struct LanguageSelectionView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isHorizontal) private var isHorizontal
    @State private var showRestartAlert = false
    @State private var selectedLanguageCode: String?
    
    private let visibleLanguageCodes = ["en", "bo", "zh-HK", "vi"]
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
                            Text("Language")
                                .titleSettings(color: Theme.Colors.loginNavigationText)
                                .accessibilityIdentifier("language_title")
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
                            let visibleLanguages = LanguageManager.availableLanguages.filter {
                                visibleLanguageCodes.contains($0.code)
                            }
                            ForEach(visibleLanguages, id: \.code) { language in
                                Button(action: {
                                    if language.code != languageManager.currentLanguage {
                                        selectedLanguageCode = language.code
                                        showRestartAlert = true
                                    }
                                }) {
                                    HStack {
                                        Text(language.name)
                                            .font(Theme.Fonts.titleMedium)
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if languageManager.currentLanguage == language.code {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Theme.Colors.accentColor)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                }
                                .accessibilityIdentifier("language_\(language.code)_button")
                                
                                if language.code != visibleLanguages.last?.code {
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
        .alert("Language updated", isPresented: $showRestartAlert) {
            Button("Later", role: .cancel) {
                if let languageCode = selectedLanguageCode {
                    languageManager.setLanguage(languageCode)
                }
                selectedLanguageCode = nil
                router.back()
            }
            Button("Close app") {
                if let languageCode = selectedLanguageCode {
                    languageManager.setLanguage(languageCode)
                }
                selectedLanguageCode = nil
                exit(0)
            }
        } message: {
            Text("The new language will be applied after you close and reopen the app. "
                 + "You can close the app now or do it later.")
        }
    }
}

#if DEBUG
#Preview {
    let router = ProfileRouterMock()
    LanguageSelectionView(router: router)
}
#endif
