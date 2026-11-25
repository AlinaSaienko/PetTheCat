import SwiftUI
import UIKit

/// In-app appearance: follow the phone (default), or always light / always dark.
enum ThemeMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self { case .system: return "System"; case .light: return "Light"; case .dark: return "Dark" }
    }
    var icon: String {
        switch self { case .system: return "circle.lefthalf.filled"; case .light: return "sun.max"; case .dark: return "moon" }
    }
    var style: UIUserInterfaceStyle {
        switch self { case .system: return .unspecified; case .light: return .light; case .dark: return .dark }
    }
    static let key = "themeMode"

    /// Applied to the whole window, so full-screen covers, sheets and dynamic colours all follow it.
    func apply() {
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for w in ws.windows { w.overrideUserInterfaceStyle = style }
        }
    }
}

@main
struct PetTheCatApp: App {
    @AppStorage(ThemeMode.key) private var theme = ThemeMode.system.rawValue
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { (ThemeMode(rawValue: theme) ?? .system).apply() }
                .onChange(of: theme) { t in (ThemeMode(rawValue: t) ?? .system).apply() }
                .onChange(of: scenePhase) { _ in (ThemeMode(rawValue: theme) ?? .system).apply() }
        }
    }
}
