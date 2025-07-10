# Music Tracking App

A comprehensive iOS music tracking application that monitors your listening habits across all music apps with intelligent deduplication to prevent double-counting.

## Architecture Overview

This app uses a **dual tracking system** with smart deduplication to provide the most accurate and comprehensive music listening statistics.

### Real-Time Tracking (Removed in Current Version)
- **Purpose**: Immediate UI updates while app is active
- **Technology**: MediaPlayer framework notifications  
- **Coverage**: Songs played while app is in foreground
- **Benefits**: Instant feedback, live session tracking
- **Status**: Currently removed in favor of MusicKit-only approach

### Historical Sync (MusicKitManager)
- **Purpose**: Comprehensive music history and cross-device sync
- **Technology**: MusicKit recently played API
- **Coverage**: All music apps, all devices, background listening
- **Benefits**: Complete listening history, works when app is closed
- **Rate Limiting**: 5-minute intervals between syncs to prevent excessive API calls

### Smart Deduplication System

The app prevents double-counting of plays through intelligent analysis:

#### **Deduplication Rules**
- **Cross-system** (realtime ↔ musickit): 2-minute window for strict deduplication
- **Same real-time source**: 30-second window with quick replay validation
- **Same MusicKit source**: 1-minute window 
- **Default**: 1-minute buffer for unknown combinations

#### **Quick Successive Play Handling**
The system correctly handles legitimate quick song switches:
- **Scenario**: Song A → Song B → Song A (within 2 minutes)
- **Result**: Both plays of Song A are counted (legitimate)
- **Logic**: Uses timing analysis and source validation

#### **Edge Cases Covered**
- Cross-device listening (iPad → iPhone sync)
- Quick song switching patterns
- Background app states and app closure
- Multiple music apps (Apple Music, Spotify, YouTube Music)
- App reinstallation scenarios

### Data Storage

#### **Core Data Model**
The app uses Core Data with enhanced tracking fields:

```swift
PlayCount Entity:
- songId: String (unique identifier)
- songTitle: String 
- artistName: String
- playCount: Int32 (total play count)
- firstTracked: Date (when song was first recorded)
- lastPlayed: Date (most recent play)
- trackingSource: String ("realtime", "musickit", "manual")
- playSessionId: String? (groups related plays)
```

#### **Install Date Filtering**
- Only tracks songs played after app installation
- Prevents inflated statistics from pre-existing play history
- Install date includes time for precise filtering

### Rate Limiting & Performance

#### **API Rate Limiting**
- MusicKit sync limited to every 5 minutes
- Prevents excessive API calls and battery drain
- Tracks last sync time in UserDefaults

#### **Background Processing**
- All Core Data operations use background contexts
- UI updates happen on main thread via notifications
- Efficient fetch requests with proper limits and sorting

### Privacy & Security

#### **Data Privacy**
- Only accesses play history metadata (titles, artists, counts)
- No audio content is accessed or stored
- All data stays on device (Core Data local storage)
- No network transmission of personal data

#### **Permissions Required**
- MusicKit framework access
- Apple Music authorization for recently played API

## Requirements

- **iOS**: 15.0+
- **Subscription**: Active Apple Music subscription
- **Frameworks**: MusicKit, Core Data, SwiftUI

## Features

### **Statistics Views**
- **Today**: Songs played today with play counts
- **This Week**: Weekly listening statistics
- **Recently Played**: Chronological list of recent songs
- **All Time**: Most played songs and total statistics

### **Settings**
- Data management (reset all statistics)
- App information and version details
- Install date display with time
- Manual data cleanup options

### **Debug Tools** (Development)
- Source attribution verification (realtime vs musickit)
- Play count accuracy checking
- Deduplication validation
- Recent tracking activity monitoring

## Implementation Details

### **Smart Deduplication Algorithm**

```swift
func checkForDuplicate(
    songId: String,
    source: String, 
    playDate: Date,
    context: NSManagedObjectContext
) -> Bool {
    // Fetch most recent play of same song
    // Calculate time difference 
    // Apply source-specific deduplication rules
    // Validate quick replays for legitimacy
}
```

### **Session ID Generation**
Real-time plays use unique session IDs:
```swift
"session_\(Date().timeIntervalSince1970)_\(UUID().uuidString.prefix(8))"
```

### **Error Handling**
- Graceful fallback if deduplication fails
- Comprehensive DEBUG logging for troubleshooting
- Maintains data integrity under all conditions

## Future Enhancements

- **Real-time tracking**: Re-implement MediaPlayer monitoring for instant updates
- **Export functionality**: CSV/JSON export of listening data
- **Advanced analytics**: Genre analysis, listening patterns, mood tracking
- **Widgets**: Home screen widgets for quick stats
- **Siri shortcuts**: Voice-activated statistics queries

## Troubleshooting

### **Common Issues**
1. **Duplicate plays showing**: Check Debug tab for source attribution
2. **Missing recent plays**: Verify Apple Music subscription status
3. **Slow sync**: Rate limiting in effect (5-minute intervals)
4. **Authorization errors**: Re-grant MusicKit permissions in Settings

### **Debug Information**
Use the Debug tab to verify:
- Source attribution (REALTIME vs MUSICKIT)
- Play count accuracy
- Recent tracking activity
- Deduplication effectiveness

---

**Note**: This app requires an active Apple Music subscription and only works with Apple Music content due to MusicKit API limitations.