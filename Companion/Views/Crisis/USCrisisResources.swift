import SwiftUI

/// US crisis resources. Fixed in code and verified by people: don't add or change numbers without review.
struct USCrisisResources: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Talk to someone now (US)")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)
            ResourceLink(title: "Call 988 Suicide & Crisis Lifeline", systemImage: "phone.fill",
                         destination: URL(string: "tel:988")!, style: .prominent)
            ResourceLink(title: "Text 988", systemImage: "message.fill",
                         destination: URL(string: "sms:988")!)
            ResourceLink(title: "Text HOME to 741741 (Crisis Text Line)", systemImage: "message",
                         destination: URL(string: "sms:741741&body=HOME")!)
            ResourceLink(title: "Emergency: call 911", systemImage: "staroflife.fill",
                         destination: URL(string: "tel:911")!, style: .emergency)
        }
    }
}
