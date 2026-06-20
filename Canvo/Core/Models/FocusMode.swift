//
//  FocusMode.swift
//  Canvo
//
//  Created by Олег Комаристый on 19.06.2026.
//

import Foundation

enum FocusMode: String, CaseIterable, Identifiable {
    case selectedOnly
    case context
//    case branch
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .selectedOnly:
            String(localized: "Selected")
        case .context:
            String(localized: "Context")
//        case .branch:
//            String(localized: "Branch")
        }
    }
}
