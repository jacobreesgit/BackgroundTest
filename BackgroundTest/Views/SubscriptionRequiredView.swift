import SwiftUI

struct SubscriptionRequiredView: View {
    @ObservedObject var musicKitManager = MusicKitManager.shared
    @State private var isRequestingAuth = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Header Icon
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundColor(.pink)
                .padding(.bottom, 20)
            
            // Title
            Text("Apple Music Required")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Status Message
            Text(musicKitManager.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Detailed Requirements
            VStack(alignment: .leading, spacing: 12) {
                RequirementRow(
                    isCompleted: musicKitManager.isAuthorized,
                    title: "Apple Music Access",
                    description: "Allow this app to access your Apple Music library"
                )
                
                RequirementRow(
                    isCompleted: musicKitManager.isSubscribed,
                    title: "Active Subscription",
                    description: "An active Apple Music subscription is required"
                )
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                if !musicKitManager.isAuthorized {
                    Button(action: {
                        requestAuthorization()
                    }) {
                        HStack {
                            if isRequestingAuth {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isRequestingAuth ? "Requesting Access..." : "Grant Apple Music Access")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRequestingAuth)
                    .padding(.horizontal, 40)
                }
                
                if musicKitManager.isAuthorized && !musicKitManager.isSubscribed {
                    Button(action: {
                        openAppleMusicApp()
                    }) {
                        HStack {
                            Image(systemName: "music.note")
                            Text("Open Apple Music")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
                
                Button(action: {
                    checkStatusAgain()
                }) {
                    Text("Check Status Again")
                        .fontWeight(.medium)
                        .foregroundColor(.pink)
                }
                .padding(.horizontal, 40)
            }
            .padding(.bottom, 50)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            Task {
                await musicKitManager.checkAuthorizationAndSubscription()
            }
        }
    }
    
    private func requestAuthorization() {
        isRequestingAuth = true
        Task {
            await musicKitManager.requestAuthorization()
            isRequestingAuth = false
        }
    }
    
    private func openAppleMusicApp() {
        if let url = URL(string: "music://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func checkStatusAgain() {
        Task {
            await musicKitManager.checkAuthorizationAndSubscription()
        }
    }
}

struct RequirementRow: View {
    let isCompleted: Bool
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Icon
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isCompleted ? .green : .secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    SubscriptionRequiredView()
}