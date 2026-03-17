import SwiftUI

struct TodoInputView: View {
    @ObservedObject var store: TodoStore
    var selectedDate: Date
    @State private var text: String = ""

    var body: some View {
        TextField("Add a todo...", text: $text)
            .textFieldStyle(.plain)
            .font(.system(.body, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .cornerRadius(8)
            .onSubmit {
                let trimmed = text.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }

                let (title, priority) = parsePriority(from: trimmed)
                guard !title.isEmpty else { return }

                let item = TodoItem(
                    title: title,
                    priority: priority,
                    dueDate: selectedDate
                )
                store.add(item)
                text = ""
            }
    }

    /// Parse priority prefix: `!` = high, `!!` = low, none = normal
    private func parsePriority(from input: String) -> (String, Priority) {
        if input.hasPrefix("!! ") {
            return (String(input.dropFirst(3)).trimmingCharacters(in: .whitespaces), .low)
        } else if input.hasPrefix("! ") {
            return (String(input.dropFirst(2)).trimmingCharacters(in: .whitespaces), .high)
        }
        return (input, .normal)
    }
}
