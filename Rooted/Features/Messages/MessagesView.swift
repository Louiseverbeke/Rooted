import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var session: AppSession
    @State private var showingNewMessage = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionHeader(title: "Messages", subtitle: "Stay close to your people and your events")

                        if !session.joinedCommunities.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Community feeds", subtitle: "Jump back into the spaces you’ve joined")

                                ForEach(session.joinedCommunities) { community in
                                    NavigationLink {
                                        CommunityDetailView(community: community)
                                            .environmentObject(session)
                                    } label: {
                                        GlassCard {
                                            HStack(spacing: 14) {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [AppTheme.Colors.highlight.opacity(0.9), AppTheme.Colors.accent.opacity(0.85)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 48, height: 48)
                                                    .overlay {
                                                        Image(systemName: "person.3.fill")
                                                            .foregroundStyle(.white)
                                                    }

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(community.name)
                                                        .font(.headline.weight(.bold))
                                                        .foregroundStyle(AppTheme.Colors.primaryText)

                                                    Text("Open feed, members, and future events")
                                                        .font(.subheadline)
                                                        .foregroundStyle(AppTheme.Colors.secondaryText)
                                                        .lineLimit(2)
                                                }

                                                Spacer()
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if session.threads.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("No messages yet")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.Colors.primaryText)

                                    Text("Start a conversation with one of your friends to see messages here.")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.Colors.secondaryText)

                                    Button {
                                        showingNewMessage = true
                                    } label: {
                                        Text("Start a Message")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(AppTheme.Colors.highlight)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }
                            }
                        } else {
                            ForEach(session.threads) { thread in
                                VStack(alignment: .leading, spacing: 10) {
                                    NavigationLink {
                                        ChatView(thread: thread, session: session)
                                    } label: {
                                        GlassCard {
                                            HStack(spacing: 14) {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [AppTheme.Colors.accentSoft, AppTheme.Colors.accent],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 52, height: 52)
                                                    .overlay {
                                                        Text(String(thread.name.prefix(1)))
                                                            .font(.headline.weight(.bold))
                                                            .foregroundStyle(.white)
                                                    }

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(thread.name)
                                                        .font(.headline.weight(.bold))
                                                        .foregroundStyle(AppTheme.Colors.primaryText)

                                                    Text(thread.preview)
                                                        .font(.subheadline)
                                                        .foregroundStyle(AppTheme.Colors.secondaryText)
                                                        .lineLimit(2)
                                                }

                                                Spacer()

                                                VStack(alignment: .trailing, spacing: 8) {
                                                    Text(thread.time)
                                                        .font(.caption.weight(.semibold))
                                                        .foregroundStyle(AppTheme.Colors.secondaryText)

                                                    if thread.unreadCount > 0 {
                                                        Text("\(thread.unreadCount)")
                                                            .font(.caption.weight(.bold))
                                                            .foregroundStyle(.white)
                                                            .frame(width: 22, height: 22)
                                                            .background(AppTheme.Colors.highlight)
                                                            .clipShape(Circle())
                                                    }
                                                }
                                            }
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    HStack {
                                        Spacer()

                                        Button(role: .destructive) {
                                            Task {
                                                await session.deleteThread(thread)
                                            }
                                        } label: {
                                            Label("Delete Conversation", systemImage: "trash")
                                                .font(.caption.weight(.semibold))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await session.reloadContent()
            }
            .onAppear {
                Task {
                    await session.reloadContent()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewMessage = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(AppTheme.Colors.highlight)
                    }
                }
            }
            .sheet(isPresented: $showingNewMessage) {
                NewMessageView()
                    .environmentObject(session)
            }
        }
    }
}

struct NewMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSession
    @State private var searchText = ""
    @State private var selectedThread: MessageThread?

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = session.errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.red)
                }

                ForEach(filteredFriends) { friend in
                    Button {
                        Task {
                            if let thread = await session.startChat(with: friend) {
                                await MainActor.run {
                                    selectedThread = thread
                                }
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(friend.fullName)
                                .font(.headline)
                            Text(friendLocation(friend))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search friends")
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if filteredFriends.isEmpty {
                    ContentUnavailableView(
                        "No friends to message",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Add friends in Discover, then start chatting here.")
                    )
                }
            }
            .navigationDestination(item: $selectedThread) { thread in
                ChatView(thread: thread, session: session)
            }
        }
    }

    private var filteredFriends: [Person] {
        guard !searchText.isEmpty else { return session.friends }
        return session.friends.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.homeCountry.localizedCaseInsensitiveContains(searchText) ||
            $0.currentCity.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func friendLocation(_ person: Person) -> String {
        let parts = [person.homeCountry, person.currentCity].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return parts.isEmpty ? "Rooted friend" : parts.joined(separator: " • ")
    }
}
