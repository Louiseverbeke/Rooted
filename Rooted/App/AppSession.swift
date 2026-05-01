import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
final class AppSession: ObservableObject {
    enum AuthState {
        case loading
        case signedOut
        case signedIn
    }

    @Published var authState: AuthState = .loading
    @Published var profile: UserProfile?
    @Published var communities: [Community] = []
    @Published var events: [EventItem] = []
    @Published var threads: [MessageThread] = []
    @Published var people: [Person] = []
    @Published var friendIDs: Set<String> = []
    @Published var friendProfilesByID: [String: Person] = [:]
    @Published var incomingFriendRequests: [FriendRequest] = []
    @Published var sentFriendRequestIDs: Set<String> = []
    @Published var joinedCommunityIDs: Set<String> = []
    @Published var communityMembersByID: [String: [Person]] = [:]
    @Published var communityPostsByID: [String: [CommunityPost]] = [:]
    @Published var savedEventIDs: Set<String> = []
    @Published var rsvpedEventIDs: Set<String> = []
    @Published var eventAttendeesByID: [String: [Person]] = [:]
    @Published var profileImageData: Data?
    @Published var errorMessage: String?

    let authService: AuthServicing
    let dataService: CommunityDataServicing

    init() {
        self.authService = ServiceFactory.makeAuthService()
        self.dataService = ServiceFactory.makeDataService()
        restoreSession()
    }

    init(
        authService: AuthServicing,
        dataService: CommunityDataServicing
    ) {
        self.authService = authService
        self.dataService = dataService
        restoreSession()
    }

    func restoreSession() {
        if let userID = authService.currentUserID() {
            authState = .signedIn
            Task {
                await loadSession(userID: userID)
            }
        } else {
            authState = .signedOut
        }
    }

