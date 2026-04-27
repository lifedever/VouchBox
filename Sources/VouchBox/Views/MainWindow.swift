import SwiftUI

struct MainWindow: View {
    @Bindable var catalog: AppCatalog
    @Bindable var helper: HelperStatusModel

    @State private var selection: ManifestEntry.ID?
    @State private var showAddSheet = false
    @State private var showHelperOnboarding = false
    @State private var bootstrap = BootstrapCoordinator()
    @State private var showBootstrap = false

    var body: some View {
        NavigationSplitView {
            AppListView(catalog: catalog, selection: $selection)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showAddSheet = true
                        } label: {
                            Label("添加 Manifest", systemImage: "plus")
                        }
                    }
                    ToolbarItem(placement: .navigation) {
                        Button {
                            Task { await catalog.refreshAll() }
                        } label: {
                            Label("刷新", systemImage: "arrow.clockwise")
                        }
                    }
                    ToolbarItem(placement: .status) {
                        helperBadge
                    }
                }
        } detail: {
            if let id = selection, let entry = catalog.entries.first(where: { $0.id == id }) {
                AppDetailView(catalog: catalog, entry: entry)
            } else {
                ContentUnavailableView("选择左侧 App", systemImage: "app.dashed")
            }
        }
        .sheet(isPresented: $showAddSheet) { AddManifestSheet(catalog: catalog) }
        .sheet(isPresented: $showHelperOnboarding) {
            HelperOnboardingView(helper: helper)
        }
        .sheet(isPresented: $showBootstrap) {
            BootstrapSheet(coordinator: bootstrap)
        }
        .task {
            await bootstrap.checkAtLaunch()
            await helper.refresh()
            if helper.status != .enabled {
                showHelperOnboarding = true
            } else if bootstrap.state == .needsBootstrap {
                showBootstrap = true
            }
            await catalog.refreshAll()
        }
    }

    @ViewBuilder
    private var helperBadge: some View {
        Button {
            showHelperOnboarding = true
        } label: {
            switch helper.status {
            case .enabled:
                Label("Helper", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(.green)
            default:
                Label("Helper 未启用", systemImage: "exclamationmark.shield")
                    .foregroundStyle(.orange)
            }
        }
    }
}
