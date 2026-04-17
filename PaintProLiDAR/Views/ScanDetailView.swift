import SwiftUI

struct ScanDetailView: View {
    let scan: RoomScanResult
    @ObservedObject var store: ScanStore
    @State private var showingSendSheet = false
    @State private var isEditing = false
    @State private var editedName: String
    @State private var editedRate: Double
    
    init(scan: RoomScanResult, store: ScanStore) {
        self.scan = scan
        self.store = store
        _editedName = State(initialValue: scan.roomName)
        _editedRate = State(initialValue: scan.customRate)
    }

    var currentBid: Double {
        scan.totalPaintableArea * editedRate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Floor Plan Visual
                FloorPlanView(scan: scan)
                    .frame(height: 200)
                    .background(Color(hex: "#1a1a1a"))
                    .cornerRadius(16)

                // Summary card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if isEditing {
                                TextField("Room Name", text: $editedName)
                                    .textFieldStyle(.plain)
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color(hex: "#2a2a2a"))
                                    .cornerRadius(8)
                            } else {
                                Text(editedName)
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            }
                            Text(scan.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Est. Bid")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(currentBid.currency)
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

                // Rate card (editable)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pricing")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack {
                        Text("Rate per sqft")
                            .foregroundColor(.gray)
                        Spacer()
                        if isEditing {
                            HStack(spacing: 4) {
                                Text("$").foregroundColor(.gray)
                                TextField("1.95", value: $editedRate, format: .number)
                                    .textFieldStyle(.plain)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                                Text("/ sqft").foregroundColor(.gray).font(.caption)
                            }
                            .padding(8)
                            .background(Color(hex: "#2a2a2a"))
                            .cornerRadius(8)
                        } else {
                            Text(String(format: "$%.2f / sqft", editedRate))
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
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
                        Text(currentBid.currency)
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
                                Text(String(format: "%.1f × %.1f ft", wall.width, wall.height))
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

                // Save edits button (when editing)
                if isEditing {
                    Button(action: saveEdits) {
                        Text("Save Changes")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#F59E0B"))
                            .cornerRadius(14)
                    }
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
            .padding(.bottom, 20)
        }
        .background(Color(hex: "#080808").ignoresSafeArea())
        .navigationTitle(editedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing { saveEdits() }
                    isEditing.toggle()
                }
                .foregroundColor(Color(hex: "#F59E0B"))
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSendSheet) {
            SendToCRMView(scan: scan, store: store)
        }
    }

    private func saveEdits() {
        var updated = scan
        updated.roomName = editedName
        updated.customRate = editedRate
        store.save(updated)
        isEditing = false
    }

    private func shareBid() {
        let text = """
PaintPro Bid — \(editedName)
Date: \(scan.date.formatted(date: .abbreviated, time: .omitted))
Paintable Area: \(scan.totalPaintableArea.sqftFormatted)
Rate: $\(String(format: "%.2f", editedRate))/sqft
Estimated Bid: \(currentBid.currency)
"""
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(av, animated: true)
    }
}

// 2D Floor Plan visualization
struct FloorPlanView: View {
    let scan: RoomScanResult
    
    // Find the room dimensions from walls
    var roomLength: Double {
        guard scan.walls.count >= 1 else { return 15 }
        return scan.walls[0].width
    }
    var roomWidth: Double {
        guard scan.walls.count >= 2 else { return 12 }
        return scan.walls[1].width
    }
    
    var body: some View {
        GeometryReader { geo in
            let padding: CGFloat = 24
            let availW = geo.size.width - padding * 2
            let availH = geo.size.height - padding * 2
            let scale = min(availW / CGFloat(roomLength), availH / CGFloat(roomWidth))
            let rectW = CGFloat(roomLength) * scale
            let rectH = CGFloat(roomWidth) * scale
            let originX = (geo.size.width - rectW) / 2
            let originY = (geo.size.height - rectH) / 2
            
            ZStack {
                // Room fill
                Rectangle()
                    .fill(Color(hex: "#F59E0B").opacity(0.08))
                    .frame(width: rectW, height: rectH)
                    .position(x: originX + rectW/2, y: originY + rectH/2)
                
                // Room outline
                Rectangle()
                    .stroke(Color(hex: "#F59E0B"), lineWidth: 2)
                    .frame(width: rectW, height: rectH)
                    .position(x: originX + rectW/2, y: originY + rectH/2)
                
                // Dimension labels
                Text(String(format: "%.0f ft", roomLength))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "#F59E0B"))
                    .position(x: originX + rectW/2, y: originY - 10)
                
                Text(String(format: "%.0f ft", roomWidth))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "#F59E0B"))
                    .rotationEffect(.degrees(-90))
                    .position(x: originX - 14, y: originY + rectH/2)
                
                // Openings (doors/windows on walls)
                ForEach(Array(scan.openings.prefix(4).enumerated()), id: \.offset) { i, opening in
                    let isHorz = i % 2 == 0
                    let openingW: CGFloat = isHorz ? CGFloat(opening.width) * scale : 4
                    let openingH: CGFloat = isHorz ? 4 : CGFloat(opening.width) * scale
                    let xPos: CGFloat = isHorz ? originX + rectW * (CGFloat(i/2) == 0 ? 0.3 : 0.7) : (i == 1 ? originX : originX + rectW)
                    let yPos: CGFloat = isHorz ? (i == 0 ? originY : originY + rectH) : originY + rectH * 0.35
                    
                    Rectangle()
                        .fill(opening.type == .door ? Color.red.opacity(0.7) : Color.blue.opacity(0.5))
                        .frame(width: openingW, height: openingH)
                        .position(x: xPos, y: yPos)
                }
                
                // Room name
                Text(scan.roomName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .position(x: originX + rectW/2, y: originY + rectH/2)
            }
        }
        .overlay(
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Rectangle().fill(Color.red.opacity(0.7)).frame(width: 12, height: 4).cornerRadius(2)
                    Text("Door").font(.system(size: 9)).foregroundColor(.gray)
                }
                HStack(spacing: 4) {
                    Rectangle().fill(Color.blue.opacity(0.5)).frame(width: 12, height: 4).cornerRadius(2)
                    Text("Window").font(.system(size: 9)).foregroundColor(.gray)
                }
            }
            .padding(6)
            .background(Color(hex: "#080808").opacity(0.7))
            .cornerRadius(6)
            .padding(8),
            alignment: .bottomTrailing
        )
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
