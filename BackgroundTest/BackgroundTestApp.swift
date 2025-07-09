import SwiftUI
import BackgroundTasks
import UIKit

@main
struct BackgroundTestApp: App {
    
    init() {
        #if DEBUG
        print("🏁 [APP_INIT] BackgroundTest app initializing...")
        logSystemInfo()
        logBackgroundCapabilities()
        #endif
        
        MusicTrackingManager.shared.registerBackgroundTask()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
        }
    }
    
    #if DEBUG
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
    #endif
}