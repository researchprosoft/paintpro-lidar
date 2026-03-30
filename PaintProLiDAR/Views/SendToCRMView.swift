import SwiftUI

struct SendToCRMView: View {
    let scan: RoomScanResult
    @ObservedObject var store: ScanStore
    @Environment(\.dismiss) var dismiss
    @State private var clientName = ""
    @State private var clientPhone = ""
    @State private var clientEmail = ""
    @State private var notes = ""
    @State private var isSending = false
    @State private var didSend = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#080808").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Bid summary
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(scan.roomName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(scan.totalPaintableArea.sqftFormatted)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(scan.estimatedBid.currency)
                                .font(.title2.bold())
                                .foregroundColor(Color(hex: "#F59E0B"))
                        }
                        .padding(16)
                        .background(Color(hex: "#1a1a1a"))
                        .cornerRadius(16)

                        // Client info
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Client Information")
                                .font(.headline)
                                .foregroundColor(.white)

                            CRMField(label: "Client Name", placeholder: "John Smith", text: $clientName, keyboardType: .default)
                            CRMField(label: "Phone", placeholder: "(480) 555-0100", text: $clientPhone, keyboardType: .phonePad)
                            CRMField(label: "Email", placeholder: "john@example.com", text: $clientEmail, keyboardType: .emailAddress)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                TextEditor(text: $notes)
                                    .frame(height: 80)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color(hex: "#2a2a2a"))
                                    .cornerRadius(10)
                                    .scrollContentBackground(.hidden)
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "#1a1a1a"))
                        .cornerRadius(16)

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        }

                        if didSend {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Sent to PaintPro CRM!")
                                    .foregroundColor(.green)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }

                        Button(action: sendToCRM) {
                            HStack(spacing: 10) {
                                if isSending {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                }
                                Text(isSending ? "Sending..." : "Send to CRM")
                                    .fontWeight(.bold)
                            }
                            .font(.system(size: 17))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isSending ? Color(hex: "#F59E0B").opacity(0.6) : Color(hex: "#F59E0B"))
                            .cornerRadius(14)
                        }
                        .disabled(isSending || didSend)
                    }
                    .padding()
                }
            }
            .navigationTitle("Send to CRM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gray)
                }
                if didSend {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .foregroundColor(Color(hex: "#F59E0B"))
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func sendToCRM() {
        isSending = true
        errorMessage = nil

        let payload: [String: Any] = [
            "roomName": scan.roomName,
            "totalArea": scan.totalPaintableArea.sqFeet,
            "estimatedBid": scan.estimatedBid,
            "rate": scan.customRate,
            "clientName": clientName,
            "clientPhone": clientPhone,
            "clientEmail": clientEmail,
            "notes": notes,
            "date": ISO8601DateFormatter().string(from: scan.date)
        ]

        guard let url = URL(string: "\(store.crmBaseURL)/api/lidar-scan"),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            isSending = false
            errorMessage = "Invalid CRM URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = store.crmToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isSending = false
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    didSend = true
                }
            }
        }.resume()
    }
}

struct CRMField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .keyboardType(keyboardType)
                .foregroundColor(.white)
                .padding(12)
                .background(Color(hex: "#2a2a2a"))
                .cornerRadius(10)
        }
    }
}
