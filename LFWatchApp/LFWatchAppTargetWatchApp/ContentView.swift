//
//  ContentView.swift
//  LFWatchAppTarget Watch App
//
//  Created by Ravikiran Gajula on 14/2/23.
//
import WatchKit
import SwiftUI
import WatchConnectivity

struct ContentView: View {
    let sharedObj = WatchConnectManager.shared
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("HI")
            Button("Send") {
                sharedObj.send("Hi from watch")

            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
