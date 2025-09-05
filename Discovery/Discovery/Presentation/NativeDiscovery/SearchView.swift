//
//  SearchView.swift
//  Discovery
//
//  Created by Paul Maul on 10.02.2023.
//

import SwiftUI
import Core
import OEXFoundation
import Theme
import UIKit
import Kingfisher

// Helper to detect Tibetan script and apply Noto Sans Tibetan font when needed
private func containsTibetan(_ text: String) -> Bool {
    return text.unicodeScalars.contains { scalar in
        return (0x0F00...0x0FFF).contains(Int(scalar.value))
    }
}

@ViewBuilder
private func tibetanAwareText(_ text: String, baseFont: Font, tibetanSize: CGFloat) -> some View {
    if containsTibetan(text) {
        if UIFont(name: "NotoSansTibetan-Regular", size: tibetanSize) != nil {
            Text(text).font(.custom("NotoSansTibetan-Regular", size: tibetanSize))
        } else {
            Text(text).font(baseFont)
        }
    } else {
        Text(text).font(baseFont)
    }
}

// TODO (Tibetan): Bundle "NotoSansTibetan-Regular.ttf" and add under UIAppFonts in Info.plist;
// then apply tibetanAwareText to Search headers/title, search placeholder/TextField display.
public struct SearchView: View {
    
    @FocusState
    private var focused: Bool
    
    @ObservedObject
    private var viewModel: SearchViewModel<RunLoop>
    @State private var animated: Bool = false
    
    public init(viewModel: SearchViewModel<RunLoop>, searchQuery: String? = nil) {
        self.viewModel = viewModel
        self.viewModel.searchText = searchQuery ?? ""
        self.viewModel.isSearchActive = !(searchQuery?.isEmpty ?? false)
    }

    // (Tibetan-aware helpers are at file scope to allow use within nested views.)

    // MARK: - Local course card (identical styling to DiscoveryView)
    private struct LocalCourseGridCardView: View {
        private let imageURL: String
        private let title: String
        private let org: String
        private let duration: String

