import SwiftUI

struct ConnectionChip: View {
    let deviceName: String
    let isConnected: Bool
    let batteryLevel: UInt8

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConnected ? Color.green : Color.secondary.opacity(0.5))
                .frame(width: 8, height: 8)
            Text(isConnected ? deviceName : "Not connected")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary)
            if isConnected {
                Text("·")
                    .foregroundStyle(.tertiary)
                Image(systemName: batterySymbol)
                    .font(.caption)
                    .foregroundStyle(batteryTint)
                Text("\(batteryLevel)%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(.background.secondary)
        )
    }

    private var batterySymbol: String {
        switch batteryLevel {
        case 0..<15: return "battery.0"
        case 15..<40: return "battery.25"
        case 40..<65: return "battery.50"
        case 65..<90: return "battery.75"
        default: return "battery.100"
        }
    }

    private var batteryTint: Color {
        batteryLevel < 25 ? .red : .secondary
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        ConnectionChip(deviceName: "QardioArm", isConnected: true, batteryLevel: 92)
        ConnectionChip(deviceName: "QardioArm", isConnected: true, batteryLevel: 18)
        ConnectionChip(deviceName: "QardioArm", isConnected: false, batteryLevel: 0)
    }
    .padding()
}
