import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    var fullName: String
    var email: String
    var gender: String
    var bio: String
    var homeCountry: String
    var currentCity: String
    var languages: [String]
    var role: String
    var interests: [String]
    var onboardingCompleted: Bool
    var isDiscoverable: Bool
    var showHomeCountry: Bool
    var showCurrentCity: Bool
    var profileImageDataBase64: String? = nil
}

struct Person: Identifiable, Codable, Hashable {
    let id: String
    let fullName: String
    let email: String
    let gender: String
    let bio: String
    let homeCountry: String
    let currentCity: String
    let languages: [String]
    let role: String
    let interests: [String]
    let profileImageDataBase64: String?
    var isAdmin: Bool = false
}

struct FriendRequest: Identifiable, Codable, Hashable {
    let id: String
    let from: Person
    let createdAt: Date
}

struct Community: Identifiable, Codable {
    let id: String
    let name: String
    let city: String
    let members: Int
    let tags: [String]
    let description: String
    let creatorID: String
    let creatorName: String
    let createdAt: Date
}

struct CommunityPost: Identifiable, Codable, Hashable {
    let id: String
    let authorID: String
    let authorName: String
    let text: String
    let createdAt: Date

    var time: String {
        createdAt.relativeTimestamp
    }
}

struct EventItem: Identifiable, Codable {
    let id: String
    let title: String
    let host: String
    let description: String
    let startAt: Date
    let place: String
    let attendees: Int
    let tags: [String]
    let creatorID: String
    let creatorName: String
    let communityID: String?
    let communityName: String?

    var dateText: String {
        startAt.formatted(date: .abbreviated, time: .shortened)
    }
}

struct MessageThread: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let preview: String
    let updatedAt: Date
    let unreadCount: Int
    let participantIDs: [String]

    var time: String {
        updatedAt.relativeTimestamp
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let senderID: String
    let senderName: String
    let text: String
    let sentAt: Date

    var isFromCurrentUser: Bool = false
}

struct QuickStat: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

extension Date {
    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}
