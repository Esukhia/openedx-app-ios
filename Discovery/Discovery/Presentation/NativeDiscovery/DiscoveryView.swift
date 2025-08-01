//
//  DiscoveryView.swift
//  Discovery
//
//  Created by Vladimir Chekyrta on 15.09.2022.
//

import SwiftUI
import Core
import OEXFoundation
import Theme

public struct DiscoveryView: View {
    
    @StateObject
    private var viewModel: DiscoveryViewModel
    private var router: DiscoveryRouter
    @State private var searchQuery: String = ""
    @State private var isRefreshing: Bool = false
    
    private var sourceScreen: LogistrationSourceScreen
    
    @Environment(\.isHorizontal) private var isHorizontal
    @Environment(\.presentationMode) private var presentationMode
    
    private let discoveryNew: some View = VStack(alignment: .leading) {
        Text(DiscoveryLocalization.Header.title1)
            .font(Theme.Fonts.displaySmall)
            .foregroundColor(Theme.Colors.textPrimary)
            .accessibilityIdentifier("title_text")
        Text(DiscoveryLocalization.Header.title2)
            .font(Theme.Fonts.titleSmall)
            .foregroundColor(Theme.Colors.textPrimary)
            .accessibilityIdentifier("subtitle_text")
    }.listRowBackground(Color.clear)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DiscoveryLocalization.Header.title1 + DiscoveryLocalization.Header.title2)
    
    public init(
        viewModel: DiscoveryViewModel,
        router: DiscoveryRouter,
        searchQuery: String? = nil,
        sourceScreen: LogistrationSourceScreen = .default
    ) {
        self._viewModel = StateObject(wrappedValue: { viewModel }())
        self.router = router
        self._searchQuery = State<String>(initialValue: searchQuery ?? "")
        self.sourceScreen = sourceScreen
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                
                // MARK: - Page name
                VStack(alignment: .center) {
                    
                    // MARK: - Search field and filter button
                    HStack(spacing: 12) {
                        // Search box
                        HStack(spacing: 11) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Theme.Colors.textSecondary)
                                .padding(.leading, 16)
                                .padding(.top, 1)
                                .accessibilityIdentifier("search_image")
                            Text(DiscoveryLocalization.search)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .accessibilityIdentifier("search_text")
                            Spacer()
                        }
                        .frame(minHeight: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 13) // More rounded corners for search bar
                                .fill(Theme.Colors.textInputUnfocusedBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13) // Matching corner radius for border
                                .stroke(lineWidth: 1)
                                .fill(Theme.Colors.textInputUnfocusedStroke)
                        )
                        .onTapGesture {
                            router.showDiscoverySearch(searchQuery: searchQuery)
                            viewModel.discoverySearchBarClicked()
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(DiscoveryLocalization.search)
                        
                        // Filter button (outside search box)
                        Button(action: {
                            viewModel.showPartnerFilterSheet()
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 24))
                                .foregroundColor(
                                    viewModel.selectedPartner != nil ?
                                    Theme.Colors.accentColor : Theme.Colors.textSecondary
                                )
                                .padding(.horizontal, 8)
                        }
                        .accessibilityIdentifier("filter_button")
                        .accessibilityLabel("Filter by organization")
                    }
                    .padding(.top, 11.5)
                    .padding(.horizontal, 24)
                    .frameLimit(width: proxy.size.width)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(DiscoveryLocalization.search)
                    
                    // Selected organization pill and clear button
                    if let selectedPartner = viewModel.selectedPartner {
                        HStack {
                            // Organization pill
                            Text(selectedPartner.organization)
                                .font(Theme.Fonts.labelMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "FC8044"))
                                )
                            
                            Spacer()
                            
                            // Clear button
                            Button(action: {
                                viewModel.clearPartnerFilter()
                            }) {
                                Text("Clear")
                                    .font(Theme.Fonts.labelMedium)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Theme.Colors.textInputUnfocusedBackground)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Theme.Colors.textInputUnfocusedStroke, lineWidth: 1)
                                    )
                            }
                            .accessibilityIdentifier("clear_filter_button")
                            .accessibilityLabel("Clear organization filter")
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 6) // Added top padding to increase space between search bar and pill
                        .padding(.bottom, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        // Add bottom padding when no filter is selected
                        Spacer()
                            .frame(height: 20)
                    }
                    
                    ZStack {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                HStack {
                                    discoveryNew
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 20)
                                    Spacer()
                                }.padding(.leading, 10)
                                let useRelativeDates = viewModel.storage.useRelativeDates
                                ForEach(Array(viewModel.courses.enumerated()), id: \.offset) { index, course in
                                    CourseCellView(
                                        model: course,
                                        type: .discovery,
                                        index: index,
                                        cellsCount: viewModel.courses.count,
                                        useRelativeDates: useRelativeDates
                                    ).padding(.horizontal, 24)
                                        .onAppear {
                                            Task {
                                                await viewModel.getDiscoveryCourses(index: index)
                                            }
                                        }
                                        .onTapGesture {
                                            viewModel.discoveryCourseClicked(
                                                courseID: course.courseID,
                                                courseName: course.name
                                            )
                                            viewModel.router.showCourseDetais(
                                                courseID: course.courseID,
                                                title: course.name
                                            )
                                        }
                                }
                                
                                // MARK: - ProgressBar
                                if viewModel.nextPage <= viewModel.totalPages {
                                    VStack(alignment: .center) {
                                        ProgressBar(size: 40, lineWidth: 8)
                                            .padding(.top, 20)
                                    }.frame(maxWidth: .infinity,
                                            maxHeight: .infinity)
                                }
                                VStack {}.frame(height: 40)
                            }
                            .frameLimit(width: proxy.size.width)
                        }.refreshable {
                            viewModel.totalPages = 1
                            viewModel.nextPage = 1
                            Task {
                                await viewModel.discovery(page: 1, withProgress: false)
                            }
                        }
                    }
                }.accessibilityAction {}

                if !viewModel.userloggedIn {
                    LogistrationBottomView(
                        ssoEnabled: viewModel.config.uiComponents.samlSSOLoginEnabled
                    ) { buttonAction in
                        switch buttonAction {
                        case .signIn:
                            viewModel.router.showLoginScreen(sourceScreen: .discovery)
                        case .register:
                            viewModel.router.showRegisterScreen(sourceScreen: .discovery)
                        case .signInWithSSO:
                            viewModel.router.showLoginScreen(sourceScreen: .discovery)
                        }
                    }
                }
            }.padding(.top, 8)

            // MARK: - Offline mode SnackBar
            OfflineSnackBarView(
                connectivity: viewModel.connectivity,
                reloadAction: {
                    await viewModel.discovery(page: 1, withProgress: false)
                })

            // MARK: - Error Alert
            if viewModel.showError {
                VStack {
                    Spacer()
                    SnackBarView(message: viewModel.errorMessage)
                }
                .padding(.bottom, viewModel.connectivity.isInternetAvaliable
                         ? 0 : OfflineSnackBarView.height)
                .transition(.move(edge: .bottom))
                .onAppear {
                    doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                        viewModel.errorMessage = nil
                    }
                }
            }
        }
        .navigationBarHidden(sourceScreen != .startup)
        .onFirstAppear {
            if !(searchQuery.isEmpty) {
                router.showDiscoverySearch(searchQuery: searchQuery)
                searchQuery = ""
            }
            Task {
                await viewModel.loadPartners()
                await viewModel.discovery(page: 1)
                if case let .courseDetail(courseID, courseTitle) = sourceScreen {
                    viewModel.router.showCourseDetais(courseID: courseID, title: courseTitle)
                }
            }
            viewModel.setupNotifications()
        }
        .sheet(isPresented: $viewModel.showPartnerFilter) {
            PartnerFilterSheet(
                partners: viewModel.partners,
                selectedPartner: viewModel.selectedPartner
            ) { selectedPartner in
                viewModel.selectPartner(selectedPartner)
            }
            .presentationDetents([.height(400), .medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }
}

#if DEBUG
struct DiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DiscoveryViewModel(router: DiscoveryRouterMock(),
                                    config: ConfigMock(),
                                    interactor: DiscoveryInteractor.mock,
                                    connectivity: Connectivity(),
                                    analytics: DiscoveryAnalyticsMock(),
                                    storage: CoreStorageMock())
        let router = DiscoveryRouterMock()
        
        DiscoveryView(viewModel: vm, router: router)
            .preferredColorScheme(.light)
            .previewDisplayName("DiscoveryView Light")
        
        DiscoveryView(viewModel: vm, router: router)
            .preferredColorScheme(.dark)
            .previewDisplayName("DiscoveryView Dark")
    }
}
#endif
