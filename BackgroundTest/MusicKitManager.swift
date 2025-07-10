import Foundation
import MusicKit
import CoreData
import Combine

@MainActor
class MusicKitManager: ObservableObject {
    static let shared = MusicKitManager()
    
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var subscriptionStatus: MusicSubscription? = nil
    @Published var isAuthorized = false
    @Published var isSubscribed = false
    @Published var isInitialized = false
    
    private let appInstallDateKey = "AppInstallDate"
    private var appInstallDate: Date
    
    private init() {
        // Get or set app install date
        if let existingDate = UserDefaults.standard.object(forKey: appInstallDateKey) as? Date {
            appInstallDate = existingDate
        } else {
            appInstallDate = Date()
            UserDefaults.standard.set(appInstallDate, forKey: appInstallDateKey)
        }
        
        #if DEBUG
        print("📅 [MUSIC_KIT] App install date: \(appInstallDate)")
        #endif
        
        Task {
            await initialize()
        }
    }
    
    // MARK: - Initialization
    
    private func initialize() async {
        await updateAuthorizationStatus()
        await updateSubscriptionStatus()
        isInitialized = true
        
        #if DEBUG
        print("🎵 [MUSIC_KIT] Initialization complete - Auth: \(authorizationStatus), Subscription: \(subscriptionStatus)")
        #endif
    }
    
    // MARK: - Authorization Management
    
    func requestAuthorization() async -> Bool {
        #if DEBUG
        print("🎵 [MUSIC_KIT] Requesting authorization...")
        #endif
        
        let status = await MusicAuthorization.request()
        await updateAuthorizationStatus()
        
        #if DEBUG
        print("🎵 [MUSIC_KIT] Authorization result: \(status)")
        #endif
        
        if status == .authorized {
            await updateSubscriptionStatus()
        }
        
        return status == .authorized
    }
    
    private func updateAuthorizationStatus() async {
        let status = MusicAuthorization.currentStatus
        authorizationStatus = status
        isAuthorized = status == .authorized
        
        #if DEBUG
        print("🎵 [MUSIC_KIT] Authorization status updated: \(status)")
        #endif
    }
    
    // MARK: - Subscription Management
    
    private func updateSubscriptionStatus() async {
        guard isAuthorized else {
            subscriptionStatus = nil
            isSubscribed = false
            return
        }
        
        do {
            let subscription = try await MusicSubscription.current
            subscriptionStatus = subscription
            isSubscribed = subscription.canPlayCatalogContent
            
            #if DEBUG
            print("🎵 [MUSIC_KIT] Subscription status updated: \(subscription)")
            #endif
        } catch {
            #if DEBUG
            print("❌ [MUSIC_KIT] Failed to check subscription: \(error)")
            #endif
            subscriptionStatus = nil
            isSubscribed = false
        }
    }
    
    // MARK: - Data Syncing
    
    func syncRecentPlays() async {
        guard isAuthorized && isSubscribed else {
            #if DEBUG
            print("⚠️ [MUSIC_KIT] Cannot sync - not authorized or subscribed")
            #endif
            return
        }
        
        #if DEBUG
        print("🔄 [MUSIC_KIT] Starting sync of recent plays...")
        #endif
        
        do {
            var request = MusicRecentlyPlayedRequest<Song>()
            request.limit = 100 // Fetch last 100 items
            
            let response = try await request.response()
            let filteredItems = response.items.filter { item in
                guard let playDate = item.lastPlayedDate else { return false }
                return playDate >= appInstallDate
            }
            
            #if DEBUG
            print("🎵 [MUSIC_KIT] Found \(response.items.count) recent items, \(filteredItems.count) after install date filter")
            #endif
            
            await processMusicItems(filteredItems)
            
        } catch {
            #if DEBUG
            print("❌ [MUSIC_KIT] Failed to sync recent plays: \(error)")
            #endif
        }
    }
    
    private func processMusicItems(_ items: [Song]) async {
        for item in items {
            await processSingleItem(item)
        }
        
        // Notify UI of updates
        NotificationCenter.default.post(name: .playCountUpdated, object: nil)
    }
    
    private func processSingleItem(_ item: Song) async {
        // Extract song information
        let songId = item.id.rawValue
        let title = item.title
        let artist = item.artistName
        
        #if DEBUG
        print("📊 [MUSIC_KIT] Processing: \"\(title)\" by \(artist)")
        #endif
        
        // Check if we've already processed this specific play
        if await shouldRecordPlay(songId: songId, playDate: item.lastPlayedDate) {
            await recordMusicKitPlay(songId: songId, title: title, artist: artist, playDate: item.lastPlayedDate)
        }
    }
    
    private func shouldRecordPlay(songId: String, playDate: Date?) async -> Bool {
        guard let playDate = playDate else { return false }
        
        // Only record if play date is after install date
        return playDate >= appInstallDate
    }
    
    private func recordMusicKitPlay(songId: String, title: String, artist: String, playDate: Date?) async {
        await withCheckedContinuation { continuation in
            CoreDataManager.shared.recordMusicKitPlay(
                songId: songId,
                title: title,
                artist: artist,
                playDate: playDate ?? Date()
            ) {
                continuation.resume()
            }
        }
    }
    
    // MARK: - Public Methods
    
    func checkAuthorizationAndSubscription() async {
        await updateAuthorizationStatus()
        if isAuthorized {
            await updateSubscriptionStatus()
        }
    }
    
    func refreshData() async {
        await syncRecentPlays()
    }
    
    // MARK: - Utility Methods
    
    var canUseApp: Bool {
        isAuthorized && isSubscribed
    }
    
    var statusMessage: String {
        if !isAuthorized {
            return "Apple Music access is required to use this app"
        } else if !isSubscribed {
            return "An active Apple Music subscription is required to use this app"
        } else {
            return "Ready to track your music"
        }
    }
}

// MARK: - Helper Extensions

extension Song {
    var playDate: Date? {
        return lastPlayedDate
    }
}