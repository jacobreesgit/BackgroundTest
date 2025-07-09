import Foundation
import MediaPlayer
import BackgroundTasks
import CoreData
import Combine

class MusicTrackingManager: ObservableObject {
    static let shared = MusicTrackingManager()
    
    @Published var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @Published var currentTrack: MPMediaItem?
    @Published var playbackStartTime: Date?
    
    private let backgroundTaskIdentifier = "com.backgroundtest.monitor"
    private var musicPlayer: MPMusicPlayerController
    private var isObservingPlayback = false
    
    init() {
        musicPlayer = MPMusicPlayerController.systemMusicPlayer
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization Management
    
    func checkAuthorizationStatus() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        
        #if DEBUG
        print("📱 [AUTH] Current authorization status: \(authorizationStatusString(authorizationStatus))")
        #endif
        
        if authorizationStatus == .authorized {
            setupMusicPlayerObserver()
        }
    }
    
    func requestMusicLibraryAccess() async -> Bool {
        #if DEBUG
        print("🎵 [AUTH] Requesting music library access...")
        #endif
        
        return await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    self?.authorizationStatus = status
                    
                    #if DEBUG
                    print("🎵 [AUTH] Authorization result: \(self?.authorizationStatusString(status) ?? "unknown")")
                    #endif
                    
                    if status == .authorized {
                        self?.setupMusicPlayerObserver()
                    }
                    
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    private func authorizationStatusString(_ status: MPMediaLibraryAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }
    
    // MARK: - Music Player Observation
    
    private func setupMusicPlayerObserver() {
        guard authorizationStatus == .authorized && !isObservingPlayback else { return }
        
        #if DEBUG
        print("🎧 [OBSERVER] Setting up music player observer...")
        #endif
        
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        // Observe now playing item changes
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer,
            queue: .main
        ) { [weak self] _ in
            self?.handleNowPlayingItemChange()
        }
        
        // Observe playback state changes
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackStateChange()
        }
        
        isObservingPlayback = true
        
        // Check initial state
        handleNowPlayingItemChange()
    }
    
    private func handleNowPlayingItemChange() {
        let newItem = musicPlayer.nowPlayingItem
        
        #if DEBUG
        if let item = newItem {
            let title = item.title ?? "Unknown Title"
            let artist = item.artist ?? "Unknown Artist"
            print("🎵 [TRACK_CHANGE] Now playing: \"\(title)\" by \(artist)")
        } else {
            print("🎵 [TRACK_CHANGE] No song playing")
        }
        #endif
        
        currentTrack = newItem
        
        // Reset play tracking for new song
        if musicPlayer.playbackState == .playing {
            startPlayTracking()
        } else {
            stopPlayTracking()
        }
    }
    
    private func handlePlaybackStateChange() {
        let state = musicPlayer.playbackState
        
        #if DEBUG
        print("🎵 [STATE_CHANGE] Playback state: \(playbackStateString(state))")
        #endif
        
        switch state {
        case .playing:
            startPlayTracking()
        case .paused, .stopped, .interrupted:
            stopPlayTracking()
        default:
            break
        }
    }
    
    private func startPlayTracking() {
        guard let track = currentTrack else { return }
        
        playbackStartTime = Date()
        
        #if DEBUG
        let title = track.title ?? "Unknown Title"
        print("⏱️ [TRACKING] Started tracking: \"\(title)\"")
        #endif
        
        // Schedule background task for tracking continuation
        scheduleBackgroundTrackingTask()
        
        // Schedule a task to check if song has been played for 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.checkForPlayCountRecord()
        }
    }
    
    private func stopPlayTracking() {
        guard playbackStartTime != nil else { return }
        
        #if DEBUG
        print("⏹️ [TRACKING] Stopped tracking")
        #endif
        
        playbackStartTime = nil
    }
    
    private func checkForPlayCountRecord() {
        guard let track = currentTrack,
              let startTime = playbackStartTime,
              musicPlayer.playbackState == .playing else { return }
        
        let playDuration = Date().timeIntervalSince(startTime)
        
        if playDuration >= 30 {
            #if DEBUG
            let title = track.title ?? "Unknown Title"
            print("✅ [PLAY_COUNT] Song played for 30+ seconds: \"\(title)\"")
            #endif
            
            recordPlayCount(for: track)
            playbackStartTime = nil // Reset to avoid duplicate counting
        }
    }
    
    private func recordPlayCount(for item: MPMediaItem) {
        let title = item.title ?? "Unknown Title"
        let artist = item.artist ?? "Unknown Artist"
        let songId = String(item.persistentID)
        
        CoreDataManager.shared.recordPlayCount(
            songId: songId,
            title: title,
            artist: artist
        )
    }
    
    // MARK: - Background Task Management
    
    func registerBackgroundTask() {
        #if DEBUG
        print("🔧 [BG_TASK] Registering background task...")
        #endif
        
        let success = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleBackgroundTask(task as! BGAppRefreshTask)
        }
        
        #if DEBUG
        print(success ? "✅ [BG_TASK] Registration successful" : "❌ [BG_TASK] Registration failed")
        #endif
    }
    
    private func handleBackgroundTask(_ task: BGAppRefreshTask) {
        #if DEBUG
        print("🔥 [BG_TASK] Background task executing...")
        #endif
        
        task.expirationHandler = {
            #if DEBUG
            print("⏱️ [BG_TASK] Task expired")
            #endif
            task.setTaskCompleted(success: false)
        }
        
        // Quick check of current playback state
        let isPlaying = musicPlayer.playbackState == .playing
        let shouldContinueTracking = isPlaying && currentTrack != nil
        
        #if DEBUG
        print("🎵 [BG_TASK] Music playing: \(isPlaying), Should continue: \(shouldContinueTracking)")
        #endif
        
        if shouldContinueTracking {
            scheduleBackgroundTrackingTask()
        }
        
        task.setTaskCompleted(success: true)
    }
    
    private func scheduleBackgroundTrackingTask() {
        Task {
            // Check for pending requests to avoid duplicates
            let pendingRequests = await BGTaskScheduler.shared.pendingTaskRequests()
            let hasPendingRequest = pendingRequests.contains { $0.identifier == backgroundTaskIdentifier }
            
            if hasPendingRequest {
                #if DEBUG
                print("⚠️ [BG_SCHEDULE] Task already scheduled, skipping")
                #endif
                return
            }
            
            let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // Check every minute
            
            do {
                try BGTaskScheduler.shared.submit(request)
                #if DEBUG
                print("✅ [BG_SCHEDULE] Background task scheduled")
                #endif
            } catch {
                #if DEBUG
                print("❌ [BG_SCHEDULE] Failed to schedule: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    private func playbackStateString(_ state: MPMusicPlaybackState) -> String {
        switch state {
        case .stopped: return "Stopped"
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .interrupted: return "Interrupted"
        case .seekingForward: return "Seeking Forward"
        case .seekingBackward: return "Seeking Backward"
        @unknown default: return "Unknown"
        }
    }
    
    deinit {
        musicPlayer.endGeneratingPlaybackNotifications()
        NotificationCenter.default.removeObserver(self)
    }
}