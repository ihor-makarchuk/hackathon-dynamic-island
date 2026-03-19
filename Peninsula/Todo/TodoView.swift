import SwiftUI
import UniformTypeIdentifiers

enum AgentModalPhase {
    case confirming, thinking, success
}

enum DropReviewState: Equatable {
    case idle
    case loading
    case review([ClaudeTodo])
    case refining(String, [ClaudeTodo])

    static func == (lhs: DropReviewState, rhs: DropReviewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading): return true
        case (.review(let a), .review(let b)): return a.map(\.title) == b.map(\.title)
        case (.refining(let s1, _), .refining(let s2, _)): return s1 == s2
        default: return false
        }
    }
}

struct TodoView: View {
    @ObservedObject var store = TodoStore.shared
    @State private var selectedDate = Date()
    @State private var isDropTargeted: Bool = false
    @State private var glowPulse = false
    @State private var dropReviewState: DropReviewState = .idle
    @State private var refinementText: String = ""
    @State private var hasRefined: Bool = false
    @State private var toastMessage: String? = nil
    @State private var expandedItemId: UUID? = nil

    @State private var agentConfirmItem: TodoItem? = nil
    @State private var agentModalPhase: AgentModalPhase = .confirming
    @State private var createdEventURL: URL? = nil

    private var displayItems: [TodoItem] {
        store.items(for: selectedDate)
    }

    var body: some View {
        ZStack {
            // Main content switches on review state
            switch dropReviewState {
            case .idle:
                // Existing content (unchanged)
                VStack(spacing: 8) {
                    DateCarouselView(selectedDate: $selectedDate)
                    TodoInputView(store: store, selectedDate: selectedDate)
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 2) {
                            ForEach(displayItems) { item in
                                TodoRowView(
                                store: store,
                                item: item,
                                expandedItemId: $expandedItemId,
                                onToast: { showToast($0) },
                                onAgentAction: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        agentConfirmItem = item
                                        agentModalPhase = .confirming
                                    }
                                }
                            )
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, 4)

            case .loading, .refining:
                // Loading indicator
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .tint(.white)
                    Text(dropReviewState == .loading ? "Creating todos..." : "Refining...")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }

            case .review(let todos):
                // Chat review panel
                reviewPanel(todos: todos)
            }

