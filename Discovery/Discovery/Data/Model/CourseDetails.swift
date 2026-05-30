//
//  CourseDetails.swift
//  CourseDetails
//
//  Created by  Stepanok Ivan on 26.09.2022.
//

import Foundation

public struct CourseDetails: Sendable {
    public let courseID: String
    public let org: String
    public let courseTitle: String
    public let courseDescription: String?
    public let longDescription: String?
    public let courseRequirement: String?
    public let learningOutcomes: [String]?
    public let instructors: [CourseInstructor]?
    public let courseStart: Date?
    public let courseEnd: Date?
    public let enrollmentStart: Date?
    public let enrollmentEnd: Date?
    public var isEnrolled: Bool
    public var overviewHTML: String
    public let courseBannerURL: String
    public let courseVideoURL: String?
    public let courseRawImage: String?
    public let duration: String?
    public let purchaseURL: String?
    
    public init(courseID: String,
                org: String,
                courseTitle: String,
                courseDescription: String?,
                longDescription: String?,
                courseRequirement: String?,
                learningOutcomes: [String]?,
                instructors: [CourseInstructor]?,
                courseStart: Date?,
                courseEnd: Date?,
                enrollmentStart: Date?,
                enrollmentEnd: Date?,
                isEnrolled: Bool,
                overviewHTML: String,
                courseBannerURL: String,
                courseVideoURL: String?,
                courseRawImage: String?,
                duration: String? = nil,
                purchaseURL: String? = nil
    ) {
        self.courseID = courseID
        self.org = org
        self.courseTitle = courseTitle
        self.courseDescription = courseDescription
        self.longDescription = longDescription
        self.courseRequirement = courseRequirement
        self.learningOutcomes = learningOutcomes
        self.instructors = instructors
        self.courseStart = courseStart
        self.courseEnd = courseEnd
        self.enrollmentStart = enrollmentStart
        self.enrollmentEnd = enrollmentEnd
        self.isEnrolled = isEnrolled
        self.overviewHTML = overviewHTML
        self.courseBannerURL = courseBannerURL
        self.courseVideoURL = courseVideoURL
        self.courseRawImage = courseRawImage
        self.duration = duration
        self.purchaseURL = purchaseURL
    }
}

public struct CourseInstructor: Sendable, Codable {
    public let name: String?
    public let title: String?
    public let organization: String?
    public let bio: String?
    public let image: String?
}
