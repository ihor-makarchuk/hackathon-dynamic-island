import SwiftUI
import AppKit

struct TodoRowView: View {
    @ObservedObject var store: TodoStore
    var item: TodoItem
    @Binding var expandedItemId: UUID?
    var onToast: ((String) -> Void)?
    var onAgentAction: (() -> Void)?
    @State private var isHovering = false
    @Environment(\.openURL) private var openURL

    private var isExpanded: Bool { expandedItemId == item.id }
    private var isInProgress: Bool { store.inProgressIds.contains(item.id) }

    private func sourceTag(for urlString: String?) -> String? {
        guard let str = urlString, let host = URL(string: str)?.host else { return nil }
        if host.contains("slack.com")       { return "#Slack" }
        if host.contains("mail.google.com") { return "#Gmail" }
        if host.contains("docs.google.com") { return "#Docs" }
        if host.contains("drive.google.com"){ return "#Drive" }
        if host.contains("github.com")      { return "#GitHub" }
        if host.contains("linear.app")      { return "#Linear" }
        if host.contains("notion.so")       { return "#Notion" }
        if host.contains("atlassian.net") || host.contains("jira") { return "#Jira" }
        if host.contains("figma.com")       { return "#Figma" }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                // Checkbox / in-progress spinner
                if isInProgress {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                        .tint(Color.orange)
                } else {
                    Button(action: { store.toggleDone(id: item.id) }) {
                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(item.isDone ? .green : .white.opacity(0.5))
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                }

                // Title
                Text(item.title)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)
                    .strikethrough(item.isDone, color: .white.opacity(0.5))
                    .opacity(item.isDone ? 0.5 : 1.0)
                    .lineLimit(1)

                if let tag = sourceTag(for: item.link) {
                    Text(tag)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                        .lineLimit(1)
                }

                Spacer()

                // Trailing status/action badges
                if isInProgress {
                    // Running indicator replaces the action button
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 5, height: 5)
                        Text("Running...")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.orange.opacity(0.9))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
                } else if item.isDone && item.completedByAI {
                    // AI completed badge — opens event URL or falls back to Calendar.app
                    Button(action: {
                        if let linkStr = item.link, let url = URL(string: linkStr) {
                            openURL(url)
                        } else {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9, weight: .medium))
                            Text("AI")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .help(item.link != nil ? "Open in Calendar" : "Completed by AI")
                } else if !item.isDone && item.actionType == "create_calendar_event" {
                    // Agent action button
                    Button(action: { onAgentAction?() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.blue.opacity(0.9))
                            Text("Add to Calendar")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.blue.opacity(0.9))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    .help("Execute with AI — create calendar event")
                }

                // Hover-visible delete button (not while in progress)
                if isHovering && !isInProgress {
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
