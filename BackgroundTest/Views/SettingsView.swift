import SwiftUI

struct SettingsView: View {
    @State private var showingResetAlert = false
    @State private var showingResetConfirmation = false
    @State private var isResetting = false
    
    var body: some View {
        NavigationView {
            List {
                // Data Management Section
                Section {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            
                            Text("Reset All Data")
                                .foregroundColor(.red)
                            
                            Spacer()
                            
                            if isResetting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isResetting)
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("This will permanently delete all your music listening statistics and play counts. This action cannot be undone.\n\nMusic tracking began on \(installDate). Only songs played after this date are included in your statistics.")
                }
                
                // App Information Section
                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build Number")
                        Spacer()
                        Text(buildNumber)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("App Information")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("Are you sure you want to delete all your music listening data? This action cannot be undone.")
        }
        .alert("Data Reset Complete", isPresented: $showingResetConfirmation) {
            Button("OK") { }
        } message: {
            Text("All your music listening data has been successfully deleted.")
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private var installDate: String {
        let appInstallDateKey = "AppInstallDate"
        if let installDate = UserDefaults.standard.object(forKey: appInstallDateKey) as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: installDate)
        }
        return "Unknown"
    }
    
    
    private func resetAllData() {
        isResetting = true
        
        Task {
            await CoreDataManager.shared.resetAllData()
            
            DispatchQueue.main.async {
                isResetting = false
                showingResetConfirmation = true
                
                // Notify other views that data was reset
                NotificationCenter.default.post(name: .playCountUpdated, object: nil)
            }
        }
    }
}


#Preview {
    SettingsView()
}