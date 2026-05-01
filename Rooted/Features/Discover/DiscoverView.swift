import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var session: AppSession
    @State private var searchText = ""
    @State private var selectedFilters: Set<String> = []
    @State private var bannerText: String?
    @State private var isShowingCreateCommunity = false

    private let smartFilters = [
        "French",
        "Boston",
        "Students",
        "Women-only",
        "Career",
        "New in town"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if let bannerText {
                            GlassCard {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.crop.circle.badge.checkmark")
                                        .foregroundStyle(AppTheme.Colors.success)
                                    Text(bannerText)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.Colors.primaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        searchBar

                        SectionHeader(title: "Discover", subtitle: "People, groups, and spaces that match your background")

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Smart filters")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                SelectableChipsGrid(
                                    tags: smartFilters,
                                    selectedTags: Array(selectedFilters),
                                    onToggle: toggleFilter
                                )
                            }
                        }

                        SectionHeader(title: "People", subtitle: "Look up people, add friends, and build your community")

                        if filteredPeople.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("No people found")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.Colors.primaryText)

                                    Text("Try searching by full name, city, or country, or clear your smart filters.")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.Colors.secondaryText)
                                }
                            }
                        } else {
                            ForEach(filteredPeople) { person in
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        NavigationLink {
                                            PublicPersonProfileView(person: person)
                                                .environmentObject(session)
                                        } label: {
                                            HStack(spacing: 14) {
                                                PersonAvatarView(
                                                    name: person.fullName,
                                                    profileImageDataBase64: person.profileImageDataBase64,
                                                    size: 56
                                                )

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(person.fullName)
                                                        .font(.headline.weight(.bold))
                                                        .foregroundStyle(AppTheme.Colors.primaryText)

                                                    Text("\(person.role) • \(person.currentCity)")
                                                        .font(.subheadline)
                                                        .foregroundStyle(AppTheme.Colors.secondaryText)

                                                    Text(person.homeCountry)
                                                        .font(.caption.weight(.semibold))
                                                        .foregroundStyle(AppTheme.Colors.highlight)
                                                }

                                                Spacer()
                                            }
                                        }
                                        .buttonStyle(.plain)

                                        FlexibleChipsView(tags: person.languages + Array(person.interests.prefix(2)))

                                        actionButtons(for: person)
                                    }
                                }
                            }
                        }

                        if !filteredEvents.isEmpty {
                            SectionHeader(title: "Matching events", subtitle: "Search by event name or narrow by smart filters")

                            ForEach(filteredEvents) { event in
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(event.title)
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(AppTheme.Colors.primaryText)

                                        Text("\(event.dateText) • \(event.place)")
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.Colors.secondaryText)

                                        FlexibleChipsView(tags: event.tags)
                                    }
                                }
                            }
                        }

                        SectionHeader(title: "Trending communities", subtitle: "Growing fast in your city")

                        Button {
                            isShowingCreateCommunity = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                Text("Create a community")
                            }
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }

                        ForEach(filteredCommunities) { community in
                            NavigationLink {
                                CommunityDetailView(community: community)
                                    .environmentObject(session)
                            } label: {
                                GlassCard {
                                    HStack(alignment: .top, spacing: 14) {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [AppTheme.Colors.accentSoft, AppTheme.Colors.highlight.opacity(0.7)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 52, height: 52)
                                            .overlay {
                                                Image(systemName: "person.3.fill")
                                                    .foregroundStyle(.white)
                                            }

                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(community.name)
                                                .font(.headline.weight(.bold))
                                                .foregroundStyle(AppTheme.Colors.primaryText)

                                            Text("Popular with newcomers and students in \(community.city).")
                                                .font(.subheadline)
                                                .foregroundStyle(AppTheme.Colors.secondaryText)

                                            FlexibleChipsView(tags: community.tags)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await session.reloadContent()
            }
            .onAppear {
                Task {
                    await session.reloadContent()
                }
            }
            .refreshable {
                await session.reloadContent()
            }
            .sheet(isPresented: $isShowingCreateCommunity) {
                CreateCommunityView { name in
                    bannerText = "Created \(name)."
                }
                .environmentObject(session)
            }
        }
    }

    private var filteredCommunities: [Community] {
        session.communities.filter { community in
            matchesSearch(
                searchText,
                values: [community.name, community.city] + community.tags
            ) && matchesFilters(community.tags + [community.city], isEvent: false)
        }
    }

    private var filteredPeople: [Person] {
        session.people.filter { person in
            matchesSearch(
                searchText,
                values: [person.fullName, person.homeCountry, person.currentCity, person.role] + person.languages + person.interests
            ) && matchesFilters(person.languages + person.interests + [person.currentCity, person.role], isEvent: false)
        }
    }

    private var filteredEvents: [EventItem] {
        session.events.filter { event in
            matchesSearch(
                searchText,
                values: [event.title, event.host, event.place] + event.tags
            ) && matchesFilters(event.tags + [event.place], isEvent: true)
        }
    }

    private func matchesSearch(_ query: String, values: [String]) -> Bool {
        guard !query.isEmpty else { return true }
        let haystack = values.joined(separator: " ")
        return haystack.localizedCaseInsensitiveContains(query)
    }

    private func matchesFilters(_ values: [String], isEvent: Bool) -> Bool {
        guard !selectedFilters.isEmpty else { return true }

        let normalizedValues = values.map { $0.lowercased() }

        return selectedFilters.allSatisfy { filter in
            switch filter {
            case "Students":
                return normalizedValues.contains { $0.contains("student") }
            case "Women-only":
                return normalizedValues.contains { $0.contains("women") || $0.contains("safe") }
            case "Career":
                return normalizedValues.contains { $0.contains("career") || $0.contains("network") }
            case "New in town":
                return normalizedValues.contains { $0.contains("new") || $0.contains("newcomer") }
            case "Boston":
                return normalizedValues.contains { $0.contains("boston") }
            case "French":
                return normalizedValues.contains { $0.contains("french") || $0.contains("francophone") }
            default:
                return true
            }
        }
    }

    private func toggleFilter(_ filter: String) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.Colors.secondaryText)

            TextField("Search people, communities, or events", text: $searchText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func actionButtons(for person: Person) -> some View {
        if session.isFriend(person) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Added")
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(AppTheme.Colors.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else if session.hasIncomingRequest(from: person) {
            HStack(spacing: 12) {
                Button {
                    if let request = session.incomingFriendRequests.first(where: { $0.from.id == person.id }) {
                        Task {
                            await session.respondToFriendRequest(request, accept: true)
                            bannerText = "You and \(person.fullName) are now friends."
                        }
                    }
                } label: {
                    Text("Accept")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.Colors.success)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button {
                    if let request = session.incomingFriendRequests.first(where: { $0.from.id == person.id }) {
                        Task {
                            await session.respondToFriendRequest(request, accept: false)
                            bannerText = "Declined \(person.fullName)'s request."
                        }
                    }
                } label: {
                    Text("Decline")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        } else if session.hasSentRequest(to: person) {
            Button {
                Task {
                    await session.cancelFriendRequest(to: person)
                    bannerText = "Cancelled your friend request to \(person.fullName)."
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Cancel Request")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.Colors.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        } else {
            Button {
                Task {
                    await session.sendFriendRequest(to: person)
                    bannerText = session.hasSentRequest(to: person)
                        ? "Sent a friend request to \(person.fullName)."
                        : bannerText
                }
            } label: {
                Text("Add Friend")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.Colors.highlight)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

struct CreateCommunityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSession

    @State private var name = ""
    @State private var city = ""
    @State private var tagsText = ""
    @State private var description = ""

    let onCreated: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Community") {
                    TextField("Community name", text: $name)
                    TextField("City", text: $city)
                }

                Section("Tags") {
                    TextField("French, Students, Networking", text: $tagsText)
                    Text("Separate tags with commas.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                }

                Section {
                    Button("Create Community") {
                        Task {
                            await session.createCommunity(
                                name: name,
                                city: city,
                                tagsText: tagsText,
                                description: description
                            )
                            onCreated(name)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Create Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                city = session.profile?.currentCity ?? ""
            }
        }
    }
}
