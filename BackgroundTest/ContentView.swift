import SwiftUI
import MediaPlayer
import CoreData

struct ContentView: View {
    @State private var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @State private var isObserverSetup = false
    @State private var playCountTimer: Timer?
    @State private var currentTrackingItem: MPMediaItem?
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "music.note")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 50))
            
            Text("Music Library Access")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Current Status: \(statusDescription)")
                .font(.body)
                .foregroundColor(statusColor)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Grant Music Access") {
                requestMusicLibraryAccess()
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
            
            if authorizationStatus == .authorized {
                Button("Test Library Access") {
                    testMusicLibraryAccess()
                }
                .buttonStyle(.bordered)
                .font(.headline)
                
                Button("Show Stats") {
                    showPlayCountStatistics()
                }
                .buttonStyle(.bordered)
                .font(.headline)
            }
        }
        .padding()
        .onAppear {
            checkCurrentAuthorizationStatus()
        }
    }
    
    private var statusDescription: String {
        switch authorizationStatus {
        case .authorized:
            return "Authorized ✅"
        case .denied:
            return "Denied ❌"
        case .restricted:
            return "Restricted ⚠️"
        case .notDetermined:
            return "Not Determined ❓"
        @unknown default:
            return "Unknown Status"
        }
    }
    
    private var statusColor: Color {
        switch authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .restricted:
            return .orange
        case .notDetermined:
            return .secondary
        @unknown default:
            return .secondary
        }
    }
    
    private func checkCurrentAuthorizationStatus() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        print("📱 [MUSIC_ACCESS] Current authorization status: \(logStatusDescription(authorizationStatus))")
        
        if authorizationStatus == .authorized && !isObserverSetup {
            setupMusicPlayerObserver()
        }
    }
    
    private func requestMusicLibraryAccess() {
        print("🎵 [MUSIC_ACCESS] Requesting music library access...")
        
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                print("🎵 [MUSIC_ACCESS] Authorization result: \(self.logStatusDescription(status))")
                
                if status == .authorized && !self.isObserverSetup {
                    self.setupMusicPlayerObserver()
                }
            }
        }
    }
    
    private func logStatusDescription(_ status: MPMediaLibraryAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Authorized - Full access to music library granted"
        case .denied:
            return "Denied - User denied access to music library"
        case .restricted:
            return "Restricted - Access restricted by system policies"
        case .notDetermined:
            return "Not Determined - User hasn't been asked for permission yet"
        @unknown default:
            return "Unknown - Unrecognized authorization status"
        }
    }
    
    private func testMusicLibraryAccess() {
        guard authorizationStatus == .authorized else {
            print("❌ [MUSIC_LIBRARY] Cannot access music library - insufficient permissions")
            return
        }
        
        print("🎵 [MUSIC_LIBRARY] Testing music library access...")
        
        let songsQuery = MPMediaQuery.songs()
        guard let songs = songsQuery.items else {
            print("❌ [MUSIC_LIBRARY] Failed to fetch songs from library")
            return
        }
        
        print("📊 [MUSIC_LIBRARY] Total songs in library: \(songs.count)")
        
        if songs.isEmpty {
            print("📭 [MUSIC_LIBRARY] No songs found in music library")
            return
        }
        
        let firstFiveSongs = Array(songs.prefix(5))
        print("🎶 [MUSIC_LIBRARY] First \(firstFiveSongs.count) songs:")
        
        for (index, song) in firstFiveSongs.enumerated() {
            let title = song.title ?? "Unknown Title"
            let artist = song.artist ?? "Unknown Artist"
            print("   \(index + 1). \"\(title)\" by \(artist)")
        }
        
        print("✅ [MUSIC_LIBRARY] Music library access test completed successfully")
    }
    
    private func setupMusicPlayerObserver() {
        guard !isObserverSetup else {
            print("⚠️ [MUSIC_PLAYER] Observer already setup, skipping")
            return
        }
        
        print("🎧 [MUSIC_PLAYER] Setting up music player observer...")
        
        let musicPlayer = MPMusicPlayerController.systemMusicPlayer
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer,
            queue: .main
        ) { _ in
            self.handleNowPlayingItemChange()
        }
        
        isObserverSetup = true
        print("✅ [MUSIC_PLAYER] Music player observer setup completed")
    }
    
    private func handleNowPlayingItemChange() {
        let musicPlayer = MPMusicPlayerController.systemMusicPlayer
        
        // Cancel existing timer if there was a previous song being tracked
        if let timer = playCountTimer {
            timer.invalidate()
            
            if let previousItem = currentTrackingItem {
                let previousTitle = previousItem.title ?? "Unknown Title"
                let previousArtist = previousItem.artist ?? "Unknown Artist"
                print("⏭️ [PLAY_COUNT] Song skipped before 30 seconds: \"\(previousTitle)\" by \(previousArtist)")
            }
        }
        
        guard let nowPlayingItem = musicPlayer.nowPlayingItem else {
            print("🎵 [NOW_PLAYING] No song currently playing")
            currentTrackingItem = nil
            playCountTimer = nil
            return
        }
        
        let title = nowPlayingItem.title ?? "Unknown Title"
        let artist = nowPlayingItem.artist ?? "Unknown Artist"
        
        print("🎵 [NOW_PLAYING] Song changed: \"\(title)\" by \(artist)")
        
        // Start tracking this new song
        startPlayCountTimer(for: nowPlayingItem)
    }
    
    private func startPlayCountTimer(for item: MPMediaItem) {
        currentTrackingItem = item
        
        let title = item.title ?? "Unknown Title"
        let artist = item.artist ?? "Unknown Artist"
        
        print("⏱️ [PLAY_COUNT] Starting 30-second timer for: \"\(title)\" by \(artist)")
        
        playCountTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            self.recordPlayCount(for: item)
        }
    }
    
    private func recordPlayCount(for item: MPMediaItem) {
        let title = item.title ?? "Unknown Title"
        let artist = item.artist ?? "Unknown Artist"
        let songId = item.persistentID
        
        print("✅ [PLAY_COUNT] Song played for 30+ seconds - counting as play: \"\(title)\" by \(artist)")
        
        // Save to Core Data
        savePlayCountToCoreData(songId: songId, title: title, artist: artist)
        
        // Clear the timer and tracking item
        playCountTimer = nil
        currentTrackingItem = nil
    }
    
    private func savePlayCountToCoreData(songId: UInt64, title: String, artist: String) {
        let context = viewContext
        
        do {
            // Check if a record already exists for this song
            let fetchRequest: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "songId == %@", String(songId))
            fetchRequest.fetchLimit = 1
            
            let existingRecords = try context.fetch(fetchRequest)
            
            let playCountRecord: PlayCount
            let currentDate = Date()
            
            if let existingRecord = existingRecords.first {
                // Update existing record
                playCountRecord = existingRecord
                playCountRecord.playCount += 1
                playCountRecord.lastPlayed = currentDate
                
                print("📊 [CORE_DATA] Updated existing record for \"\(title)\" - Play count: \(playCountRecord.playCount)")
            } else {
                // Create new record
                playCountRecord = PlayCount(context: context)
                playCountRecord.songId = String(songId)
                playCountRecord.songTitle = title
                playCountRecord.artistName = artist
                playCountRecord.playCount = 1
                playCountRecord.lastPlayed = currentDate
                playCountRecord.firstTracked = currentDate
                
                print("📊 [CORE_DATA] Created new record for \"\(title)\" - First play tracked")
            }
            
            // Save the context
            try context.save()
            print("✅ [CORE_DATA] Successfully saved play count for \"\(title)\" by \(artist)")
            
        } catch {
            print("❌ [CORE_DATA] Failed to save play count for \"\(title)\" by \(artist)")
            print("   - Error: \(error.localizedDescription)")
            
            if let nsError = error as NSError? {
                print("   - Error code: \(nsError.code)")
                print("   - Error domain: \(nsError.domain)")
                print("   - User info: \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Play Count Statistics Functions
    
    private func showPlayCountStatistics() {
        print("📊 [STATISTICS] Generating play count statistics...")
        
        // 1. Total play counts for all songs
        let totalPlays = getTotalPlayCounts()
        
        // 2. Most played songs (top 10)
        let mostPlayedSongs = getMostPlayedSongs(limit: 10)
        
        // 3. Songs played today
        let songsPlayedToday = getSongsPlayedToday()
        
        // 4. Play counts for last 7 days
        let lastWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let lastWeekPlays = getPlayCountsForDateRange(startDate: lastWeekStart, endDate: Date())
        
        // Display statistics
        displayStatistics(
            totalPlays: totalPlays,
            mostPlayedSongs: mostPlayedSongs,
            songsPlayedToday: songsPlayedToday,
            lastWeekPlays: lastWeekPlays
        )
    }
    
    private func getTotalPlayCounts() -> (totalSongs: Int, totalPlays: Int) {
        let context = viewContext
        
        do {
            let fetchRequest: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
            let records = try context.fetch(fetchRequest)
            
            let totalSongs = records.count
            let totalPlays = records.reduce(0) { $0 + Int($1.playCount) }
            
            return (totalSongs: totalSongs, totalPlays: totalPlays)
        } catch {
            print("❌ [STATISTICS] Failed to fetch total play counts: \(error.localizedDescription)")
            return (totalSongs: 0, totalPlays: 0)
        }
    }
    
    private func getMostPlayedSongs(limit: Int) -> [PlayCount] {
        let context = viewContext
        
        do {
            let fetchRequest: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "playCount", ascending: false)]
            fetchRequest.fetchLimit = limit
            
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ [STATISTICS] Failed to fetch most played songs: \(error.localizedDescription)")
            return []
        }
    }
    
    private func getPlayCountsForDateRange(startDate: Date, endDate: Date) -> [PlayCount] {
        let context = viewContext
        
        do {
            let fetchRequest: NSFetchRequest<PlayCount> = PlayCount.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "lastPlayed >= %@ AND lastPlayed <= %@",
                startDate as NSDate,
                endDate as NSDate
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastPlayed", ascending: false)]
            
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ [STATISTICS] Failed to fetch play counts for date range: \(error.localizedDescription)")
            return []
        }
    }
    
    private func getSongsPlayedToday() -> [PlayCount] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        return getPlayCountsForDateRange(startDate: startOfDay, endDate: endOfDay)
    }
    
    private func displayStatistics(totalPlays: (totalSongs: Int, totalPlays: Int), mostPlayedSongs: [PlayCount], songsPlayedToday: [PlayCount], lastWeekPlays: [PlayCount]) {
        print("\n" + String(repeating: "=", count: 60))
        print("📊 MUSIC TRACKING STATISTICS")
        print(String(repeating: "=", count: 60))
        
        // Total statistics
        print("\n📈 OVERALL STATISTICS:")
        print("   • Total unique songs tracked: \(totalPlays.totalSongs)")
        print("   • Total plays recorded: \(totalPlays.totalPlays)")
        
        // Most played songs
        print("\n🏆 TOP \(mostPlayedSongs.count) MOST PLAYED SONGS:")
        if mostPlayedSongs.isEmpty {
            print("   • No songs tracked yet")
        } else {
            for (index, song) in mostPlayedSongs.enumerated() {
                let title = song.songTitle ?? "Unknown Title"
                let artist = song.artistName ?? "Unknown Artist"
                print("   \(index + 1). \"\(title)\" by \(artist) - \(song.playCount) plays")
            }
        }
        
        // Songs played today
        print("\n📅 SONGS PLAYED TODAY:")
        if songsPlayedToday.isEmpty {
            print("   • No songs played today")
        } else {
            print("   • Total songs played today: \(songsPlayedToday.count)")
            for song in songsPlayedToday.prefix(5) {
                let title = song.songTitle ?? "Unknown Title"
                let artist = song.artistName ?? "Unknown Artist"
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                let timeString = formatter.string(from: song.lastPlayed ?? Date())
                print("   • \"\(title)\" by \(artist) - Last played at \(timeString)")
            }
            if songsPlayedToday.count > 5 {
                print("   • ... and \(songsPlayedToday.count - 5) more")
            }
        }
        
        // Last week statistics
        print("\n📊 LAST 7 DAYS STATISTICS:")
        if lastWeekPlays.isEmpty {
            print("   • No songs played in the last 7 days")
        } else {
            let totalWeekPlays = lastWeekPlays.reduce(0) { $0 + Int($1.playCount) }
            print("   • Unique songs played: \(lastWeekPlays.count)")
            print("   • Total plays: \(totalWeekPlays)")
            print("   • Average plays per day: \(String(format: "%.1f", Double(totalWeekPlays) / 7.0))")
        }
        
        print("\n" + String(repeating: "=", count: 60))
        print("✅ Statistics generated successfully!")
        print(String(repeating: "=", count: 60) + "\n")
    }
}

#Preview {
    ContentView()
}