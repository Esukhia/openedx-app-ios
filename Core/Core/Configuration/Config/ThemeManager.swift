//
//  ThemeManager.swift
//  Core
//
//  Created for in-app theme switching
//

import Foundation
import SwiftUI

public enum ThemeMode: String, CaseIterable {
    case system
    case light
    case dark
    
    public var displayName: String {
        switch self {
        case .system:
            return "Use system theme"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}

@MainActor
public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @Published public var currentMode: ThemeMode {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: "AppThemeMode")
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: .themeChanged, object: currentMode)
        }
    }
    
    private init() {
        if let savedMode = UserDefaults.standard.string(forKey: "AppThemeMode"),
           let mode = ThemeMode(rawValue: savedMode) {
            self.currentMode = mode
        } else {
            self.currentMode = .system
        }
    }
    
    public func setMode(_ mode: ThemeMode) {
        currentMode = mode
    }
    
    public var resolvedColorScheme: ColorScheme? {
        switch currentMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    public var resolvedInterfaceStyle: UIUserInterfaceStyle {
        switch currentMode {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

public extension Notification.Name {
    static let themeChanged = Notification.Name("themeChanged")
}
