import PhotosUI
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: AppSession
    @State private var isShowingEditProfile = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        profileHero

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                Text(aboutText)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.Colors.secondaryText)

                                FlexibleChipsView(tags: profileTags)
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your spaces")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                NavigationLink {
                                    FriendsListView()
                                        .environmentObject(session)
                                } label: {
                                    profileRow(icon: "person.crop.circle.badge.checkmark", title: "Friends", value: "\(session.friends.count)")
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    JoinedCommunitiesView()
                                        .environmentObject(session)
                                } label: {
                                    profileRow(icon: "person.3.fill", title: "Joined communities", value: "\(session.joinedCommunities.count)")
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    SavedEventsView()
                                        .environmentObject(session)
                                } label: {
                                    profileRow(icon: "calendar", title: "Saved events", value: "\(session.savedEvents.count)")
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Friend requests")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.Colors.primaryText)

                                    Spacer()

                                    if isRefreshing {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Button("Refresh") {
                                            Task { await refreshProfileData() }
                                        }
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.Colors.highlight)
                                    }
                                }

                                if session.incomingFriendRequests.isEmpty {
                                    Text("No incoming friend requests right now.")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.Colors.secondaryText)
                                } else {
                                    ForEach(session.incomingFriendRequests) { request in
                                        VStack(alignment: .leading, spacing: 10) {
                                            NavigationLink {
                                                PublicPersonProfileView(person: request.from)
                                                    .environmentObject(session)
                                            } label: {
                                                HStack(spacing: 12) {
                                                    PersonAvatarView(
                                                        name: request.from.fullName,
                                                        profileImageDataBase64: request.from.profileImageDataBase64,
                                                        size: 40
                                                    )

                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(request.from.fullName)
                                                            .font(.subheadline.weight(.bold))
                                                            .foregroundStyle(AppTheme.Colors.primaryText)

                                                        Text(locationText(for: request.from))
                                                            .font(.caption)
                                                            .foregroundStyle(AppTheme.Colors.secondaryText)
                                                    }

                                                    Spacer()
                                                }
                                            }
                                            .buttonStyle(.plain)

                                            HStack(spacing: 10) {
                                                Button {
                                                    Task {
                                                        await session.respondToFriendRequest(request, accept: true)
                                                    }
                                                } label: {
                                                    Text("Accept")
                                                        .font(.caption.weight(.bold))
                                                        .foregroundStyle(.white)
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.vertical, 10)
                                                        .background(AppTheme.Colors.success)
                                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                                }

                                                Button {
                                                    Task {
                                                        await session.respondToFriendRequest(request, accept: false)
                                                    }
                                                } label: {
                                                    Text("Decline")
                                                        .font(.caption.weight(.bold))
                                                        .foregroundStyle(AppTheme.Colors.primaryText)
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.vertical, 10)
                                                        .background(Color.white.opacity(0.78))
                                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if !session.friends.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Friends")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.Colors.primaryText)

                                    ForEach(session.friends.prefix(4)) { friend in
                                        HStack(spacing: 12) {
                                            NavigationLink {
                                                PublicPersonProfileView(person: friend)
                                                    .environmentObject(session)
                                            } label: {
                                                HStack(spacing: 12) {
                                                    PersonAvatarView(
                                                        name: friend.fullName,
                                                        profileImageDataBase64: friend.profileImageDataBase64,
                                                        size: 40
                                                    )

                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(friend.fullName)
                                                            .font(.subheadline.weight(.bold))
                                                            .foregroundStyle(AppTheme.Colors.primaryText)

                                                        Text("\(friend.homeCountry) • \(friend.currentCity)")
                                                            .font(.caption)
                                                            .foregroundStyle(AppTheme.Colors.secondaryText)
                                                    }
                                                }
                                            }
                                            .buttonStyle(.plain)

                                            Spacer()

                                            Button("Remove") {
                                                Task {
                                                    await session.removeFriend(friend)
                                                }
                                            }
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(AppTheme.Colors.highlight)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingEditProfile) {
                EditProfileView()
                    .environmentObject(session)
            }
            .task {
                await refreshProfileData()
            }
            .onAppear {
                Task {
                    await refreshProfileData()
                }
            }
        }
    }

    private var profileHero: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        avatarView
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.profile?.fullName ?? "Awa Konan")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.Colors.primaryText)

                        Text("\(session.profile?.currentCity ?? "Boston"), USA")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.Colors.secondaryText)

                        HStack(spacing: 8) {
                            Text("Verified \(session.profile?.role.lowercased() ?? "member")")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.Colors.success)

                            if session.profile?.isDiscoverable ?? true {
                                Text("Visible in Discover")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.Colors.highlight)
                            } else {
                                Text("Hidden from Discover")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.Colors.secondaryText)
                            }
                        }

                        Text("Tap photo to change")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                }

                Button {
                    isShowingEditProfile = true
                } label: {
                    Text("Edit Profile")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        session.saveProfileImage(data)
                    }
                }
            }
        }
    }

    private func profileRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.highlight)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Spacer()

            Text(value)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }

    private var aboutText: String {
        guard let profile = session.profile else {
            return "International student abroad looking for community, cultural events, and people who understand home."
        }

        if !profile.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return profile.bio
        }

        let interests = profile.interests.isEmpty ? "community and events" : profile.interests.joined(separator: ", ").lowercased()
        return "\(profile.role) in \(profile.currentCity) looking for \(interests)."
    }

    private var profileTags: [String] {
        guard let profile = session.profile else {
            return ["French", "Cote d'Ivoire", "Boston", "Student", "Networking"]
        }

        return profile.languages + [profile.homeCountry, profile.currentCity, profile.role]
    }

    private var avatarView: some View {
        PersonAvatarView(
            name: session.profile?.fullName ?? "Awa Konan",
            profileImageDataBase64: session.profile?.profileImageDataBase64,
            size: 76
        )
    }

    private func locationText(for person: Person) -> String {
        let parts = [person.homeCountry, person.currentCity].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return parts.isEmpty ? "Rooted member" : parts.joined(separator: " • ")
    }

    private func refreshProfileData() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        await session.reloadContent()
        isRefreshing = false
    }
}

