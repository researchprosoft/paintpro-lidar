import SwiftUI

struct ScanDetailView: View {
    let scan: RoomScanResult
    @ObservedObject var store: ScanStore
    @State private var showingBidSheet = false
    @State private var showingSendSheet = false
    @State private var isSending = false
    @State private var sendSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Summary card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scan.roomName)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text(scan.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Est. Bid")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(scan.estimatedBid.currency)
                                .font(.title.bold())
                                .foregroundColor(Color(hex: "#F59E0B"))
                        }
                    }

                    Divider().background(Color.gray.opacity(0.3))

                    HStack(spacing: 0) {
                        AreaStat(label: "Wall Area", value: scan.totalWallArea.sqftFormatted, icon: "rectangle.portrait")
                        Divider().frame(height: 40).background(Color.gray.opacity(0.3))
                        AreaStat(label: "Ceiling", value: scan.totalCeilingArea.sqftFormatted, icon: "square.grid.2x2")
                        Divider().frame(height: 40).background(Color.gray.opacity(0.3))
                        AreaStat(label: "Paintable", value: scan.totalPaintableArea.sqftFormatted, icon: "paintbrush.fill")
                    }
                }
                .padding(16)
                .background(Color(hex: "#1a1a1a"))
                .cornerRadius(16)

                // Rate card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pricing")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack {
                        Text("Rate per sqft")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "$%.2f / sqft", scan.customRate))
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Total paintable area")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(scan.totalPaintableArea.sqftFormatted)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    Divider().background(Color.gray.opacity(0.3))
                    HStack {
                        Text("Estimated Bid")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        Spacer()
                        Text(scan.estimatedBid.currency)
                            .foregroundColor(Color(hex: "#F59E0B"))
                            .font(.title3.bold())
                    }
                }
                .padding(16)
                .background(Color(hex: "#1a1a1a"))
                .cornerRadius(16)

                // Walls breakdown
                if !scan.walls.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Walls (\(scan.walls.count))")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(scan.walls) { wall in
                            HStack {
                                Image(systemName: "rectangle.portrait")
                                    .foregroundColor(Color(hex: "#F59E0B"))
                                    .frame(width: 24)
                                Text(wall.label)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(String(format: "%.1f × %.1f m", wall.width, wall.height))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(wall.paintableArea.sqftFormatted)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(16)
                    .background(Color(hex: "#1a1a1a"))
                    .cornerRadius(16)
                }

                // Openings
                if !scan.openings.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Openings (subtracted)")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(scan.openings) { opening in
                            HStack {
                                Image(systemName: opening.type == .door ? "door.left.hand.open" : "window.casement")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                Text(opening.type.rawValue)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("-\(opening.area.sqftFormatted)")
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(16)
                    .background(Color(hex: "#1a1a1a"))
                    .cornerRadius(16)
                }

                // Actions
                VStack(spacing: 12) {
                    Button(action: { showingSendSheet = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "paperplane.fill")
                            Text("Send to PaintPro CRM")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 17))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#F59E0B"))
                        .cornerRadius(14)
                    }

                    Button(action: shareBid) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Bid")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 17))
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
        .background(Color(hex: "#080808").ignoresSafeArea())
        .navigationTitle(scan.roomName)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSendSheet) {
            SendToCRMView(scan: scan, store: store)
        }
    }

    private func shareBid() {
        let text = """
PaintPro Bid — \(scan.roomName)
Date: \(scan.date.formatted(date: .abbreviated, time: .omitted))
Paintable Area: \(scan.totalPaintableArea.sqftFormatted)
Rate: $\(String(format: "%.2f", scan.customRate))/sqft
Estimated Bid: \(scan.estimatedBid.currency)
"""
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(av, animated: true)
    }
}

struct AreaStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color(hex: "#F59E0B"))
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}
