# Firestore Setup

Use [firestore.seed.json](/Users/louiseverbeke/Documents/Codex/2026-04-21-i-am-making-an-app-for/Rooted/Seed/firestore.seed.json:1) as the sample data source when you populate Firebase.

## Collections

Create these top-level collections:

- `users`
- `communities`
- `events`
- `threads`

Each `threads/{threadID}` document should contain a `messages` subcollection.

## Suggested document shapes

### `users/{userID}`

```json
{
  "fullName": "Awa Konan",
  "email": "awa@example.com",
  "homeCountry": "Cote d'Ivoire",
  "currentCity": "Boston",
  "languages": ["French", "English"],
  "role": "Student",
  "interests": ["Make friends", "Women-only spaces", "Networking"],
  "onboardingCompleted": true,
  "notificationsEnabled": true,
  "fcmToken": "optional-fcm-token"
}
```

### `communities/{communityID}`

```json
{
  "name": "Francophone Women in Boston",
  "city": "Boston",
  "members": 214,
  "tags": ["French", "Women", "Networking"]
}
```

### `events/{eventID}`

```json
{
  "title": "International Women Mixer",
  "host": "Rooted Collective",
  "startAt": "Timestamp",
  "place": "Downtown Boston",
  "attendees": 54,
  "tags": ["Women", "Networking", "Safe Space"]
}
```

### `threads/{threadID}`

```json
{
  "name": "Aminata",
  "participantIDs": ["demo-user", "aminata-user"],
  "preview": "I added you to the dinner event chat.",
  "updatedAt": "Timestamp",
  "unreadCount": 2
}
```

### `threads/{threadID}/messages/{messageID}`

```json
{
  "senderID": "aminata-user",
  "senderName": "Aminata Diallo",
  "text": "Hey, I added you to the event chat.",
  "sentAt": "Timestamp"
}
```

## Notes

- `updatedAt` on a thread should be refreshed whenever a new message is sent.
- `preview` should mirror the latest message text for inbox rendering.
- `unreadCount` can be replaced later with a per-user unread map if you want more precise chat state.
- `fcmToken` should be set from the app after the user signs in and accepts notifications.
