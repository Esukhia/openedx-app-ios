//
//  CourseDetailsView.swift
//  CourseDetailsView
//
//  Created by  Stepanok Ivan on 22.09.2022.
//

import SwiftUI
import Core
import OEXFoundation
import Kingfisher
import WebKit
import Theme

public struct CourseDetailsView: View {

    @ObservedObject private var viewModel: CourseDetailsViewModel
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.isHorizontal) var isHorizontal
    @State private var isOverviewRendering = true
    private var title: String
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    private var courseID: String

    private func updateOrientation() {
        viewModel.isHorisontal =
        UIDevice.current.orientation == .landscapeLeft
        || UIDevice.current.orientation == .landscapeRight
    }

    public init(viewModel: CourseDetailsViewModel, courseID: String, title: String) {
        self.viewModel = viewModel
        self.title = title
        self.courseID = courseID
        Task {
            await viewModel.getCourseDetail(courseID: courseID)
        }
        self.updateOrientation()
    }

    public var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .center) {
                // MARK: - Page Body
                GeometryReader { proxy in
                    if viewModel.isShowProgress {
                        HStack(alignment: .center) {
                            ProgressBar(size: 40, lineWidth: 8)
                                .padding(.top, 200)
                                .padding(.horizontal)
                                .accessibilityIdentifier("progress_bar")
                        }.frame(width: proxy.size.width)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading) {
                                if let courseDetails = viewModel.courseDetails {
                                
                                    // MARK: - iPad
                                    if viewModel.isHorisontal {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading) {
                                            
                                                // MARK: - Title and description
                                                CourseTitleView(courseDetails: courseDetails)
                                                Spacer()
                                            
                                                // MARK: - Course state button
                                                CourseStateView(title: title,
                                                                courseDetails: courseDetails,
                                                                viewModel: viewModel)
                                            }
                                            VStack {
                                                // MARK: - Course Banner
                                                CourseBannerView(
                                                    courseDetails: courseDetails,
                                                    proxy: proxy,
                                                    isHorisontal: viewModel.isHorisontal,
                                                    onPlayButtonTap: { [weak viewModel] in
                                                        viewModel?.showCourseVideo()
                                                    }
                                                )
                                            }.aspectRatio(CGSize(width: 16, height: 8.5), contentMode: .fill)
                                                .frame(maxHeight: 250)
                                                .cornerRadius(12)
                                                .padding(.horizontal, 6)
                                                .padding(.top, 7)
                                        
                                        }
                                    } else {
                                        // MARK: - iPhone
                                        VStack(alignment: .leading) {
                                            // MARK: - Course Banner
                                            CourseBannerView(
                                                courseDetails: courseDetails,
                                                proxy: proxy,
                                                isHorisontal: viewModel.isHorisontal,
                                                onPlayButtonTap: { [weak viewModel] in
                                                    viewModel?.showCourseVideo()
                                                })
                                        }.aspectRatio(CGSize(width: 16, height: 8.5), contentMode: .fill)
                                            .cornerRadius(12)
                                            .padding(.horizontal, 6)
                                            .padding(.top, 7)
                                            .fixedSize(horizontal: false, vertical: true)
                                    
                                        // MARK: - Title and description
                                        CourseTitleView(courseDetails: courseDetails)
                                            .padding(.top, 16)

                                        // MARK: - Course state button
                                        CourseStateView(title: title,
                                                        courseDetails: courseDetails,
                                                        viewModel: viewModel)
                                        .padding(.top, 4)
                                    }
                                
                                    // Info sections
                                    VStack(alignment: .leading, spacing: 24) {
                                        // About this Course (Short description)
                                        if let shortDesc = courseDetails.courseDescription, !shortDesc.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Image(systemName: "info.circle.fill")
                                                        .foregroundColor(Theme.Colors.accentColor)
                                                        .font(.system(size: 16))
                                                    Text("About this Course")
                                                        .font(Theme.Fonts.titleSmall)
                                                        .foregroundColor(Theme.Colors.textSecondary)
                                                }
                                                Text(shortDesc)
                                                    .font(Theme.Fonts.bodyMedium)
                                                    .foregroundColor(Theme.Colors.textPrimary)
                                                    .multilineTextAlignment(.leading)
                                                    .lineSpacing(4)
                                            }
                                            .padding(.horizontal, 16)
                                        }

                                        // Long Description
                                        if let longDesc = courseDetails.longDescription, !longDesc.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Image(systemName: "doc.text.fill")
                                                        .foregroundColor(Theme.Colors.accentColor)
                                                        .font(.system(size: 16))
                                                    Text("Course Description")
                                                        .font(Theme.Fonts.titleSmall)
                                                        .foregroundColor(Theme.Colors.textSecondary)
                                                }
                                                Text(longDesc)
                                                    .font(Theme.Fonts.bodyMedium)
                                                    .foregroundColor(Theme.Colors.textPrimary)
                                                    .multilineTextAlignment(.leading)
                                                    .lineSpacing(4)
                                            }
                                            .padding(.horizontal, 16)
                                        }

                                        // Course Overview (HTML)
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Image(systemName: "list.bullet.clipboard.fill")
                                                    .foregroundColor(Theme.Colors.accentColor)
                                                    .font(.system(size: 16))
                                                Text("Course Overview")
                                                    .font(Theme.Fonts.titleSmall)
                                                    .foregroundColor(Theme.Colors.textSecondary)
                                            }
                                            .padding(.horizontal, 16)

                                            ZStack(alignment: .topLeading) {
                                                HTMLFormattedText(
                                                    viewModel.cssInjector.injectCSS(
                                                        colorScheme: themeManager.resolvedColorScheme ?? colorScheme,
                                                        html: courseDetails.overviewHTML,
                                                        type: .discovery,
                                                        fontSize: 120,
                                                        screenWidth: proxy.size.width - 48
                                                    ),
                                                    processing: { rendering in
                                                        isOverviewRendering = rendering
                                                    }
                                                )
                                                .padding(.horizontal, 16)

                                                if isOverviewRendering {
                                                    ProgressBar(size: 40, lineWidth: 8)
                                                        .padding(.top, 20)
                                                        .frame(maxWidth: .infinity)
                                                        .accessibilityIdentifier("progress_bar")
                                                }
                                            }
                                        }

                                        // Course Requirement
                                        if let requirement = courseDetails.courseRequirement, !requirement.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Image(systemName: "checklist")
                                                        .foregroundColor(Theme.Colors.accentColor)
                                                        .font(.system(size: 16))
                                                    Text("Course Requirements")
                                                        .font(Theme.Fonts.titleSmall)
                                                        .foregroundColor(Theme.Colors.textSecondary)
                                                }
                                                Text(requirement)
                                                    .font(Theme.Fonts.bodyMedium)
                                                    .foregroundColor(Theme.Colors.textPrimary)
                                                    .multilineTextAlignment(.leading)
                                                    .lineSpacing(4)
                                            }
                                            .padding(.horizontal, 16)
                                        }

                                        // Learning Outcomes
                                        if let outcomes = courseDetails.learningOutcomes, !outcomes.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Image(systemName: "target")
                                                        .foregroundColor(Theme.Colors.accentColor)
                                                        .font(.system(size: 16))
                                                    Text("Learning Outcomes")
                                                        .font(Theme.Fonts.titleSmall)
                                                        .foregroundColor(Theme.Colors.textSecondary)
                                                }
                                                VStack(alignment: .leading, spacing: 6) {
                                                    ForEach(
                                                        Array(outcomes.enumerated()),
                                                        id: \.offset
                                                    ) { _, item in
                                                        HStack(alignment: .top, spacing: 8) {
                                                            Text("•")
                                                                .font(Theme.Fonts.bodyMedium)
                                                                .foregroundColor(Theme.Colors.textPrimary)
                                                            Text(item)
                                                                .font(Theme.Fonts.bodyMedium)
                                                                .foregroundColor(Theme.Colors.textPrimary)
                                                                .multilineTextAlignment(.leading)
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                        }

                                        // Instructors
                                        if let instructors = courseDetails.instructors, !instructors.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Image(systemName: "person.2.fill")
                                                        .foregroundColor(Theme.Colors.accentColor)
                                                        .font(.system(size: 16))
                                                    Text("Instructors")
                                                        .font(Theme.Fonts.titleSmall)
                                                        .foregroundColor(Theme.Colors.textSecondaryLight)
                                                }
                                                .padding(.horizontal, 16)

                                                let isPad = UIDevice.current.userInterfaceIdiom == .pad
                                                let columns: [GridItem] = isPad
                                                ? [
                                                    GridItem(.flexible()),
                                                    GridItem(.flexible())
                                                ]
                                                : [
                                                    GridItem(.flexible())
                                                ]

                                                LazyVGrid(columns: columns, spacing: 12) {
                                                    ForEach(
                                                        Array(instructors.enumerated()),
                                                        id: \.offset
                                                    ) { _, instructor in
                                                        InstructorCardView(instructor: instructor)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                            .frameLimit(width: proxy.size.width)
                        }
                        .refreshable {
                            Task {
                                await viewModel.getCourseDetail(courseID: courseID, withProgress: false)
                            }
                        }
                        .onRightSwipeGesture {
                            viewModel.router.back()
                        }
                        Spacer(minLength: 84)
                    }
                }
                if !viewModel.userloggedIn {
                    LogistrationBottomView(
                        ssoEnabled: viewModel.config.uiComponents.samlSSOLoginEnabled
                    ) { buttonAction in
                        switch buttonAction {
                        case .signIn:
                            viewModel.router.showLoginScreen(
                                sourceScreen: .courseDetail(
                                    courseID,
                                    viewModel.courseDetails?.courseTitle ?? ""
                                )
                            )
                        case .register:
                            viewModel.router.showRegisterScreen(
                                sourceScreen: .courseDetail(
                                    courseID,
                                    viewModel.courseDetails?.courseTitle ?? ""
                                )
                            )
                        case .signInWithSSO:
                            viewModel.router.showLoginScreen(
                                sourceScreen: .courseDetail(
                                    courseID,
                                    viewModel.courseDetails?.courseTitle ?? ""
                                )
                            )
                        }
                    }
                }
            }.padding(.top, 8)
            .navigationBarHidden(false)
            .navigationBarBackButtonHidden(false)
            .navigationTitle(DiscoveryLocalization.Details.title)
        
            .onReceive(NotificationCenter
                .Publisher(center: .default,
                           name: UIDevice.orientationDidChangeNotification)) { _ in
                updateOrientation()
            }
        
            // MARK: - Offline mode SnackBar
            if viewModel.courseState() != .enrollOpen {
                OfflineSnackBarView(connectivity: viewModel.connectivity,
                                    reloadAction: {
                    await viewModel.getCourseDetail(courseID: courseID, withProgress: false)
                })
            }
        
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
        .background(
            Theme.Colors.background
                .ignoresSafeArea()
        )
    }
}

