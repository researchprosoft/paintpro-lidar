import SwiftUI

struct ContentView: View {
    @StateObject private var scanStore = ScanStore()
    @State private var showingScanner = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#080808").ignoresSafeArea()
                if scanStore.scans.isEmpty {
                    EmptyStateView(onScan: { showingScanner = true })
                } else {
                    ScanListView(store: scanStore, onNewScan: { showingScanner = true })
                }
            }
            .navigationTitle("PaintPro LiDAR")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill").foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !scanStore.scans.isEmpty {
                        Button(action: { showingScanner = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                Text("Scan Room")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(Color(hex: "#F59E0B")).cornerRadius(20)
                        }
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingScanner) { RoomScannerView(store: scanStore) }
        .sheet(isPresented: $showingSettings) { SettingsView(store: scanStore) }
    }
}

struct EmptyStateView: View {
    let onScan: () -> Void
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color(hex: "#F59E0B").opacity(0.15)).frame(width: 120, height: 120)
                    Image(systemName: "camera.viewfinder").font(.system(size: 52)).foregroundColor(Color(hex: "#F59E0B"))
                }
                VStack(spacing: 8) {
                    Text("Scan Your First Room").font(.title2.bold()).foregroundColor(.white)
                    Text("Point your iPhone at any room to instantly calculate paintable square footage and generate a bid.")
                        .font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 40)
                }
            }
            VStack(spacing: 12) {
                FeatureRow(icon: "cube.fill", text: "LiDAR-powered room scanning")
                FeatureRow(icon: "ruler", text: "Automatic wall & ceiling measurement")
                FeatureRow(icon: "dollarsign.circle.fill", text: "Instant paint bid generation")
                FeatureRow(icon: "paperplane.fill", text: "Send estimate to PaintPro CRM")
            }.padding(.horizontal, 40)
            Button(action: onScan) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                    Text("Start Scanning").fontWeight(.bold)
                }
                .font(.system(size: 18, weight: .semibold)).foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(Color(hex: "#F59E0B")).cornerRadius(16).padding(.horizontal, 32)
            }
            Spacer()
        }
    }
}

struct FeatureRow: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(Color(hex: "#F59E0B")).frame(width: 24)
            Text(text).font(.subheadline).foregroundColor(.gray)
            Spacer()
        }
    }
}

struct ScanListView: View {
    @ObservedObject var store: ScanStore; let onNewScan: () -> Void
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.scans) { scan in
                    NavigationLink(destination: ScanDetailView(scan: scan, store: store)) {
                        ScanCard(scan: scan)
                    }.buttonStyle(PlainButtonStyle())
                }
            }.padding()
        }
    }
}

struct ScanCard: View {
    let scan: RoomScanResult
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scan.roomName).font(.headline).foregroundColor(.white)
                    Text(scan.date, style: .date).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Text(scan.estimatedBid.currency).font(.title3.bold()).foregroundColor(Color(hex: "#F59E0B"))
            }
            Divider().background(Color.gray.opacity(0.3))
            HStack(spacing: 20) {
                StatPill(label: "Walls", value: scan.totalWallArea.sqftFormatted)
                StatPill(label: "Ceiling", value: scan.totalCeilingArea.sqftFormatted)
                StatPill(label: "Total", value: scan.totalPaintableArea.sqftFormatted)
            }
        }
        .padding(16).background(Color(hex: "#1a1a1a")).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

struct StatPill: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
            Text(label).font(.caption2).foregroundColor(.gray)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
