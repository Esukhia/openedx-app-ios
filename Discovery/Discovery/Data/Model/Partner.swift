//
//  Partner.swift
//  Discovery
//
//  Created by Cascade on 31.07.2025.
//

import Foundation

public struct Partner: Codable, Hashable, Identifiable, Sendable {
    public var id: String { organization }
    public let partnerName: String
    public let logo: String
    public let organization: String
    
    enum CodingKeys: String, CodingKey {
        case partnerName = "partner_name"
        case logo
        case organization
    }
    
    public init(partnerName: String, logo: String, organization: String) {
        self.partnerName = partnerName
        self.logo = logo
        self.organization = organization
    }
}
