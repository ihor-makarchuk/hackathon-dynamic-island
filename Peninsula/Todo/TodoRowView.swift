import SwiftUI

struct TodoRowView: View {
    @ObservedObject var store: TodoStore
    var item: TodoItem
    @Binding var expandedItemId: UUID?
    var onToast: ((String) -> Void)?
    @State private var isHovering = false
    @State private var isExecuting = false

    private var isExpanded: Bool { expandedItemId == item.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                // Checkbox
                Button(action: { store.toggleDone(id: item.id) }) {
                    Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isDone ? .green : .white.opacity(0.5))
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)

                // Title
                Text(item.title)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)
                    .strikethrough(item.isDone, color: .white.opacity(0.5))
                    .opacity(item.isDone ? 0.5 : 1.0)
                    .lineLimit(1)

                Spacer()

                // Agent icon — always visible for create_calendar_event items
                if !item.isDone && item.actionType == "create_calendar_event" {
                    Button(action: {
                        guard !isExecuting else { return }
                        isExecuting = true
                        Task {
                            do {
                                try await CalendarAgentService.shared.createEvent(from: item)
                                await MainActor.run {
                                    store.toggleDone(id: item.id)
                                    onToast?("Calendar event created")
                                    isExecuting = false
                                }
                            } catch {
                                await MainActor.run {
                                    onToast?(error.localizedDescription)
                                    isExecuting = false
                                }
                            }
                        }
                    }) {
                        if isExecuting {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 12, height: 12)
                        } else {
                            HStack(spacing: 4) {
                                AsyncImage(url: URL(string: "https://calendar.google.com/googlecalendar/images/favicons_2020q4/calendar_18.ico")) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue.opacity(0.8))
                                }
                                .frame(width: 12, height: 12)
                                Text("Add Event")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(.purple.opacity(0.8))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Execute with AI — create calendar event")
                }

                // Hover-visible buttons
                if isHovering {
                    // Delete
                    Button(action: { store.delete(id: item.id) }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.7))
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { expandedItemId = isExpanded ? nil : item.id } }

            // Expandable detail panel
            if isExpanded {
                TodoDetailView(store: store, itemId: item.id)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
