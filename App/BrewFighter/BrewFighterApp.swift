import SwiftUI

@main
struct BrewFighterApp: App {
    @State private var store = GameStore.live()

    var body: some Scene {
        WindowGroup {
            GameShell()
                .environment(store)
        }
    }
}
