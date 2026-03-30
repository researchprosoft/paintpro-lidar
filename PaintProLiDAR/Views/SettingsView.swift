import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ScanStore
    @Environment(\.dismiss) var dismiss
    @State private var rateText: String = ""
    @State private var crmURL: String = ""
    @State private var crmToken: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#080808").ignoresSafeArea()

                Form {
                    Section {
                        HStack {
                            Text("Default Rate ($/sqft)")
                                .foregroundColor(.white)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("$")
                                    .foregroundColor(.gray)
                                TextField("1.95", text: $rateText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(Color(hex: "#F59E0B"))
                                    .fontWeight(.bold)
                                    .frame(width: 60)
                            }
                        }
                    } header: {
                        Text("Pricing").foregroundColor(.gray)
                    }
                    .listRowBackground(Color(hex: "#1a1a1a"))

                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CRM Base URL").foregroundColor(.gray).font(.caption)
                            TextField("https://paintprosoft.com", text: $crmURL)
                                .foregroundColor(.white)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("API Token (optional)").foregroundColor(.gray).font(.caption)
                            SecureField("Token", text: $crmToken)
                                .foregroundColor(.white)
                        }
                    } header: {
                        Text("PaintPro CRM Connection").foregroundColor(.gray)
                    }
                    .listRowBackground(Color(hex: "#1a1a1a"))

                    Section {
                        HStack {
                            Image(systemName: "iphone.gen3")
                                .foregroundColor(Color(hex: "#F59E0B"))
                            Text("Requires iPhone 12 Pro or later with LiDAR")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("Scans stored locally on device")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } header: {
                        Text("About").foregroundColor(.gray)
                    }
                    .listRowBackground(Color(hex: "#1a1a1a"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .foregroundColor(Color(hex: "#F59E0B"))
                        .fontWeight(.bold)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                rateText = String(format: "%.2f", store.defaultRate)
                crmURL = store.crmBaseURL
                crmToken = store.crmToken ?? ""
            }
        }
    }

    private func save() {
        if let rate = Double(rateText), rate > 0 {
            store.defaultRate = rate
        }
        if !crmURL.isEmpty {
            store.crmBaseURL = crmURL
        }
        store.crmToken = crmToken.isEmpty ? nil : crmToken
        dismiss()
    }
}
