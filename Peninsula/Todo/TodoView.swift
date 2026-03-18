import SwiftUI

struct TodoView: View {
    @ObservedObject var store = TodoStore.shared
    @State private var selectedDate = Date()
    @State private var isDropTargeted: Bool = false

    private var displayItems: [TodoItem] {
        store.items(for: selectedDate)
    }

    var body: some View {
        ZStack {
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

            // Drop hint overlay — visible only when a file is dragged over the opened notch
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 2, antialiased: true)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Drop to create todos")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    )
                    .padding(8)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            // File processing is handled in NotchView.dragDetector.
            // This secondary drop target just captures drops that land on
            // the opened notch content area (dragDetector may not catch these
            // when the notch is fully expanded). Route to FileTodoService directly.
            for provider in providers {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    FileTodoService.shared.process(fileURL: url)
                }
            }
            return true
        }
        .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
    }
}
