import SwiftUI
import Core
import Theme

public struct LockedContentView: View {
    let gatedContent: GatedContent
    let courseID: String
    let chapters: [CourseChapter]
    let router: CourseRouter
    
    public init(
        gatedContent: GatedContent,
        courseID: String,
        chapters: [CourseChapter],
        router: CourseRouter
    ) {
        self.gatedContent = gatedContent
        self.courseID = courseID
        self.chapters = chapters
        self.router = router
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Lock icon
            Image(systemName: "lock.fill")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(.bottom, 40)
            
            // Title
            Text(CourseLocalization.LockedContent.title)
                .font(Theme.Fonts.titleLarge)
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
            
            // Description
            Text(CourseLocalization.LockedContent.description(
                gatedContent.prereqSectionName ?? "the prerequisite section"
            ))
                .font(Theme.Fonts.bodyLarge)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            
            // Go to prerequisite button
            StyledButton(
                CourseLocalization.LockedContent.goToPrerequisite,
                action: {
                    navigateToPrerequisite()
                }
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
        .navigationTitle(
            gatedContent.gatedSectionName ??
            gatedContent.prereqSectionName ??
            CourseLocalization.LockedContent.title
        )
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func navigateToPrerequisite() {
        guard let prereqId = gatedContent.prereqId else {
            openInBrowser()
            return
        }
        
        // Find the prerequisite sequential in chapters
        for (chapterIndex, chapter) in chapters.enumerated() {
            for (sequentialIndex, sequential) in chapter.childs.enumerated()
            where sequential.id == prereqId {
                // Found the prerequisite, navigate to subsection view
                router.showCourseVerticalView(
                    courseID: courseID,
                    courseName: "",
                    title: sequential.displayName,
                    chapters: chapters,
                    chapterIndex: chapterIndex,
                    sequentialIndex: sequentialIndex
                )
                return
            }
        }
        
        // Fallback: if prerequisite not found, open in browser
        openInBrowser()
    }
    
    private func openInBrowser() {
        guard let prereqUrl = gatedContent.prereqUrl,
              let url = URL(string: prereqUrl),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url, options: [:])
    }
}

#if DEBUG
struct LockedContentView_Previews: PreviewProvider {
    static var previews: some View {
        let gatedContent = GatedContent(
            prereqId: "block-v1:Sherab+CS004+2025+type@sequential+block@47abcc977afb482c8e13bd37123a72a3",
            prereqSectionName: "Subsection-1",
            gated: true,
            gatedSectionName: "Subsection-2 (locked)",
            prereqUrl: "/courses/course-v1:Sherab+CS004+2025/jump_to/" +
                "block-v1:Sherab+CS004+2025+type@sequential+block@47abcc977afb482c8e13bd37123a72a3"
        )
        
        return Group {
            LockedContentView(
                gatedContent: gatedContent,
                courseID: "course-v1:Sherab+CS004+2025",
                chapters: [],
                router: CourseRouterMock()
            )
            .preferredColorScheme(.light)
            .previewDisplayName("LockedContentView Light")
            
            LockedContentView(
                gatedContent: gatedContent,
                courseID: "course-v1:Sherab+CS004+2025",
                chapters: [],
                router: CourseRouterMock()
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("LockedContentView Dark")
        }
    }
}
#endif
