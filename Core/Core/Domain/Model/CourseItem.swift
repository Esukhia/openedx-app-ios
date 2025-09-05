//
//  Discovery.swift
//  Core
//
//  Created by  Stepanok Ivan on 16.09.2022.
//

import Foundation

public struct CourseItem: Hashable, Identifiable, Sendable {
    public var id: String { courseID }
    public let name: String
    public let org: String
    public let shortDescription: String
    public let imageURL: String
    public let hasAccess: Bool
    public let courseStart: Date?
    public let courseEnd: Date?
    public let enrollmentStart: Date?
    public let enrollmentEnd: Date?
    public let courseID: String
    public let numPages: Int
    public let coursesCount: Int
    public let courseRawImage: String?
    public let progressEarned: Int
    public let progressPossible: Int
    public let duration: String?
    
    public init(name: String,
                org: String,
                shortDescription: String,
                imageURL: String,
                hasAccess: Bool,
                courseStart: Date?,
                courseEnd: Date?,
                enrollmentStart: Date?,
                enrollmentEnd: Date?,
                courseID: String,
                numPages: Int,
                coursesCount: Int,
                courseRawImage: String?,
                progressEarned: Int,
                progressPossible: Int,
                duration: String? = nil) {
        self.name = name
        self.org = org
        self.shortDescription = shortDescription
        self.imageURL = imageURL
        self.hasAccess = hasAccess
        self.courseStart = courseStart
        self.courseEnd = courseEnd
        self.enrollmentStart = enrollmentStart
        self.enrollmentEnd = enrollmentEnd
        self.courseID = courseID
        self.numPages = numPages
        self.coursesCount = coursesCount
        self.courseRawImage = courseRawImage
        self.progressEarned = progressEarned
        self.progressPossible = progressPossible
        self.duration = duration
    }
}