    func signIn(email: String, password: String) async {
        do {
            try await authService.signIn(email: email, password: password)
            guard let userID = authService.currentUserID() else { return }
            authState = .signedIn
            await loadSession(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String, fullName: String, gender: String) async {
        do {
            try await authService.signUp(email: email, password: password)
            guard let userID = authService.currentUserID() else { return }

            let starterProfile = UserProfile(
                id: userID,
                fullName: fullName,
                email: email,
                gender: gender,
                bio: "",
                homeCountry: "",
                currentCity: "",
                languages: [],
                role: "Student",
                interests: [],
                onboardingCompleted: false,
                isDiscoverable: true,
                showHomeCountry: true,
                showCurrentCity: true,
                profileImageDataBase64: nil
            )
            try await dataService.saveProfile(starterProfile)
            authState = .signedIn
            await loadSession(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try authService.signOut()
            profile = nil
            communities = []
            events = []
            threads = []
            people = []
            friendIDs = []
            friendProfilesByID = [:]
            incomingFriendRequests = []
            sentFriendRequestIDs = []
            joinedCommunityIDs = []
            communityMembersByID = [:]
            communityPostsByID = [:]
            savedEventIDs = []
            rsvpedEventIDs = []
            eventAttendeesByID = [:]
            profileImageData = nil
            authState = .signedOut
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeOnboarding(homeCountry: String, currentCity: String, role: String, interests: [String]) async {
        guard var profile else { return }
        profile.homeCountry = homeCountry
        profile.currentCity = currentCity
        profile.role = role
        profile.interests = interests
        profile.languages = ["English"]
        profile.onboardingCompleted = true

        do {
            try await dataService.saveProfile(profile)
            self.profile = profile
            await reloadContent()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadContent() async {
        guard let profile else { return }

        async let communitiesTask = safeFetch([Community].self) { try await self.dataService.fetchCommunities(for: profile) }
        async let eventsTask = safeFetch([EventItem].self) { try await self.dataService.fetchEvents(for: profile) }
        async let threadsTask = safeFetch([MessageThread].self) { try await self.dataService.fetchMessageThreads(for: profile.id) }
        async let peopleTask = safeFetch([Person].self) { try await self.dataService.fetchPeople(excluding: profile.id) }
        async let friendIDsTask = safeFetch(Set<String>.self) { try await self.dataService.fetchFriendIDs(for: profile.id) }
        async let incomingRequestsTask = safeFetch([FriendRequest].self) { try await self.dataService.fetchIncomingFriendRequests(for: profile.id) }
        async let sentRequestsTask = safeFetch(Set<String>.self) { try await self.dataService.fetchSentFriendRequestIDs(for: profile.id) }
        async let joinedCommunitiesTask = safeFetch(Set<String>.self) { try await self.dataService.fetchJoinedCommunityIDs(for: profile.id) }
        async let rsvpsTask = safeFetch(Set<String>.self) { try await self.dataService.fetchRSVPEventIDs(for: profile.id) }

        communities = await communitiesTask ?? communities
        events = await eventsTask ?? events
        threads = await threadsTask ?? []
        people = await peopleTask ?? []
        let fetchedFriendIDs = await friendIDsTask ?? Set<String>()
        let threadFriendIDs = Set(
            threads.compactMap { thread in
                thread.participantIDs.first(where: { $0 != profile.id })
            }
        )
        let reconciledFriendIDs = fetchedFriendIDs.union(threadFriendIDs)
        friendIDs = reconciledFriendIDs

        let fetchedIncomingRequests = await incomingRequestsTask ?? []
        incomingFriendRequests = normalizedIncomingRequests(
            fetchedIncomingRequests,
            excluding: reconciledFriendIDs
        )

        let fetchedSentRequestIDs = await sentRequestsTask ?? Set<String>()
        sentFriendRequestIDs = normalizedSentRequestIDs(
            fetchedSentRequestIDs,
            excluding: reconciledFriendIDs
        )
        joinedCommunityIDs = await joinedCommunitiesTask ?? joinedCommunityIDs
        rsvpedEventIDs = await rsvpsTask ?? rsvpedEventIDs

        var loadedFriendProfiles: [String: Person] = [:]
        for friendID in reconciledFriendIDs {
            if let friendProfile = await safeFetch(UserProfile.self, operation: {
                try await self.dataService.fetchProfile(userID: friendID)
            }) {
                loadedFriendProfiles[friendID] = person(from: friendProfile, respectPrivacy: true)
            }
        }
        friendProfilesByID = loadedFriendProfiles

        var attendees: [String: [Person]] = [:]
        for event in events {
            if let fetchedAttendees = await safeFetch([Person].self, operation: {
                try await self.dataService.fetchEventAttendees(eventID: event.id)
            }) {
                attendees[event.id] = fetchedAttendees
            }
        }
        eventAttendeesByID = attendees

        var communityMembers: [String: [Person]] = [:]
        var communityPosts: [String: [CommunityPost]] = [:]
        for community in communities where joinedCommunityIDs.contains(community.id) {
            if let fetchedMembers = await safeFetch([Person].self, operation: {
                try await self.dataService.fetchCommunityMembers(communityID: community.id)
            }) {
                communityMembers[community.id] = fetchedMembers
            }
            if let fetchedPosts = await safeFetch([CommunityPost].self, operation: {
                try await self.dataService.fetchCommunityPosts(communityID: community.id)
            }) {
                communityPosts[community.id] = fetchedPosts
            }
        }
        communityMembersByID = communityMembers
        communityPostsByID = communityPosts
    }

    func isFriend(_ person: Person) -> Bool {
        friendIDs.contains(person.id)
    }

    func hasIncomingRequest(from person: Person) -> Bool {
        !friendIDs.contains(person.id) && incomingFriendRequests.contains(where: { $0.from.id == person.id })
    }

    func hasSentRequest(to person: Person) -> Bool {
        !friendIDs.contains(person.id) && sentFriendRequestIDs.contains(person.id)
    }

    func sendFriendRequest(to person: Person) async {
        guard let profile else { return }

        do {
            try await dataService.sendFriendRequest(from: profile, to: person)
            sentFriendRequestIDs.insert(person.id)
            sentFriendRequestIDs = try await dataService.fetchSentFriendRequestIDs(for: profile.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelFriendRequest(to person: Person) async {
        guard let profile else { return }

        do {
            try await dataService.cancelFriendRequest(from: profile.id, to: person.id)
            sentFriendRequestIDs.remove(person.id)
            await reloadContent()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func respondToFriendRequest(_ request: FriendRequest, accept: Bool) async {
        guard let profile else { return }

        do {
            try await dataService.respondToFriendRequest(currentUserID: profile.id, request: request, accept: accept)
            incomingFriendRequests.removeAll { $0.from.id == request.from.id }
            sentFriendRequestIDs.remove(request.from.id)
            if accept {
                friendIDs.insert(request.from.id)
                friendProfilesByID[request.from.id] = request.from
                if !people.contains(where: { $0.id == request.from.id }) {
                    people.insert(request.from, at: 0)
                }
            }
            await reloadContent()
            incomingFriendRequests = normalizedIncomingRequests(
                incomingFriendRequests,
                excluding: friendIDs
            )
            sentFriendRequestIDs = normalizedSentRequestIDs(
                sentFriendRequestIDs,
                excluding: friendIDs
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFriend(_ person: Person) async {
        guard let profile else { return }

        do {
            try await dataService.removeFriend(currentUserID: profile.id, friendID: person.id)
            friendIDs.remove(person.id)
            friendProfilesByID[person.id] = nil
            incomingFriendRequests.removeAll { $0.from.id == person.id }
            sentFriendRequestIDs.remove(person.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProfile(
        fullName: String,
        bioText: String,
        homeCountry: String,
        currentCity: String,
        languagesText: String,
        isDiscoverable: Bool,
        showHomeCountry: Bool,
        showCurrentCity: Bool
    ) async {
        guard var profile else { return }

        profile.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.bio = bioText.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.homeCountry = homeCountry.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.currentCity = currentCity.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.languages = languagesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        profile.isDiscoverable = isDiscoverable
        profile.showHomeCountry = showHomeCountry
        profile.showCurrentCity = showCurrentCity

        do {
            try await dataService.saveProfile(profile)
            self.profile = profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createCommunity(name: String, city: String, tagsText: String, description: String) async {
        guard let profile else { return }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        do {
            let community = try await dataService.createCommunity(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                tags: tags,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                creator: profile
            )
            communities.insert(community, at: 0)
            joinedCommunityIDs.insert(community.id)
            let currentPerson = Person(
                id: profile.id,
                fullName: profile.fullName,
                email: profile.email,
                gender: profile.gender,
                bio: profile.bio,
                homeCountry: profile.homeCountry,
                currentCity: profile.currentCity,
                languages: profile.languages,
                role: profile.role,
                interests: profile.interests,
                profileImageDataBase64: profile.profileImageDataBase64,
                isAdmin: true
            )
            communityMembersByID[community.id] = [currentPerson]
            communityPostsByID[community.id] = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfileImage(_ data: Data?) {
        let normalizedData = normalizedProfileImageData(from: data)
        profileImageData = normalizedData

        guard var profile else { return }
        profile.profileImageDataBase64 = normalizedData?.base64EncodedString()
        self.profile = profile

        Task {
            do {
                try await dataService.saveProfile(profile)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func isCommunityJoined(_ community: Community) -> Bool {
        joinedCommunityIDs.contains(community.id)
    }

    func toggleCommunityMembership(_ community: Community) async {
        guard let profile else { return }
        let shouldJoin = !joinedCommunityIDs.contains(community.id)

        do {
            try await dataService.setCommunityMembership(currentUser: profile, community: community, isJoined: shouldJoin)
            communities = try await dataService.fetchCommunities(for: profile)
            if shouldJoin {
                joinedCommunityIDs.insert(community.id)
                communityMembersByID[community.id] = try await dataService.fetchCommunityMembers(communityID: community.id)
                communityPostsByID[community.id] = try await dataService.fetchCommunityPosts(communityID: community.id)
            } else {
                joinedCommunityIDs.remove(community.id)
                communityMembersByID[community.id] = nil
                communityPostsByID[community.id] = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func members(for community: Community) -> [Person] {
        communityMembersByID[community.id] ?? []
    }

    func posts(for community: Community) -> [CommunityPost] {
        communityPostsByID[community.id] ?? []
    }

    func createCommunityPost(for community: Community, text: String) async {
        guard let profile else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let post = try await dataService.createCommunityPost(communityID: community.id, author: profile, text: trimmed)
            var posts = communityPostsByID[community.id] ?? []
            posts.insert(post, at: 0)
            communityPostsByID[community.id] = posts
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createEvent(title: String, host: String, description: String, place: String, startAt: Date, tagsText: String, community: Community? = nil) async {
        guard let profile else { return }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        do {
            let event = try await dataService.createEvent(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                host: host.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                place: place.trimmingCharacters(in: .whitespacesAndNewlines),
                startAt: startAt,
                tags: tags,
                creator: profile,
                community: community
            )
            events.insert(event, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isCommunityAdmin(_ community: Community) -> Bool {
        community.creatorID == profile?.id || members(for: community).contains(where: { $0.id == profile?.id && $0.isAdmin })
    }

    func updateCommunityDetails(_ community: Community, description: String, tagsText: String) async {
        guard let profile else { return }
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        do {
            try await dataService.updateCommunityDetails(
                communityID: community.id,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                tags: tags,
                currentUserID: profile.id
            )
            communities = try await dataService.fetchCommunities(for: profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func makeCommunityAdmin(_ person: Person, in community: Community) async {
        guard let profile else { return }
        do {
            try await dataService.setCommunityAdmin(
                communityID: community.id,
                memberID: person.id,
                isAdmin: true,
                currentUserID: profile.id
            )
            communityMembersByID[community.id] = try await dataService.fetchCommunityMembers(communityID: community.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func futureEvents(for community: Community) -> [EventItem] {
        events
            .filter { $0.communityID == community.id && $0.startAt >= .now }
            .sorted { $0.startAt < $1.startAt }
    }

    func isEventSaved(_ event: EventItem) -> Bool {
        savedEventIDs.contains(event.id)
    }

    func toggleSavedEvent(_ event: EventItem) {
        if savedEventIDs.contains(event.id) {
            savedEventIDs.remove(event.id)
        } else {
            savedEventIDs.insert(event.id)
        }
    }

    func isGoing(to event: EventItem) -> Bool {
        rsvpedEventIDs.contains(event.id)
    }

    func toggleRSVP(for event: EventItem) async {
        guard let profile else { return }
        let newValue = !rsvpedEventIDs.contains(event.id)

        do {
            try await dataService.setRSVPStatus(currentUser: profile, event: event, isGoing: newValue)
            events = try await dataService.fetchEvents(for: profile)
            if newValue {
                rsvpedEventIDs.insert(event.id)
            } else {
                rsvpedEventIDs.remove(event.id)
            }
            eventAttendeesByID[event.id] = try await dataService.fetchEventAttendees(eventID: event.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func attendees(for event: EventItem) -> [Person] {
        eventAttendeesByID[event.id] ?? []
    }

    func startChat(with person: Person) async -> MessageThread? {
        guard let profile else { return nil }
        errorMessage = nil

        do {
            let thread = try await dataService.createOrGetThread(
                currentUserID: profile.id,
                currentUserName: profile.fullName,
                otherPerson: person
            )

            if let index = threads.firstIndex(where: { $0.id == thread.id }) {
                threads.remove(at: index)
            }
            threads.insert(thread, at: 0)
            return thread
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func deleteThread(_ thread: MessageThread) async {
        guard let profile else { return }

        do {
            try await dataService.deleteThread(threadID: thread.id, currentUserID: profile.id)
            threads.removeAll { $0.id == thread.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var friends: [Person] {
        let visibleFriends = people.filter { friendIDs.contains($0.id) }
        let loadedFriends = friendProfilesByID.values
        let all = visibleFriends + loadedFriends
        var seen: Set<String> = []
        return all.filter { person in
            seen.insert(person.id).inserted
        }
    }

    var joinedCommunities: [Community] {
        communities.filter { joinedCommunityIDs.contains($0.id) }
    }

    var savedEvents: [EventItem] {
        events.filter { savedEventIDs.contains($0.id) }
    }

    private func loadSession(userID: String) async {
        do {
            let profile = try await dataService.fetchProfile(userID: userID)
            self.profile = profile
            self.profileImageData = profile.profileImageDataBase64.flatMap { Data(base64Encoded: $0) }
            await reloadContent()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func safeFetch<T>(_ type: T.Type, operation: @escaping () async throws -> T) async -> T? {
        do {
            return try await operation()
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func person(from profile: UserProfile, respectPrivacy: Bool) -> Person {
        Person(
            id: profile.id,
            fullName: profile.fullName,
            email: profile.email,
            gender: profile.gender,
            bio: profile.bio,
            homeCountry: respectPrivacy && !profile.showHomeCountry ? "" : profile.homeCountry,
            currentCity: respectPrivacy && !profile.showCurrentCity ? "" : profile.currentCity,
            languages: profile.languages,
            role: profile.role,
            interests: profile.interests,
            profileImageDataBase64: profile.profileImageDataBase64
        )
    }

    private func normalizedIncomingRequests(
        _ requests: [FriendRequest],
        excluding friendIDs: Set<String>
    ) -> [FriendRequest] {
        var seen: Set<String> = []
        return requests.filter { request in
            guard !friendIDs.contains(request.from.id) else { return false }
            return seen.insert(request.from.id).inserted
        }
    }

    private func normalizedSentRequestIDs(
        _ requestIDs: Set<String>,
        excluding friendIDs: Set<String>
    ) -> Set<String> {
        requestIDs.subtracting(friendIDs)
    }

    private func normalizedProfileImageData(from data: Data?) -> Data? {
        guard
            let data,
            let image = UIImage(data: data)
        else {
            return nil
        }

        let targetSize = CGSize(width: 320, height: 320)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return rendered.jpegData(compressionQuality: 0.72)
    }
}

enum ServiceFactory {
    static func makeAuthService() -> AuthServicing {
        FirebaseAuthService()
    }

    static func makeDataService() -> CommunityDataServicing {
        FirebaseCommunityDataService()
    }
}
