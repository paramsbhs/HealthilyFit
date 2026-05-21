import SwiftUI

struct RepCounterView: View {
    @ObservedObject var viewModel: RepCounterViewModel

    var body: some View {
        VStack(spacing: 6) {
            Text(viewModel.selectedExercise.displayName)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            Text("Rep \(viewModel.repCount)/\(viewModel.targetReps)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Phase: \(viewModel.phase.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))

            if let completionMessage = viewModel.completionMessage {
                Text(completionMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    let vm = RepCounterViewModel()
    vm.startSet()
    return ZStack {
        Color.black
        RepCounterView(viewModel: vm)
    }
}
