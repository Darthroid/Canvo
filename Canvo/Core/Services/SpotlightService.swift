//
//  SpotlightService.swift
//  Canvo
//
//  Created by Олег Комаристый on 15.06.2026.
//

import CoreSpotlight

class SpotlightService {
    
    static func index(canvases: [Canvas]) {
        let items = canvases.map { canvas in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = canvas.name
            attributeSet.thumbnailURL = CanvasPreviewService().getPreviewURL(for: canvas)
            attributeSet.lastUsedDate = canvas.updatedAt
            attributeSet.addedDate = canvas.createdAt
            attributeSet.contentDescription = canvas.nodes?.count ?? 0 > 0
                ? String(localized: "\(canvas.nodes?.count ?? 0) nodes")
                : String(localized: "0 nodes")
            
            let item = CSSearchableItem(uniqueIdentifier: canvas.id,
                                        domainIdentifier: "com.darthroid.nodes",
                                        attributeSet: attributeSet)
            
            return item
        }
        
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
            } else {
                print("Item indexed successfully!")
            }
        }
    }

    static func index(canvas: Canvas) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = canvas.name
        attributeSet.contentDescription = canvas.nodes?.count ?? 0 > 0 ? "\(canvas.nodes?.count ?? 0) nodes" : "Empty"
        
        let item = CSSearchableItem(uniqueIdentifier: canvas.id,
                                    domainIdentifier: "com.darthroid.nodes",
                                    attributeSet: attributeSet)
        
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
            } else {
                print("Item indexed successfully!")
            }
        }
    }
    
    static func removeFromIndexing(canvases: [Canvas]) {
        let ids = canvases.map { $0.id }
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ids) { error in
            if let error = error {
                print("Remove from indexing error: \(error.localizedDescription)")
            } else {
                print("Item removed from indexing successfully!")
            }
        }
    }
    
    static func removeFromIndexing(canvas: Canvas) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [canvas.id]) { error in
            if let error = error {
                print("Remove from indexing error: \(error.localizedDescription)")
            } else {
                print("Item removed from indexing successfully!")
            }
        }
    }
}
