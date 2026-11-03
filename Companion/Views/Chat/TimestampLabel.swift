import SwiftUI

/// A quiet, centered time label between messages: "9:41 AM", "Yesterday 9:41 PM", "Tuesday 9:41 PM" or a date.
struct TimestampLabel: View {
    let date: Date

    @Environment(\.calendar) private var calendar

    var body: some View {
        label
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.bottom, Theme.Spacing.small)
    }

    private var label: Text {
        let time = Text(date, format: .dateTime.hour().minute())
        let daysAgo = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                              to: calendar.startOfDay(for: .now)).day ?? 0
        return switch daysAgo {
        case 0: time
        case 1: Text("Yesterday \(time)")
        case 2..<7: Text(date, format: .dateTime.weekday(.wide).hour().minute())
        default: Text(date, format: .dateTime.month().day().hour().minute())
        }
    }
}

#Preview {
    VStack {
        TimestampLabel(date: .now)
        TimestampLabel(date: .now.addingTimeInterval(-86_400))
        TimestampLabel(date: .now.addingTimeInterval(-3 * 86_400))
        TimestampLabel(date: .now.addingTimeInterval(-30 * 86_400))
    }
}
