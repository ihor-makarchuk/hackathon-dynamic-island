import SwiftUI

struct TodoDetailView: View {
    @ObservedObject var store: TodoStore
    var itemId: UUID
    @Environment(\.openURL) private var openURL

    private var item: TodoItem? {
        store.items.first { $0.id == itemId }
    }

    var body: some View {
        if let item = item {
            VStack(alignment: .leading, spacing: 0) {
                // Separator
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 8)

                VStack(alignment: .leading, spacing: 10) {
                    // Description (notes) block
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.45))
                            .textCase(.uppercase)

                        ZStack(alignment: .topLeading) {
                            if (item.notes ?? "").isEmpty {
                                Text("Add a description…")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.white.opacity(0.25))
                                    .padding(.top, 6)
                                    .padding(.leading, 6)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: Binding(
                                get: { item.notes ?? "" },
                                set: { store.update(id: itemId, notes: $0.isEmpty ? nil : $0) }
                            ))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: 52)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                    }

                    // Link block
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Link", systemImage: "link")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.45))
                            .textCase(.uppercase)

                        HStack(spacing: 6) {
                            TextField("https://…", text: Binding(
                                get: { item.link ?? "" },
                                set: { store.update(id: itemId, link: $0.isEmpty ? nil : $0) }
                            ))
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.75))

                            if let linkStr = item.link, !linkStr.isEmpty, let url = URL(string: linkStr) {
                                Button(action: { openURL(url) }) {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 11))
                                        .foregroundColor(.blue.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                                .help("Open link")
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
        }
    }
}
