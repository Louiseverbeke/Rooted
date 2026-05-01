import Foundation

import FirebaseFirestore

enum FirestoreCollection {
    static let users = "users"
    static let communities = "communities"
    static let joinedCommunities = "joinedCommunities"
    static let communityMembers = "communityMembers"
    static let communityPosts = "communityPosts"
    static let events = "events"
    static let threads = "threads"
    static let messages = "messages"
    static let friends = "friends"
    static let friendRequests = "friendRequests"
    static let sentFriendRequests = "sentFriendRequests"
    static let rsvps = "rsvps"
    static let attendees = "attendees"
}

struct FirebaseCommunityDataService: CommunityDataServicing {
    func fetchProfile(userID: String) async throws -> UserProfile {
                let snapshot = try await Firestore.firestore().collection(FirestoreCollection.users).document(userID).getDocument()
        guard let data = snapshot.data() else {
            return UserProfile(
                id: userID,
                fullName: "",
                email: "",
                gender: "",
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
        }
        return UserProfile(
            id: snapshot.documentID,
            fullName: data["fullName"] as? String ?? "",
            email: data["email"] as? String ?? "",
            gender: data["gender"] as? String ?? "",
            bio: data["bio"] as? String ?? "",
            homeCountry: data["homeCountry"] as? String ?? "",
            currentCity: data["currentCity"] as? String ?? "",
            languages: data["languages"] as? [String] ?? [],
            role: data["role"] as? String ?? "Student",
            interests: data["interests"] as? [String] ?? [],
            onboardingCompleted: data["onboardingCompleted"] as? Bool ?? false,
            isDiscoverable: data["isDiscoverable"] as? Bool ?? true,
            showHomeCountry: data["showHomeCountry"] as? Bool ?? true,
            showCurrentCity: data["showCurrentCity"] as? Bool ?? true,
            profileImageDataBase64: data["profileImageDataBase64"] as? String
        )
    }

    func saveProfile(_ profile: UserProfile) async throws {
                try await Firestore.firestore().collection(FirestoreCollection.users).document(profile.id).setData([
            "fullName": profile.fullName,
            "email": profile.email,
            "gender": profile.gender,
            "bio": profile.bio,
            "homeCountry": profile.homeCountry,
            "currentCity": profile.currentCity,
            "languages": profile.languages,
            "role": profile.role,
            "interests": profile.interests,
            "onboardingCompleted": profile.onboardingCompleted,
            "isDiscoverable": profile.isDiscoverable,
            "showHomeCountry": profile.showHomeCountry,
            "showCurrentCity": profile.showCurrentCity,
            "profileImageDataBase64": profile.profileImageDataBase64 as Any
        ], merge: true)
    }

    func fetchCommunities(for profile: UserProfile?) async throws -> [Community] {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.communities)
            .limit(to: 12)
            .getDocuments()

        let mapped = snapshot.documents.map { document in
            let data = document.data()
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .now
            return Community(
                id: document.documentID,
                name: data["name"] as? String ?? "Community",
                city: data["city"] as? String ?? "",
                members: data["members"] as? Int ?? 0,
                tags: data["tags"] as? [String] ?? [],
                description: data["description"] as? String ?? "A cultural community space to connect, share events, and meet people nearby.",
                creatorID: data["creatorID"] as? String ?? "",
                creatorName: data["creatorName"] as? String ?? "",
                createdAt: createdAt
            )
        }
        return mapped
    }

    func createCommunity(name: String, city: String, tags: [String], description: String, creator: UserProfile) async throws -> Community {
        let cleanedTags = tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                let ref = Firestore.firestore().collection(FirestoreCollection.communities).document()
        let community = Community(
            id: ref.documentID,
            name: name,
            city: city,
            members: 1,
            tags: cleanedTags,
            description: description,
            creatorID: creator.id,
            creatorName: creator.fullName,
            createdAt: .now
        )

        try await ref.setData([
            "name": name,
            "city": city,
            "members": 1,
            "tags": cleanedTags,
            "description": description,
            "creatorID": creator.id,
            "creatorName": creator.fullName,
            "createdAt": Timestamp(date: .now)
        ])
        try await setCommunityMembership(currentUser: creator, community: community, isJoined: true)
        return community
    }

