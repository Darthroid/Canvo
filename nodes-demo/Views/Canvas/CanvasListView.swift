//
//  ContentView.swift
//  nodes-demo
//
//  Created by Oleg Komaristy on 17.11.2025.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct CanvasListView: View {
    @Environment(AppModel.self) var appModel
    @State var showCreateCanvas: Bool = false
    
    
    var body: some View {
        
        NavigationStack {
            canvasesList
                .navigationTitle("Nodes Demo")
                .toolbar {
                    Button {
                        showCreateCanvas = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
        }
        .sheet(isPresented: $showCreateCanvas) {
            CreateCanvasView()
                .environment(appModel)
        }
    }
    
    var canvasesList: some View {
        List {
            ForEach(appModel.canvases) { canvas in
                NavigationLink {
                    NodeMapView()
                        .environment(appModel)
                        .onAppear {
                            appModel.switchToCanvas(canvas)
                        }
                } label: {
                    Text(canvas.name)
                        .padding()
                }
            }
            .onDelete { indexSet in
                appModel.removeCanvas(at: indexSet)
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    CanvasListView()
}
