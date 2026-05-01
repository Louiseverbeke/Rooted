import SwiftUI

struct EventsView: View {
    @EnvironmentObject private var session: AppSession
    @State private var bannerText: String?
    @State private var isShowingCreateEvent = false

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
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.Colors.success)
                                    Text(bannerText)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.Colors.primaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        SectionHeader(title: "Events", subtitle: "Culture, career, and community around you")

                        Button {
                            isShowingCreateEvent = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                Text("Create an event")
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.Colors.highlight)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }

                        if upcomingEvents.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("No upcoming events")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.Colors.primaryText)

                                    Text("Create the first upcoming event for your community right from the app.")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.Colors.secondaryText)
                                }
                            }
                        } else {
                            ForEach(upcomingEvents) { event in
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 14) {
                                        ZStack(alignment: .topTrailing) {
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [AppTheme.Colors.highlight.opacity(0.92), AppTheme.Colors.accent.opacity(0.82)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(height: 150)
                                                .overlay(alignment: .bottomLeading) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(event.title)
                                                            .font(.title3.weight(.bold))
                                                        Text(event.host)
                                                            .font(.subheadline)
                                                    }
                                                    .foregroundStyle(.white)
                                                    .padding(18)
                                                }

                                            Text("\(attendeeCount(for: event)) going")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(AppTheme.Colors.primaryText)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.white.opacity(0.88))
                                                .clipShape(Capsule())
                                                .padding(14)
                                        }

                                        Text("\(event.dateText) • \(event.place)")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.Colors.secondaryText)

                                        if event.creatorID == session.profile?.id {
                                            Text("You created this event")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(AppTheme.Colors.success)
                                        }

                                        if !event.description.isEmpty {
                                            Text(event.description)
                                                .font(.subheadline)
                                                .foregroundStyle(AppTheme.Colors.secondaryText)
                                        }

                                        FlexibleChipsView(tags: event.tags)

                                        if !session.attendees(for: event).isEmpty {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Who's going")
                                                    .font(.subheadline.weight(.bold))
                                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                                ForEach(session.attendees(for: event).prefix(4)) { attendee in
                                                    NavigationLink {
                                                        PublicPersonProfileView(person: attendee)
                                                            .environmentObject(session)
                                                    } label: {
                                                        HStack(spacing: 10) {
                                                            PersonAvatarView(
                                                                name: attendee.fullName,
                                                                profileImageDataBase64: attendee.profileImageDataBase64,
                                                                size: 34
                                                            )

                                                            VStack(alignment: .leading, spacing: 2) {
                                                                Text(attendee.fullName)
                                                                    .font(.caption.weight(.bold))
                                                                    .foregroundStyle(AppTheme.Colors.primaryText)
                                                                Text(attendee.currentCity)
                                                                    .font(.caption2)
                                                                    .foregroundStyle(AppTheme.Colors.secondaryText)
                                                            }

                                                            Spacer()
                                                        }
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                        }

                                        HStack(spacing: 12) {
                                            Button {
                                                Task {
                                                    let wasGoing = session.isGoing(to: event)
                                                    await session.toggleRSVP(for: event)
                                                    bannerText = wasGoing ? "Removed RSVP for \(event.title)." : "You're going to \(event.title)."
                                                }
                                            } label: {
                                                Text(session.isGoing(to: event) ? "Going" : "RSVP")
                                                    .font(.headline.weight(.bold))
                                                    .foregroundStyle(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 12)
                                                    .background(session.isGoing(to: event) ? AppTheme.Colors.success : AppTheme.Colors.accent)
                                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                            }

                                            Button {
                                                toggleSaved(for: event)
                                            } label: {
                                                Image(systemName: session.isEventSaved(event) ? "bookmark.fill" : "bookmark")
                                                    .font(.headline)
                                                    .foregroundStyle(AppTheme.Colors.highlight)
                                                    .frame(width: 48, height: 48)
                                                    .background(Color.white.opacity(0.78))
                                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if !pastRSVPEvents.isEmpty {
                            SectionHeader(title: "Past events", subtitle: "Events you RSVP’d to that have already ended")

                            ForEach(pastRSVPEvents) { event in
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(event.title)
                                                    .font(.headline.weight(.bold))
                                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                                Text("Hosted by \(event.host)")
                                                    .font(.subheadline)
                                                    .foregroundStyle(AppTheme.Colors.secondaryText)
                                            }

                                            Spacer()

                                            Text("Past")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(AppTheme.Colors.primaryText)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.white.opacity(0.82))
                                                .clipShape(Capsule())
                                        }

                                        Text("\(event.dateText) • \(event.place)")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppTheme.Colors.secondaryText)

                                        if !event.description.isEmpty {
                                            Text(event.description)
                                                .font(.subheadline)
                                                .foregroundStyle(AppTheme.Colors.secondaryText)
                                        }

                                        FlexibleChipsView(tags: event.tags)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingCreateEvent) {
                CreateEventView { title, host, description, place, startAt, tags in
                    Task {
                        await session.createEvent(
                            title: title,
                            host: host,
                            description: description,
                            place: place,
                            startAt: startAt,
                            tagsText: tags
                        )
                        bannerText = "Your event is live."
                    }
                }
            }
        }
    }

    private func toggleSaved(for event: EventItem) {
        if session.isEventSaved(event) {
            session.toggleSavedEvent(event)
            bannerText = "Removed \(event.title) from saved events."
        } else {
            session.toggleSavedEvent(event)
            bannerText = "Saved \(event.title) for later."
        }
    }

    private func attendeeCount(for event: EventItem) -> Int {
        let liveCount = session.attendees(for: event).count
        return max(liveCount, event.attendees)
    }

    private var upcomingEvents: [EventItem] {
        session.events
            .filter { $0.startAt >= .now }
            .sorted { $0.startAt < $1.startAt }
    }

    private var pastRSVPEvents: [EventItem] {
        session.events
            .filter { session.isGoing(to: $0) && $0.startAt < .now }
            .sorted { $0.startAt > $1.startAt }
    }
}

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSession
    @State private var title = ""
    @State private var host = ""
    @State private var description = ""
    @State private var place = ""
    @State private var tagsText = ""
    @State private var startAt = Date().addingTimeInterval(60 * 60 * 24)

    let onCreate: (String, String, String, String, Date, String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Create an event")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                inputField("Event title", text: $title)
                                inputField("Host name", text: $host)
                                multilineField("Description", text: $description)
                                inputField("Location", text: $place)

                                DatePicker("Start time", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                inputField("Tags (comma separated)", text: $tagsText)

                                Button {
                                    onCreate(title, resolvedHost, description, place, startAt, tagsText)
                                    dismiss()
                                } label: {
                                    Text("Publish Event")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(canSubmit ? AppTheme.Colors.accent : AppTheme.Colors.accent.opacity(0.45))
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }
                                .disabled(!canSubmit)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    host = session.profile?.fullName ?? ""
                }
                if place.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    place = session.profile?.currentCity ?? ""
                }
            }
        }
    }

    private var resolvedHost: String {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? (session.profile?.fullName ?? "Rooted Host") : trimmed
    }

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !place.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func inputField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)

            TextField(title, text: text)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func multilineField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.primaryText)

            TextField(title, text: text, axis: .vertical)
                .lineLimit(4...7)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
