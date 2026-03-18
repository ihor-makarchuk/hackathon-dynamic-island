import SwiftUI

struct TodoCounterBadge: View {
    @ObservedObject var store = TodoStore.shared
    var notchHeight: CGFloat

    private var count: Int {
        store.incompleteCount(for: Date())
    }

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.system(size: notchHeight * 0.45, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .frame(height: notchHeight)
        }
    }
}
