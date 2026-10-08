import SwiftUI

enum Screen: Equatable {
    case cellar
}

struct GameShell: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        switch store.screen {
        case .cellar:
            CellarView()
        }
    }
}
