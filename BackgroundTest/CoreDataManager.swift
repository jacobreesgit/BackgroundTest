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
    
    // MARK: - Play Count Management with Smart Deduplication
    
    func recordPlayCount(
        songId: String,
        title: String,
        artist: String,
        source: String = "realtime",
        playDate: Date = Date(),
        sessionId: String? = nil
    ) {
        persistentContainer.performBackgroundTask { context in
            do {
                // Check for duplicates using smart logic
                if self.checkForDuplicate(songId: songId, source: source, playDate: playDate, sessionId: sessionId, context: context) {
                    #if DEBUG
                    print("🚫 [DEDUP] Duplicate play detected for \"\(title)\" from \(source) - skipping")
                    #endif
                    return
                }
                
                // Get or create the play count record
                let playCountRecord = self.getOrCreatePlayCount(songId: songId, title: title, artist: artist, context: context)
                
                // Update the record
                playCountRecord.playCount += 1
                playCountRecord.lastPlayed = playDate
                playCountRecord.trackingSource = source
                
                if let sessionId = sessionId {
                    playCountRecord.playSessionId = sessionId
                }
                
                try context.save()
                
                #if DEBUG
                print("✅ [CORE_DATA] Recorded play for \"\(title)\" from \(source) - Count: \(playCountRecord.playCount)")
                #endif
                
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
    
    // MARK: - Smart Deduplication Logic
    
    private func checkForDuplicate(
        songId: String,
        source: String,
        playDate: Date,
        sessionId: String?,
        context: NSManagedObjectContext
    ) -> Bool {
        do {
            // Fetch recent plays of the same song
            let fetchRequest: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "songId == %@", songId)
            fetchRequest.fetchLimit = 1
            
            guard let existingRecord = try context.fetch(fetchRequest).first,
                  let lastPlayed = existingRecord.lastPlayed else {
                return false // No existing record, not a duplicate
            }
            
            let timeDifference = playDate.timeIntervalSince(lastPlayed)
            let lastSource = existingRecord.trackingSource ?? "unknown"
            
            // Smart deduplication rules
            switch (source, lastSource) {
            case ("realtime", "musickit"), ("musickit", "realtime"):
                // Cross-system: Use stricter timing (2 minutes)
                return timeDifference < 120
                
            case ("realtime", "realtime"):
                // Same real-time source: 30-second window (but allow quick replays)
                if timeDifference < 30 {
                    return !validateQuickReplay(timeDifference: timeDifference)
                }
                return false
                
            case ("musickit", "musickit"):
                // Same MusicKit source: 1-minute window
                return timeDifference < 60
                
            default:
                // Default: 1-minute buffer for unknown combinations
                return timeDifference < 60
            }
            
        } catch {
            #if DEBUG
            print("❌ [DEDUP] Error checking for duplicate: \(error)")
            #endif
            return false // Error occurred, allow the play to be recorded
        }
    }
    
    private func validateQuickReplay(timeDifference: TimeInterval) -> Bool {
        // Allow plays that are 10+ seconds apart as legitimate quick replays
        // (e.g., user skipped to another song, then immediately back)
        return timeDifference >= 10
    }
    
    private func getOrCreatePlayCount(
        songId: String,
        title: String,
        artist: String,
        context: NSManagedObjectContext
    ) -> PlayCount {
        do {
            let fetchRequest: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "songId == %@", songId)
            fetchRequest.fetchLimit = 1
            
            if let existingRecord = try context.fetch(fetchRequest).first {
                return existingRecord
            } else {
                // Create new record
                let newRecord = PlayCount(context: context)
                newRecord.songId = songId
                newRecord.songTitle = title
                newRecord.artistName = artist
                newRecord.playCount = 0 // Will be incremented by caller
                newRecord.firstTracked = Date()
                
                #if DEBUG
                print("📊 [CORE_DATA] Created new play count record for \"\(title)\"")
                #endif
                
                return newRecord
            }
        } catch {
            #if DEBUG
            print("❌ [CORE_DATA] Error fetching/creating play count: \(error)")
            #endif
            
            // Fallback: create new record
            let newRecord = PlayCount(context: context)
            newRecord.songId = songId
            newRecord.songTitle = title
            newRecord.artistName = artist
            newRecord.playCount = 0
            newRecord.firstTracked = Date()
            return newRecord
        }
    }
    
    // MARK: - Legacy Methods (Deprecated)
    
    @available(*, deprecated, message: "Use recordPlayCount with source parameter instead")
    func recordMusicKitPlay(songId: String, title: String, artist: String, playDate: Date, completion: @escaping () -> Void) {
        recordPlayCount(songId: songId, title: title, artist: artist, source: "musickit", playDate: playDate)
        completion()
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
    
    // MARK: - Debug Methods
    
    func fetchDebugData() -> [(title: String, artist: String, count: Int32, source: String, lastPlayed: Date?)] {
        let request: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastPlayed", ascending: false)]
        request.fetchLimit = 100
        
        do {
            let records = try viewContext.fetch(request)
            return records.map { record in
                (
                    title: record.songTitle ?? "Unknown",
                    artist: record.artistName ?? "Unknown",
                    count: record.playCount,
                    source: record.trackingSource ?? "unknown",
                    lastPlayed: record.lastPlayed
                )
            }
        } catch {
            #if DEBUG
            print("❌ [CORE_DATA] Failed to fetch debug data: \(error)")
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