private struct CourseStateView: View {

    let title: String
    let courseDetails: CourseDetails
    let viewModel: CourseDetailsViewModel

    init(title: String,
         courseDetails: CourseDetails,
         viewModel: CourseDetailsViewModel) {
        self.title = title
        self.courseDetails = courseDetails
        self.viewModel = viewModel
    }

    var body: some View {
        let hasDuration = courseDetails.duration?.isEmpty == false
        let durationText = hasDuration ? courseDetails.duration ?? "" : "Not specified"
        let courseDurationText = "Course Duration: " + durationText
    
        switch viewModel.courseState() {
        case .enrollOpen:
            VStack(spacing: 8) {
                Group {
                if viewModel.connectivity.isInternetAvaliable {
                        StyledButton(DiscoveryLocalization.Details.enrollNow, action: {
                            if !viewModel.userloggedIn {
                                viewModel.router.showLoginScreen(
                                    sourceScreen: .courseDetail(
                                        courseDetails.courseID,
                                        courseDetails.courseTitle)
                                )
                            } else {
                                Task {
                                    await viewModel.enrollToCourse(id: courseDetails.courseID)
                                }
                            }
                        })
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    } else {
                        HStack(alignment: .center, spacing: 10) {
                            CoreAssets.noWifiMini.swiftUIImage
                                .renderingMode(.template)
                                .foregroundStyle(Theme.Colors.warning)
                            Text(DiscoveryLocalization.Details.enrollmentNoInternet)
                                .multilineTextAlignment(.leading)
                                .font(Theme.Fonts.titleSmall)
                            Spacer()
                        }.cardStyle(
                            paddingAll: 12,
                            bgColor: Theme.Colors.textInputUnfocusedBackground,
                            strokeColor: .clear
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
                .accessibilityIdentifier("enroll_button")

                Text(courseDurationText)
                    .font(Theme.Fonts.titleSmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .accessibilityIdentifier("course_duration_text")
            }
            Group {
            if viewModel.connectivity.isInternetAvaliable {
                    StyledButton(DiscoveryLocalization.Details.enrollNow, action: {
                        if !viewModel.userloggedIn {
                            viewModel.router.presentView(
                                transitionStyle: .crossDissolve,
                                animated: true
                            ) {
                                AlertView(
                                    alertTitle: DiscoveryLocalization.Alert.authorization,
                                    alertMessage: DiscoveryLocalization.Alert.pleaseEnterTheSystem,
                                    positiveAction: CoreLocalization.Alert.signIn,
                                    onCloseTapped: {
                                        self.viewModel.router.dismiss(animated: true)
                                    },
                                    firstButtonTapped: {
                                        self.viewModel.router.dismiss(animated: false)
                                        viewModel.router.showLoginScreen(
                                            sourceScreen: .courseDetail(
                                                courseDetails.courseID,
                                                viewModel.courseDetails?.courseTitle ?? ""
                                            )
                                        )
                                    },
                                    secondButtonTapped: {
                                        self.viewModel.router.dismiss(animated: false)
                                        viewModel.router.showRegisterScreen(
                                            sourceScreen: .courseDetail(
                                                courseDetails.courseID,
                                                courseDetails.courseTitle)
                                        )

                                    },
                                    type: .authorization
                                )
                            }
                        } else {
                            Task {
                                await viewModel.enrollToCourse(id: courseDetails.courseID)
                            }
                        }
                    })
                    .padding(16)
                } else {
                    HStack(alignment: .center, spacing: 10) {
                        CoreAssets.noWifiMini.swiftUIImage
                            .renderingMode(.template)
                            .foregroundStyle(Theme.Colors.warning)
                        Text(DiscoveryLocalization.Details.enrollmentNoInternet)
                            .multilineTextAlignment(.leading)
                            .font(Theme.Fonts.titleSmall)
                        Spacer()
                    }.cardStyle(paddingAll: 12, bgColor: Theme.Colors.textInputUnfocusedBackground, strokeColor: .clear)
                }
            }
            .accessibilityIdentifier("enroll_button")
        case .enrollClose:
            VStack(spacing: 8) {
                Text(DiscoveryLocalization.Details.enrollmentDateIsOver)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(Theme.Fonts.titleSmall)
                    .cardStyle()
                    .padding(.top, 24)
                    .accessibilityIdentifier("date_over_text")
            
                Text(courseDurationText)
                    .font(Theme.Fonts.titleSmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .accessibilityIdentifier("course_duration_text")
            }
        case .alreadyEnrolled:
            VStack(spacing: 8) {
                StyledButton(DiscoveryLocalization.Details.viewCourse, action: {
                    if !viewModel.userloggedIn {
                        viewModel.router.showLoginScreen(
                            sourceScreen: .courseDetail(
                                courseDetails.courseID,
                                courseDetails.courseTitle)
                        )
                    } else {
                        viewModel.viewCourseClicked(
                            courseId: courseDetails.courseID,
                            courseName: courseDetails.courseTitle
                        )
                        viewModel.router.showCourseScreens(
                            courseID: courseDetails.courseID,
                            hasAccess: nil,
                            courseStart: courseDetails.courseStart,
                            courseEnd: courseDetails.courseEnd,
                            enrollmentStart: courseDetails.enrollmentStart,
                            enrollmentEnd: courseDetails.enrollmentEnd,
                            title: title,
                            courseRawImage: courseDetails.courseRawImage,
                            showDates: false,
                            lastVisitedBlockID: nil
                        )
                    }
                })
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .accessibilityIdentifier("view_course_button")
            
                Text(courseDurationText)
                    .font(Theme.Fonts.titleSmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .accessibilityIdentifier("course_duration_text")
            }
        }
    }
}

private struct PlayButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action, label: {
            CoreAssets.playVideo.swiftUIImage
                .resizable()
                .frame(width: 40, height: 40)
        })
        .accessibilityIdentifier("play_button")
    }
}

private struct CourseTitleView: View {
    let courseDetails: CourseDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(courseDetails.courseTitle)
                .font(Theme.Fonts.headlineMedium)
                .foregroundColor(Theme.Colors.textPrimary)
                .lineSpacing(2)
                .accessibilityIdentifier("title_text")

            HStack(spacing: 6) {
                Text("Organisation:")
                    .font(Theme.Fonts.titleSmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                Text(courseDetails.org)
                    .font(Theme.Fonts.titleSmall)
                    .foregroundColor(Theme.Colors.accentColor)
                    .accessibilityIdentifier("org_text")
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CourseBannerView: View {
    @State private var animate = false
    private var isHorisontal: Bool
    private let courseDetails: CourseDetails
    private let idiom: UIUserInterfaceIdiom
    private let proxy: GeometryProxy
    private let onPlayButtonTap: () -> Void

    init(courseDetails: CourseDetails,
         proxy: GeometryProxy,
         isHorisontal: Bool,
         onPlayButtonTap: @escaping () -> Void) {
        self.courseDetails = courseDetails
        self.isHorisontal = isHorisontal
        self.idiom = UIDevice.current.userInterfaceIdiom
        self.proxy = proxy
        self.onPlayButtonTap = onPlayButtonTap
    }

    var body: some View {
        ZStack(alignment: .center) {
            if !isHorisontal {
                KFImage(URL(string: courseDetails.courseBannerURL))
                    .onFailureImage(CoreAssets.noCourseImage.image)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: idiom == .pad ? nil : proxy.size.width - 12)
                    .opacity(animate ? 1 : 0)
                    .onAppear {
                        withAnimation(.linear(duration: 0.5)) {
                            animate = true
                        }
                    }
                    .accessibilityIdentifier("course_image")
                if courseDetails.courseVideoURL != nil {
                    PlayButton(action: onPlayButtonTap)
                }
            } else {
                KFImage(URL(string: courseDetails.courseBannerURL))
                    .onFailureImage(CoreAssets.noCourseImage.image)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 312)
                    .opacity(animate ? 1 : 0)
                    .onAppear {
                        withAnimation(.linear(duration: 0.5)) {
                            animate = true
                        }
                    }
                    .accessibilityIdentifier("course_image")
                if courseDetails.courseVideoURL != nil {
                    PlayButton(action: onPlayButtonTap)
                }
            }
        }
    }
}

private struct InstructorCardView: View {
    let instructor: CourseInstructor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top section: Avatar and Info side by side
            HStack(alignment: .top, spacing: 12) {
                // Instructor Avatar
                if let imageUrl = instructor.image, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    KFImage(url)
                        .placeholder {
                            Circle()
                                .fill(Theme.Colors.textInputUnfocusedBackground)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Theme.Colors.textSecondary)
                                )
                        }
                        .onFailureImage(CoreAssets.noCourseImage.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.cardViewStroke, lineWidth: 1)
                        )
                        .accessibilityIdentifier("instructor_avatar")
                } else {
                    Circle()
                        .fill(Theme.Colors.textInputUnfocusedBackground)
                        .frame(width: 88, height: 88)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(Theme.Colors.textSecondary)
                                .font(.system(size: 24))
                        )
                }
                
