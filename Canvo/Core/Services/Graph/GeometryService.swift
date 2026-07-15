//
//  GeometryService.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

public class GeometryService {
    static func visionOSPosition(_ position: SIMD3<Float>) -> SIMD3<Float> {
        let scaleFactor: Float = 0.001

        let x = Float(position.x) * scaleFactor
        let y = -Float(position.y) * scaleFactor

        let z = -1.5 + Float(position.z) * scaleFactor

        return SIMD3<Float>(
            x,
            y + 1.5,
            z
        )
    }
    
    static func iOSPosition(_ position: SIMD3<Float>) -> SIMD3<Float> {
        let scaleFactor: Float = 0.001

        let x = position.x / scaleFactor
        let y = -(position.y - 1.5) / scaleFactor
        let z = (position.z + 1.5) / scaleFactor

        return SIMD3<Float>(
            x: x,
            y: y,
            z: z
        )
    }
}
