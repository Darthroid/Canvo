//
//  NodeEditorView.swift
//  nodes-demo
//

import SwiftUI
import PhotosUI
import ImagePlayground

@Observable
fileprivate final class NodeEditorModel {

    enum Mode {
        case create(position: SIMD3<Float>?)
        case edit(Node)
    }

    let mode: Mode

    var nodeId: String?
    var position: SIMD3<Float>?

    var name: String
    var attributedDetail: AttributedString
    var color: Color?
    var tagsRaw: String
    var images: [Data]

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .create(let position):
            self.nodeId = nil
            self.position = position

            self.name = ""
            self.attributedDetail = AttributedString()
            self.color = nil
            self.tagsRaw = ""
            self.images = []

        case .edit(let node):
            self.nodeId = node.id
            self.position = nil

            self.name = node.name
            self.attributedDetail = node.richText
            self.color = node.colorRaw.flatMap { Color(hex: $0) }
            self.tagsRaw = node.tagsRaw ?? ""
            self.images = node.images
        }
    }

    var isEditing: Bool {
        nodeId != nil
    }

    var title: String {
        isEditing ? String(localized: "Edit Node") : String(localized: "Create Node")
    }
}

struct NodeEditorView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeStore: ThemeStore

    @State private var model: NodeEditorModel

    @State private var selectedItem: PhotosPickerItem?

    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showImagePlayground = false
    @State private var showImageSourceDialog = false

    @FocusState private var isNameFocused: Bool

    init(position: SIMD3<Float>? = nil) {
        _model = State(
            initialValue: NodeEditorModel(
                mode: .create(position: position)
            )
        )
    }

    init(node: Node) {
        _model = State(
            initialValue: NodeEditorModel(
                mode: .edit(node)
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    cover

                    HStack {

                        EditorBlock(title: String(localized: "Name")) {
                            TextField(String(localized: "Untitled node"), text: $model.name)
                                .font(.system(size: 20, weight: .medium))
                                .focused($isNameFocused)
                        }

                        EditorBlock(title: String(localized: "Color")) {
                            ColorPicker(
                                "",
                                selection: Binding(
                                    get: {
                                        model.color ?? themeStore.theme.canvasTheme.nodeBackground
                                    },
                                    set: { newValue in
                                        model.color = newValue
                                    }
                                )
                            )
                            .labelsHidden()
                        }
                        .frame(maxWidth: 80)
                    }

                    EditorBlock(title: String(localized: "Detail")) {
                        TextEditor(text: $model.attributedDetail)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundColor(.primary)
                            .frame(minHeight: 160)
                    }

                    EditorBlock(title: String(localized: "Tags")) {
                        TextField(
                            String(localized: "Add tags separated by commas"),
                            text: $model.tagsRaw
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .navigationTitle(model.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        submit()
                        dismiss()
                    }
                    .disabled(
                        model.name
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
            }
            .confirmationDialog(
                String(localized: "Add Cover"),
                isPresented: $showImageSourceDialog
            ) {
                Button {
                    showPhotoPicker = true
                } label: {
                    Label(String(localized: "Choose Photo"), systemImage: "photo")
                }

                Button {
                    showCamera = true
                } label: {
                    Label(String(localized: "Take Photo"), systemImage: "camera")
                }
                
                Button {
                    showImagePlayground = true
                } label: {
                    Label(String(localized: "AI Image"), systemImage: "apple.image.playground")
                }

                if !model.images.isEmpty {
                    Button(
                        String(localized: "Remove Image"),
                        role: .destructive
                    ) {
                        model.images.removeAll()
                        selectedItem = nil
                    }
                }
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedItem,
                matching: .images
            )
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(
                    imageData: Binding(
                        get: { nil },
                        set: { data in
                            guard let data else { return }
                            model.images = [data]
                        }
                    )
                )
            }
            .imagePlaygroundSheet(isPresented: $showImagePlayground, concept: "", onCompletion: {
                guard let data = try? Data(contentsOf: $0) else {
                    return
                }
                model.images = [data]
            })
            .onChange(of: selectedItem) { _, newValue in
                loadImage(from: newValue)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isNameFocused = true
                }
            }
        }
    }
}

// MARK: - Cover

private extension NodeEditorView {

    var cover: some View {
        ZStack {

            if let data = model.images.first,
               let uiImage = UIImage(data: data) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .clipped()

            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .frame(height: 240)
                    .overlay {
                        Text(String(localized: "Tap to add cover (optional)"))
                            .foregroundStyle(.secondary)
                            .padding(30)
                            .multilineTextAlignment(.center)
                    }
            }

            VStack {
                HStack {
                    Spacer()

                    if model.images.first != nil {
                        Button {
                            model.images.removeAll()
                            selectedItem = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(.black.opacity(0.6)))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)

                Spacer()
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .onTapGesture {
            showImageSourceDialog = true
        }
    }

    func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    model.images = [data]
                }
            }
        }
    }

    func submit() {
        switch model.mode {

        case .create(let position):
            let positionValue = position ?? SIMD3<Float>(0, 1.0, -1.5)

            appModel.createNode(
                name: model.name,
                attributedDetail: model.attributedDetail,
                position: positionValue,
                color: model.color,
                tagsRaw: model.tagsRaw,
                images: model.images
            )

        case .edit:
            guard let nodeId = model.nodeId else { return }

            appModel.editNode(
                nodeId: nodeId,
                name: model.name,
                attributedDetail: model.attributedDetail,
                color: model.color,
                tagsRaw: model.tagsRaw,
                images: model.images
            )
        }
    }
}