                // Instructor Info (Name, Title, Organization)
                VStack(alignment: .leading, spacing: 4) {
                    if let name = instructor.name, !name.isEmpty {
                        Text(name)
                            .font(Theme.Fonts.titleMedium)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .accessibilityIdentifier("instructor_name")
                    }
                    if let title = instructor.title, !title.isEmpty {
                        Text(title)
                            .font(Theme.Fonts.titleSmall)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .accessibilityIdentifier("instructor_title")
                    }
                    if let org = instructor.organization, !org.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.system(size: 14))
                            Text(org)
                                .font(Theme.Fonts.titleSmall)
                        }
                        .foregroundColor(Theme.Colors.accentColor)
                        .accessibilityIdentifier("instructor_org")
                    }
                }
                Spacer(minLength: 0)
            }
            
            // Bottom section: Bio spanning full width
            if let bio = instructor.bio, !bio.isEmpty {
                Text(bio)
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .accessibilityIdentifier("instructor_bio")
            }
        }
        .padding(12)
        .cardStyle(bgColor: Theme.Colors.background,
                   strokeColor: Theme.Colors.cardViewStroke,
                   outerHorizontalPadding: 8)
    }
}

#if DEBUG
// swiftlint:disable all
struct CourseDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = CourseDetailsViewModel(
            interactor: DiscoveryInteractor.mock,
            router: DiscoveryRouterMock(),
            analytics: DiscoveryAnalyticsMock(),
            config: ConfigMock(),
            cssInjector: CSSInjectorMock(),
            connectivity: Connectivity(),
            storage: CoreStorageMock()
        )
    
        CourseDetailsView(
            viewModel: vm,
            courseID: "courseID",
            title: "Course title"
        )
        .preferredColorScheme(.light)
        .previewDisplayName("CourseDetailsView Light")
    
        CourseDetailsView(
            viewModel: vm,
            courseID: "courseID",
            title: "Course title"
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("CourseDetailsView Dark")
    }
}
// swiftlint:enable all
#endif
