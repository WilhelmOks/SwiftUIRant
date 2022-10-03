//
//  InternalView.swift
//  SwiftUIRant
//
//  Created by Wilhelm Oks on 29.08.22.
//

import SwiftUI

struct InternalView: View {
    @ObservedObject var appState = AppState.shared
    
    enum Tab: Int, Hashable {
        case feed
        case settings
    }
    
    @State private var tab: Tab = .feed
    
    var body: some View {
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
            .toolbar(.visible, in: .navigationBar, .tabBar)
            
            NavigationStack() {
                //TODO: make a SettingsView in an extra file
                Text("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label {
                    Text("Settings")
                } icon: {
                    Image(systemName: "gear")
                }
            }
            .tag(Tab.settings)
            .toolbar(.visible, in: .navigationBar, .tabBar)
        }
    }
}

struct InternalView_Previews: PreviewProvider {
    static var previews: some View {
        InternalView()
    }
}
