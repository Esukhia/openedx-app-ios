//
//  CourseVerticalView.swift
//  Course
//
//  Created by  Stepanok Ivan on 12.12.2022.
//

import SwiftUI
import Core
import OEXFoundation
import Kingfisher
import Theme

public struct CourseVerticalView: View {
    
    private var title: String
    private var courseName: String
    private var courseID: String
    @ObservedObject
    private var viewModel: CourseVerticalViewModel
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    public init(
        title: String,
        courseName: String,
        courseID: String,
        viewModel: CourseVerticalViewModel
    ) {
        self.title = title
        self.courseName = courseName
        self.courseID = courseID
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // MARK: - Page Body
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading) {
                        // MARK: - Lessons list
                        ForEach(viewModel.verticals, id: \.id) { vertical in
                            if let index = viewModel.verticals.firstIndex(where: {$0.id == vertical.id}) {
                                HStack {
                                Button(action: {
                                    let vertical = viewModel.verticals[index]
                                    let sequential = viewModel.chapters[viewModel.chapterIndex]
                                        .childs[viewModel.sequentialIndex]
                                    let verticalGatedContent = vertical.gatedContent
                                    let sequentialGatedContent = sequential.gatedContent
                                    let isLocked = (verticalGatedContent?.gated ?? false) ||
                                        (sequentialGatedContent?.gated ?? false)
                                    if isLocked {
                                        let initialGatedContent = verticalGatedContent?.gated == true
                                            ? verticalGatedContent
                                            : sequentialGatedContent
                                        Task {
                                            if let result = await viewModel.refreshAndCheckVertical(
                                                verticalIndex: index
                                            ) {
                                                let freshVertical = result.vertical
                                                let freshSequential = result.sequential
                                                if let freshGatedContent = freshVertical.gatedContent,
                                                   freshGatedContent.gated {
                                                    viewModel.router.showLockedContent(
                                                        gatedContent: freshGatedContent,
                                                        courseID: courseID,
                                                        chapters: viewModel.chapters
                                                    )
                                                } else if let freshSequentialGated = freshSequential.gatedContent,
                                                          freshSequentialGated.gated {
                                                    viewModel.router.showLockedContent(
                                                        gatedContent: freshSequentialGated,
                                                        courseID: courseID,
                                                        chapters: viewModel.chapters
                                                    )
                                                } else if let block = freshVertical.childs.first {
                                                    viewModel.trackVerticalClicked(
                                                        courseId: courseID,
                                                        courseName: courseName,
                                                        vertical: freshVertical
                                                    )
                                                    viewModel.router.showCourseUnit(
                                                        courseName: courseName,
                                                        blockId: block.id,
                                                        courseID: courseID,
                                                        verticalIndex: index,
                                                        chapters: viewModel.chapters,
                                                        chapterIndex: viewModel.chapterIndex,
                                                        sequentialIndex: viewModel.sequentialIndex
                                                    )
                                                } else if let fallbackGated = initialGatedContent {
                                                    viewModel.router.showLockedContent(
                                                        gatedContent: fallbackGated,
                                                        courseID: courseID,
                                                        chapters: viewModel.chapters
                                                    )
                                                }
                                            } else if let fallbackGated = initialGatedContent {
                                                viewModel.router.showLockedContent(
                                                    gatedContent: fallbackGated,
                                                    courseID: courseID,
                                                    chapters: viewModel.chapters
                                                )
                                            }
                                        }
                                        return
                                    }
                                    if let block = vertical.childs.first {
                                        viewModel.trackVerticalClicked(
                                            courseId: courseID,
                                            courseName: courseName,
                                            vertical: vertical
                                        )
                                        viewModel.router.showCourseUnit(
                                            courseName: courseName,
                                            blockId: block.id,
                                            courseID: courseID,
                                            verticalIndex: index,
                                            chapters: viewModel.chapters,
                                            chapterIndex: viewModel.chapterIndex,
                                            sequentialIndex: viewModel.sequentialIndex
                                        )
                                    }
                                }, label: {
                                        HStack(alignment: .top, spacing: 16) {
                                            Group {
                                                if let gatedContent = vertical.gatedContent, gatedContent.gated {
                                                    Image(systemName: "lock.fill")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .foregroundColor(Theme.Colors.textSecondary)
                                                } else if vertical.completion == 1 {
                                                    CoreAssets.finished.swiftUIImage
                                                        .renderingMode(.template)
                                                        .foregroundColor(.accentColor)
                                                } else {
                                                    CourseVerticalImageView(blocks: vertical.childs)
                                                }
                                            }
                                            .frame(width: 20, height: 20, alignment: .top)
                                            Text(vertical.displayName)
                                                .font(Theme.Fonts.titleMedium)
                                                .lineLimit(1)
                                                .frame(maxWidth: idiom == .pad
                                                       ? proxy.size.width * 0.5
                                                       : proxy.size.width * 0.6,
                                                       alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    }).accessibilityElement(children: .ignore)
                                        .accessibilityLabel(vertical.displayName)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                        .flipsForRightToLeftLayoutDirection(true)
                                            .padding(.vertical, 8)
                                    }
                                .padding(.horizontal, 36)
                                    .padding(.vertical, 14)
                                if index != viewModel.verticals.count - 1 {
                                    Divider()
                                        .frame(height: 1)
                                        .overlay(Theme.Colors.cardViewStroke)
                                        .padding(.horizontal, 24)
                                }
                            }
                        }
                    }
                    .frameLimit(width: proxy.size.width)
                    Spacer(minLength: 84)
                }
                .accessibilityAction {}
                .onRightSwipeGesture {
                    viewModel.router.back()
                }
            }
            .padding(.top, 8)
            
