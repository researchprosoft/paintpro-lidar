import SwiftUI

// Manual room measurement - works on ALL iPhones
// LiDAR auto-scan will be enabled when iOS 26 stable releases

struct RoomScannerView: View {
    @ObservedObject var store: ScanStore
    @Environment(\.dismiss) var dismiss
    @State private var roomName = ""
    @State private var wallHeight = 9.0
    @State private var roomLength = 15.0
    @State private var roomWidth = 12.0
    @State private var doorCount = 1
    @State private var windowCount = 2
    @State private var showingResult = false
    @State private var scanResult: RoomScanResult?

    var totalWallArea: Double { 2 * (roomLength + roomWidth) * wallHeight }
    var totalOpeningArea: Double { (Double(doorCount) * 21.0) + (Double(windowCount) * 15.0) }
    var paintableArea: Double { max(0, totalWallArea - totalOpeningArea) }
    var estimatedBid: Double { paintableArea * store.defaultRate }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#080808").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // LiDAR coming soon badge
                        HStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .foregroundColor(Color(hex: "#F59E0B"))
                            Text("LiDAR auto-scan coming in next update")
                                .font(.caption).foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(Color(hex: "#F59E0B").opacity(0.1))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#F59E0B").opacity(0.3), lineWidth: 1))

                        // Room name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Room Name").font(.caption).foregroundColor(.gray)
                            TextField("e.g. Master Bedroom", text: $roomName)
                                .textFieldStyle(.plain).foregroundColor(.white)
                                .padding(12).background(Color(hex: "#2a2a2a")).cornerRadius(10)
                        }
                        .padding(16).background(Color(hex: "#1a1a1a")).cornerRadius(16)

                        // Dimensions
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Room Dimensions").font(.headline).foregroundColor(.white)
                            DimSlider(label: "Length", value: $roomLength, range: 5...100, unit: "ft")
                            DimSlider(label: "Width", value: $roomWidth, range: 5...60, unit: "ft")
                            DimSlider(label: "Wall Height", value: $wallHeight, range: 7...20, unit: "ft")
                        }
                        .padding(16).background(Color(hex: "#1a1a1a")).cornerRadius(16)

                        // Openings
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Openings").font(.headline).foregroundColor(.white)
                            Text("Doors (21 sqft avg) and windows (15 sqft avg) will be subtracted")
                                .font(.caption).foregroundColor(.gray)
                            CounterRow(label: "Doors", count: $doorCount)
                            CounterRow(label: "Windows", count: $windowCount)
                        }
                        .padding(16).background(Color(hex: "#1a1a1a")).cornerRadius(16)

                        // Live bid
                        VStack(spacing: 6) {
                            Text("Estimated Bid").font(.caption).foregroundColor(.gray)
                            Text(estimatedBid.currency)
                                .font(.system(size: 52, weight: .black))
                                .foregroundColor(Color(hex: "#F59E0B"))
                            Text("\(String(format: "%.0f", paintableArea)) paintable sqft @ $\(String(format: "%.2f", store.defaultRate))/sqft")
                                .font(.caption).foregroundColor(.gray)
                            HStack(spacing: 16) {
                                MiniStat(label: "Walls", value: String(format: "%.0f sqft", totalWallArea))
                                MiniStat(label: "Openings", value: String(format: "-%.0f sqft", totalOpeningArea))
                                MiniStat(label: "Net", value: String(format: "%.0f sqft", paintableArea))
                            }.padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity).padding(20)
                        .background(Color(hex: "#1a1a1a")).cornerRadius(20)

                        Button(action: save) {
                            Text("Save Bid")
                                .font(.system(size: 18, weight: .bold)).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 18)
                                .background(Color(hex: "#F59E0B")).cornerRadius(16)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Bid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.gray)
                }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingResult) {
            if let result = scanResult {
                ScanResultView(scan: result, store: store, onDismiss: { dismiss() })
            }
        }
    }

    func save() {
        let name = roomName.isEmpty ? "Room" : roomName
        var result = RoomScanResult(roomName: name, rate: store.defaultRate)
        let sides = [roomLength, roomWidth, roomLength, roomWidth]
        for (i, w) in sides.enumerated() {
            result.walls.append(WallSurface(width: w, height: wallHeight, label: "Wall \(i+1)"))
        }
        result.ceiling = CeilingSurface(width: roomWidth, length: roomLength)
        for _ in 0..<doorCount { result.openings.append(Opening(type: .door, width: 3.0, height: 7.0)) }
        for _ in 0..<windowCount { result.openings.append(Opening(type: .window, width: 3.0, height: 5.0)) }
        store.save(result)
        scanResult = result
        showingResult = true
    }
}

struct DimSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label).foregroundColor(.gray).font(.subheadline)
                Spacer()
                Text(String(format: "%.0f \(unit)", value))
                    .foregroundColor(.white).font(.subheadline.bold())
            }
            Slider(value: $value, in: range, step: 1).tint(Color(hex: "#F59E0B"))
        }
    }
}

struct CounterRow: View {
    let label: String
    @Binding var count: Int
    var body: some View {
        HStack {
            Text(label).foregroundColor(.white)
            Spacer()
            Button(action: { if count > 0 { count -= 1 } }) {
                Image(systemName: "minus.circle.fill").foregroundColor(.gray).font(.title2)
            }
            Text("\(count)").foregroundColor(.white).font(.title3.bold()).frame(width: 36, alignment: .center)
            Button(action: { count += 1 }) {
                Image(systemName: "plus.circle.fill").foregroundColor(Color(hex: "#F59E0B")).font(.title2)
            }
        }
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.bold()).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}
