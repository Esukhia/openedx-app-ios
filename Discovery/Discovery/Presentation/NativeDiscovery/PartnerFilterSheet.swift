//
//  PartnerFilterSheet.swift
//  Discovery
//
//  Created by Cascade on 31.07.2025.
//

import SwiftUI
import Kingfisher
import Core
import Theme

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

public struct PartnerFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let partners: [Partner]
    let onPartnerSelected: (Partner?) -> Void
    @State private var selectedPartner: Partner?
    
    public init(partners: [Partner], selectedPartner: Partner? = nil, onPartnerSelected: @escaping (Partner?) -> Void) {
        self.partners = partners
        self._selectedPartner = State(initialValue: selectedPartner)
        self.onPartnerSelected = onPartnerSelected
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top spacing for visual separation
                Spacer(minLength: 8)
                // Header
                Text("Schools and Partners")
                    .font(Theme.Fonts.titleMedium)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // All option (hidden but functional for selection logic)
                        EmptyView()
                            .frame(width: 0, height: 0)
                            .onAppear {
                                // If no partner is selected initially, ensure it stays that way
                                if selectedPartner == nil {
                                    selectedPartner = nil
                                }
                            }
                        
                        // Partner options
                        ForEach(partners) { partner in
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.Colors.cardViewBackground)
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    selectedPartner?.id == partner.id ?
                                                    Color(hex: "FC8044") : Theme.Colors.cardViewStroke,
                                                    lineWidth: selectedPartner?.id == partner.id ? 3 : 1
                                                )
                                        )
                                    
                                    KFImage(URL(string: partner.logo))
                                        .onFailureImage(CoreAssets.noCourseImage.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                }
                                .scaleEffect(selectedPartner?.id == partner.id ? 1.0 : 0.95)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedPartner = partner
                                    }
                                }
                                
                                Text(partner.partnerName)
                                    .font(Theme.Fonts.labelMedium)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(partner.partnerName)
                            .accessibilityAddTraits(selectedPartner?.id == partner.id ? .isSelected : [])
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                Spacer(minLength: 20)
                
                // Apply Button
                HStack {
                    Spacer()
                    Button(action: {
                        onPartnerSelected(selectedPartner)
                        dismiss()
                    }) {
                        Text("Apply")
                            .font(Theme.Fonts.labelLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 250)
                            .frame(height: 48)
                            .background(Color(hex: "FC8044"))
                            .cornerRadius(24)
                            .shadow(color: Color(hex: "FC8044").opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(Theme.Colors.background)
            .cornerRadius(15)
        }
        .navigationBarHidden(true)
    }
}

#if DEBUG
struct PartnerFilterSheet_Previews: PreviewProvider {
    static var previews: some View {
        let mockPartners = [
            Partner(
                partnerName: "BDRC",
                logo: "https://staging.sherab.org/media/partner/BDRC_Logo.png",
                organization: "BDRC"
            ),
            Partner(
                partnerName: "Kumarajiva",
                logo: "https://staging.sherab.org/media/partner/Kumarajiva_logo.png",
                organization: "Kumarajiva"
            ),
            Partner(
                partnerName: "Sherab",
                logo: "https://staging.sherab.org/media/partner/sherab.jpeg",
                organization: "Sherab"
            ),
            Partner(
                partnerName: "Esukhia",
                logo: "https://staging.sherab.org/media/partner/Esukhia_logo.png",
                organization: "Esukhia"
            ),
            Partner(
                partnerName: "Sarah College",
                logo: "https://staging.sherab.org/media/partner/Sarah_college_logo.png",
                organization: "Sarah"
            )
        ]
        
        PartnerFilterSheet(partners: mockPartners) { _ in }
            .preferredColorScheme(.light)
            .previewDisplayName("PartnerFilterSheet Light")
        
        PartnerFilterSheet(partners: mockPartners) { _ in }
            .preferredColorScheme(.dark)
            .previewDisplayName("PartnerFilterSheet Dark")
    }
}
#endif
