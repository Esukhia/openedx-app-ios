//
//  AgreementConfig.swift
//  Core
//
//  Created by Muhammad Umer on 11/13/23.
//

import Foundation
import OEXFoundation

private enum AgreementKeys: String, RawStringExtractable {
    case privacyPolicyURL = "PRIVACY_POLICY_URL"
    case tosURL = "TOS_URL"
    case cookiePolicyURL = "COOKIE_POLICY_URL"
    case dataSellContentURL = "DATA_SELL_CONSENT_URL"
    case eulaURL = "EULA_URL"
    case supportedLanguages = "SUPPORTED_LANGUAGES"
}

public class AgreementConfig: NSObject {
    public var privacyPolicyURL: URL?
    public var tosURL: URL?
    public var cookiePolicyURL: URL?
    public var dataSellContentURL: URL?
    public var eulaURL: URL?
    public var supportedLanguages: [String]?

    init(dictionary: [String: AnyObject]) {
        supportedLanguages = dictionary[AgreementKeys.supportedLanguages] as? [String]
        cookiePolicyURL = (dictionary[AgreementKeys.cookiePolicyURL] as? String).flatMap(URL.init)
        dataSellContentURL = (dictionary[AgreementKeys.dataSellContentURL] as? String).flatMap(URL.init)
        eulaURL = (dictionary[AgreementKeys.eulaURL] as? String).flatMap(URL.init)

        super.init()

        if let tosURL = dictionary[AgreementKeys.tosURL.rawValue] as? String {
            self.tosURL = URL(string: completePath(url: tosURL))
        }

        if let privacyPolicyURL = dictionary[AgreementKeys.privacyPolicyURL.rawValue] as? String {
            self.privacyPolicyURL = URL(string: completePath(url: privacyPolicyURL))
        }
    }

    /**
     * Processes URLs to include language code in the path when appropriate.
     * 
     * This method takes a URL string and attempts to insert the device's current language code
     * into the URL path, creating a localized URL path structure like:
     * https://domain.com/{language_code}/path
     *
     * Special cases:
     * - URLs containing "sherab.org" are returned as-is without modification to preserve
     *   their original structure and prevent navigation issues
     * - If the current language is not in the supported languages list, the URL is returned as-is
     * - If the URL structure doesn't match the expected format, the URL is returned as-is
     *
     * @param url The original URL string to process
     * @return The processed URL string with language code inserted if applicable
     */
    private func completePath(url: String) -> String {
        // Skip language insertion for sherab.org domain
        // This prevents URL transformation issues with the sherab.org privacy policy
        if url.contains("sherab.org") {
            return url
        }
        
        let langCode = Locale.current.language.languageCode?.identifier ?? ""

        if let supportedLanguages = supportedLanguages,
           !supportedLanguages.contains(langCode) {
            return url
        }

        let URL = URL(string: url)
        let host = URL?.host ?? ""
        let components = url.components(separatedBy: host)

        if components.count != 2 {
            return url
        }

        if let firstComponent = components.first, let lastComponent = components.last {
            return "\(firstComponent)\(host)/\(langCode)\(lastComponent)"
        }

        return url
    }
}

private let key = "AGREEMENT_URLS"
extension Config {
    public var agreement: AgreementConfig {
        return AgreementConfig(dictionary: self[key] as? [String: AnyObject] ?? [:])
    }
}
