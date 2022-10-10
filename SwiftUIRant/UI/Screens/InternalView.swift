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
    
    enum Tab: Int, Hashable {
        case feed
        case notifications
        case settings
    }
    
    @State private var tab: Tab = .feed
    
    var body: some View {
        content()
            .onAppear {
                Task {
                    try? await DataLoader.shared.loadNotificationsNumber()
                }
            }
            .onChange(of: tab) { _ in
                Task {
                    try? await DataLoader.shared.loadNotificationsNumber()
                }
            }
    }
    
    @ViewBuilder private func content() -> some View {
        TabView(selection: $tab) {
            NavigationStack(path: $appState.navigationPath) {
                FeedView()
            }
            .tabItem {
                Label {
                    Text("Feed")
                } icon: {
                    Image(systemName: "list.bullet.rectangle")
                }
            }
            .tag(Tab.feed)
            .toolbarsVisible()
            
            NavigationStack() {
                NotificationsView()
            }
            .tabItem {
                Label {
                    Text("Notifications (\(dataStore.numberOfUnreadNotifications))") //TODO: make a proper number badge
                } icon: {
                    Image(systemName: "bell")
                }
            }
            .tag(Tab.notifications)
            .toolbarsVisible()
            
            NavigationStack() {
                SettingsView()
            }
            .tabItem {
                Label {
                    Text("Settings")
                } icon: {
                    Image(systemName: "gear")
                }
            }
            .tag(Tab.settings)
            .toolbarsVisible()
        }
    }
}

struct InternalView_Previews: PreviewProvider {
    static var previews: some View {
        InternalView()
    }
}
