import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: AppSession
    @State private var bannerText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if let bannerText {
                            GlassCard {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.Colors.success)
                                    Text(bannerText)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.Colors.primaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        topBanner
                        statsSection
                        recommendedEvent
                        peopleSection
                        communitySection
                    }
                    .padding(20)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var topBanner: some View {
        let city = session.profile?.currentCity.nonEmpty ?? "your city"
        let topLanguage = preferredLanguages.first ?? "your language"
        let peopleCount = personalizedPeople.count
        let communityCount = joinedCommunitiesForHome.count
        let eventCount = upcomingRSVPEvents.count

        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your community is active in \(city)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.primaryText)

                Text("\(peopleCount) people who match \(topLanguage), \(communityCount) communities you’ve joined, and \(eventCount) upcoming events you’ve RSVP’d to.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondaryText)

                HStack(spacing: 10) {
                    TagChip(title: topLanguage, icon: "message.fill")
                    TagChip(title: city, icon: "mappin.and.ellipse")
                }
            }
        }
    }

    private var statsSection: some View {
        let stats = personalizedStats

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "At a glance", subtitle: "A quick read on your network this week")

            HStack(spacing: 12) {
                ForEach(stats) { stat in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(stat.value)
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.Colors.highlight)

                            Text(stat.label)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var recommendedEvent: some View {
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your upcoming events", subtitle: "Only future events you already RSVP’d to")

            if upcomingRSVPEvents.isEmpty {
                GlassCard {
                    Text("No upcoming RSVP’d events yet. RSVP to an event and it will appear here until it ends.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            } else {
                ForEach(upcomingRSVPEvents) { featuredEvent in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(featuredEvent.title)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.Colors.primaryText)

                                    Text("Hosted by \(featuredEvent.host)")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.Colors.secondaryText)
                                }

                                Spacer()

                                Image(systemName: "calendar.badge.checkmark")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.Colors.accent)
                            }

                            Text("\(featuredEvent.dateText) • \(featuredEvent.place)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.Colors.highlight)

                            FlexibleChipsView(tags: featuredEvent.tags)

                            Button {
                                Task {
                                    let wasGoing = session.isGoing(to: featuredEvent)
                                    await session.toggleRSVP(for: featuredEvent)
                                    bannerText = wasGoing ? "Removed RSVP for \(featuredEvent.title)." : "You're going to \(featuredEvent.title)."
                                }
                            } label: {
                                Text(session.isGoing(to: featuredEvent) ? "You're Going" : "RSVP Now")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(session.isGoing(to: featuredEvent) ? AppTheme.Colors.success : AppTheme.Colors.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                    }
                }
            }
        }
    }

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "People for you", subtitle: "Suggested from your language, city, and background")

            if session.people.isEmpty {
                GlassCard {
                    Text("No people yet. Once other users complete their profiles in Firebase, your matches will show up here.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            } else if personalizedPeople.isEmpty {
                GlassCard {
                    Text("No close matches yet. Try adding more languages or interests to improve recommendations.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            } else {
                ForEach(personalizedPeople.prefix(3)) { person in
                    GlassCard {
                        HStack(spacing: 14) {
                            PersonAvatarView(
                                name: person.fullName,
                                profileImageDataBase64: person.profileImageDataBase64,
                                size: 54
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(person.fullName)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                Text("\(person.role) • \(person.currentCity)")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.Colors.secondaryText)

                                Text(matchReason(for: person))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.Colors.highlight)
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var communitySection: some View {
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your communities", subtitle: "Only communities you’ve already joined")

            if joinedCommunitiesForHome.isEmpty {
                GlassCard {
                    Text("You haven’t joined any communities yet. Once you join one, it will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            } else {
                ForEach(joinedCommunitiesForHome) { community in
                    NavigationLink {
                        CommunityDetailView(community: community)
                            .environmentObject(session)
                    } label: {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(community.name)
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(AppTheme.Colors.primaryText)

                                        Text("\(memberCount(for: community)) members • \(community.city)")
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.Colors.secondaryText)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .foregroundStyle(AppTheme.Colors.highlight)
                                }

                                FlexibleChipsView(tags: community.tags)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var preferredLanguages: [String] {
        let languages = session.profile?.languages.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? []
        return languages.isEmpty ? ["English"] : languages
    }

    private var personalizedPeople: [Person] {
        session.people
            .sorted { score(for: $0) > score(for: $1) }
            .filter { score(for: $0) > 0 }
    }

    private var joinedCommunitiesForHome: [Community] {
        session.joinedCommunities
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var upcomingRSVPEvents: [EventItem] {
        session.events
            .filter { session.isGoing(to: $0) && $0.startAt >= .now }
            .sorted { $0.startAt < $1.startAt }
    }

    private var personalizedStats: [QuickStat] {
        [
            QuickStat(label: "People Like You", value: "\(personalizedPeople.count)"),
            QuickStat(label: "Joined Groups", value: "\(joinedCommunitiesForHome.count)"),
            QuickStat(label: "Upcoming RSVPs", value: "\(upcomingRSVPEvents.count)")
        ]
    }

    private func score(for person: Person) -> Int {
        guard let profile = session.profile else { return 0 }
        var score = 0

        if person.currentCity.caseInsensitiveCompare(profile.currentCity) == .orderedSame {
            score += 4
        }

        if person.homeCountry.caseInsensitiveCompare(profile.homeCountry) == .orderedSame {
            score += 4
        }

        let matchingLanguages = Set(person.languages.map { $0.lowercased() })
            .intersection(Set(preferredLanguages.map { $0.lowercased() }))
        score += matchingLanguages.count * 5

        let matchingInterests = Set(person.interests.map { $0.lowercased() })
            .intersection(Set(profile.interests.map { $0.lowercased() }))
        score += matchingInterests.count * 2

        if person.role.caseInsensitiveCompare(profile.role) == .orderedSame {
            score += 1
        }

        return score
    }

    private func matchReason(for person: Person) -> String {
        guard let profile = session.profile else { return "Recommended for you" }

        let normalizedPreferredLanguages = preferredLanguages.map { $0.lowercased() }

        if let language = person.languages.first(where: { normalizedPreferredLanguages.contains($0.lowercased()) }) {
            return "You both speak \(language)"
        }

        if person.currentCity.caseInsensitiveCompare(profile.currentCity) == .orderedSame {
            return "Also based in \(profile.currentCity)"
        }

        if person.homeCountry.caseInsensitiveCompare(profile.homeCountry) == .orderedSame {
            return "From \(profile.homeCountry)"
        }

        return "Shares your interests"
    }
    private func memberCount(for community: Community) -> Int {
        let liveCount = session.members(for: community).count
        return max(liveCount, community.members)
    }

}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct CommunityDetailView: View {
    @EnvironmentObject private var session: AppSession
    let community: Community
    @State private var draftPost = ""
    @State private var bannerText: String?
    @State private var isShowingEditCommunity = false
    @State private var isShowingCreateEvent = false

    private var displayCommunity: Community {
        session.communities.first(where: { $0.id == community.id }) ?? community
    }

    var body: some View {
        ZStack {
            AppTheme.screenGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if let bannerText {
                        GlassCard {
                            Text(bannerText)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.Colors.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(displayCommunity.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppTheme.Colors.primaryText)

                            Text("\(max(session.members(for: community).count, displayCommunity.members)) members • \(displayCommunity.city)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.Colors.highlight)

                            Text("Created by \(displayCommunity.creatorName)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.Colors.secondaryText)

                            if displayCommunity.creatorID == session.profile?.id {
                                Text("You manage this community")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.Colors.success)
                            }

                            Text(displayCommunity.description)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.Colors.secondaryText)

                            FlexibleChipsView(tags: displayCommunity.tags)

                            if session.isCommunityAdmin(community) {
                                HStack(spacing: 10) {
                                    Button {
                                        isShowingEditCommunity = true
                                    } label: {
                                        Text("Edit Community")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(AppTheme.Colors.primaryText)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.82))
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }

                                    Button {
                                        isShowingCreateEvent = true
                                    } label: {
                                        Text("Create Event")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(AppTheme.Colors.accent)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }
                            }

                            Button {
                                Task {
                                        let wasJoined = session.isCommunityJoined(displayCommunity)
                                        await session.toggleCommunityMembership(displayCommunity)
                                        bannerText = wasJoined ? "You left \(displayCommunity.name)." : "You joined \(displayCommunity.name)."
                                    }
                                } label: {
                                Text(session.isCommunityJoined(displayCommunity) ? "Remove Community" : "Join Community")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(session.isCommunityJoined(community) ? AppTheme.Colors.primaryText : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(session.isCommunityJoined(community) ? Color.white.opacity(0.8) : AppTheme.Colors.highlight)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Members")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.Colors.primaryText)

                            if session.members(for: community).isEmpty {
                                Text("No one has joined yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.Colors.secondaryText)
                            } else {
                                ForEach(session.members(for: community)) { member in
                                    NavigationLink {
                                        PublicPersonProfileView(person: member)
                                            .environmentObject(session)
                                    } label: {
                                        HStack(spacing: 12) {
                                            PersonAvatarView(
                                                name: member.fullName,
                                                profileImageDataBase64: member.profileImageDataBase64,
                                                size: 38
                                            )

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(member.fullName)
                                                    .font(.subheadline.weight(.bold))
                                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                                Text(locationText(for: member))
                                                    .font(.caption)
                                                    .foregroundStyle(AppTheme.Colors.secondaryText)
                                            }

                                            Spacer()

                                            if member.isAdmin {
                                                Text(member.id == displayCommunity.creatorID ? "Creator" : "Admin")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(member.id == displayCommunity.creatorID ? AppTheme.Colors.success : AppTheme.Colors.highlight)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    if displayCommunity.creatorID == session.profile?.id && !member.isAdmin && member.id != session.profile?.id {
                                        Button {
                                            Task {
                                                await session.makeCommunityAdmin(member, in: displayCommunity)
                                                bannerText = "\(member.fullName) is now an admin."
                                            }
                                        } label: {
                                            Text("Make Admin")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(AppTheme.Colors.highlight)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !session.futureEvents(for: displayCommunity).isEmpty || session.isCommunityAdmin(displayCommunity) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Future events")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.Colors.primaryText)

                                    Spacer()

                                    if session.isCommunityAdmin(displayCommunity) {
                                        Button("Create") {
                                            isShowingCreateEvent = true
                                        }
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.Colors.highlight)
                                    }
                                }

                                if session.futureEvents(for: displayCommunity).isEmpty {
                                    Text("No community-hosted events yet.")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.Colors.secondaryText)
                                } else {
                                    ForEach(session.futureEvents(for: displayCommunity)) { event in
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(event.title)
                                                .font(.subheadline.weight(.bold))
                                                .foregroundStyle(AppTheme.Colors.primaryText)

                                            Text("\(event.dateText) • \(event.place)")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.Colors.secondaryText)

                                            if !event.description.isEmpty {
                                                Text(event.description)
                                                    .font(.caption)
                                                    .foregroundStyle(AppTheme.Colors.secondaryText)
                                            }
                                        }
                                        .padding(14)
                                        .background(Color.white.opacity(0.7))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Community feed")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.Colors.primaryText)

                            if session.isCommunityJoined(displayCommunity) {
                                VStack(alignment: .leading, spacing: 10) {
                                    TextField("Share an update with the community", text: $draftPost, axis: .vertical)
                                        .lineLimit(3...6)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.8))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                    Button {
                                        let postText = draftPost
                                        Task {
                                            await session.createCommunityPost(for: displayCommunity, text: postText)
                                            draftPost = ""
                                            bannerText = "Posted in \(displayCommunity.name)."
                                        }
                                    } label: {
                                        Text("Post")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(AppTheme.Colors.accent)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                    .disabled(draftPost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            } else {
                                Text("Join this community to post updates and take part in the conversation.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.Colors.secondaryText)
                            }

                            if session.posts(for: displayCommunity).isEmpty {
                                Text("No posts yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.Colors.secondaryText)
                            } else {
                                ForEach(session.posts(for: displayCommunity)) { post in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(post.authorName)
                                                .font(.subheadline.weight(.bold))
                                                .foregroundStyle(AppTheme.Colors.primaryText)

                                            Spacer()

                                            Text(post.time)
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.Colors.secondaryText)
                                        }

                                        Text(post.text)
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.Colors.secondaryText)
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingEditCommunity) {
            EditCommunityView(community: displayCommunity) { description, tags in
                Task {
                    await session.updateCommunityDetails(displayCommunity, description: description, tagsText: tags)
                    bannerText = "\(displayCommunity.name) has been updated."
                }
            }
            .environmentObject(session)
        }
        .sheet(isPresented: $isShowingCreateEvent) {
            CreateEventView { title, host, description, place, startAt, tags in
                Task {
                    await session.createEvent(
                        title: title,
                        host: host,
                        description: description,
                        place: place,
                        startAt: startAt,
                        tagsText: tags,
                        community: displayCommunity
                    )
                    bannerText = "A new event is live for \(displayCommunity.name)."
                }
            }
            .environmentObject(session)
        }
    }
    private func locationText(for person: Person) -> String {
        let parts = [person.homeCountry, person.currentCity].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return parts.isEmpty ? "Rooted member" : parts.joined(separator: " • ")
    }
}

private struct EditCommunityView: View {
    @Environment(\.dismiss) private var dismiss
    let community: Community
    let onSave: (String, String) -> Void

    @State private var description: String
    @State private var tagsText: String

    init(community: Community, onSave: @escaping (String, String) -> Void) {
        self.community = community
        self.onSave = onSave
        _description = State(initialValue: community.description)
        _tagsText = State(initialValue: community.tags.joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    TextEditor(text: $description)
                        .frame(minHeight: 140)
                }

                Section("Tags") {
                    TextField("French, Students, Networking", text: $tagsText)
                }

                Section {
                    Button("Save Changes") {
                        onSave(description, tagsText)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
