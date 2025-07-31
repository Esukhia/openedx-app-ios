//
//  DiscoveryInteractor.swift
//  Discovery
//
//  Created by  Stepanok Ivan on 16.09.2022.
//

import Foundation
import Core

//sourcery: AutoMockable
public protocol DiscoveryInteractorProtocol: Sendable {
    func discovery(page: Int) async throws -> [CourseItem]
    func discoveryByOrg(page: Int, organization: String) async throws -> [CourseItem]
    func discoveryOffline() async throws -> [CourseItem]
    func search(page: Int, searchTerm: String) async throws -> [CourseItem]
    func getLoadedCourseDetails(courseID: String) async throws -> CourseDetails
    func getCourseDetails(courseID: String) async throws -> CourseDetails
    func enrollToCourse(courseID: String) async throws -> Bool
    func getPartners() async throws -> [Partner]
}

public actor DiscoveryInteractor: DiscoveryInteractorProtocol {
    
    private let repository: DiscoveryRepositoryProtocol
    
    public init(repository: DiscoveryRepositoryProtocol) {
        self.repository = repository
    }
    
    public func discovery(page: Int) async throws -> [CourseItem] {
        return try await repository.getDiscovery(page: page)
    }
    
    public func discoveryByOrg(page: Int, organization: String) async throws -> [CourseItem] {
        return try await repository.getDiscoveryByOrg(page: page, organization: organization)
    }
    
    public func search(page: Int, searchTerm: String) async throws -> [CourseItem] {
        return try await repository.searchCourses(page: page, searchTerm: searchTerm)
    }
    
    public func discoveryOffline() async throws -> [CourseItem] {
        try await repository.getDiscoveryOffline()
    }
    
    public func getCourseDetails(courseID: String) async throws -> CourseDetails {
        return try await repository.getCourseDetails(courseID: courseID)
    }
    
    public func getLoadedCourseDetails(courseID: String) async throws -> CourseDetails {
        return try await repository.getLoadedCourseDetails(courseID: courseID)
    }
    
    public func enrollToCourse(courseID: String) async throws -> Bool {
        return try await repository.enrollToCourse(courseID: courseID)
    }
    
    public func getPartners() async throws -> [Partner] {
        return try await repository.getPartners()
    }
}

// Mark - For testing and SwiftUI preview
#if DEBUG
public extension DiscoveryInteractor {
    static let mock = DiscoveryInteractor(repository: DiscoveryRepositoryMock())
}
#endif
