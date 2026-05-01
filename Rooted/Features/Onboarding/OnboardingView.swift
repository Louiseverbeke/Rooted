import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var session: AppSession

    @State private var homeCountry = "Cote d'Ivoire"
    @State private var currentCity = "Boston"
    @State private var role = "Student"
    @State private var selectedInterests = [
        "Make friends",
        "Find my community",
        "Women-only spaces"
    ]

    private let roles = ["Student", "Professional", "Both"]
    private let availableVibes = [
        "Make friends",
        "Find my community",
        "Women-only spaces",
        "Career networking",
        "Food from home",
        "Faith groups"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        heroSection

                        GlassCard {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Tell us about your move")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                Group {
                                    inputField(title: "Home Country", text: $homeCountry)
                                    inputField(title: "Current City", text: $currentCity)

                                    Picker("Role", selection: $role) {
                                        ForEach(roles, id: \.self) { item in
                                            Text(item)
                                        }
                                    }
                                    .tint(AppTheme.Colors.highlight)
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Your vibe")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.Colors.secondaryText)

                                    SelectableChipsGrid(
                                        tags: availableVibes,
                                        selectedTags: selectedInterests,
                                        onToggle: toggleInterest
                                    )
                                }
                            }
                        }

                        Button {
                            Task {
                                await session.completeOnboarding(
                                    homeCountry: homeCountry,
                                    currentCity: currentCity,
                                    role: role,
                                    interests: selectedInterests
                                )
                            }
                        } label: {
                            Text("Enter Rooted")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [AppTheme.Colors.highlight, AppTheme.Colors.accent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: AppTheme.Colors.highlight.opacity(0.35), radius: 18, x: 0, y: 10)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.removeAll { $0 == interest }
        } else {
            selectedInterests.append(interest)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rooted")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("Find your people, wherever you land.")
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.Colors.secondaryText)

            HStack(spacing: 10) {
                TagChip(title: "Culture-first", icon: "globe")
                TagChip(title: "Events", icon: "calendar")
                TagChip(title: "Community", icon: "person.3.fill")
            }
        }
        .padding(.top, 24)
    }

    private func inputField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.secondaryText)

            TextField(title, text: text)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

struct FlexibleChipsView: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(tags, id: \.self) { tag in
                TagChip(title: tag)
            }
        }
    }
}

struct SelectableChipsGrid: View {
    let tags: [String]
    let selectedTags: [String]
    let onToggle: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(tags, id: \.self) { tag in
                SelectableTagChip(title: tag, isSelected: selectedTags.contains(tag)) {
                    onToggle(tag)
                }
            }
        }
    }
}