            // Pulsing glow drop zone — visible only when a file or text is dragged over the opened notch
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                    .blur(radius: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.6), lineWidth: 6)
                            .blur(radius: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 12)
                            .blur(radius: 8)
                    )
                    .opacity(glowPulse ? 1.0 : 0.4)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: glowPulse)
                    .onAppear { glowPulse = true }
                    .onDisappear { glowPulse = false }
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            if let item = agentConfirmItem {
                agentModal(for: item)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: agentConfirmItem != nil)
        .onDrop(of: [.fileURL, .plainText], isTargeted: $isDropTargeted) { providers in
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                        guard let data = item as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                        DispatchQueue.main.async { dropReviewState = .loading }
                        Task {
                            do {
                                let todos = try await FileTodoService.shared.process(fileURL: url)
                                await MainActor.run {
                                    if todos.isEmpty {
                                        dropReviewState = .idle
                                    } else {
                                        dropReviewState = .review(todos)
                                    }
                                }
                            } catch {
                                print("[TodoView] Error processing file: \(error)")
                                await MainActor.run { dropReviewState = .idle }
                            }
                        }
                    }
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadObject(ofClass: String.self) { string, _ in
                        guard let text = string, !text.isEmpty else { return }
                        DispatchQueue.main.async { dropReviewState = .loading }
                        Task {
                            do {
                                let todos = try await FileTodoService.shared.process(text: text)
                                await MainActor.run {
                                    if todos.isEmpty {
                                        dropReviewState = .idle
                                    } else {
                                        dropReviewState = .review(todos)
                                    }
                                }
                            } catch {
                                print("[TodoView] Error processing text: \(error)")
                                await MainActor.run { dropReviewState = .idle }
                            }
                        }
                    }
                }
            }
            return true
        }
        .onReceive(NotificationCenter.default.publisher(for: .notchDidReceiveDrop)) { notification in
            guard dropReviewState == .idle else { return }  // Don't interrupt active review
            if let url = notification.userInfo?["fileURL"] as? URL {
                dropReviewState = .loading
                Task {
                    do {
                        let todos = try await FileTodoService.shared.process(fileURL: url)
                        await MainActor.run {
                            dropReviewState = todos.isEmpty ? .idle : .review(todos)
                        }
                    } catch {
                        await MainActor.run { dropReviewState = .idle }
                    }
                }
            } else if let text = notification.userInfo?["text"] as? String {
                dropReviewState = .loading
                Task {
                    do {
                        let todos = try await FileTodoService.shared.process(text: text)
                        await MainActor.run {
                            dropReviewState = todos.isEmpty ? .idle : .review(todos)
                        }
                    } catch {
                        await MainActor.run { dropReviewState = .idle }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage = toastMessage {
                Text(toastMessage)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.15)))
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: toastMessage)
        .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
        .animation(.easeInOut(duration: 0.2), value: dropReviewState)
        .task {
            await store.fetchFromServer()
        }
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMessage = nil }
        }
    }

    // MARK: - Agent Confirmation Modal

    @ViewBuilder
    private func agentModal(for item: TodoItem) -> some View {
        ZStack {
            // Solid opaque background — no transparency bleed
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 0) {
                switch agentModalPhase {
                case .confirming:
                    // Header: icon + title
                    HStack(spacing: 10) {
                        CalendarAppIcon()
                        Text("Quick Add")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 18)

                    // Account row
                    HStack(spacing: 8) {
                        Text("Account")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white.opacity(0.45))
                        Text(CalendarAgentService.shared.accountDisplayName)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                    }
                    .padding(.bottom, 16)

                    // Description label + text
                    Text("Description")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.bottom, 6)

                    Text(item.title)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 22)

                    // Buttons
                    HStack(spacing: 10) {
                        Button("Approve") {
                            store.setInProgress(id: item.id, true)
                            withAnimation(.easeInOut(duration: 0.25)) {
                                agentModalPhase = .thinking
                            }
                            Task {
                                do {
                                    // Enforce minimum 2.5 s thinking display
                                    let deadline = Date().addingTimeInterval(2.5)
                                    let url = try await CalendarAgentService.shared.createEvent(from: item)
                                    let remaining = deadline.timeIntervalSinceNow
                                    if remaining > 0 {
                                        try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                                    }

                                    await MainActor.run {
                                        createdEventURL = url
                                        // Close popup — row "Running…" badge takes over
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            agentConfirmItem = nil
                                        }
                                    }

                                    // Keep "Running…" badge visible for 6 more seconds
                                    try? await Task.sleep(nanoseconds: 6_000_000_000)

                                    await MainActor.run {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            store.markDoneByAI(id: item.id, eventURL: createdEventURL)
                                            createdEventURL = nil
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        store.setInProgress(id: item.id, false)
                                        showToast(error.localizedDescription)
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            agentConfirmItem = nil
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.55, green: 0.35, blue: 0.95)))

                        Button("Dismiss") {
                            withAnimation(.easeOut(duration: 0.2)) {
                                agentConfirmItem = nil
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                    }

                case .thinking:
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            ThinkingDotsView()
                            Text("Agent is thinking...")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.orange.opacity(0.9))
                        }
                        Spacer()
                    }

                case .success:
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            SuccessCheckmarkView()
                            Text("Event created!")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(.white)
                            if let url = createdEventURL {
                                Button(action: { NSWorkspace.shared.open(url) }) {
                                    HStack(spacing: 5) {
                                        Text("Open in Calendar")
                                            .font(.system(.caption, design: .rounded, weight: .medium))
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 9, weight: .medium))
                                    }
                                    .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.95))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(24)
        }
        .padding(8)
    }

    // MARK: - Review Panel

    @ViewBuilder
    private func reviewPanel(todos: [ClaudeTodo]) -> some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.white.opacity(0.7))
                Text("Extracted Todos")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            // Scrollable todo list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(Array(todos.enumerated()), id: \.offset) { _, todo in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(reviewPriorityColor(todo.priority))
                                .frame(width: 6, height: 6)
                            Text(todo.title)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            Spacer()
                            Text(todo.priority.capitalized)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(reviewPriorityColor(todo.priority))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            // Refinement input (only if not yet refined)
            if !hasRefined {
                HStack(spacing: 6) {
                    TextField("Refine... (e.g. 'make #2 high priority')", text: $refinementText)
                        .textFieldStyle(.plain)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
                        .onSubmit {
                            guard !refinementText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            let instruction = refinementText
                            let currentTodos = todos
                            refinementText = ""
                            hasRefined = true
                            dropReviewState = .refining(instruction, currentTodos)
                            Task {
                                do {
                                    let refined = try await FileTodoService.shared.refine(
                                        originalTodos: currentTodos,
                                        instruction: instruction
                                    )
                                    await MainActor.run {
                                        dropReviewState = refined.isEmpty ? .idle : .review(refined)
                                    }
                                } catch {
                                    print("[TodoView] Refinement error: \(error)")
                                    await MainActor.run { dropReviewState = .review(currentTodos) }
                                }
                            }
                        }
                }
                .padding(.horizontal, 8)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    // Add all todos to today's list
                    for todo in todos {
                        TodoStore.shared.add(TodoItem(
                            title: todo.title,
                            priority: FileTodoService.shared.priority(from: todo.priority),
                            dueDate: Calendar.current.startOfDay(for: Date())
                        ))
                    }
                    dropReviewState = .idle
                    hasRefined = false
                    refinementText = ""
                }) {
                    Text("Add all")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(.plain)

                Button(action: {
                    dropReviewState = .idle
                    hasRefined = false
                    refinementText = ""
                }) {
                    Text("Dismiss")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Helpers

    private func reviewPriorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "low": return .blue
        default: return .gray
        }
    }
}

// MARK: - Calendar app icon

private struct CalendarAppIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(.white)
            VStack(spacing: 0) {
                // Blue top strip (like Google Calendar)
                Rectangle()
                    .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                    .frame(height: 11)
                // Colored quadrants
                HStack(spacing: 0) {
                    Rectangle().fill(Color(red: 0.18, green: 0.80, blue: 0.44))
                    Rectangle().fill(Color(red: 0.99, green: 0.74, blue: 0.14))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 7))
            // Day number
            Text("31")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                .offset(y: 5)
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Thinking animation

private struct ThinkingDotsView: View {
    @State private var phase: Int = 0
    let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.orange)
                    .frame(width: 9, height: 9)
                    .scaleEffect(phase == index ? 1.3 : 0.65)
                    .opacity(phase == index ? 1.0 : 0.35)
                    .animation(.easeInOut(duration: 0.25), value: phase)
            }
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

// MARK: - Success checkmark

private struct SuccessCheckmarkView: View {
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 0.0

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 54))
            .foregroundColor(.green)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}
