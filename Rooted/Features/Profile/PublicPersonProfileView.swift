import SwiftUI

struct PublicPersonProfileView: View {
    @EnvironmentObject private var session: AppSession
    let person: Person
    @State private var bannerText: String?
    @State private var selectedThread: MessageThread?

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
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                PersonAvatarView(
                                    name: person.fullName,
                                    profileImageDataBase64: person.profileImageDataBase64,
                                    size: 82
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(person.fullName)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(AppTheme.Colors.primaryText)

                                    Text("\(person.role) • \(person.currentCity)")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.Colors.secondaryText)

                                    Text(person.homeCountry)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.Colors.highlight)
                                }
                            }

                            actionArea
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.Colors.primaryText)

                            Text(person.bio.isEmpty ? "No bio yet." : person.bio)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Languages")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.Colors.primaryText)

                            FlexibleChipsView(tags: person.languages)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Interests")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.Colors.primaryText)

                            FlexibleChipsView(tags: person.interests)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedThread) { thread in
            ChatView(thread: thread, session: session)
        }
    }

    @ViewBuilder
    private var actionArea: some View {
        if session.isFriend(person) {
            VStack(spacing: 12) {
                Button {
                    Task {
                        if let thread = await session.startChat(with: person) {
                            await MainActor.run {
                                selectedThread = thread
                            }
                        }
                    }
                } label: {
                    Text("Message")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Button {
                    Task {
                        await session.removeFriend(person)
                        bannerText = "Removed \(person.fullName) from your friends."
                    }
                } label: {
                    Text("Remove Friend")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.highlight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        } else if session.hasIncomingRequest(from: person) {
            HStack(spacing: 12) {
                Button {
                    if let request = session.incomingFriendRequests.first(where: { $0.from.id == person.id }) {
                        Task {
                            await session.respondToFriendRequest(request, accept: true)
                            bannerText = "You and \(person.fullName) are now friends."
                        }
                    }
                } label: {
                    Text("Accept")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.Colors.success)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Button {
                    if let request = session.incomingFriendRequests.first(where: { $0.from.id == person.id }) {
                        Task {
                            await session.respondToFriendRequest(request, accept: false)
                            bannerText = "Declined \(person.fullName)'s request."
                        }
                    }
                } label: {
                    Text("Decline")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        } else if session.hasSentRequest(to: person) {
            VStack(spacing: 12) {
                Text("Friend request sent")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)

                Button {
                    Task {
                        await session.cancelFriendRequest(to: person)
                        bannerText = "Cancelled your friend request to \(person.fullName)."
                    }
                } label: {
                    Text("Cancel Request")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        } else {
            Button {
                Task {
                    await session.sendFriendRequest(to: person)
                    bannerText = "Sent a friend request to \(person.fullName)."
                }
            } label: {
                Text("Send Friend Request")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.Colors.highlight)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

}
