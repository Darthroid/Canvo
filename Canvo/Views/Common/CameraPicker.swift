//
//  CameraPicker.swift
//  Canvo
//
//  Created by Олег Комаристый on 20.06.2026.
//

import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {

    @Binding var imageData: Data?

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        private let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            let image =
                (info[.editedImage] as? UIImage)
                ?? (info[.originalImage] as? UIImage)

            if let image,
               let data = image.jpegData(compressionQuality: 0.9) {
                parent.imageData = data
            }

            parent.dismiss()
        }
    }
}
