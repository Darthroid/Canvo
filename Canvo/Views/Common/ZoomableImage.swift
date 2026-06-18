//
//  ZoomableImage.swift
//  Canvo
//
//  Created by Олег Комаристый on 18.06.2026.
//

import SwiftUI

struct ZoomableImage: View {
    let image: UIImage

    private let minScale: CGFloat = 1
    private let midScale: CGFloat = 3
    private let maxScale: CGFloat = 5

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(magnificationGesture)
            .simultaneousGesture(dragGesture)
            .simultaneousGesture(doubleTapGesture)
            .animation(.easeOut(duration: 0.15), value: scale)
            .animation(.easeOut(duration: 0.15), value: offset)
    }

    // MARK: - Pinch zoom

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, minScale), maxScale)
            }
            .onEnded { _ in
                scale = min(max(scale, minScale), maxScale)
                lastScale = scale

                if scale == 1 {
                    offset = .zero
                    lastOffset = .zero
                }
            }
    }

    // MARK: - Pan

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }

                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    // MARK: - Double tap zoom

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                if scale > 1 {
                    reset()
                } else {
                    zoomIn()
                }
            }
    }

    // MARK: - Actions

    private func zoomIn() {
        scale = midScale
        lastScale = midScale
    }

    private func reset() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}
