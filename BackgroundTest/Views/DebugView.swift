import SwiftUI
import CoreData

struct DebugView: View {
    @State private var debugData: [(title: String, artist: String, count: Int32, source: String, lastPlayed: Date?)] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading debug data...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else if debugData.isEmpty {
                        ContentUnavailableView(
                            "No Tracking Data",
                            systemImage: "magnifyingglass",
                            description: Text("No songs have been tracked yet.")
                        )
                    } else {
                        ForEach(Array(debugData.enumerated()), id: \.offset) { index, item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.title)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text("\(item.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                
                                Text(item.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                HStack {
                                    // Source badge
                                    Text(item.source.uppercased())
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(sourceColor(item.source))
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                    
                                    Spacer()
                                    
                                    if let lastPlayed = item.lastPlayed {
                                        Text(lastPlayed, style: .relative)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Never played")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Recent Tracking Activity")
                } footer: {
                    Text("Shows the most recent 100 tracked songs with their source (REALTIME vs MUSICKIT) and play counts. Use this to verify deduplication is working correctly.")
                }
            }
            .navigationTitle("Debug Tracking")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadDebugData()
            }
        }
    }
    
    private func sourceColor(_ source: String) -> Color {
        switch source.lowercased() {
        case "realtime":
            return .blue
        case "musickit":
            return .green
        default:
            return .gray
        }
    }
    
    private func loadDebugData() {
        isLoading = true
        
        Task.detached {
            let data = CoreDataManager.shared.fetchDebugData()
            
            DispatchQueue.main.async {
                debugData = data
                isLoading = false
            }
        }
    }
}

#Preview {
    DebugView()
}