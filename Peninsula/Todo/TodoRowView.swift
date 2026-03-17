import SwiftUI

struct TodoRowView: View {
    @ObservedObject var store: TodoStore
    var item: TodoItem
    @State private var isHovering = false
    @State private var isExpanded = false

    private var priorityColor: Color {
        switch item.priority {
        case .high: return .red
        case .normal: return .gray
        case .low: return .blue
        }
    }

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

                // Priority badge
                HStack(spacing: 3) {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 6, height: 6)
                    Text(item.priority.rawValue.capitalized)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(priorityColor)
                }

                // Hover-visible buttons
                if isHovering {
                    // Expand/collapse arrow
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)

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

            // Expandable detail panel
            if isExpanded {
                TodoDetailView(store: store, itemId: item.id)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
