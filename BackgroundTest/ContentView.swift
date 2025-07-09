import SwiftUI

struct ContentView: View {
    var body: some View {
        MusicStatsView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
}