import SwiftUI
import UniformTypeIdentifiers

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
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 2) {
                            ForEach(displayItems) { item in
                                TodoRowView(store: store, item: item)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    TodoInputView(store: store, selectedDate: selectedDate)
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
        .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
        .animation(.easeInOut(duration: 0.2), value: dropReviewState)
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
