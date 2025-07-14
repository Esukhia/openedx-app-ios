//
//  SignInView.swift
//  Authorization
//
//  Created by Vladimir Chekyrta on 13.09.2022.
//

import SwiftUI
import Core
import OEXFoundation
import Theme
import Swinject

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

public struct SignInView: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @Environment(\.isHorizontal) private var isHorizontal
    
    @ObservedObject
    private var viewModel: SignInViewModel
    
    public init(viewModel: SignInViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            VStack {
                ThemeAssets.headerBackground.swiftUIImage
                    .resizable()
                    .edgesIgnoringSafeArea(.top)
                    .accessibilityIdentifier("auth_bg_image")
                    .overlay(
                        VStack {
                            Spacer()
                            // Welcome text removed
                        }
                    )
            }.frame(maxWidth: .infinity, maxHeight: 200)
            if viewModel.config.features.startupScreenEnabled {
                VStack {
                    BackNavigationButton(
                        color: Theme.Colors.loginNavigationText,
                        action: {
                            viewModel.router.back()
                        }
                    )
                    .backViewStyle()
                    .padding(.leading, isHorizontal ? 48 : 0)
                    .padding(.top, 11)
                    
                }.frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, isHorizontal ? 20 : 0)
            }
            
            VStack(alignment: .center) {
                ThemeAssets.appLogo.swiftUIImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 250, maxHeight: 120)
                    .padding(.top, isHorizontal ? 20 : 40)
                    .padding(.bottom, isHorizontal ? 10 : 40)
                    .accessibilityIdentifier("logo_image")
                
                GeometryReader { proxy in
                    ScrollView {
                        VStack {
                            VStack(alignment: .leading) {
                                if viewModel.config.uiComponents.loginRegistrationEnabled {
                                    Text(AuthLocalization.SignIn.logInTitle)
                                        .font(Theme.Fonts.displaySmall)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                        .padding(.bottom, 4)
                                        .accessibilityIdentifier("signin_text")
                                    Text(AuthLocalization.SignIn.welcomeBack)
                                        .font(Theme.Fonts.titleSmall)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                        .padding(.bottom, 20)
                                        .accessibilityIdentifier("welcome_back_text")
                                    if viewModel.socialAuthEnabled {
                                        SocialAuthView(
                                            viewModel: .init(
                                                config: viewModel.config,
                                                lastUsedOption: viewModel.storage.lastUsedSocialAuth
                                            ) { result in
                                                Task { await viewModel.login(with: result) }
                                            }
                                        )
                                        .padding(.top, 22)
                                        .padding(.bottom, 16)
                                    }
                                    Text(AuthLocalization.SignIn.emailOrUsername)
                                        .font(Theme.Fonts.labelLarge)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                        .accessibilityIdentifier("username_text")
                                    TextField("", text: $email)
                                        .font(Theme.Fonts.bodyLarge)
                                        .foregroundColor(Theme.Colors.textInputTextColor)
                                        .keyboardType(.emailAddress)
                                        .textContentType(.emailAddress)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .padding(.all, 14)
                                        .background(
                                            Theme.InputFieldBackground(
                                                placeHolder: AuthLocalization.SignIn.emailOrUsername,
                                                text: email,
                                                padding: 15
                                            )
                                        )
                                        .overlay(
                                            Theme.Shapes.textInputShape
                                                .stroke(lineWidth: 1)
                                                .fill(Theme.Colors.textInputStroke)
                                        )
                                        .accessibilityIdentifier("username_textfield")
                                    
                                    Text(AuthLocalization.SignIn.password)
                                        .font(Theme.Fonts.labelLarge)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                        .padding(.top, 18)
                                        .accessibilityIdentifier("password_text")
                                    SecureInputView($password)
                                        .font(Theme.Fonts.bodyLarge)
                                        .padding(.all, 14)
                                        .background(
                                            Theme.InputFieldBackground(
                                                placeHolder: AuthLocalization.SignIn.password,
                                                text: password,
                                                padding: 15
                                            )
                                        )
                                        .overlay(
                                            Theme.Shapes.textInputShape
                                                .stroke(lineWidth: 1)
                                                .fill(Theme.Colors.textInputStroke)
                                        )
                                        .accessibilityIdentifier("password_textfield")
                                    HStack {
                                        if !viewModel.config.features.startupScreenEnabled {
                                            Button(CoreLocalization.SignIn.registerBtn) {
                                                viewModel.router.showRegisterScreen(
                                                    sourceScreen: viewModel.sourceScreen
                                                )
                                            }
                                            .foregroundColor(Theme.Colors.accentColor)
                                            .accessibilityIdentifier("register_button")
                                            
                                            Spacer()
                                        }
                                        
                                        Button(AuthLocalization.SignIn.forgotPassBtn) {
                                            viewModel.trackForgotPasswordClicked()
                                            viewModel.router.showForgotPasswordScreen()
                                        }
                                        .font(Theme.Fonts.bodyLarge)
                                        .foregroundColor(Theme.Colors.infoColor)
                                        .padding(.top, 0)
                                        .accessibilityIdentifier("forgot_password_button")
                                    }
                                    
                                    if viewModel.isShowProgress {
                                        HStack(alignment: .center) {
                                            ProgressBar(size: 40, lineWidth: 8)
                                                .padding(20)
                                                .accessibilityIdentifier("progress_bar")
                                        }.frame(maxWidth: .infinity)
                                    } else {
                                        StyledButton(
                                            CoreLocalization.SignIn.logInBtn,
                                            action: {
                                                Task {
                                                    await viewModel.login(username: email, password: password)
                                                }
                                            },
                                            color: Color(hex: "#FFAF66")
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.top, 20)
                                        .accessibilityIdentifier("signin_button")
                                        
                                        // "or" divider removed
                                    }
                                }
                                if viewModel.config.uiComponents.samlSSOLoginEnabled {
                                    if !viewModel.config.uiComponents.loginRegistrationEnabled {
                                        VStack(alignment: .center) {
                                            Text(AuthLocalization.SignIn.ssoHeading)
                                                .font(Theme.Fonts.headlineSmall)
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(Theme.Colors.textPrimary)
                                                .padding(.bottom, 4)
                                                .padding(.horizontal, 20)
                                                .accessibilityIdentifier("signin_sso_heading")
                                        }
                                        
                                        Divider()
                                        
                                        VStack(alignment: .center) {
                                            Text(AuthLocalization.SignIn.ssoLogInTitle)
                                                .font(Theme.Fonts.headlineSmall)
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(Theme.Colors.textPrimary)
                                                .padding(.bottom, 10)
                                                .padding(.horizontal, 20)
                                                .accessibilityIdentifier("signin_sso_login_title")
                                            
                                            Text(AuthLocalization.SignIn.ssoLogInSubtitle)
                                                .font(Theme.Fonts.titleMedium)
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(Theme.Colors.textSecondaryLight)
                                                .padding(.bottom, 10)
                                                .padding(.horizontal, 20)
                                                .accessibilityIdentifier("signin_sso_login_subtitle")
                                        }
                                    }
                                    
                                    VStack(alignment: .center) {
                                        if viewModel.isShowProgress {
                                            HStack(alignment: .center) {
                                                ProgressBar(size: 40, lineWidth: 8)
                                                    .padding(20)
                                                    .accessibilityIdentifier("progressbar")
                                            }.frame(maxWidth: .infinity)
                                        } else {
                                            let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
                                            // Google sign-in button styled to match the design
                                            Button(action: {
                                                viewModel.router
                                                    .showSSOWebBrowser(title: CoreLocalization.SignIn.logInBtn)
                                            }) {
                                                HStack {
                                                    Text("Continue with Google")
                                                        .font(Theme.Fonts.labelLarge)
                                                        .foregroundColor(Color.gray)
                                                }
                                                .frame(width: 250)
                                                .padding(.vertical, 10)
                                                .background(Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(Color(hex: "#FFAF66"), lineWidth: 1)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .frame(maxWidth: .infinity)
                                            .accessibilityIdentifier("signin_SSO_button")
                                        }
                                    }
                                }
                            }
                            agreements
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 50)
                        .frameLimit(width: proxy.size.width)
                    }
                    .background(Theme.Colors.loginBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.top, -20)
                    .scrollAvoidKeyboard(dismissKeyboardByTap: true)
                }
            }
            
            // MARK: - Alert
            if viewModel.showAlert {
                VStack {
                    Text(viewModel.alertMessage ?? "")
                        .shadowCardStyle(bgColor: Theme.Colors.accentColor,
                                         textColor: Theme.Colors.white)
                        .padding(.top, 80)
                    Spacer()
                    
                }
                .transition(.move(edge: .top))
                .onAppear {
                    doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                        viewModel.alertMessage = nil
                    }
                }
            }
            
            // MARK: - Show error
            if viewModel.showError {
                VStack {
                    Spacer()
                    SnackBarView(message: viewModel.errorMessage)
                }.transition(.move(edge: .bottom))
                    .onAppear {
                        doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                            viewModel.errorMessage = nil
                        }
                    }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.all, edges: .horizontal)
        .background(Theme.Colors.background.ignoresSafeArea(.all))
        .onFirstAppear {
            viewModel.trackScreenEvent()
        }
    }
    
    @ViewBuilder
    private var agreements: some View {
        if let eulaURL = viewModel.config.agreement.eulaURL,
           let tosURL =  viewModel.config.agreement.tosURL,
           let policy = viewModel.config.agreement.privacyPolicyURL {
            let text = AuthLocalization.SignIn.agreement(
                "\(viewModel.config.platformName)",
                eulaURL,
                "\(viewModel.config.platformName)",
                tosURL,
                "\(viewModel.config.platformName)",
                policy
            )
            Text(.init(text))
                .tint(Theme.Colors.infoColor)
                .foregroundStyle(Theme.Colors.textSecondaryLight)
                .font(Theme.Fonts.labelSmall)
                .padding(.top, viewModel.socialAuthEnabled ? 0 : 15)
                .padding(.bottom, 15)
                .environment(\.openURL, OpenURLAction(handler: handleURL))
        }
    }
    
    private func handleURL(_ url: URL) -> OpenURLAction.Result {
        viewModel.router.showWebBrowser(title: "", url: url)
        return .handled
    }
}

#if DEBUG
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = SignInViewModel(
            interactor: AuthInteractor.mock,
            router: AuthorizationRouterMock(),
            config: ConfigMock(),
            analytics: AuthorizationAnalyticsMock(),
            validator: Validator(),
            storage: CoreStorageMock(),
            sourceScreen: .default
        )
        
        SignInView(viewModel: vm)
            .preferredColorScheme(.light)
            .previewDisplayName("SignInView Light")
            .loadFonts()
        
        SignInView(viewModel: vm)
            .preferredColorScheme(.dark)
            .previewDisplayName("SignInView Dark")
            .loadFonts()
    }
}
#endif
