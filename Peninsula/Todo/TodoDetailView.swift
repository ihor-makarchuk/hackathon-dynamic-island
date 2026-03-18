import SwiftUI

struct TodoDetailView: View {
    @ObservedObject var store: TodoStore
    var itemId: UUID

    private var item: TodoItem? {
        store.items.first { $0.id == itemId }
    }

    var body: some View {
        if let item = item {
            VStack(alignment: .leading, spacing: 6) {
                // Link field
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.5))
                    TextField("Link (optional)", text: Binding(
                        get: { item.link ?? "" },
                        set: { store.update(id: itemId, link: $0.isEmpty ? nil : $0) }
                    ))
                    .textFieldStyle(.plain)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                }

                // Notes field
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 2)
                    TextField("Notes (optional)", text: Binding(
                        get: { item.notes ?? "" },
                        set: { store.update(id: itemId, notes: $0.isEmpty ? nil : $0) }
                    ))
                    .textFieldStyle(.plain)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.leading, 28)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
        }
    }
}
