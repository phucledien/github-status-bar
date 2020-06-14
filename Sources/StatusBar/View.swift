import Cocoa
import Combine

public final class View {

    public init(store: Store) {
        self.store = store
        self.viewStore = .init(store.scope(
            state: ViewState.state,
            action: \.action
        ))
        item.menu = menu
        viewStore.$state
            .sink(receiveValue: { [unowned self] in self.update(viewState: $0) })
            .store(in: &cancellables)
    }

    let store: Store
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu = NSMenu()

    private let viewStore: ViewStore
    private var cancellables = Set<AnyCancellable>()

    private func update(viewState: ViewState) {
        item.button?.title = viewState.title
        menu.items = [
            MenuItem(title: "Quit", action: { [weak self] in
                self?.viewStore.send(.didSelectQuit)
            })
        ]
    }

}
