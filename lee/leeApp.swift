//
//  leeApp.swift
//  lee
//
//  Created by phuc lee on 9/2/25.
//

import SwiftUI

@main
struct leeApp: App {
    // Initialize any app-wide services or state here
    init() {
        // Configure the app appearance
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    var body: some Scene {
        WindowGroup {
            WeatherView()
        }
    }
}
