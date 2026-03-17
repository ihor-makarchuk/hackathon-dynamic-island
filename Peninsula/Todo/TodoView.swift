import SwiftUI

struct TodoView: View {
    @ObservedObject var store = TodoStore.shared
    @State private var selectedDate = Date()

    private var displayItems: [TodoItem] {
        store.items(for: selectedDate)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Date carousel
            DateCarouselView(selectedDate: $selectedDate)

            // Scrollable todo list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    ForEach(displayItems) { item in
                        TodoRowView(store: store, item: item)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            // Input field at the bottom
            TodoInputView(store: store, selectedDate: selectedDate)
        }
        .padding(.horizontal, 4)
    }
}
