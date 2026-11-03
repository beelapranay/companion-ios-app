import Foundation
import MemoryKit

/// An example "life graph" for trying the memory timeline: two weeks of notes about a student juggling a chem exam,
/// rent, café shifts, sleep, a roommate, mom, a friend and a manager. "load sample memories" saves it to the real
/// store (it replaces what's there), and previews and the demo use the same data. Dates are relative to `now`, so it
/// always ends on today. Day 6 is left quiet on purpose, and two notes are private.
enum MemorySamples {
    static func facts(now: Date = Date()) -> [MemoryFact] {
        let notes: [(daysAgo: Int, type: String, text: String, when: String, sensitive: Bool, source: String)] = [
            (13, "person", "roommate sam keeps eating their food", "", false,
             "ugh my roommate sam keeps eating my food again, like i literally labelled it"),
            (13, "theme", "money's tight this month", "", false,
             "money's really tight this month and it's stressing me out"),
            (12, "theme", "can't fall asleep before 3am", "", false,
             "i can't fall asleep before like 3am lately, my brain just won't switch off"),
            (12, "event", "chem exam on thursday", "thursday", false,
             "i have a chem exam on thursday and i haven't even started studying"),
            (11, "person", "manager priya keeps adding weekend shifts", "", false,
             "my manager priya keeps putting me on weekend shifts without asking"),
            (11, "feeling", "nervous about the chem exam", "", false,
             "honestly i'm so nervous about this exam, i feel like i'm gonna blank"),
            (10, "plan", "studying at the library after class", "this week", false,
             "i'm gonna try studying at the library after class this week, i get nothing done at home"),
            (10, "person", "mom is visiting next weekend", "next weekend", false,
             "my mom is visiting next weekend so i need to actually clean lol"),
            (9, "health", "skips meals when stressed", "", true,
             "i've been skipping meals when i get stressed, i just forget to eat"),
            (8, "event", "the chem exam went okay", "today", false,
             "the exam went okay i think? better than i expected at least"),
            (8, "person", "friend jo took them out for food after the exam", "", false,
             "my friend jo took me out for food after the exam which was really nice"),
            (7, "theme", "worried about making rent", "end of the month", false,
             "i'm worried i won't make rent at the end of the month"),
            (7, "plan", "picking up extra shifts at the café", "", false,
             "i'm gonna ask priya for extra shifts at the café, i need the money"),
            (5, "theme", "slept a bit better with their phone in the other room", "", false,
             "i left my phone in the kitchen last night and actually slept a bit better"),
            (5, "person", "sam said sorry and bought groceries", "", false,
             "sam actually said sorry and bought groceries, i was shocked"),
            (4, "preference", "walks by the river to clear their head", "", false,
             "walking by the river always clears my head"),
            (4, "person", "mom's visit was nice but tiring", "", false,
             "my mom's visit was nice but i'm so tired now, she had plans every hour"),
            (3, "feeling", "felt low after a long week", "", true,
             "i felt really low after this week, kind of numb honestly"),
            (3, "person", "priya gave them the extra shifts", "", false,
             "priya gave me the extra shifts so rent should be okay"),
            (2, "plan", "calling mom on sunday", "sunday", false,
             "i'll call my mom on sunday, i promised"),
            (1, "theme", "rent's covered this month", "", false,
             "rent's covered this month!! finally one less thing"),
            (1, "event", "jo's birthday dinner on friday", "friday", false,
             "jo's birthday dinner is on friday, i need to get her something"),
            (0, "person", "friend jo is coming by during the café shift", "tonight", false,
             "my friend jo is coming by during my shift tonight"),
            (0, "theme", "still up late most nights", "", false,
             "still up late most nights tbh but it's getting a bit better"),
        ]
        return notes.map { note in
            MemoryFact(type: note.type, text: note.text, when: note.when, sensitive: note.sensitive,
                       saidAt: min(day(note.daysAgo, now: now).addingTimeInterval(20 * 3600), now),
                       source: note.source)
        }
    }

    /// One summary per day chatted: lighter, mixed and heavier days, the heaviest around the exam and the low
    /// week. Day 6 has no chats.
    static func days(now: Date = Date()) -> [DaySummary] {
        let counts: [(daysAgo: Int, messages: Int, checkins: Int)] = [
            (13, 9, 0), (12, 11, 2), (11, 7, 1), (10, 5, 0), (9, 12, 5), (8, 8, 0), (7, 10, 3),
            (5, 6, 0), (4, 7, 0), (3, 9, 4), (2, 4, 0), (1, 6, 0), (0, 5, 1),
        ]
        return counts.map { count in
            DaySummary(day: day(count.daysAgo, now: now), messages: count.messages, checkins: count.checkins,
                       crises: 0)
        }
    }

    private static func day(_ daysAgo: Int, now: Date) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
    }
}
