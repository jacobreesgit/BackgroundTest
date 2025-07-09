import SwiftUI
import CoreData
import BackgroundTasks
import MediaPlayer
import UIKit

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "MusicTracker")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ [CORE_DATA] Failed to load persistent store: \(error)")
                print("   - Error description: \(error.localizedDescription)")
                print("   - Error code: \(error.code)")
                print("   - User info: \(error.userInfo)")
                
                // In a production app, you might want to handle this more gracefully
                // For now, we'll continue with a potentially broken state
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            } else {
                print("✅ [CORE_DATA] Successfully loaded persistent store")
                print("   - Store URL: \(storeDescription.url?.absoluteString ?? "Unknown")")
                print("   - Store type: \(storeDescription.type)")
            }
        }
    }
}

@main
struct BackgroundTestApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        print("🏁 [APP_INIT] BackgroundTest app initializing...")
        logSystemInfo()
        registerBackgroundTasks()
        logBackgroundCapabilities()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    private func logSystemInfo() {
        print("📱 [SYSTEM] Device Information:")
        print("   - Model: \(UIDevice.current.model)")
        print("   - Name: \(UIDevice.current.name)")
        print("   - System: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
        print("   - Identifier: \(UIDevice.current.identifierForVendor?.uuidString ?? "Unknown")")
        
        #if targetEnvironment(simulator)
        let isSimulator = true
        #else
        let isSimulator = false
        #endif
        print("   - Running on: \(isSimulator ? "Simulator" : "Physical Device")")
        
        if let bundleId = Bundle.main.bundleIdentifier {
            print("   - Bundle ID: \(bundleId)")
        }
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            print("   - App Version: \(version)")
        }
        
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            print("   - Build: \(build)")
        }
    }
    
    private func logBackgroundCapabilities() {
        print("⚙️ [BACKGROUND] Background capabilities analysis:")
        
        let backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        print("   - Background App Refresh Status: \(backgroundRefreshStatusString(backgroundRefreshStatus))")
        
        if let backgroundModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] {
            print("   - Configured Background Modes:")
            for mode in backgroundModes {
                print("     • \(mode)")
            }
        } else {
            print("   - No background modes configured")
        }
        
        if let taskIdentifiers = Bundle.main.infoDictionary?["BGTaskSchedulerPermittedIdentifiers"] as? [String] {
            print("   - Permitted Task Identifiers:")
            for identifier in taskIdentifiers {
                print("     • \(identifier)")
            }
        } else {
            print("   - No background task identifiers configured")
        }
    }
    
    private func backgroundRefreshStatusString(_ status: UIBackgroundRefreshStatus) -> String {
        switch status {
        case .available:
            return "Available ✅"
        case .denied:
            return "Denied by user ❌"
        case .restricted:
            return "Restricted by system ⚠️"
        @unknown default:
            return "Unknown status ❓"
        }
    }
    
    private func registerBackgroundTasks() {
        let identifier = "com.backgroundtest.monitor"
        print("🔧 [REGISTRATION] Registering background task identifier: \(identifier)")
        
        let success = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            print("🔥 [EXECUTION] Background task started executing!")
            self.handleMusicTrackingBackgroundTask(task: task as! BGProcessingTask)
        }
        
        if success {
            print("✅ [REGISTRATION] Background task registration successful")
        } else {
            print("❌ [REGISTRATION] Background task registration failed")
            print("   - Possible causes:")
            print("     • Identifier not in BGTaskSchedulerPermittedIdentifiers")
            print("     • Identifier already registered")
            print("     • System error")
        }
    }
    
    private func handleMusicTrackingBackgroundTask(task: BGProcessingTask) {
        print("⏰ [BG_TASK] Music tracking background task execution started")
        print("   - Task identifier: \(task.identifier)")
        
        task.expirationHandler = {
            print("⏱️ [BG_EXPIRATION] Background task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Check current music playback state
        checkMusicPlaybackStateInBackground { isTrackingMusic in
            if isTrackingMusic {
                print("🎵 [BG_TASK] Music is being tracked - scheduling next background task")
                self.scheduleNextMusicTrackingTask()
            } else {
                print("🚫 [BG_TASK] No active music tracking - not scheduling next task")
            }
            
            // Complete the background task
            print("✅ [BG_TASK] Background task completed successfully")
            task.setTaskCompleted(success: true)
        }
    }
    
    private func checkMusicPlaybackStateInBackground(completion: @escaping (Bool) -> Void) {
        print("🔍 [BG_CHECK] Checking music playback state in background...")
        
        let musicPlayer = MPMusicPlayerController.systemMusicPlayer
        let playbackState = musicPlayer.playbackState
        
        print("🎵 [BG_CHECK] Music player state: \(playbackStateString(playbackState))")
        
        // Check if there's a currently playing item
        if let nowPlayingItem = musicPlayer.nowPlayingItem {
            let title = nowPlayingItem.title ?? "Unknown Title"
            let artist = nowPlayingItem.artist ?? "Unknown Artist"
            print("🎵 [BG_CHECK] Currently playing: \"\(title)\" by \(artist)")
            
            // Check if music is actively playing
            let isActivelyTracking = playbackState == .playing
            print("🎵 [BG_CHECK] Is actively tracking: \(isActivelyTracking)")
            
            completion(isActivelyTracking)
        } else {
            print("🚫 [BG_CHECK] No song currently playing")
            completion(false)
        }
    }
    
    private func playbackStateString(_ state: MPMusicPlaybackState) -> String {
        switch state {
        case .stopped:
            return "Stopped"
        case .playing:
            return "Playing ▶️"
        case .paused:
            return "Paused ⏸️"
        case .interrupted:
            return "Interrupted ⚠️"
        case .seekingForward:
            return "Seeking Forward ⏩"
        case .seekingBackward:
            return "Seeking Backward ⏪"
        @unknown default:
            return "Unknown State"
        }
    }
    
    private func scheduleNextMusicTrackingTask() {
        let identifier = "com.backgroundtest.monitor"
        print("📅 [BG_SCHEDULE] Scheduling next music tracking background task...")
        
        let request = BGProcessingTaskRequest(identifier: identifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30) // Check again in 30 seconds
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ [BG_SCHEDULE] Next background task scheduled successfully")
            print("   - Earliest begin date: \(request.earliestBeginDate?.description ?? "Unknown")")
        } catch {
            print("❌ [BG_SCHEDULE] Failed to schedule next background task: \(error.localizedDescription)")
        }
    }
}