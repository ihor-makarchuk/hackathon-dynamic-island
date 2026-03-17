import SwiftUI

struct DateCarouselView: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current

    private var dayLabel: String {
        if calendar.isDateInToday(selectedDate) { return "Today" }
        if calendar.isDateInYesterday(selectedDate) { return "Yesterday" }
        if calendar.isDateInTomorrow(selectedDate) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        HStack {
            Button(action: { selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)

            Text(dayLabel)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(minWidth: 120)

            Button(action: { selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
