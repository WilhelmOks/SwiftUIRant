//
//  InternalView.swift
//  SwiftUIRant
//
//  Created by Wilhelm Oks on 29.08.22.
//

import SwiftUI

struct InternalView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var dataStore = DataStore.shared
    @ObservedObject var dataLoader = DataLoader.shared
    
    enum Tab: Int, CaseIterable, Hashable, Identifiable {
        case feed
        case notifications
        case settings
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .feed:             return "Feed"
            case .notifications:    return "Notifications"
            case .settings:         return "Settings"
            }
        }
    }
    
    @State private var tab: Tab = .feed
    
    var body: some View {
        content()
            .onAppear {
                Task {
                    try? await dataLoader.loadNotificationsNumber()
                }
            }
            .onChange(of: tab) { _ in
                Task {
                    try? await dataLoader.loadNotificationsNumber()
                }
            }
    }
    
    @ViewBuilder private func content() -> some View {
        #if os(iOS)
        TabView(selection: $tab) {
            ForEach(Tab.allCases) { tab in
                tabView(tab)
            }
        }
        #elseif os(macOS)
        NavigationStack(path: $appState.navigationPath) {
            TabView(selection: $tab) {
                ForEach(Tab.allCases) { tab in
                    tabView(tab)
                }
            }
        }
        #endif
    }
    
    @ViewBuilder private func wrappedContentForTab(_ tab: Tab) -> some View {
        #if os(iOS)
        switch tab {
        case .feed:
            NavigationStack(path: $appState.navigationPath) {
                contentForTab(tab)
            }
        default:
            NavigationStack() {
                contentForTab(tab)
            }
        }
        #elseif os(macOS)
        if self.tab == tab {
            contentForTab(tab)
        } else {
            ZStack {}
        }
        #endif
    }
    
    @ViewBuilder private func contentForTab(_ tab: Tab) -> some View {
        switch tab {
        case .feed:             FeedView()
        case .notifications:    NotificationsView()
        case .settings:         SettingsView()
        }
    }
    
    @ViewBuilder private func tabView(_ tab: Tab) -> some View {
        //TODO: make a proper number badge
        let title = tab == .notifications ? "\(tab.displayName) (\(dataStore.numberOfUnreadNotifications))" : tab.displayName
        
        wrappedContentForTab(tab)
            .tabItem {
                Label {
                    Text(title)
                } icon: {
                    tabIcon(tab)
                }
            }
            .tag(tab)
            .toolbarsVisible()
    }
    
    @ViewBuilder private func tabIcon(_ tab: Tab) -> some View {
        switch tab {
        case .feed:
            Image(systemName: "list.bullet.rectangle")
        case .notifications:
            Image(systemName: "bell")
        case .settings:
            Image(systemName: "gear")
        }
    }
}

struct InternalView_Previews: PreviewProvider {
    static var previews: some View {
        InternalView()
    }
}