struct FriendsListView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        contentView(
            title: "Friends",
            emptyText: "You haven't added any friends yet."
        ) {
            ForEach(session.friends) { friend in
                HStack(spacing: 12) {
                    NavigationLink {
                        PublicPersonProfileView(person: friend)
                            .environmentObject(session)
                    } label: {
                        HStack(spacing: 12) {
                            PersonAvatarView(
                                name: friend.fullName,
                                profileImageDataBase64: friend.profileImageDataBase64,
                                size: 44
                            )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(friend.fullName)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.Colors.primaryText)
                                Text("\(friend.homeCountry) • \(friend.currentCity)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.Colors.secondaryText)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button("Remove") {
                        Task {
                            await session.removeFriend(friend)
                        }
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.highlight)
                }
            }
        }
    }
}

struct JoinedCommunitiesView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        contentView(
            title: "Joined Communities",
            emptyText: "You haven't joined any communities yet."
        ) {
            ForEach(session.joinedCommunities) { community in
                NavigationLink {
                    CommunityDetailView(community: community)
                        .environmentObject(session)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(community.name)
                            .font(.headline)
                            .foregroundStyle(AppTheme.Colors.primaryText)
                        Text("\(community.members) members • \(community.city)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SavedEventsView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        contentView(
            title: "Saved Events",
            emptyText: "You haven't saved any events yet."
        ) {
            ForEach(session.savedEvents) { event in
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                    Text("\(event.dateText) • \(event.place)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            }
        }
    }
}

private func contentView<Content: View>(
    title: String,
    emptyText: String,
    @ViewBuilder content: () -> Content
) -> some View {
    ZStack {
        AppTheme.screenGradient
            .ignoresSafeArea()

        ScrollView(showsIndicators: false) {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.primaryText)

                    content()
                }
            }
            .padding(20)
        }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
}


struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSession

    @State private var fullName = ""
    @State private var bioText = ""
    @State private var homeCountry = ""
    @State private var currentCity = ""
    @State private var languagesText = ""
    @State private var isDiscoverable = true
    @State private var showHomeCountry = true
    @State private var showCurrentCity = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Full name", text: $fullName)
                    TextField("Home country", text: $homeCountry)
                    TextField("Current city", text: $currentCity)
                }

                Section("About") {
                    TextEditor(text: $bioText)
                        .frame(minHeight: 120)
                    Text("Write a short bio for your public profile.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Languages") {
                    TextField("French, English, Arabic", text: $languagesText)
                    Text("Separate languages with commas.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Privacy") {
                    Toggle("Show my profile in Discover", isOn: $isDiscoverable)
                    Toggle("Show my home country", isOn: $showHomeCountry)
                    Toggle("Show my current city", isOn: $showCurrentCity)
                }

                Section {
                    Button("Save Changes") {
                        Task {
                            await session.updateProfile(
                                fullName: fullName,
                                bioText: bioText,
                                homeCountry: homeCountry,
                                currentCity: currentCity,
                                languagesText: languagesText,
                                isDiscoverable: isDiscoverable,
                                showHomeCountry: showHomeCountry,
                                showCurrentCity: showCurrentCity
                            )
                            dismiss()
                        }
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        session.signOut()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                fullName = session.profile?.fullName ?? ""
                bioText = session.profile?.bio ?? ""
                homeCountry = session.profile?.homeCountry ?? ""
                currentCity = session.profile?.currentCity ?? ""
                languagesText = session.profile?.languages.joined(separator: ", ") ?? ""
                isDiscoverable = session.profile?.isDiscoverable ?? true
                showHomeCountry = session.profile?.showHomeCountry ?? true
                showCurrentCity = session.profile?.showCurrentCity ?? true
            }
        }
    }
}
