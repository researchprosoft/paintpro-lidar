import SwiftUI

struct ScanResultView: View {
    let scan: RoomScanResult
    @ObservedObject var store: ScanStore
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var roomName: String
    @State private var rate: Double

    init(scan: RoomScanResult, store: ScanStore, onDismiss: @escaping () -> Void) {
        self.scan = scan
        self.store = store
        self.onDismiss = onDismiss
        _roomName = State(initialValue: scan.roomName)
        _rate = State(initialValue: scan.customRate)
    }

    var estimatedBid: Double {
        scan.totalPaintableArea * rate
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#080808").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Success header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.green)
                            }
                            Text("Room Scanned!")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text("\(scan.walls.count) walls · \(scan.openings.count) openings detected")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)

                        // Bid result
                        VStack(spacing: 8) {
                            Text("Estimated Bid")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(estimatedBid.currency)
                                .font(.system(size: 52, weight: .black))
                                .foregroundColor(Color(hex: "#F59E0B"))
                            Text("\(scan.totalPaintableArea.sqftFormatted) @ $\(String(format: "%.2f", rate))/sqft")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color(hex: "#1a1a1a"))
                        .cornerRadius(20)

                        // Edit room name + rate
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Room Name")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                TextField("Room Name", text: $roomName)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color(hex: "#2a2a2a"))
                                    .cornerRadius(10)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Rate per sqft")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                HStack {
                                    Text("$")
                                        .foregroundColor(.gray)
                                    TextField("1.95", value: $rate, format: .number)
                                        .textFieldStyle(.plain)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(.white)
                                }
                                .padding(12)
                                .background(Color(hex: "#2a2a2a"))
                                .cornerRadius(10)
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "#1a1a1a"))
                        .cornerRadius(16)

                        // Area breakdown
                        HStack(spacing: 12) {
                            MiniStatCard(label: "Walls", value: scan.totalWallArea.sqftFormatted, color: .blue)
                            MiniStatCard(label: "Ceiling", value: scan.totalCeilingArea.sqftFormatted, color: .purple)
                            MiniStatCard(label: "Openings", value: "-\(scan.totalOpeningArea.sqftFormatted)", color: .red)
                        }

                        // Actions
                        VStack(spacing: 12) {
                            Button(action: saveAndSendToCRM) {
                                HStack(spacing: 10) {
                                    Image(systemName: "paperplane.fill")
                                    Text("Save & Send to CRM")
                                        .fontWeight(.bold)
                                }
                                .font(.system(size: 17))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#F59E0B"))
                                .cornerRadius(14)
                            }

                            Button(action: saveOnly) {
                                Text("Save Only")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: "#1a1a1a"))
                                    .cornerRadius(14)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Discard") { dismiss() }
                        .foregroundColor(.red)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func saveOnly() {
        var updated = scan
        store.save(updated)
        dismiss()
        onDismiss()
    }

    private func saveAndSendToCRM() {
        var updated = scan
        store.save(updated)
        store.sendToCRM(updated)
        dismiss()
        onDismiss()
    }
}

struct MiniStatCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.3), lineWidth: 1))
    }
}
