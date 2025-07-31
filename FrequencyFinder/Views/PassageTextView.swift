import SwiftUI

struct PassageTextView: View {
    let passage: ReadingPassage

    // As per AC2.2, though the model doesn't have tags, we can add a placeholder.
    // For now, I will omit this as the data model doesn't support it.
    // let skillFocusTags: [String] = ["Intonation", "Pacing"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(passage.title)
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(passage.text)
                    .font(.body)
                    .lineSpacing(4) // AC2.1 suggests 1.5 line spacing. .body font size is ~17pt, so 17*0.5 = 8.5. Let's use a value that looks good.
                    .multilineTextAlignment(.leading)
            }
        }
    }
}
