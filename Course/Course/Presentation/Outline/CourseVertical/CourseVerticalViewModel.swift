//
//  CourseVerticalViewModel.swift
//  Course
//
//  Created by  Stepanok Ivan on 14.03.2023.
//

import SwiftUI
import Core
import OEXFoundation

public final class CourseVerticalViewModel: ObservableObject, @unchecked Sendable {
    let router: CourseRouter
    let analytics: CourseAnalytics
    let connectivity: ConnectivityProtocol
    let interactor: CourseInteractorProtocol
    @Published var verticals: [CourseVertical]
    @Published var showError: Bool = false
    @Published var isLoading: Bool = false
    @Published var chapters: [CourseChapter]
    let chapterIndex: Int
    let sequentialIndex: Int
    let courseID: String
    
    var errorMessage: String? {
        didSet {
            withAnimation {
                showError = errorMessage != nil
            }
        }
    }
    
    public init(
        chapters: [CourseChapter],
        chapterIndex: Int,
        sequentialIndex: Int,
        courseID: String,
        router: CourseRouter,
        analytics: CourseAnalytics,
        connectivity: ConnectivityProtocol,
        interactor: CourseInteractorProtocol
    ) {
        self.chapters = chapters
        self.chapterIndex = chapterIndex
        self.sequentialIndex = sequentialIndex
        self.courseID = courseID
        self.router = router
        self.analytics = analytics
        self.connectivity = connectivity
        self.interactor = interactor
        self.verticals = chapters[chapterIndex].childs[sequentialIndex].childs
    }
    
    func trackVerticalClicked(
        courseId: String,
        courseName: String,
        vertical: CourseVertical
    ) {
        analytics.verticalClicked(
            courseId: courseId,
            courseName: courseName,
            blockId: vertical.blockId,
            blockName: vertical.displayName
        )
    }
    
    @MainActor
    func refreshAndCheckVertical(
        verticalIndex: Int
    ) async -> (vertical: CourseVertical, sequential: CourseSequential)? {
        guard connectivity.isInternetAvaliable else { return nil }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let freshStructure = try await interactor.getCourseBlocks(courseID: courseID)
            self.chapters = freshStructure.childs
            
            // Notify that course structure has been updated
            NotificationCenter.default.post(
                name: .courseStructureUpdated,
                object: nil,
                userInfo: ["courseID": courseID, "chapters": freshStructure.childs]
            )
            
            guard chapterIndex < chapters.count,
                  sequentialIndex < chapters[chapterIndex].childs.count else {
                return nil
            }
            
            let freshSequential = chapters[chapterIndex].childs[sequentialIndex]
            self.verticals = freshSequential.childs
            
            guard verticalIndex < verticals.count else { return nil }
            return (verticals[verticalIndex], freshSequential)
        } catch {
            return nil
        }
    }
}
