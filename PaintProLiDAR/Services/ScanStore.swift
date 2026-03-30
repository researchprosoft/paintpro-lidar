import Foundation
import Combine

class ScanStore: ObservableObject {
    @Published var scans: [RoomScanResult] = []
    @Published var defaultRate: Double = 1.95
    @Published var crmBaseURL: String = "https://paintprosoft.com"
    @Published var crmToken: String? = nil

    private let scansKey = "saved_scans"
    private let rateKey = "default_rate"
    private let urlKey = "crm_base_url"
    private let tokenKey = "crm_token"

    init() {
        load()
    }

    func save(_ scan: RoomScanResult) {
        if let index = scans.firstIndex(where: { $0.id == scan.id }) {
            scans[index] = scan
        } else {
            scans.insert(scan, at: 0)
        }
        persist()
    }

    func delete(_ scan: RoomScanResult) {
        scans.removeAll { $0.id == scan.id }
        persist()
    }

    func sendToCRM(_ scan: RoomScanResult) {
        // Fire and forget — full implementation in SendToCRMView
        let payload: [String: Any] = [
            "roomName": scan.roomName,
            "totalArea": scan.totalPaintableArea.sqFeet,
            "estimatedBid": scan.estimatedBid,
            "rate": scan.customRate,
            "date": ISO8601DateFormatter().string(from: scan.date)
        ]

        guard let url = URL(string: "\(crmBaseURL)/api/lidar-scan"),
              let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = crmToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request).resume()
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(scans) {
            UserDefaults.standard.set(encoded, forKey: scansKey)
        }
        UserDefaults.standard.set(defaultRate, forKey: rateKey)
        UserDefaults.standard.set(crmBaseURL, forKey: urlKey)
        if let token = crmToken {
            UserDefaults.standard.set(token, forKey: tokenKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: scansKey),
           let decoded = try? JSONDecoder().decode([RoomScanResult].self, from: data) {
            scans = decoded
        }
        defaultRate = UserDefaults.standard.double(forKey: rateKey).nonZero ?? 1.95
        crmBaseURL = UserDefaults.standard.string(forKey: urlKey) ?? "https://paintprosoft.com"
        crmToken = UserDefaults.standard.string(forKey: tokenKey)
    }
}

extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
