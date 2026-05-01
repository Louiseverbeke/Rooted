import Combine
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var draft = ""

    private let thread: MessageThread
    private let dataService: CommunityDataServicing
    private let currentUserID: String
    private let currentUserName: String
    private var listener: CancellableListening?

    init(
        thread: MessageThread,
        dataService: CommunityDataServicing,
        currentUserID: String,
        currentUserName: String
    ) {
        self.thread = thread
        self.dataService = dataService
        self.currentUserID = currentUserID
        self.currentUserName = currentUserName
    }

    func start() {
        listener = dataService.listenForMessages(threadID: thread.id) { [weak self] incoming in
            Task { @MainActor in
                self?.messages = incoming.map {
                    ChatMessage(
                        id: $0.id,
                        senderID: $0.senderID,
                        senderName: $0.senderName,
                        text: $0.text,
                        sentAt: $0.sentAt,
                        isFromCurrentUser: $0.senderID == self?.currentUserID
                    )
                }
            }
        }
    }

    func stop() {
        listener?.cancel()
    }

    func send() async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try await dataService.sendMessage(
                threadID: thread.id,
                senderID: currentUserID,
                senderName: currentUserName,
                text: trimmed
            )
            if !messages.contains(where: { $0.text == trimmed && $0.senderID == currentUserID }) {
                messages.append(
                    ChatMessage(
                        id: UUID().uuidString,
                        senderID: currentUserID,
                        senderName: currentUserName,
                        text: trimmed,
                        sentAt: .now,
                        isFromCurrentUser: true
                    )
                )
            }
            draft = ""
        } catch {
            print("Failed to send message: \(error)")
        }
    }
}

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    let thread: MessageThread

    init(thread: MessageThread, session: AppSession) {
        self.thread = thread
        _viewModel = StateObject(
            wrappedValue: ChatViewModel(
                thread: thread,
                dataService: session.dataService,
                currentUserID: session.profile?.id ?? "demo-user",
                currentUserName: session.profile?.fullName ?? "You"
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        HStack {
                            if message.isFromCurrentUser {
                                Spacer(minLength: 40)
                            }

                            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 6) {
                                Text(message.senderName)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.Colors.secondaryText)

                                Text(message.text)
                                    .font(.subheadline)
                                    .foregroundStyle(message.isFromCurrentUser ? .white : AppTheme.Colors.primaryText)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(message.isFromCurrentUser ? AppTheme.Colors.highlight : Color.white.opacity(0.86))
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }

                            if !message.isFromCurrentUser {
                                Spacer(minLength: 40)
                            }
                        }
                    }
                }
                .padding(16)
            }

            HStack(spacing: 12) {
                TextField("Message \(thread.name)", text: $viewModel.draft, axis: .vertical)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    Task {
                        await viewModel.send()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(AppTheme.Colors.highlight)
                }
            }
            .padding(16)
            .background(AppTheme.screenGradient.opacity(0.7))
        }
        .background(AppTheme.screenGradient.ignoresSafeArea())
        .navigationTitle(thread.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}
