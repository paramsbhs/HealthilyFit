import Foundation
import SwiftUI

struct FormFeedbackView: View {
    @ObservedObject var viewModel: FormViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Form")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(String(format: "%.2f", viewModel.formScore))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.green)
            }

            let topMessages = Array(viewModel.feedbackMessages.prefix(3))
            ForEach(Array(topMessages.enumerated()), id: \.offset) { _, message in
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.95))
            }
        }
        .padding(12)
        .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let vm = FormViewModel()
    return ZStack {
        Color.black
        FormFeedbackView(viewModel: vm)
            .padding()
    }
}
