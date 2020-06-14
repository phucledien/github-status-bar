import App
import Cocoa
import ComposableArchitecture
import GitHub

let app: NSApplication = .shared
let appView: App.View = .init(store: .init(
    initialState: .init(),
    reducer: reducer,
    environment: .init(
        notificationsEndpoint: Notifications.urlEndpoint(),
        appTerminator: app.terminate(_:)
    )
))

app.delegate = appView
app.run()
