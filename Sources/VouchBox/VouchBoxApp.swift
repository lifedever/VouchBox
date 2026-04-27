import SwiftUI

@main
struct VouchBoxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var catalog = AppCatalog()
    @State private var helper = HelperStatusModel()

    var body: some Scene {
        Window("VouchBox", id: "main") {
            MainWindow(catalog: catalog, helper: helper)
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarView(catalog: catalog)
        } label: {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 18, weight: .regular))
        }
        .menuBarExtraStyle(.window)
    }
}
