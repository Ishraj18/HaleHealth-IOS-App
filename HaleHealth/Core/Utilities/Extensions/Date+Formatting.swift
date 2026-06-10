import Foundation

extension Date {
    /// A short day label such as "9 Jun", localised to en_IN.
    var hhShortDay: String { Self.shortDayFormatter.string(from: self) }

    /// "YYYY-MM-DD" — the wire format for Postgres `date` columns.
    var hhISODate: String { Self.isoDateFormatter.string(from: self) }

    var hhIsToday: Bool { Calendar.current.isDateInToday(self) }

    private static let shortDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