    func fetchJoinedCommunityIDs(for userID: String) async throws -> Set<String> {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.users)
            .document(userID)
            .collection(FirestoreCollection.joinedCommunities)
            .getDocuments()
        return Set(snapshot.documents.map(\.documentID))
    }

    func setCommunityMembership(currentUser: UserProfile, community: Community, isJoined: Bool) async throws {
        let person = Person(
            id: currentUser.id,
            fullName: currentUser.fullName,
            email: currentUser.email,
            gender: currentUser.gender,
            bio: currentUser.bio,
            homeCountry: currentUser.showHomeCountry ? currentUser.homeCountry : "",
            currentCity: currentUser.showCurrentCity ? currentUser.currentCity : "",
            languages: currentUser.languages,
            role: currentUser.role,
            interests: currentUser.interests,
            profileImageDataBase64: currentUser.profileImageDataBase64,
            isAdmin: community.creatorID == currentUser.id
        )
                let db = Firestore.firestore()
        let joinedRef = db
            .collection(FirestoreCollection.users)
            .document(currentUser.id)
            .collection(FirestoreCollection.joinedCommunities)
            .document(community.id)
        let memberRef = db
            .collection(FirestoreCollection.communities)
            .document(community.id)
            .collection(FirestoreCollection.communityMembers)
            .document(currentUser.id)

        if isJoined {
            try await joinedRef.setData([
                "joinedAt": Timestamp(date: .now),
                "communityName": community.name
            ], merge: true)
            try await memberRef.setData([
                "fullName": person.fullName,
                "gender": person.gender,
                "bio": person.bio,
                "homeCountry": person.homeCountry,
                "currentCity": person.currentCity,
                "languages": person.languages,
                "role": person.role,
                "interests": person.interests,
                "profileImageDataBase64": person.profileImageDataBase64 as Any,
                "isAdmin": person.isAdmin,
                "joinedAt": Timestamp(date: .now)
            ], merge: true)
        } else {
            try await joinedRef.delete()
            try await memberRef.delete()
        }
    }

    func fetchCommunityMembers(communityID: String) async throws -> [Person] {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.communities)
            .document(communityID)
            .collection(FirestoreCollection.communityMembers)
            .getDocuments()

        return snapshot.documents.map { document in
            let data = document.data()
            return Person(
                id: document.documentID,
                fullName: data["fullName"] as? String ?? "Member",
                email: "",
                gender: data["gender"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                homeCountry: data["homeCountry"] as? String ?? "",
                currentCity: data["currentCity"] as? String ?? "",
                languages: data["languages"] as? [String] ?? [],
                role: data["role"] as? String ?? "Student",
                interests: data["interests"] as? [String] ?? [],
                profileImageDataBase64: data["profileImageDataBase64"] as? String,
                isAdmin: data["isAdmin"] as? Bool ?? false
            )
        }
    }

    func fetchCommunityPosts(communityID: String) async throws -> [CommunityPost] {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.communities)
            .document(communityID)
            .collection(FirestoreCollection.communityPosts)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.map { document in
            let data = document.data()
            let timestamp = data["createdAt"] as? Timestamp
            return CommunityPost(
                id: document.documentID,
                authorID: data["authorID"] as? String ?? "",
                authorName: data["authorName"] as? String ?? "Member",
                text: data["text"] as? String ?? "",
                createdAt: timestamp?.dateValue() ?? .now
            )
        }
    }

    func createCommunityPost(communityID: String, author: UserProfile, text: String) async throws -> CommunityPost {
                let ref = Firestore.firestore()
            .collection(FirestoreCollection.communities)
            .document(communityID)
            .collection(FirestoreCollection.communityPosts)
            .document()

        let post = CommunityPost(
            id: ref.documentID,
            authorID: author.id,
            authorName: author.fullName,
            text: text,
            createdAt: .now
        )
        try await ref.setData([
            "authorID": author.id,
            "authorName": author.fullName,
            "text": text,
            "createdAt": Timestamp(date: post.createdAt)
        ])
        return post
    }

    func updateCommunityDetails(communityID: String, description: String, tags: [String], currentUserID: String) async throws {
        let cleanedTags = tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                try await Firestore.firestore()
            .collection(FirestoreCollection.communities)
            .document(communityID)
            .setData([
                "description": description,
                "tags": cleanedTags,
                "updatedAt": Timestamp(date: .now),
                "updatedBy": currentUserID
            ], merge: true)
    }

    func setCommunityAdmin(communityID: String, memberID: String, isAdmin: Bool, currentUserID: String) async throws {
                try await Firestore.firestore()
            .collection(FirestoreCollection.communities)
            .document(communityID)
            .collection(FirestoreCollection.communityMembers)
            .document(memberID)
            .setData([
                "isAdmin": isAdmin,
                "updatedAt": Timestamp(date: .now),
                "updatedBy": currentUserID
            ], merge: true)
    }

    func fetchEvents(for profile: UserProfile?) async throws -> [EventItem] {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.events)
            .order(by: "startAt", descending: false)
            .limit(to: 20)
            .getDocuments()

        let mapped = snapshot.documents.map { document in
            let data = document.data()
            let timestamp = data["startAt"] as? Timestamp
            return EventItem(
                id: document.documentID,
                title: data["title"] as? String ?? "Event",
                host: data["host"] as? String ?? "Host",
                description: data["description"] as? String ?? "",
                startAt: timestamp?.dateValue() ?? .now,
                place: data["place"] as? String ?? "",
                attendees: data["attendees"] as? Int ?? 0,
                tags: data["tags"] as? [String] ?? [],
                creatorID: data["creatorID"] as? String ?? "",
                creatorName: data["creatorName"] as? String ?? "",
                communityID: data["communityID"] as? String,
                communityName: data["communityName"] as? String
            )
        }
        return mapped
    }

    func createEvent(title: String, host: String, description: String, place: String, startAt: Date, tags: [String], creator: UserProfile, community: Community?) async throws -> EventItem {
        let cleanedTags = tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                let ref = Firestore.firestore().collection(FirestoreCollection.events).document()
        let event = EventItem(
            id: ref.documentID,
            title: title,
            host: community?.name ?? host,
            description: description,
            startAt: startAt,
            place: place,
            attendees: 0,
            tags: cleanedTags,
            creatorID: creator.id,
            creatorName: creator.fullName,
            communityID: community?.id,
            communityName: community?.name
        )
        try await ref.setData([
            "title": title,
            "host": community?.name ?? host,
            "description": description,
            "startAt": Timestamp(date: startAt),
            "place": place,
            "attendees": 0,
            "tags": cleanedTags,
            "creatorID": creator.id,
            "creatorName": creator.fullName,
            "communityID": community?.id as Any,
            "communityName": community?.name as Any,
            "createdAt": Timestamp(date: .now)
        ])
        return event
    }

    func fetchPeople(excluding userID: String?) async throws -> [Person] {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.users)
            .limit(to: 100)
            .getDocuments()

        let people = snapshot.documents.compactMap { document -> Person? in
            guard document.documentID != userID else { return nil }
            let data = document.data()
            let isDiscoverable = data["isDiscoverable"] as? Bool ?? true
            guard isDiscoverable else { return nil }
            let showHomeCountry = data["showHomeCountry"] as? Bool ?? true
            let showCurrentCity = data["showCurrentCity"] as? Bool ?? true
            return Person(
                id: document.documentID,
                fullName: data["fullName"] as? String ?? "Community Member",
                email: data["email"] as? String ?? "",
                gender: data["gender"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                homeCountry: showHomeCountry ? (data["homeCountry"] as? String ?? "") : "",
                currentCity: showCurrentCity ? (data["currentCity"] as? String ?? "") : "",
                languages: data["languages"] as? [String] ?? [],
                role: data["role"] as? String ?? "Student",
                interests: data["interests"] as? [String] ?? [],
                profileImageDataBase64: data["profileImageDataBase64"] as? String
            )
        }
        return people
    }

    func fetchFriendIDs(for userID: String) async throws -> Set<String> {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.users)
            .document(userID)
            .collection(FirestoreCollection.friends)
            .getDocuments()

        return Set(snapshot.documents.map(\.documentID))
    }

    func removeFriend(currentUserID: String, friendID: String) async throws {
                let db = Firestore.firestore()
        let friendRef = db
            .collection(FirestoreCollection.users)
            .document(currentUserID)
            .collection(FirestoreCollection.friends)
            .document(friendID)
        let reciprocalRef = db
            .collection(FirestoreCollection.users)
            .document(friendID)
            .collection(FirestoreCollection.friends)
            .document(currentUserID)

        try await friendRef.delete()
        try await reciprocalRef.delete()
    }

    func fetchIncomingFriendRequests(for userID: String) async throws -> [FriendRequest] {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.users)
            .document(userID)
            .collection(FirestoreCollection.friendRequests)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            let data = document.data()
            let timestamp = data["createdAt"] as? Timestamp
            let person = Person(
                id: data["fromUserID"] as? String ?? document.documentID,
                fullName: data["fromUserName"] as? String ?? "Community Member",
                email: "",
                gender: data["fromGender"] as? String ?? "",
                bio: data["fromBio"] as? String ?? "",
                homeCountry: data["fromHomeCountry"] as? String ?? "",
                currentCity: data["fromCurrentCity"] as? String ?? "",
                languages: data["fromLanguages"] as? [String] ?? [],
                role: data["fromRole"] as? String ?? "Student",
                interests: data["fromInterests"] as? [String] ?? [],
                profileImageDataBase64: data["fromProfileImageDataBase64"] as? String
            )
            return FriendRequest(
                id: document.documentID,
                from: person,
                createdAt: timestamp?.dateValue() ?? .now
            )
        }
    }

    func fetchSentFriendRequestIDs(for userID: String) async throws -> Set<String> {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.users)
            .document(userID)
            .collection(FirestoreCollection.sentFriendRequests)
            .getDocuments()
        return Set(snapshot.documents.map(\.documentID))
    }

    func sendFriendRequest(from profile: UserProfile, to person: Person) async throws {
                let db = Firestore.firestore()
        let incomingRef = db
            .collection(FirestoreCollection.users)
            .document(person.id)
            .collection(FirestoreCollection.friendRequests)
            .document(profile.id)
        let sentRef = db
            .collection(FirestoreCollection.users)
            .document(profile.id)
            .collection(FirestoreCollection.sentFriendRequests)
            .document(person.id)

        try await incomingRef.setData([
            "fromUserID": profile.id,
            "fromUserName": profile.fullName,
            "fromGender": profile.gender,
            "fromBio": profile.bio,
            "fromHomeCountry": profile.showHomeCountry ? profile.homeCountry : "",
            "fromCurrentCity": profile.showCurrentCity ? profile.currentCity : "",
            "fromLanguages": profile.languages,
            "fromRole": profile.role,
            "fromInterests": profile.interests,
            "fromProfileImageDataBase64": profile.profileImageDataBase64 as Any,
            "createdAt": Timestamp(date: .now)
        ], merge: true)

        try await sentRef.setData([
            "createdAt": Timestamp(date: .now)
        ], merge: true)
    }

    func cancelFriendRequest(from currentUserID: String, to personID: String) async throws {
                let db = Firestore.firestore()
        let incomingRef = db
            .collection(FirestoreCollection.users)
            .document(personID)
            .collection(FirestoreCollection.friendRequests)
            .document(currentUserID)
        let sentRef = db
            .collection(FirestoreCollection.users)
            .document(currentUserID)
            .collection(FirestoreCollection.sentFriendRequests)
            .document(personID)

        try await incomingRef.delete()
        try await sentRef.delete()
    }

    func respondToFriendRequest(currentUserID: String, request: FriendRequest, accept: Bool) async throws {
                let db = Firestore.firestore()
        let incomingRef = db
            .collection(FirestoreCollection.users)
            .document(currentUserID)
            .collection(FirestoreCollection.friendRequests)
            .document(request.from.id)
        let sentRef = db
            .collection(FirestoreCollection.users)
            .document(request.from.id)
            .collection(FirestoreCollection.sentFriendRequests)
            .document(currentUserID)

        if accept {
            let currentFriendRef = db
                .collection(FirestoreCollection.users)
                .document(currentUserID)
                .collection(FirestoreCollection.friends)
                .document(request.from.id)
            let reciprocalRef = db
                .collection(FirestoreCollection.users)
                .document(request.from.id)
                .collection(FirestoreCollection.friends)
                .document(currentUserID)

            try await currentFriendRef.setData(["addedAt": Timestamp(date: .now)], merge: true)
            try await reciprocalRef.setData(["addedAt": Timestamp(date: .now)], merge: true)
        }

        try await incomingRef.delete()
        try await sentRef.delete()
    }

    func fetchRSVPEventIDs(for userID: String) async throws -> Set<String> {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.users)
            .document(userID)
            .collection(FirestoreCollection.rsvps)
            .getDocuments()
        return Set(snapshot.documents.map(\.documentID))
    }

    func fetchEventAttendees(eventID: String) async throws -> [Person] {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.events)
            .document(eventID)
            .collection(FirestoreCollection.attendees)
            .getDocuments()

        return snapshot.documents.map { document in
            let data = document.data()
            return Person(
                id: document.documentID,
                fullName: data["fullName"] as? String ?? "Attendee",
                email: "",
                gender: data["gender"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                homeCountry: data["homeCountry"] as? String ?? "",
                currentCity: data["currentCity"] as? String ?? "",
                languages: data["languages"] as? [String] ?? [],
                role: data["role"] as? String ?? "Student",
                interests: data["interests"] as? [String] ?? [],
                profileImageDataBase64: data["profileImageDataBase64"] as? String
            )
        }
    }

    func setRSVPStatus(currentUser: UserProfile, event: EventItem, isGoing: Bool) async throws {
                let db = Firestore.firestore()
        let userRSVPRef = db
            .collection(FirestoreCollection.users)
            .document(currentUser.id)
            .collection(FirestoreCollection.rsvps)
            .document(event.id)
        let attendeeRef = db
            .collection(FirestoreCollection.events)
            .document(event.id)
            .collection(FirestoreCollection.attendees)
            .document(currentUser.id)
        if isGoing {
            try await userRSVPRef.setData([
                "eventTitle": event.title,
                "createdAt": Timestamp(date: .now)
            ], merge: true)
            try await attendeeRef.setData([
                "fullName": currentUser.fullName,
                "gender": currentUser.gender,
                "bio": currentUser.bio,
                "homeCountry": currentUser.showHomeCountry ? currentUser.homeCountry : "",
                "currentCity": currentUser.showCurrentCity ? currentUser.currentCity : "",
                "languages": currentUser.languages,
                "role": currentUser.role,
                "interests": currentUser.interests,
                "profileImageDataBase64": currentUser.profileImageDataBase64 as Any
            ], merge: true)
        } else {
            try await userRSVPRef.delete()
            try await attendeeRef.delete()
        }
    }

    func fetchMessageThreads(for userID: String) async throws -> [MessageThread] {
                let snapshot = try await Firestore.firestore()
            .collection(FirestoreCollection.threads)
            .whereField("participantIDs", arrayContains: userID)
            .limit(to: 20)
            .getDocuments()

        let mapped = snapshot.documents.map { document in
            let data = document.data()
            let timestamp = data["updatedAt"] as? Timestamp
            let participantNames = data["participantNames"] as? [String: String] ?? [:]
            let participantIDs = data["participantIDs"] as? [String] ?? []
            let otherParticipantID = participantIDs.first(where: { $0 != userID })
            let resolvedName = otherParticipantID.flatMap { participantNames[$0] } ?? data["name"] as? String ?? "Chat"
            return MessageThread(
                id: document.documentID,
                name: resolvedName,
                preview: data["preview"] as? String ?? "",
                updatedAt: timestamp?.dateValue() ?? .now,
                unreadCount: data["unreadCount"] as? Int ?? 0,
                participantIDs: participantIDs
            )
        }
        return mapped.sorted { $0.updatedAt > $1.updatedAt }
    }

    func createOrGetThread(currentUserID: String, currentUserName: String, otherPerson: Person) async throws -> MessageThread {
                let db = Firestore.firestore()
        let snapshot = try await db.collection(FirestoreCollection.threads)
            .whereField("participantIDs", arrayContains: currentUserID)
            .getDocuments()

        if let existing = snapshot.documents.first(where: {
            let ids = $0.data()["participantIDs"] as? [String] ?? []
            return ids.contains(otherPerson.id)
        }) {
            let data = existing.data()
            let timestamp = data["updatedAt"] as? Timestamp
            let participantNames = data["participantNames"] as? [String: String] ?? [:]
            return MessageThread(
                id: existing.documentID,
                name: participantNames[otherPerson.id] ?? data["name"] as? String ?? otherPerson.fullName,
                preview: data["preview"] as? String ?? "Start your conversation",
                updatedAt: timestamp?.dateValue() ?? .now,
                unreadCount: data["unreadCount"] as? Int ?? 0,
                participantIDs: [currentUserID, otherPerson.id]
            )
        }

        let threadRef = db.collection(FirestoreCollection.threads).document()
        let thread = MessageThread(
            id: threadRef.documentID,
            name: otherPerson.fullName,
            preview: "Start your conversation",
            updatedAt: .now,
            unreadCount: 0,
            participantIDs: [currentUserID, otherPerson.id]
        )

        try await threadRef.setData([
            "name": otherPerson.fullName,
            "participantIDs": [currentUserID, otherPerson.id],
            "participantNames": [
                currentUserID: currentUserName,
                otherPerson.id: otherPerson.fullName
            ],
            "preview": thread.preview,
            "updatedAt": Timestamp(date: thread.updatedAt),
            "unreadCount": 0
        ])
        return thread
    }

    func deleteThread(threadID: String, currentUserID: String) async throws {
                let db = Firestore.firestore()
        let messagesSnapshot = try await db
            .collection(FirestoreCollection.threads)
            .document(threadID)
            .collection(FirestoreCollection.messages)
            .getDocuments()

        for document in messagesSnapshot.documents {
            try await document.reference.delete()
        }

        try await db.collection(FirestoreCollection.threads).document(threadID).delete()
    }

    func listenForMessages(threadID: String, onChange: @escaping ([ChatMessage]) -> Void) -> CancellableListening {
                let listener = Firestore.firestore()
            .collection(FirestoreCollection.threads)
            .document(threadID)
            .collection(FirestoreCollection.messages)
            .order(by: "sentAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let messages: [ChatMessage] = snapshot?.documents.map { document in
                    let data = document.data()
                    let timestamp = data["sentAt"] as? Timestamp
                    return ChatMessage(
                        id: document.documentID,
                        senderID: data["senderID"] as? String ?? "",
                        senderName: data["senderName"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        sentAt: timestamp?.dateValue() ?? .now
                    )
                } ?? [ChatMessage]()
                onChange(messages)
            }
        return FirestoreListenerRegistration(listener: listener)
    }

    func sendMessage(threadID: String, senderID: String, senderName: String, text: String) async throws {
                let db = Firestore.firestore()
        let threadRef = db.collection(FirestoreCollection.threads).document(threadID)
        let messageRef = threadRef.collection(FirestoreCollection.messages).document()

        try await messageRef.setData([
            "senderID": senderID,
            "senderName": senderName,
            "text": text,
            "sentAt": Timestamp(date: .now)
        ])

        try await threadRef.setData([
            "preview": text,
            "updatedAt": Timestamp(date: .now)
        ], merge: true)
    }
}

private struct FirestoreListenerRegistration: CancellableListening {
    let listener: ListenerRegistration

    func cancel() {
        listener.remove()
    }
}
