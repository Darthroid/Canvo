//
//  CanvasGridView.swift
//  nodes-demo
//
//  Created by Oleg Komaristy on 17.11.2025.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct CanvasGridView: View {
    @Environment(AppModel.self) var appModel
    @State var showCreateCanvas: Bool = false
    @State private var gridLayout = [GridItem(.adaptive(minimum: 280), spacing: 20)]
    
    var body: some View {
        NavigationStack {
            canvasesGrid
                .navigationTitle("Nodes Demo")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showCreateCanvas = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
        }
        .sheet(isPresented: $showCreateCanvas) {
            CreateCanvasView()
                .environment(appModel)
        }
    }
    
    var canvasesGrid: some View {
        ZStack {
            if appModel.canvases.isEmpty {
                ContentUnavailableView(
                    "No Canvases",
                    systemImage: "rectangle.split.3x3",
                    description: Text("Tap the + button to create your first canvas")
                )
                .zIndex(1)
            }
            
            ScrollView {
                LazyVGrid(columns: gridLayout, spacing: 24) {
                    ForEach(appModel.canvases) { canvas in
                        NavigationLink {
                            NodeMapView()
                                .environment(appModel)
                                .onAppear {
                                    appModel.switchToCanvas(canvas)
                                }
                        } label: {
                            CanvasCardView(canvas: canvas)
                                .hoverEffect(.highlight)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                if let index = appModel.canvases.firstIndex(where: { $0.id == canvas.id }) {
                                    appModel.removeCanvas(at: IndexSet([index]))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
    }
}

struct CanvasCardView: View {
    let canvas: Canvas
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Card header with gradient background
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                // Canvas icon
                Image(systemName: "rectangle.split.3x3")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            
            // Card content
            VStack(alignment: .leading, spacing: 12) {
                // Canvas name
                Text(canvas.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Metadata footer
                HStack {
                    // Creation date
                    Label(
                        canvas.createdAt.formatted(.dateTime.day().month().year()),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Node count badge
                    Label("\(canvas.nodes.count)", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(canvas.nodes.count > 0 ? .blue : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(canvas.nodes.count > 0 ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .frame(height: 320)
    }
}

// Optional: Add a floating action button for visionOS
extension CanvasGridView {
    var floatingActionButton: some View {
        Button {
            showCreateCanvas = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            .linearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview(windowStyle: .automatic) {
    CanvasGridView()
}
