import SwiftUI
import CoreData

struct MusicStatsView: View {
    @StateObject private var musicKitManager = MusicKitManager.shared
    
    var body: some View {
        Group {
            if musicKitManager.isInitialized {
                if musicKitManager.canUseApp {
                    StatsTabView()
                } else {
                    SubscriptionRequiredView()
                }
            } else {
                // Loading state
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Initializing...")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await musicKitManager.checkAuthorizationAndSubscription()
            }
        }
    }
}

struct StatsTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                TodayStatsView()
                    .navigationTitle("Today")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Today")
            }
            
            NavigationView {
                ThisWeekStatsView()
                    .navigationTitle("This Week")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "calendar.circle")
                Text("This Week")
            }
            
            NavigationView {
                RecentlyPlayedView()
                    .navigationTitle("Recently Played")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "clock.arrow.circlepath")
                Text("Recent")
            }
            
            NavigationView {
                AllTimeStatsView()
                    .navigationTitle("All Time")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "infinity")
                Text("All Time")
            }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
            
            DebugView()
                .tabItem {
                    Image(systemName: "ant")
                    Text("Debug")
                }
        }
    }
}

struct TodayStatsView: View {
    @State private var todaysSongs: [PlayCount] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            Section {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading today's stats...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else if todaysSongs.isEmpty {
                    ContentUnavailableView(
                        "No Songs Today",
                        systemImage: "music.note.slash",
                        description: Text("You haven't listened to any songs today yet.")
                    )
                } else {
                    ForEach(Array(todaysSongs.enumerated()), id: \.element.objectID) { index, song in
                        SongRowView(song: song, rank: index + 1)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await MusicKitManager.shared.syncRecentPlays()
                await loadTodaysSongs()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playCountUpdated)) { _ in
            Task {
                await loadTodaysSongs()
            }
        }
    }
    
    private func loadTodaysSongs() async {
        isLoading = true
        
        let songs = await Task.detached {
            CoreDataManager.shared.fetchTodaysSongs()
        }.value
        
        todaysSongs = songs
        isLoading = false
    }
}

struct ThisWeekStatsView: View {
    @State private var weekSongs: [PlayCount] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            Section {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading this week's stats...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else if weekSongs.isEmpty {
                    ContentUnavailableView(
                        "No Songs This Week",
                        systemImage: "music.note.slash",
                        description: Text("You haven't listened to any songs this week yet.")
                    )
                } else {
                    ForEach(Array(weekSongs.enumerated()), id: \.element.objectID) { index, song in
                        SongRowView(song: song, rank: index + 1)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await MusicKitManager.shared.syncRecentPlays()
                await loadWeekSongs()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playCountUpdated)) { _ in
            Task {
                await loadWeekSongs()
            }
        }
    }
    
    private func loadWeekSongs() async {
        isLoading = true
        
        let songs = await Task.detached {
            CoreDataManager.shared.fetchThisWeeksSongs()
        }.value
        
        weekSongs = songs
        isLoading = false
    }
}

struct RecentlyPlayedView: View {
    @State private var recentSongs: [PlayCount] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            Section {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading recently played songs...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else if recentSongs.isEmpty {
                    ContentUnavailableView(
                        "No Recently Played Songs",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Your recently played songs will appear here.\n\nMusic tracking began on \(installDate). Only songs played after this date are included in your statistics.")
                    )
                } else {
                    ForEach(Array(recentSongs.enumerated()), id: \.element.objectID) { index, song in
                        SongRowView(song: song, rank: index + 1)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await MusicKitManager.shared.syncRecentPlays()
                await loadRecentSongs()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playCountUpdated)) { _ in
            Task {
                await loadRecentSongs()
            }
        }
    }
    
    private var installDate: String {
        let appInstallDateKey = "AppInstallDate"
        if let installDate = UserDefaults.standard.object(forKey: appInstallDateKey) as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: installDate)
        }
        return "Unknown"
    }
    
    private func loadRecentSongs() async {
        isLoading = true
        
        let songs = await Task.detached {
            CoreDataManager.shared.fetchRecentlyPlayedSongs()
        }.value
        
        recentSongs = songs
        isLoading = false
    }
}

struct AllTimeStatsView: View {
    @State private var allTimeSongs: [PlayCount] = []
    @State private var totalStats: (songs: Int, plays: Int) = (0, 0)
    @State private var isLoading = true
    
    var body: some View {
        List {
            Section {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading all-time stats...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Songs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(totalStats.songs)")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Total Plays")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(totalStats.plays)")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading most played songs...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } else if allTimeSongs.isEmpty {
                    ContentUnavailableView(
                        "No Songs Tracked",
                        systemImage: "music.note.slash",
                        description: Text("Start listening to music to see your stats here.")
                    )
                } else {
                    ForEach(Array(allTimeSongs.enumerated()), id: \.element.objectID) { index, song in
                        SongRowView(song: song, rank: index + 1)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await MusicKitManager.shared.syncRecentPlays()
                await loadAllTimeStats()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playCountUpdated)) { _ in
            Task {
                await loadAllTimeStats()
            }
        }
    }
    
    private func loadAllTimeStats() async {
        isLoading = true
        
        let (songs, stats) = await Task.detached {
            let songs = CoreDataManager.shared.fetchAllTimeSongs()
            let stats = CoreDataManager.shared.fetchTotalStats()
            return (songs, stats)
        }.value
        
        allTimeSongs = songs
        totalStats = stats
        isLoading = false
    }
}

struct SongRowView: View {
    let song: PlayCount
    let rank: Int
    
    var body: some View {
        HStack {
            // Rank circle
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 32, height: 32)
                
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.songTitle ?? "Unknown Title")
                    .font(.headline)
                    .lineLimit(1)
                
                Text(song.artistName ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let firstTracked = song.firstTracked {
                    Text("First tracked: \(firstTracked, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(song.playCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(song.playCount == 1 ? "play" : "plays")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastPlayed = song.lastPlayed {
                    Text(lastPlayed, formatter: timeFormatter)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}


#Preview {
    MusicStatsView()
}