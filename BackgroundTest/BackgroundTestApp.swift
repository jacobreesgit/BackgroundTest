import SwiftUI
import CoreData

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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}