//
//  AppState.swift
//  SwiftUIRant
//
//  Created by Wilhelm Oks on 29.08.22.
//

import Foundation
import SwiftRant
import SwiftUI

#if os(iOS)
import UIKit
#endif

final class AppState: ObservableObject {
    static let shared = AppState()
    
    enum NavigationDestination: Hashable {
        case rantDetails(rantId: Rant.ID)
        case userProfile(userId: UserID)
    }
    
    @Published var navigationPath: [NavigationDestination] = []
    @Published var notificationsNavigationPath = NavigationPath()
        
    var isLoggedIn: Bool {
        LoginStore.shared.isLoggedIn
    }
    
    func navigate(from sourceTab: InternalView.Tab, to destination: NavigationDestination) {
        switch sourceTab {
        case .feed:
            AppState.shared.navigationPath.append(destination)
        case .notifications:
            AppState.shared.notificationsNavigationPath.append(destination)
        case .settings:
            break
        }
    }
    
    func navigate(from sourceTab: InternalView.Tab, to url: URL) {
        guard let destination = URLHandler().navigationDestination(forUrl: url) else { return }
        navigate(from: sourceTab, to: destination)
    }
    
    func clearImageCache() {
        URLCache.postedImageCache.removeAllCachedResponses()
        URLCache.userAvatarCache.removeAllCachedResponses()
    }
    
    var customAccentColor: CGColor? {
        get {
            if let hexString = UserDefaults.standard.string(forKey: "accent_color") {
                return PlatformColor.fromHexString(hexString)?.cgColor
            } else {
                return nil
            }
        }
        set {
            if let newValue {
                #if os(iOS)
                let hexString = hexStringFromColor(color: .init(cgColor: newValue))
                #elseif os(macOS)
                let hexString = hexStringFromColor(color: .init(cgColor: newValue) ?? .init(white: 0.5, alpha: 1))
                #endif
                UserDefaults.standard.set(hexString, forKey: "accent_color")
            } else {
                UserDefaults.standard.removeObject(forKey: "accent_color")
            }
            objectWillChange.send()
        }
    }
    
    func applyAccentColor() {
        #if os(iOS)
            DispatchQueue.main.async {
                UIApplication.shared.windows.forEach { window in
                    window.tintColor = UIColor(Color.primaryAccent)
                }
            }
        #endif
    }
}
