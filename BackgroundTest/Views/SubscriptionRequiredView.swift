import SwiftUI

struct SubscriptionRequiredView: View {
    @ObservedObject var musicKitManager = MusicKitManager.shared
    @State private var isRequestingAuth = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header Icon
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundColor(.pink)
                .padding(.bottom, 24)
            
            // Title
            Text("Apple Music Required")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
            
            // Status Message
            Text(musicKitManager.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            
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
            }
            
            Spacer()
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
            _ = await musicKitManager.requestAuthorization()
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
    
}


#Preview {
    SubscriptionRequiredView()
}