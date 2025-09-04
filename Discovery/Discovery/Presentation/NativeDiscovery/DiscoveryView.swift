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
import UIKit
import Kingfisher

// Local implementation of course card to avoid module import issues
private struct LocalCourseGridCardView: View {
    private let imageURL: String
    private let title: String
    private let org: String
    private let startDate: String
    private let endDate: String
    private let duration: String
    
    init(model: CourseItem, useRelativeDates: Bool) {
        self.imageURL = model.imageURL
        self.title = model.name
        self.org = model.org
        self.startDate = model.courseStart?.dateToString(
            style: .courseStartsMonthDDYear,
            useRelativeDates: useRelativeDates
        ) ?? ""
        self.endDate = model.courseEnd?.dateToString(
            style: .courseEndsMonthDDYear,
            useRelativeDates: useRelativeDates
        ) ?? ""
        self.duration = (model.duration?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? model.duration!.trimmingCharacters(in: .whitespacesAndNewlines)
            : "Duration not specified"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Course banner image
            KFImage(URL(string: imageURL))
                .onFailureImage(CoreAssets.noCourseImage.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 120, minHeight: 90, maxHeight: 100)
                .clipped()
                .accessibilityIdentifier("course_card_image")
            
            // Course title and meta (org + duration)
            VStack(alignment: .leading, spacing: 3) {
                // Organization
                if !org.isEmpty {
                    Text(org)
                        .font(Theme.Fonts.labelSmall)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .accessibilityIdentifier("course_card_org")
                }

                // Duration
                Text(duration)
                    .font(Theme.Fonts.labelSmall)
                    .foregroundColor(Theme.Colors.textSecondaryLight)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .accessibilityIdentifier("course_card_duration")

                // Course title
                Text(title)
                    .font(Theme.Fonts.labelMedium)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .accessibilityIdentifier("course_card_title")
            }
            .frame(height: 51, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 10)
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .background(Theme.Colors.courseCardBackground)
        .cornerRadius(8)
        .shadow(color: Theme.Colors.courseCardShadow, radius: 6, x: 2, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("course_grid_card")
    }
}

public struct DiscoveryView: View {
    
    @StateObject
    private var viewModel: DiscoveryViewModel
    private var router: DiscoveryRouter
    @State private var searchQuery: String = ""
    @State private var isRefreshing: Bool = false
    
    private var sourceScreen: LogistrationSourceScreen
    
    @Environment(\.isHorizontal) private var isHorizontal
    @Environment(\.presentationMode) private var presentationMode
    
    private func discoveryHeader(_ viewModel: DiscoveryViewModel) -> some View {
        Group {
            if let selectedPartner = viewModel.selectedPartner, !viewModel.courses.isEmpty {
                // Show course count when filter is active
                VStack(alignment: .leading) {
                    Text("Viewing \(viewModel.totalCourseCount) Courses")
                        .font(Theme.Fonts.titleLarge) // Smaller font size
                        .foregroundColor(Theme.Colors.textPrimary)
                        .accessibilityIdentifier("viewing_courses_text")
                }
                .listRowBackground(Color.clear)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Viewing \(viewModel.totalCourseCount) Courses")
            } else {
                // Default header
                VStack(alignment: .leading) {
                    Text(DiscoveryLocalization.Header.title1)
                        .font(Theme.Fonts.displaySmall)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .accessibilityIdentifier("title_text")
                    Text(DiscoveryLocalization.Header.title2)
                        .font(Theme.Fonts.titleSmall)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .accessibilityIdentifier("subtitle_text")
                }
                .listRowBackground(Color.clear)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(DiscoveryLocalization.Header.title1 + DiscoveryLocalization.Header.title2)
            }
        }
    }
    
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
        ZStack(alignment: .top) {
            
            // MARK: - Page name
            VStack(alignment: .center) {
                
                // MARK: - Search field and filter button
                searchAndFilterBar
                .padding(.top, 11.5)
                .padding(.horizontal, 24)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(DiscoveryLocalization.search)
                
                // Selected organization pill and clear button
                partnerFilterPill
                
                refreshableView
            }.accessibilityAction {}
            
            if !viewModel.userloggedIn {
                VStack(spacing: 0) {
                    Spacer()
                    // Gradient spacer above the buttons
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Theme.Colors.background.opacity(0.0),
                                Theme.Colors.background.opacity(0.5),
                                Theme.Colors.background.opacity(0.8),
                                Theme.Colors.background
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    
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
                        .background(Theme.Colors.background)
                        .zIndex(100)
                }
            }
            
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
        .navigationBarHidden(sourceScreen != .startup)
    }
}

// MARK: - Extracted subviews
extension DiscoveryView {
    private var searchAndFilterBar: some View {
// ...
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
                RoundedRectangle(cornerRadius: 13)
                    .fill(Theme.Colors.textInputUnfocusedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
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
    }

    // MARK: - Grid Header
    private func gridHeader() -> some View {
        HStack {
            discoveryHeader(viewModel)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            Spacer()
        }
        .padding(.leading, 10)
    }
    
    // MARK: - Course Card
    private func courseCard(course: CourseItem, useRelativeDates: Bool) -> some View {
        Button(
            action: {
                // Track course click
                viewModel.discoveryCourseClicked(
                    courseID: course.courseID,
                    courseName: course.name
                )
                // Navigate to course details
                viewModel.router.showCourseDetais(
                    courseID: course.courseID,
                    title: course.name
                )
            },
            label: {
                LocalCourseGridCardView(
                    model: course,
                    useRelativeDates: useRelativeDates
                )
            }
        )
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("course_card_button")
    }
    
    // MARK: - Bottom Spacer
    private func bottomSpacer() -> some View {
        VStack {}
            .frame(height: viewModel.userloggedIn ? 40 : 100)
    }
    
    // MARK: - Main Grid Function
    private func coursesGrid(_ proxy: GeometryProxy) -> some View {
        ZStack {
            // Grid view replacing list of course cells
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    gridHeader()
                    
                    // Dynamic column count (2 on iPhone, 3 on iPad)
                    let isPad = UIDevice.current.userInterfaceIdiom == .pad
                    let useRelativeDates = viewModel.storage.useRelativeDates
                    
                    // Grid content with columns
                    let columns = isPad ? [
                        GridItem(.flexible(), spacing: 0),
                        GridItem(.flexible(), spacing: 0),
                        GridItem(.flexible(), spacing: 0)
                    ] : [
                        GridItem(.flexible(), spacing: 0),
                        GridItem(.flexible(), spacing: 0)
                    ]
                    
                    gridContent(useRelativeDates: useRelativeDates, columns: columns)
                    
                    // Progress indicator
                    progressIndicator()
                    
                    // Bottom padding
                    bottomSpacer()
                }
                .frameLimit(width: proxy.size.width)
            }
        }
    }
    
    // MARK: - Progress Indicator
    private func progressIndicator() -> some View {
        Group {
            if viewModel.nextPage <= viewModel.totalPages {
                VStack(alignment: .center) {
                    ProgressBar(size: 40, lineWidth: 8)
                        .padding(.top, 20)
                }
            }
        }
    }
    
    // MARK: - Grid Content
    private func gridContent(useRelativeDates: Bool, columns: [GridItem]) -> some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
            if !viewModel.courses.isEmpty {
                ForEach(viewModel.courses) { course in
                    courseCard(course: course, useRelativeDates: useRelativeDates)
                        .padding(8) // Add padding around each card like in AllCoursesView
                        .onAppear {
                            // Pagination logic
                            if let index = viewModel.courses.firstIndex(where: { $0.id == course.id }),
                               index == viewModel.courses.count - 3 {
                                Task {
                                    await viewModel.discovery(page: viewModel.nextPage)
                                }
                            }
                        }
                }
            }
        }
        .accessibilityIdentifier("discovery_courses_grid")
        .padding(10) // Match AllCoursesView padding
    }
    
    private var refreshableView: some View {
        GeometryReader { proxy in
            coursesGrid(proxy)
        }
        .refreshable {
            viewModel.totalPages = 1
            viewModel.nextPage = 1
            Task {
                await viewModel.discovery(page: 1, withProgress: false)
            }
        }
    }

    private var partnerFilterPill: some View {
        Group {
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
                .padding(.top, 6)
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Add bottom padding when no filter is selected
                Spacer()
                    .frame(height: 20)
            }
        }
        .padding(.horizontal, 24)
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
