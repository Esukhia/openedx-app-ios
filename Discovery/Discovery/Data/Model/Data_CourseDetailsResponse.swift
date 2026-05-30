//
//  CourseDetailsResponse.swift
//  CourseDetails
//
//  Created by  Stepanok Ivan on 26.09.2022.
//

import Foundation
import Core

public extension DataLayer {
    // MARK: - CourseDetailsResponse
    struct CourseDetailsResponse: Codable {
        public let blocksURL: String
        public let effort: String?
        public let duration: String?
        public let end: String?
        public let enrollmentStart: String?
        public let enrollmentEnd: String?
        public let isEnrolled: Bool?
        public let id: String
        public let media: Media
        public let name: String
        public let number: String
        public let org: String
        public let shortDescription: String?
        public let description: String?
        public let courseRequirement: String?
        public let learningOutcomes: [String]?
        public let instructors: [Instructor]?
        public let start: String?
        public let startDisplay: String?
        public let startType: String?
        public let pacing: String
        public let mobileAvailable: Bool
        public let hidden: Bool
        public let invitationOnly: Bool
        public let courseID: String
        public let overview: String
        public let purchaseLink: String?
        
        enum CodingKeys: String, CodingKey {
            case blocksURL = "blocks_url"
            case effort
            case duration
            case end
            case enrollmentStart = "enrollment_start"
            case enrollmentEnd = "enrollment_end"
            case isEnrolled = "is_enrolled"
            case id
            case media
            case name
            case number
            case org
            case shortDescription = "short_description"
            case description
            case courseRequirement = "course_requirement"
            case learningOutcomes = "learning_outcomes"
            case instructors
            case start
            case startDisplay = "start_display"
            case startType = "start_type"
            case pacing
            case mobileAvailable = "mobile_available"
            case hidden
            case invitationOnly = "invitation_only"
            case courseID = "course_id"
            case overview
            case purchaseLink = "purchase_link"
        }
    }
    
    struct Instructor: Codable {
        public let name: String?
        public let title: String?
        public let organization: String?
        public let bio: String?
        public let image: String?
    }
}

public extension DataLayer.CourseDetailsResponse {
    func domain(baseURL: String) -> CourseDetails {
        let imageURL = baseURL.removingTrailingSlash + (media.courseImage?.url?.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed) ?? "")
        return CourseDetails(
            courseID: id,
            org: org,
            courseTitle: name,
            courseDescription: shortDescription,
            longDescription: description,
            courseRequirement: courseRequirement,
            learningOutcomes: learningOutcomes,
            instructors: instructors?.map {
                CourseInstructor(
                    name: $0.name,
                    title: $0.title,
                    organization: $0.organization,
                    bio: $0.bio,
                    image: $0.image
                )
            },
            courseStart: start != nil ? Date(iso8601: start!) : nil,
            courseEnd: end != nil ? Date(iso8601: end!) : nil,
            enrollmentStart: enrollmentStart != nil ? Date(iso8601: enrollmentStart!) : nil,
            enrollmentEnd: enrollmentEnd != nil ? Date(iso8601: enrollmentEnd!) : nil,
            isEnrolled: isEnrolled ?? false,
            overviewHTML: overview,
            courseBannerURL: imageURL,
            courseVideoURL: media.courseVideo?.url,
            courseRawImage: media.image?.raw,
            duration: duration,
            purchaseURL: purchaseLink
        )
    }
}
