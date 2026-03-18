import SwiftUI
import UniformTypeIdentifiers

struct TodoView: View {
    @ObservedObject var store = TodoStore.shared
    @State private var selectedDate = Date()
    @State private var isDropTargeted: Bool = false
    @State private var glowPulse = false

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
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                        guard let data = item as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                        print("[TodoView] File dropped — review flow pending")
                        _ = url
                    }
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadObject(ofClass: String.self) { string, _ in
                        guard let text = string else { return }
                        print("[TodoView] Text dropped — review flow pending")
                        _ = text
                    }
                }
            }
            return true
        }
        .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
    }
}
