//
//  BackgroundTestApp.swift
//  BackgroundTest
//
//  Created by Jacob Rees on 28/06/2025.
//

import SwiftUI
import BackgroundTasks
import UIKit
import CoreData

@main
struct BackgroundTestApp: App {
    init() {
        print("🏁 [APP_INIT] BackgroundTest app initializing...")
        logSystemInfo()
        registerBackgroundTasks()
        logBackgroundCapabilities()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
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
            self.handleBackgroundTask(task: task as! BGProcessingTask)
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
    
    private func handleBackgroundTask(task: BGProcessingTask) {
        print("⏰ [TASK_HANDLER] Background task execution started")
        print("   - Task identifier: \(task.identifier)")
        
        task.expirationHandler = {
            print("⏱️ [EXPIRATION] Background task expired")
            task.setTaskCompleted(success: false)
        }
        
        print("📝 [TASK_WORK] Performing background work...")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            print("✅ [TASK_COMPLETE] Background work completed successfully")
            task.setTaskCompleted(success: true)
        }
    }
}