            // MARK: - Offline mode SnackBar
            OfflineSnackBarView(connectivity: viewModel.connectivity,
                                reloadAction: { })
            
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
        .overlay {
            if viewModel.isLoading {
                DimmedLoadingOverlay()
            }
        }
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
        .navigationTitle(title)
        .background(
            Theme.Colors.background
                .ignoresSafeArea()
        )
    }
}

struct DimmedLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            ProgressBar(size: 48, lineWidth: 6)
        }
        .transition(.opacity)
    }
}

#if DEBUG
struct CourseVerticalView_Previews: PreviewProvider {
    static var previews: some View {
        let chapters = [
            CourseChapter(
                blockId: "1",
                id: "1",
                displayName: "Chapter 1",
                type: .chapter,
                childs: [
                    CourseSequential(
                        blockId: "3",
                        id: "3",
                        displayName: "Sequential",
                        type: .sequential,
                        completion: 1,
                        childs: [
                            CourseVertical(
                                blockId: "4",
                                id: "4",
                                courseId: "1",
                                displayName: "Vertical",
                                type: .vertical,
                                completion: 0,
                                childs: [],
                                webUrl: ""
                            )
                        ],
                        sequentialProgress: SequentialProgress(
                            assignmentType: "Advanced Assessment Tools",
                            numPointsEarned: 1,
                            numPointsPossible: 3
                        ),
                        due: Date()
                    )
                ])
        ]
        
        let courseStructure = CourseStructure(
            id: "course-id",
            graded: false,
            completion: 0,
            viewYouTubeUrl: "",
            encodedVideo: "",
            displayName: "CourseName",
            topicID: nil,
            childs: chapters,
            media: CourseMedia(image: CourseImage(raw: "", small: "", large: "")),
            certificate: nil,
            org: "",
            isSelfPaced: true,
            courseProgress: nil
        )
        
        let viewModel = CourseVerticalViewModel(
            chapters: chapters,
            chapterIndex: 0,
            sequentialIndex: 0,
            courseID: courseStructure.id,
            router: CourseRouterMock(),
            analytics: CourseAnalyticsMock(),
            connectivity: Connectivity(),
            interactor: PreviewCourseInteractor(structure: courseStructure)
        )
        
        return Group {
            CourseVerticalView(
                title: "Course title",
                courseName: courseStructure.displayName,
                courseID: courseStructure.id,
                viewModel: viewModel
            )
            .preferredColorScheme(.light)
            .previewDisplayName("CourseVerticalView Light")
            
            CourseVerticalView(
                title: "Course title",
                courseName: courseStructure.displayName,
                courseID: courseStructure.id,
                viewModel: viewModel
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("CourseVerticalView Dark")
        }
    }
    
    private enum PreviewError: Error {
        case notSupported
    }
    
    private final class PreviewCourseInteractor: CourseInteractorProtocol {
        private let structure: CourseStructure
        
        init(structure: CourseStructure) {
            self.structure = structure
        }
        
        func getCourseBlocks(courseID: String) async throws -> CourseStructure {
            structure
        }
        
        func getCourseVideoBlocks(fullStructure: CourseStructure) async -> CourseStructure {
            fullStructure
        }
        
        func getLoadedCourseBlocks(courseID: String) async throws -> CourseStructure {
            structure
        }
        
        func getSequentialsContainsBlocks(blockIds: [String], courseID: String) async throws -> [CourseSequential] {
            structure.childs.flatMap { $0.childs }
        }
        
        func blockCompletionRequest(courseID: String, blockID: String) async throws {}
        
        func getHandouts(courseID: String) async throws -> String? {
            nil
        }
        
        func getUpdates(courseID: String) async throws -> [CourseUpdate] {
            []
        }
        
        func resumeBlock(courseID: String) async throws -> ResumeBlock {
            throw PreviewError.notSupported
        }
        
        func getSubtitles(url: String, selectedLanguage: String) async throws -> [Subtitle] {
            []
        }
        
        func getCourseDates(courseID: String) async throws -> CourseDates {
            throw PreviewError.notSupported
        }
        
        func getCourseDeadlineInfo(courseID: String) async throws -> CourseDateBanner {
            throw PreviewError.notSupported
        }
        
        func shiftDueDates(courseID: String) async throws {
            throw PreviewError.notSupported
        }
    }
}

#endif
