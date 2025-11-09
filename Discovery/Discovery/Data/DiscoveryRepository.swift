//
//  DiscoveryRepository.swift
//  Discovery
//
//  Created by  Stepanok Ivan on 16.09.2022.
//

import Foundation
import Core
import OEXFoundation
import CoreData
import Alamofire

public protocol DiscoveryRepositoryProtocol: Sendable {
    func getDiscovery(page: Int) async throws -> [CourseItem]
    func getDiscoveryByOrg(page: Int, organization: String) async throws -> [CourseItem]
    func searchCourses(page: Int, searchTerm: String) async throws -> [CourseItem]
    func getDiscoveryOffline() async throws -> [CourseItem]
    func getCourseDetails(courseID: String) async throws -> CourseDetails
    func getLoadedCourseDetails(courseID: String) async throws -> CourseDetails
    func enrollToCourse(courseID: String) async throws -> Bool
    func getPartners() async throws -> [Partner]
}

public actor DiscoveryRepository: DiscoveryRepositoryProtocol {
    
    private let api: API
    private let coreStorage: CoreStorage
    private let config: ConfigProtocol
    private let persistence: DiscoveryPersistenceProtocol
    
    public init(
        api: API,
        appStorage: CoreStorage,
        config: ConfigProtocol,
        persistence: DiscoveryPersistenceProtocol
    ) {
        self.api = api
        self.coreStorage = appStorage
        self.config = config
        self.persistence = persistence
    }
    
    public func getDiscovery(page: Int) async throws -> [CourseItem] {
        let discoveryResponse = try await api.requestData(DiscoveryEndpoint.getDiscovery(
            username: coreStorage.user?.username ?? "", page: page)
        ).mapResponse(DataLayer.DiscoveryResponce.self).domain
        await persistence.saveDiscovery(items: discoveryResponse)
        return discoveryResponse
    }
    
    public func getDiscoveryByOrg(page: Int, organization: String) async throws -> [CourseItem] {
        let discoveryResponse = try await api.requestData(DiscoveryEndpoint.getDiscoveryByOrg(
            username: coreStorage.user?.username ?? "", page: page, organization: organization)
        ).mapResponse(DataLayer.DiscoveryResponce.self).domain
        await persistence.saveDiscovery(items: discoveryResponse)
        return discoveryResponse
    }
    
    public func getDiscoveryOffline() async throws -> [CourseItem] {
        try await persistence.loadDiscovery()
    }
    
    public func searchCourses(page: Int, searchTerm: String) async throws -> [CourseItem] {
        let searchResponse = try await api.requestData(DiscoveryEndpoint.searchCourses(
            username: coreStorage.user?.username ?? "", page: page, searchTerm: searchTerm)
        ).mapResponse(DataLayer.DiscoveryResponce.self).domain
                         
        return searchResponse
    }
    
    public func getCourseDetails(courseID: String) async throws -> CourseDetails {
        let response = try await api.requestData(
            DiscoveryEndpoint.getCourseDetail(courseID: courseID, username: coreStorage.user?.username ?? "")
        ).mapResponse(DataLayer.CourseDetailsResponse.self)
            .domain(baseURL: config.baseURL.absoluteString)
        
        await persistence.saveCourseDetails(course: response)
        
        return response
    }
    
    public func getLoadedCourseDetails(courseID: String) async throws -> CourseDetails {
        try await persistence.loadCourseDetails(courseID: courseID)
    }
    
    public func enrollToCourse(courseID: String) async throws -> Bool {
        let enroll = try await api.request(DiscoveryEndpoint.enrollToCourse(courseID: courseID))
        return enroll.statusCode == 200
    }
    
    public func getPartners() async throws -> [Partner] {
        let partnersResponse = try await api.requestData(DiscoveryEndpoint.getPartners)
            .mapResponse([Partner].self)
        return partnersResponse
    }
}

// Mark - For testing and SwiftUI preview
#if DEBUG
final class DiscoveryRepositoryMock: DiscoveryRepositoryProtocol {
    
    public  func getCourseDetails(courseID: String) async throws -> CourseDetails {
        return CourseDetails(
            courseID: "courseID",
            org: "Organization",
            courseTitle: "Course title",
            courseDescription: "Course description",
            longDescription: "Long description",
            courseRequirement: "Some requirements",
            learningOutcomes: ["Outcome 1", "Outcome 2"],
            instructors: [
                CourseInstructor(
                    name: "Instructor Name",
                    title: "Professor",
                    organization: "Org",
                    bio: "Bio",
                    image: nil
                )
            ],
            courseStart: Date(iso8601: "2021-05-26T12:13:14Z"),
            courseEnd: Date(iso8601: "2022-05-26T12:13:14Z"),
            enrollmentStart: nil,
            enrollmentEnd: nil,
            isEnrolled: false,
            overviewHTML: "<b>Course description</b><br><br>Lorem ipsum",
            courseBannerURL: "courseBannerURL",
            courseVideoURL: nil,
            courseRawImage: nil
        )
    }
    
