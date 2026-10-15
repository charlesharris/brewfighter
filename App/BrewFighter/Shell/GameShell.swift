import SwiftUI

enum Screen: Equatable {
    case cellar
    case wizard
    case detail(UUID)
}

struct GameShell: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            switch store.screen {
            case .cellar:
                CellarView()
                    .transition(.opacity)
            case .wizard:
                RecipeWizardView(content: store.content)
                    .id(store.wizardSession)
                    .transition(.move(edge: .bottom))
            case let .detail(id):
                BeerDetailView(beerID: id)
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: store.screen)
    }
}
