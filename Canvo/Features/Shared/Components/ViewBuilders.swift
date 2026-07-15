//
//  ViewBuilders.swift
//  Canvo
//
//  Created by Олег Комаристый on 03.07.2026.
//

import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveGlass() -> some View {
#if os(visionOS)
        self.glassBackgroundEffect()
#else
        if #available(iOS 26.0, *) {
            self.glassEffect()
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
#endif
    }
    
    @ViewBuilder
    func adaptiveGlass(isSheet: Bool, in shape: AnyShape) -> some View {
#if os(visionOS)
        self.glassBackgroundEffect()
#else
        if #available(iOS 26.0, *) {
            self.glassEffect(isSheet ? .identity : .regular, in: shape)
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(shape)
        }
#endif
    }
}

extension View {
    @ViewBuilder
    func ifAvailableIOS26<NewContent: View, FallbackContent: View>(
        @ViewBuilder new: (Self) -> NewContent,
        @ViewBuilder fallback: (Self) -> FallbackContent
    ) -> some View {
        if #available(iOS 26.0, visionOS 26.0, *) {
            new(self)
        } else {
            fallback(self)
        }
    }
}