    func getLoadedCourseDetails(courseID: String) async throws -> CourseDetails {
        return CourseDetails(
            courseID: "courseID",
            org: "Organization",
            courseTitle: "Course title",
            courseDescription: "Course description",
            longDescription: nil,
            courseRequirement: nil,
            learningOutcomes: nil,
            instructors: nil,
            courseStart: Date(iso8601: "2021-05-26T12:13:14Z"),
            courseEnd: Date(iso8601: "2022-05-26T12:13:14Z"),
            enrollmentStart: nil,
            enrollmentEnd: nil,
            isEnrolled: false,
            overviewHTML: "<b>Course description</b><br><br>Lorem ipsum",
            courseBannerURL: "courseBannerURL",
            courseVideoURL: nil,
            courseRawImage: nil
        )
    }
    
    public  func enrollToCourse(courseID: String) async throws -> Bool {
        return true
    }
    
    func getDiscovery(page: Int) async throws -> [CourseItem] {
        var models: [CourseItem] = []
        for i in 0...10 {
            models.append(
                CourseItem(
                    name: "Course name \(i)",
                    org: "Organization",
                    shortDescription: "shortDescription",
                    imageURL: "",
                    hasAccess: true,
                    courseStart: nil,
                    courseEnd: nil,
                    enrollmentStart: nil,
                    enrollmentEnd: nil,
                    courseID: "course_id_\(i)",
                    numPages: 1, coursesCount: 10,
                    courseRawImage: nil,
                    progressEarned: 0,
                    progressPossible: 0
                )
            )
        }
        return models
    }
    
    func searchCourses(page: Int, searchTerm: String) async throws -> [CourseItem] {
        var models: [CourseItem] = []
        for i in 0...10 {
            models.append(
                CourseItem(
                    name: "Course name \(i)",
                    org: "Organization",
                    shortDescription: "shortDescription",
                    imageURL: "",
                    hasAccess: true,
                    courseStart: nil,
                    courseEnd: nil,
                    enrollmentStart: nil,
                    enrollmentEnd: nil,
                    courseID: "course_id_\(i)",
                    numPages: 1, coursesCount: 10,
                    courseRawImage: nil,
                    progressEarned: 0,
                    progressPossible: 0
                )
            )
        }
        return models
    }
    
    func getDiscoveryOffline() -> [CourseItem] {
        var models: [CourseItem] = []
        for i in 0...10 {
            models.append(
                CourseItem(
                    name: "Course name \(i)",
                    org: "Organization",
                    shortDescription: "shortDescription",
                    imageURL: "",
                    hasAccess: true,
                    courseStart: nil,
                    courseEnd: nil,
                    enrollmentStart: nil,
                    enrollmentEnd: nil,
                    courseID: "course_id_\(i)",
                    numPages: 1,
                    coursesCount: 10,
                    courseRawImage: nil,
                    progressEarned: 0,
                    progressPossible: 0
                )
            )
        }
        return models
    }
    
    func getDiscoveryByOrg(page: Int, organization: String) async throws -> [CourseItem] {
        var models: [CourseItem] = []
        for i in 0...5 {
            models.append(
                CourseItem(
                    name: "\(organization) Course \(i)",
                    org: organization,
                    shortDescription: "Course from \(organization)",
                    imageURL: "",
                    hasAccess: true,
                    courseStart: nil,
                    courseEnd: nil,
                    enrollmentStart: nil,
                    enrollmentEnd: nil,
                    courseID: "\(organization.lowercased())_course_\(i)",
                    numPages: 1,
                    coursesCount: 6,
                    courseRawImage: nil,
                    progressEarned: 0,
                    progressPossible: 0
                )
            )
        }
        return models
    }
    
    func getPartners() async throws -> [Partner] {
        return [
            Partner(
                partnerName: "BDRC",
                logo: "https://staging.sherab.org/media/partner/BDRC_Logo.png",
                organization: "BDRC"
            ),
            Partner(
                partnerName: "Kumarajiva",
                logo: "https://staging.sherab.org/media/partner/Kumarajiva_logo.png",
                organization: "Kumarajiva"
            ),
            Partner(
                partnerName: "Sherab",
                logo: "https://staging.sherab.org/media/partner/sherab.jpeg",
                organization: "Sherab"
            ),
            Partner(
                partnerName: "Esukhia",
                logo: "https://staging.sherab.org/media/partner/Esukhia_logo.png",
                organization: "Esukhia"
            ),
            Partner(
                partnerName: "Sarah College",
                logo: "https://staging.sherab.org/media/partner/Sarah_college_logo.png",
                organization: "Sarah"
            )
        ]
    }
}
#endif
