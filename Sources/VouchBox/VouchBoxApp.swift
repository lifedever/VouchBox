import SwiftUI

@main
struct VouchBoxApp: App {
    @State private var catalog = AppCatalog()
    @State private var helper = HelperStatusModel()

    var body: some Scene {
        WindowGroup("VouchBox", id: "main") {
            MainWindow(catalog: catalog, helper: helper)
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowStyle(.titleBar)

        MenuBarExtra("VouchBox", systemImage: "shippingbox") {
            MenuBarView(catalog: catalog)
        }
        .menuBarExtraStyle(.window)
    }
}
