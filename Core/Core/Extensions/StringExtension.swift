//
//  StringExtension.swift
//  Core
//
//  Created by Ivan Stepanok on 24.04.2025.
//

import Foundation

public extension String {
    /// Prepends `baseURL` only when the receiver is a relative path.
    /// Returns the receiver unchanged if it is empty or already an absolute http(s) URL.
    /// Handles trailing-slash / leading-slash mismatches to avoid double or missing slashes.
    func prependingBaseURL(_ baseURL: String) -> String {
        if isEmpty { return "" }
        if hasPrefix("http://") || hasPrefix("https://") { return self }
        if baseURL.hasSuffix("/") && hasPrefix("/") {
            return String(baseURL.dropLast()) + self
        }
        if !baseURL.hasSuffix("/") && !hasPrefix("/") {
            return baseURL + "/" + self
        }
        return baseURL + self
    }

    func isAppVersionGreater(than otherVersion: String) -> Bool {
        let v1 = self.split(separator: ".").compactMap { Int($0) }
        let v2 = otherVersion.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(v1.count, v2.count)
        for i in 0..<maxCount {
            let part1 = i < v1.count ? v1[i] : 0
            let part2 = i < v2.count ? v2[i] : 0
            if part1 != part2 {
                return part1 > part2
            }
        }
        return false // equal or less
    }
    
    func youtubeVideoID() -> String? {
            guard let url = URL(string: self) else { return nil }

            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let id = components.queryItems?.first(where: { $0.name == "v" })?.value,
               !id.isEmpty {
                return id
            }

            // https://youtu.be/ID
            if url.host == "youtu.be" {
                let id = url.lastPathComponent
                return id.isEmpty ? nil : id
            }

            if url.pathComponents.contains("embed"),
               let id = url.pathComponents.last,
               id != "embed" {
                return id
            }

            return nil
        }
}
