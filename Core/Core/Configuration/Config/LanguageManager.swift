//
//  LanguageManager.swift
//  Core
//
//  Created for in-app language switching
//

import Foundation
import SwiftUI

@MainActor
public class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()
    
    @Published public var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: .languageChanged, object: currentLanguage)
        }
    }
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            self.currentLanguage = savedLanguage
            UserDefaults.standard.set([savedLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        } else {
            self.currentLanguage = Locale.preferredLanguages.first ?? "en"
        }
    }
    
    public func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
    }
    
    public func getBundle(for bundleClass: AnyClass) -> Bundle {
        let mainBundle = Bundle(for: bundleClass)
        guard let path = mainBundle.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return mainBundle
        }
        return bundle
    }
    
    public static var availableLanguages: [(code: String, name: String)] {
        return [
            ("en", "English"),
            ("bo", "བོད་སྐད་"),
            ("ar", "العربية"),
            ("fa", "فارسی"),
            ("uk", "Українська"),
            ("zh-HK", "繁體中文"),
            ("vi", "Tiếng Việt"),
            ("lv", "Latviešu"),
            ("uz", "Oʻzbekcha")
        ]
    }
}

public extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