        init(model: CourseItem) {
            self.imageURL = model.imageURL
            self.title = model.name
            self.org = model.org
            self.duration = (model.duration?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
                ? model.duration!.trimmingCharacters(in: .whitespacesAndNewlines)
                : "Duration not specified"
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Course banner image
                KFImage(URL(string: imageURL))
                    .onFailureImage(CoreAssets.noCourseImage.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 120, minHeight: 100, maxHeight: 120)
                    .clipped()
                    .accessibilityIdentifier("course_card_image")

                // Course title and meta (org, title, duration)
                VStack(alignment: .leading, spacing: 2) {
                    // Organization
                    if !org.isEmpty {
                        tibetanAwareText(org, baseFont: Theme.Fonts.labelMedium, tibetanSize: 14)
                            .foregroundColor(Theme.Colors.textSecondaryLight)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .accessibilityIdentifier("course_card_org")
                    }

                    // Course title
                    tibetanAwareText(title, baseFont: Theme.Fonts.titleSmall, tibetanSize: 24)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .accessibilityIdentifier("course_card_title")

                    // Push duration to bottom of the fixed container
                    Spacer(minLength: 0)

                    // Duration (fixed at bottom)
                    tibetanAwareText(duration, baseFont: Theme.Fonts.labelMedium, tibetanSize: 14)
                        .foregroundColor(Theme.Colors.textSecondaryLight)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .padding(.top, 2)
                        .padding(.bottom, 8)
                        .accessibilityIdentifier("course_card_duration")
                }
                .frame(height: 100, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .padding(.bottom, 2)
            }
            .background(Theme.Colors.courseCardBackground)
            .cornerRadius(8)
            .shadow(color: Theme.Colors.courseCardShadow, radius: 6, x: 2, y: 2)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("course_grid_card")
        }
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                
                // MARK: - Page name
                VStack(alignment: .center) {
                    NavigationBar(title: DiscoveryLocalization.search,
                                  leftButtonAction: {
                        viewModel.router.backWithFade()
                    }).padding(.bottom, -7)
                    
                    HStack(spacing: 11) {
                        Image(systemName: "magnifyingglass")
                            .padding(.leading, 16)
                            .padding(.top, 1)
                            .foregroundColor(Theme.Colors.accentColor)
                            .accessibilityHidden(true)
                            .accessibilityIdentifier("search_image")
                        
                        TextField(
                            !viewModel.isSearchActive
                            ? DiscoveryLocalization.search
                            : "",
                            text: $viewModel.searchText,
                            onEditingChanged: { editing in
                                viewModel.isSearchActive = editing
                            }
                        ).focused($focused)
                            .onAppear {
                                self.focused = true
                            }
                            .foregroundColor(Theme.Colors.textInputTextColor)
                            .font(Theme.Fonts.bodyLarge)
                            .accessibilityIdentifier("search_textfields")
                        Spacer()
                        if !viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button(action: { viewModel.searchText.removeAll() }, label: {
                                CoreAssets.clearInput.swiftUIImage
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 24)
                                    .padding(.horizontal)
                            })
                            .foregroundColor(Theme.Colors.styledButtonText)
                            .accessibilityIdentifier("search_button")
                        }
                    }
                    .frame(minHeight: 48)
                    .frame(maxWidth: .infinity)
                    .background(
                        Theme.Shapes.textInputShape
                            .fill(viewModel.isSearchActive
                                  ? Theme.Colors.textInputBackground
                                  : Theme.Colors.textInputUnfocusedBackground)
                    )
                    .overlay(
                        Theme.Shapes.textInputShape
                            .stroke(lineWidth: 1)
                            .fill(viewModel.isSearchActive
                                  ? Theme.Colors.accentColor
                                  : Theme.Colors.textInputUnfocusedStroke)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .frameLimit(width: proxy.size.width)
                    
                    ZStack {
                        ScrollView {
                            VStack(spacing: 0) {
                                // Header
                                HStack {
                                    searchHeader(viewModel: viewModel)
                                        .padding(.horizontal, 24)
                                        .padding(.bottom, 20)
                                        .offset(y: animated ? 0 : 50)
                                        .opacity(animated ? 1 : 0)
                                    Spacer()
                                }
                                .padding(.leading, 10)
                                .frameLimit(width: proxy.size.width)

                                // Grid
                                let isPad = UIDevice.current.userInterfaceIdiom == .pad
                                let columns = isPad ? [
                                    GridItem(.flexible(), spacing: 0),
                                    GridItem(.flexible(), spacing: 0),
                                    GridItem(.flexible(), spacing: 0)
                                ] : [
                                    GridItem(.flexible(), spacing: 0),
                                    GridItem(.flexible(), spacing: 0)
                                ]

                                LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                                    ForEach(viewModel.searchResults) { course in
                                        Button(
                                            action: {
                                                viewModel.router.showCourseDetais(
                                                    courseID: course.courseID,
                                                    title: course.name
                                                )
                                            },
                                            label: {
                                                LocalCourseGridCardView(model: course)
                                            }
                                        )
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(8)
                                        .onAppear {
                                            if let index = viewModel
                                                .searchResults
                                                .firstIndex(where: { $0.id == course.id }),
                                               index == viewModel.searchResults.count - 3 {
                                                Task {
                                                    await viewModel.searchCourses(
                                                        index: index,
                                                        searchTerm: viewModel.searchText
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(10)
                                .frameLimit(width: proxy.size.width)

                                // Progress indicator
                                if viewModel.fetchInProgress {
                                    VStack(alignment: .center) {
                                        ProgressBar(size: 40, lineWidth: 8)
                                            .padding(.top, 20)
                                    }
                                }

                                // Bottom spacer
                                Spacer(minLength: 40)
                            }
                        }
                    }
                }
                // MARK: - Error Alert
                if viewModel.showError {
                    VStack {
                        Spacer()
                        SnackBarView(message: viewModel.errorMessage)
                    }
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                            viewModel.errorMessage = nil
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        animated = true
                    }
                }
            }
            
            .onDisappear {
                viewModel.searchText = ""
            }
            .avoidKeyboard(dismissKeyboardByTap: true)
            .background(Theme.Colors.background.ignoresSafeArea())
        }
    }
    
    private func searchHeader(viewModel: SearchViewModel<RunLoop>) -> some View {
        return VStack(alignment: .leading) {
            Text(DiscoveryLocalization.Search.title)
                .font(Theme.Fonts.displaySmall)
                .foregroundColor(Theme.Colors.textPrimary)
                .accessibilityIdentifier("title_text")
            Text(searchDescription(viewModel: viewModel))
                .font(Theme.Fonts.titleSmall)
                .foregroundColor(Theme.Colors.textPrimary)
                .accessibilityIdentifier("description_text")
        }.listRowBackground(Color.clear)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(DiscoveryLocalization.Search.title + searchDescription(viewModel: viewModel))
    }
    
    private func searchDescription(viewModel: SearchViewModel<RunLoop>) -> String {
        let searchEmptyDescription = DiscoveryLocalization.Search.emptyDescription
        let searchDescription =  DiscoveryLocalization.searchResultsDescription(
            viewModel.searchResults.isEmpty
            ? 0
            : viewModel.searchResults[0].coursesCount
        )
        let searchFieldEmpty = viewModel.searchText
            .trimmingCharacters(in: .whitespaces)
            .isEmpty
        if searchFieldEmpty {
            return searchEmptyDescription
        } else {
            return searchDescription
        }
    }
}

#if DEBUG
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        let router = DiscoveryRouterMock()
        let vm = SearchViewModel(
            interactor: DiscoveryInteractor.mock,
            connectivity: Connectivity(),
            router: router,
            analytics: DiscoveryAnalyticsMock(),
            storage: CoreStorageMock(),
            debounce: .searchDebounce
        )
        
        SearchView(viewModel: vm)
            .preferredColorScheme(.light)
            .previewDisplayName("SearchView Light")
        
        SearchView(viewModel: vm)
            .preferredColorScheme(.dark)
            .previewDisplayName("SearchView Dark")
    }
}
#endif
