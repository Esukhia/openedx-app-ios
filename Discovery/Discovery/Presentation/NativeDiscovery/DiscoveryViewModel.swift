//
//  DiscoveryViewModel.swift
//  Discovery
//
//  Created by  Stepanok Ivan on 16.09.2022.
//

import Combine
import Core
import SwiftUI

@MainActor
public final class DiscoveryViewModel: ObservableObject {
    
    var nextPage = 1
    var totalPages = 1
    private(set) var fetchInProgress = false
    private var cancellables = Set<AnyCancellable>()
    private var updateShowedOnce: Bool = false
    
    @Published var courses: [CourseItem] = []
    @Published var partners: [Partner] = []
    @Published var selectedPartner: Partner?
    @Published var showError: Bool = false
    @Published var showPartnerFilter: Bool = false
    @Published var totalCourseCount: Int = 0
    
    var userloggedIn: Bool {
        return !(storage.user?.username?.isEmpty ?? true)
    }
    
    var errorMessage: String? {
        didSet {
            withAnimation {
                showError = errorMessage != nil
            }
        }
    }
    
    let router: DiscoveryRouter
    let config: ConfigProtocol
    let connectivity: ConnectivityProtocol
    private let interactor: DiscoveryInteractorProtocol
    private let analytics: DiscoveryAnalytics
    let storage: CoreStorage
    
    public init(
        router: DiscoveryRouter,
        config: ConfigProtocol,
        interactor: DiscoveryInteractorProtocol,
        connectivity: ConnectivityProtocol,
        analytics: DiscoveryAnalytics,
        storage: CoreStorage
    ) {
        self.router = router
        self.config = config
        self.interactor = interactor
        self.connectivity = connectivity
        self.analytics = analytics
        self.storage = storage
    }
    
    @MainActor
    public func getDiscoveryCourses(index: Int) async {
        if !fetchInProgress {
            if totalPages > 1 {
                if index == courses.count - 3 {
                    if totalPages != 1 {
                        if nextPage <= totalPages {
                            await discovery(page: self.nextPage)
                        }
                    }
                }
            }
        }
    }
    
    func setupNotifications() {
        NotificationCenter.default.publisher(for: .onActualVersionReceived)
            .sink { [weak self] notification in
                if let latestVersion = notification.object as? String {
                    if let info = Bundle.main.infoDictionary {
                        guard let currentVersion = info["CFBundleShortVersionString"] as? String,
                                let self else { return }
                        switch self.compareVersions(currentVersion, latestVersion) {
                        case .orderedAscending:
                            if self.updateShowedOnce == false {
                                DispatchQueue.main.async {
                                    self.router.showUpdateRecomendedView()
                                }
                                self.updateShowedOnce = true
                            }
                        default:
                            return
                        }
                    }
                }
            }.store(in: &cancellables)
    }
    
    @MainActor
    func discovery(page: Int, withProgress: Bool = true) async {
        fetchInProgress = withProgress
        do {
            if connectivity.isInternetAvaliable {
                if page == 1 {
                    // First page load - reset pagination state
                    if let selectedPartner = selectedPartner {
                        courses = try await interactor.discoveryByOrg(
                            page: page,
                            organization: selectedPartner.organization
                        )
                    } else {
                        courses = try await interactor.discovery(page: page)
                    }
                    self.totalPages = 1
                    self.nextPage = 1
                } else {
                    // Only attempt to fetch next page if we're within valid page range
                    if page <= totalPages {
                        do {
                            let newCourses: [CourseItem]
                            if let selectedPartner = selectedPartner {
                                newCourses = try await interactor.discoveryByOrg(
                                    page: page,
                                    organization: selectedPartner.organization
                                )
                                courses += newCourses
                            } else {
                                newCourses = try await interactor.discovery(page: page)
                                courses += newCourses
                            }
                        } catch let pageError {
                            // Handle invalid page error by checking error description
                            // This is a more general approach that doesn't rely on specific error types
                            let errorString = String(describing: pageError)
                            if errorString.contains("Invalid page") {
                                // We've reached the end of available pages
                                totalPages = page - 1
                                // Don't show error for invalid page - just stop pagination
                            } else {
                                // Re-throw other errors to be caught by outer catch block
                                throw pageError
                            }
                        }
                    }
                }
                
                // Only increment nextPage if we're not at the end
                if nextPage <= totalPages {
                    self.nextPage += 1
                }
                
                if !courses.isEmpty {
                    // Update totalPages from API response
                    totalPages = courses[0].numPages
                    
                    // Calculate total course count based on pagination info
                    if let selectedPartner = selectedPartner {
                        // For filtered courses, use the coursesCount property
                        totalCourseCount = courses[0].coursesCount
                    } else {
                        // For all courses, use the coursesCount property too
                        totalCourseCount = courses[0].coursesCount
                    }
                }
                
                fetchInProgress = false
            } else {
                courses = try await interactor.discoveryOffline()
                self.nextPage += 1
                fetchInProgress = false
            }
        } catch let error {
            fetchInProgress = false
            
            // Check for "Invalid page" error in the error description
            let errorString = String(describing: error)
            if errorString.contains("Invalid page") {
                // Don't show error for invalid page - just stop pagination
                if page > 1 {
                    totalPages = page - 1
                }
            } else if error.isInternetError || error is NoCachedDataError {
                errorMessage = CoreLocalization.Error.slowOrNoInternetConnection
            } else if error.isUpdateRequeiredError {
                self.router.showUpdateRequiredView(showAccountLink: true)
            } else {
                errorMessage = CoreLocalization.Error.unknownError
            }
        }
    }
    
    func discoveryCourseClicked(courseID: String, courseName: String) {
        analytics.discoveryCourseClicked(courseID: courseID, courseName: courseName)
    }
    
    func discoverySearchBarClicked() {
        analytics.discoverySearchBarClicked()
    }
    
    @MainActor
    func loadPartners() async {
        do {
            if connectivity.isInternetAvaliable {
                partners = try await interactor.getPartners()
            }
        } catch let error {
            if error.isInternetError {
                errorMessage = CoreLocalization.Error.slowOrNoInternetConnection
            } else {
                errorMessage = CoreLocalization.Error.unknownError
            }
        }
    }
    
    func showPartnerFilterSheet() {
        showPartnerFilter = true
    }
    
    func selectPartner(_ partner: Partner?) {
        selectedPartner = partner
        // Reset pagination and reload courses
        totalPages = 1
        nextPage = 1
        Task {
            await discovery(page: 1, withProgress: true)
        }
    }
    
    func clearPartnerFilter() {
        selectedPartner = nil
        // Reset pagination and reload all courses
        totalPages = 1
        nextPage = 1
        Task {
            await discovery(page: 1, withProgress: true)
        }
    }
    
    private func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let components1 = version1.components(separatedBy: ".").prefix(2)
        let components2 = version2.components(separatedBy: ".").prefix(2)
        
        guard let major1 = Int(components1.first ?? ""),
              let minor1 = Int(components1.last ?? ""),
              let major2 = Int(components2.first ?? ""),
              let minor2 = Int(components2.last ?? "") else {
            return .orderedSame
        }
        
        if major1 < major2 {
            return .orderedAscending
        } else if major1 > major2 {
            return .orderedDescending
        } else {
            if minor1 < minor2 {
                return .orderedAscending
            } else if minor1 > minor2 {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
    }
}
