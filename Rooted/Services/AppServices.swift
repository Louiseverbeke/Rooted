import Foundation

protocol AuthServicing {
    func currentUserID() -> String?
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signOut() throws
}

protocol CommunityDataServicing {
    func fetchProfile(userID: String) async throws -> UserProfile
    func saveProfile(_ profile: UserProfile) async throws
    func fetchCommunities(for profile: UserProfile?) async throws -> [Community]
    func createCommunity(name: String, city: String, tags: [String], description: String, creator: UserProfile) async throws -> Community
    func fetchJoinedCommunityIDs(for userID: String) async throws -> Set<String>
    func setCommunityMembership(currentUser: UserProfile, community: Community, isJoined: Bool) async throws
    func fetchCommunityMembers(communityID: String) async throws -> [Person]
    func fetchCommunityPosts(communityID: String) async throws -> [CommunityPost]
    func createCommunityPost(communityID: String, author: UserProfile, text: String) async throws -> CommunityPost
    func updateCommunityDetails(communityID: String, description: String, tags: [String], currentUserID: String) async throws
    func setCommunityAdmin(communityID: String, memberID: String, isAdmin: Bool, currentUserID: String) async throws
    func fetchEvents(for profile: UserProfile?) async throws -> [EventItem]
    func createEvent(title: String, host: String, description: String, place: String, startAt: Date, tags: [String], creator: UserProfile, community: Community?) async throws -> EventItem
    func fetchPeople(excluding userID: String?) async throws -> [Person]
    func fetchFriendIDs(for userID: String) async throws -> Set<String>
    func removeFriend(currentUserID: String, friendID: String) async throws
    func fetchIncomingFriendRequests(for userID: String) async throws -> [FriendRequest]
    func fetchSentFriendRequestIDs(for userID: String) async throws -> Set<String>
    func sendFriendRequest(from profile: UserProfile, to person: Person) async throws
    func cancelFriendRequest(from currentUserID: String, to personID: String) async throws
    func respondToFriendRequest(currentUserID: String, request: FriendRequest, accept: Bool) async throws
    func fetchRSVPEventIDs(for userID: String) async throws -> Set<String>
    func fetchEventAttendees(eventID: String) async throws -> [Person]
    func setRSVPStatus(currentUser: UserProfile, event: EventItem, isGoing: Bool) async throws
    func fetchMessageThreads(for userID: String) async throws -> [MessageThread]
    func createOrGetThread(currentUserID: String, currentUserName: String, otherPerson: Person) async throws -> MessageThread
    func deleteThread(threadID: String, currentUserID: String) async throws
    func listenForMessages(threadID: String, onChange: @escaping ([ChatMessage]) -> Void) -> CancellableListening
    func sendMessage(threadID: String, senderID: String, senderName: String, text: String) async throws
}

protocol CancellableListening {
    func cancel()
}
