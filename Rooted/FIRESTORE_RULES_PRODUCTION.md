
```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() {
      return request.auth != null;
    }

    function isSelf(userId) {
      return signedIn() && request.auth.uid == userId;
    }

    function communityDoc(communityId) {
      return get(/databases/$(database)/documents/communities/$(communityId));
    }

    function eventDoc(eventId) {
      return get(/databases/$(database)/documents/events/$(eventId));
    }

    function threadDoc(threadId) {
      return get(/databases/$(database)/documents/threads/$(threadId));
    }

    function isCommunityCreator(communityId) {
      return signedIn() && communityDoc(communityId).data.creatorID == request.auth.uid;
    }

    function isCommunityAdmin(communityId) {
      return signedIn() &&
        (
          isCommunityCreator(communityId) ||
          get(/databases/$(database)/documents/communities/$(communityId)/communityMembers/$(request.auth.uid)).data.isAdmin == true
        );
    }

    function isCommunityMember(communityId) {
      return signedIn() &&
        exists(/databases/$(database)/documents/communities/$(communityId)/communityMembers/$(request.auth.uid));
    }

    function isThreadParticipant(threadId) {
      return signedIn() &&
        request.auth.uid in threadDoc(threadId).data.participantIDs;
    }

    match /users/{userId} {
      allow read: if signedIn();
      allow create: if isSelf(userId);
      allow update: if isSelf(userId);
      allow delete: if false;

      match /friends/{friendId} {
        allow read: if isSelf(userId);
        allow create: if isSelf(userId) ||
          (
            signedIn() &&
            request.auth.uid == friendId &&
            exists(/databases/$(database)/documents/users/$(request.auth.uid)/friendRequests/$(userId))
          );
        allow delete: if isSelf(userId) ||
          (
            signedIn() &&
            request.auth.uid == friendId &&
            exists(/databases/$(database)/documents/users/$(request.auth.uid)/friends/$(userId))
          );
        allow update: if false;
      }

      match /friendRequests/{requestId} {
        allow read: if isSelf(userId);
        allow create: if signedIn() && request.auth.uid == requestId;
        allow delete: if isSelf(userId) || (signedIn() && request.auth.uid == requestId);
        allow update: if false;
      }

      match /sentFriendRequests/{requestId} {
        allow read: if isSelf(userId);
        allow create, delete: if isSelf(userId);
        allow update: if false;
      }

      match /joinedCommunities/{communityId} {
        allow read, write: if isSelf(userId);
      }

      match /rsvps/{eventId} {
        allow read, write: if isSelf(userId);
      }
    }

    match /communities/{communityId} {
      allow read: if signedIn();
      allow create: if signedIn() &&
        request.resource.data.creatorID == request.auth.uid;
      allow update: if isCommunityAdmin(communityId);
      allow delete: if isCommunityCreator(communityId);

      match /communityMembers/{memberId} {
        allow read: if isCommunityMember(communityId) || isCommunityCreator(communityId);
        allow create, delete: if isSelf(memberId);
        allow update: if isSelf(memberId) || isCommunityCreator(communityId);
      }

      match /communityPosts/{postId} {
        allow read: if isCommunityMember(communityId) || isCommunityAdmin(communityId);
        allow create: if isCommunityMember(communityId) &&
          request.resource.data.authorID == request.auth.uid;
        allow update, delete: if false;
      }
    }

    match /events/{eventId} {
      allow read: if signedIn();
      allow create: if signedIn() &&
        request.resource.data.creatorID == request.auth.uid &&
        (
          !("communityID" in request.resource.data) ||
          request.resource.data.communityID == null ||
          isCommunityAdmin(request.resource.data.communityID)
        );
      allow update, delete: if signedIn() &&
        resource.data.creatorID == request.auth.uid;

      match /attendees/{attendeeId} {
        allow read: if signedIn();
        allow create, update, delete: if isSelf(attendeeId);
      }
    }

    match /threads/{threadId} {
      allow read: if isThreadParticipant(threadId);
      allow create: if signedIn() &&
        request.auth.uid in request.resource.data.participantIDs;
      allow update, delete: if isThreadParticipant(threadId);

      match /messages/{messageId} {
        allow read: if isThreadParticipant(threadId);
        allow create: if isThreadParticipant(threadId) &&
          request.resource.data.senderID == request.auth.uid;
        allow update, delete: if false;
      }
    }
  }
}
```
