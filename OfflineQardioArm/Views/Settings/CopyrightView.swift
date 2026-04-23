import SwiftUI

struct CopyrightView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Forked from Offline QardioArm")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            Text("© Edward Vella / Dwardu Ltd — Licensed under AGPL-3.0")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Link("github.com/dwardu-ltd/offline-qardio-app-ios",
                 destination: URL(string: "https://github.com/dwardu-ltd/offline-qardio-app-ios")!)
                .font(.caption)
        }
        .padding()
    }
}

#Preview {
    CopyrightView()
}
