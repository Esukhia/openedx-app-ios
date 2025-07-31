//
//  DiscoveryEndpoint.swift
//  Discovery
//
//  Created by  Stepanok Ivan on 16.09.2022.
//

import Foundation
import Core
import OEXFoundation
import Alamofire

enum DiscoveryEndpoint: EndPointType {
    case getDiscovery(username: String, page: Int)
    case getDiscoveryByOrg(username: String, page: Int, organization: String)
    case searchCourses(username: String, page: Int, searchTerm: String)
    case getCourseDetail(courseID: String, username: String)
    case enrollToCourse(courseID: String)
    case getPartners
    
    var path: String {
        switch self {
        case .getDiscovery, .getDiscoveryByOrg:
            return "/api/courses/v1/courses/"
        case .searchCourses:
            return "/api/courses/v1/courses/"
        case .getCourseDetail(courseID: let courseID, _):
            return "/api/courses/v1/courses/\(courseID)"
        case .enrollToCourse:
            return "/api/enrollment/v1/enrollment"
        case .getPartners:
            return "/api/partners/"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .getDiscovery, .getDiscoveryByOrg, .searchCourses, .getPartners:
            return .get
        case .getCourseDetail:
            return .get
        case .enrollToCourse:
            return .post
        }
    }
    
    var headers: HTTPHeaders? {
        nil
    }
    
    var task: HTTPTask {
        switch self {
        case let .getDiscovery(_, page):
            let params: Parameters = [
                "mobile": true,
                "permissions": ["enroll", "see_about_page", "see_in_catalog"],
                "page": page
            ]
            return .requestParameters(parameters: params, encoding: CustomGetEncoding())
            
        case let .getDiscoveryByOrg(_, page, organization):
            let params: Parameters = [
                "mobile": true,
                "permissions": ["enroll", "see_about_page", "see_in_catalog"],
                "page": page,
                "org": organization
            ]
            return .requestParameters(parameters: params, encoding: CustomGetEncoding())
            
        case let .searchCourses(username, page, searchTerm):
            let params: Parameters = [
                "username": username,
                "mobile": true,
                "mobile_search": true,
                "page": page,
                "search_term": searchTerm
            ]
            
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
            
        case .enrollToCourse(courseID: let courseID):
            
            let details: [String: any Any & Sendable] = [
                "course_id": courseID,
                "email_opt_in": true
            ]
            
            let params: [String: any Any & Sendable] = [
                "course_details": details
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case let .getCourseDetail(_, username):
            let params: [String: Encodable & Sendable] = ["username": username]
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
            
        case .getPartners:
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        }
    }
}
