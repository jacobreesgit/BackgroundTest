import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        persistentContainer = NSPersistentContainer(name: "MusicTracker")
        
        // Configure the container for better performance
        persistentContainer.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        persistentContainer.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        persistentContainer.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                #if DEBUG
                print("❌ [CORE_DATA] Failed to load persistent store: \(error)")
                #endif
                fatalError("Core Data store failed to load: \(error)")
            } else {
                #if DEBUG
                print("✅ [CORE_DATA] Successfully loaded persistent store")
                #endif
            }
        }
        
        // Configure view context
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Play Count Management
    
    func recordPlayCount(songId: String, title: String, artist: String) {
        persistentContainer.performBackgroundTask { context in
            do {
                // Check if record already exists
                let fetchRequest: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "songId == %@", songId)
                fetchRequest.fetchLimit = 1
                
                let existingRecords = try context.fetch(fetchRequest)
                let currentDate = Date()
                
                let playCountRecord: PlayCount
                
                if let existingRecord = existingRecords.first {
                    // Update existing record
                    playCountRecord = existingRecord
                    playCountRecord.playCount += 1
                    playCountRecord.lastPlayed = currentDate
                    
                    #if DEBUG
                    print("📊 [CORE_DATA] Updated play count for \"\(title)\" - Count: \(playCountRecord.playCount)")
                    #endif
                } else {
                    // Create new record
                    playCountRecord = PlayCount(context: context)
                    playCountRecord.songId = songId
                    playCountRecord.songTitle = title
                    playCountRecord.artistName = artist
                    playCountRecord.playCount = 1
                    playCountRecord.lastPlayed = currentDate
                    playCountRecord.firstTracked = currentDate
                    
                    #if DEBUG
                    print("📊 [CORE_DATA] Created new play count record for \"\(title)\"")
                    #endif
                }
                
                try context.save()
                
                // Notify on main queue
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .playCountUpdated, object: nil)
                }
                
            } catch {
                #if DEBUG
                print("❌ [CORE_DATA] Failed to record play count: \(error)")
                #endif
            }
        }
    }
    
    // MARK: - MusicKit Integration
    
    func recordMusicKitPlay(songId: String, title: String, artist: String, playDate: Date, completion: @escaping () -> Void) {
        persistentContainer.performBackgroundTask { context in
            do {
                // Check if record already exists
                let fetchRequest: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "songId == %@", songId)
                fetchRequest.fetchLimit = 1
                
                let existingRecords = try context.fetch(fetchRequest)
                let playCountRecord: PlayCount
                
                if let existingRecord = existingRecords.first {
                    // Update existing record
                    playCountRecord = existingRecord
                    playCountRecord.playCount += 1
                    playCountRecord.lastPlayed = playDate
                    
                    #if DEBUG
                    print("📊 [MUSIC_KIT] Updated play count for \"\(title)\" - Count: \(playCountRecord.playCount)")
                    #endif
                } else {
                    // Create new record
                    playCountRecord = PlayCount(context: context)
                    playCountRecord.songId = songId
                    playCountRecord.songTitle = title
                    playCountRecord.artistName = artist
                    playCountRecord.playCount = 1
                    playCountRecord.lastPlayed = playDate
                    playCountRecord.firstTracked = playDate
                    
                    #if DEBUG
                    print("📊 [MUSIC_KIT] Created new play count record for \"\(title)\"")
                    #endif
                }
                
                try context.save()
                
                // Notify on main queue
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .playCountUpdated, object: nil)
                    completion()
                }
                
            } catch {
                #if DEBUG
                print("❌ [MUSIC_KIT] Failed to record play count: \(error)")
                #endif
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    func getExistingPlayCount(songId: String) -> PlayCount? {
        let fetchRequest: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "songId == %@", songId)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            #if DEBUG
            print("❌ [CORE_DATA] Failed to fetch existing play count: \(error)")
            #endif
            return nil
        }
    }
    
    // MARK: - Fetch Methods
    
    func fetchTodaysSongs() -> [PlayCount] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        return fetchSongs(from: startOfDay, to: endOfDay, limit: 10)
    }
    
    func fetchThisWeeksSongs() -> [PlayCount] {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return fetchSongs(from: weekStart, to: Date(), limit: 10)
    }
    
    func fetchRecentlyPlayedSongs(limit: Int = 50) -> [PlayCount] {
        let request: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastPlayed", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try viewContext.fetch(request)
        } catch {
            #if DEBUG
            print("❌ [CORE_DATA] Failed to fetch recently played songs: \(error)")
            #endif
            return []
        }
    }
    
    func fetchAllTimeSongs(limit: Int = 10) -> [PlayCount] {
        let request: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "playCount", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try viewContext.fetch(request)
        } catch {
            #if DEBUG
            print("❌ [CORE_DATA] Failed to fetch all-time songs: \(error)")
            #endif
            return []
        }
    }
    
    func fetchTotalStats() -> (songs: Int, plays: Int) {
        let request: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
        
        do {
            let records = try viewContext.fetch(request)
            let totalSongs = records.count
            let totalPlays = records.reduce(0) { $0 + Int($1.playCount) }
            return (songs: totalSongs, plays: totalPlays)
        } catch {
            #if DEBUG
            print("❌ [CORE_DATA] Failed to fetch total stats: \(error)")
            #endif
            return (songs: 0, plays: 0)
        }
    }
    
    private func fetchSongs(from startDate: Date, to endDate: Date, limit: Int) -> [PlayCount] {
        let request: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
        request.predicate = NSPredicate(
            format: "lastPlayed >= %@ AND lastPlayed <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "playCount", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try viewContext.fetch(request)
        } catch {
            #if DEBUG
            print("❌ [CORE_DATA] Failed to fetch songs for date range: \(error)")
            #endif
            return []
        }
    }
    
    // MARK: - Cleanup
    
    func deleteOldRecords(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        persistentContainer.performBackgroundTask { context in
            let request: NSFetchRequest<NSFetchRequestResult> = PlayCount.fetchRequest()
            request.predicate = NSPredicate(format: "lastPlayed < %@", cutoffDate as NSDate)
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeObjectIDs
            
            do {
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                let objectIDArray = result?.result as? [NSManagedObjectID]
                let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
                
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.viewContext])
                
                #if DEBUG
                print("✅ [CORE_DATA] Deleted old records older than \(days) days")
                #endif
            } catch {
                #if DEBUG
                print("❌ [CORE_DATA] Failed to delete old records: \(error)")
                #endif
            }
        }
    }
    
    func resetAllData() async {
        await withCheckedContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                let request: NSFetchRequest<NSFetchRequestResult> = PlayCount.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                deleteRequest.resultType = .resultTypeObjectIDs
                
                do {
                    let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                    let objectIDArray = result?.result as? [NSManagedObjectID]
                    let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
                    
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.viewContext])
                    
                    #if DEBUG
                    print("✅ [CORE_DATA] All data reset successfully")
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ [CORE_DATA] Failed to reset data: \(error)")
                    #endif
                }
                
                continuation.resume()
            }
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let playCountUpdated = Notification.Name("playCountUpdated")
}