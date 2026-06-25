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
    
    enum AIHighlightBlock {
        case detail
        case tags
    }
    
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeStore: ThemeStore

    @State private var model: NodeEditorModel

    @State private var selectedItem: PhotosPickerItem?

    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showImagePlayground = false
    @State private var showImageSourceDialog = false
    
    @State private var showCustomInstruction = false
    @State private var customInstruction = ""
    
    @State private var aiStatus: String?
    @State private var animatedAIGradient = false
    @State private var aiHighlightBlock: AIHighlightBlock?

    @FocusState private var isNameFocused: Bool
    
    private var aiBorderGradient: AngularGradient {
        AngularGradient(
            colors: [
                .blue,
                .purple,
                .cyan,
                .mint,
                .blue
            ],
            center: .center,
            angle: .degrees(animatedAIGradient ? 360 : 0)
        )
    }

    private var aiGlowGradient: AngularGradient {
        AngularGradient(
            colors: [
                .blue.opacity(0.9),
                .purple.opacity(0.9),
                .cyan.opacity(0.9),
                .mint.opacity(0.9),
                .blue.opacity(0.9)
            ],
            center: .center,
            angle: .degrees(animatedAIGradient ? 360 : 0)
        )
    }

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
                    
                    ZStack {
                        EditorBlock(title: String(localized: "Detail")) {
                            TextEditor(text: $model.attributedDetail)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundColor(.primary)
                                .frame(minHeight: 160)
                        }

                        aiHighlightOverlay(for: .detail)
                    }

                    ZStack {

                        EditorBlock(title: String(localized: "Tags")) {

                            TextField(
                                String(localized: "Add tags separated by commas"),
                                text: $model.tagsRaw
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        }

                        aiHighlightOverlay(for: .tags)
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
                        appModel.aiGenerationService.isRunning ||
                        model.name
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
                
                if appModel.aiGenerationService.isAvailable {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                improveWriting()
                            } label: {
                                Label("Improve Writing", systemImage: "wand.and.stars")
                            }

                            Button {
                                makeShorter()
                            } label: {
                                Label("Make Shorter", systemImage: "arrow.down.to.line")
                            }

                            Button {
                                makeLonger()
                            } label: {
                                Label("Make Longer", systemImage: "arrow.up.to.line")
                            }

                            Button {
                                explainBetter()
                            } label: {
                                Label("Explain Better", systemImage: "text.alignleft")
                            }

                            Button {
                                simplify()
                            } label: {
                                Label("Simplify", systemImage: "textformat.size.smaller")
                            }

                            Button {
                                professionalTone()
                            } label: {
                                Label("Professional Tone", systemImage: "briefcase")
                            }

                            Divider()

                            Button {
                                generateTags()
                            } label: {
                                Label("Generate Tags", systemImage: "tag")
                            }

                            Divider()

                            Button {
                                showCustomInstruction = true
                            } label: {
                                Label("Custom Instruction", systemImage: "square.and.pencil")
                            }

                        } label: {
                            Image(systemName: "sparkles")
                        }
                        .labelsHidden()
                        .disabled(appModel.aiGenerationService.isRunning)
                    }
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

                #if !os(visionOS)
                Button {
                    showCamera = true
                } label: {
                    Label(String(localized: "Take Photo"), systemImage: "camera")
                }
                #endif
                
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
            .onChange(of: appModel.aiGenerationService.isRunning) { _, isRunning in

                if isRunning {
                    startAIAnimation()
                } else {
                    stopAIAnimation()
                }
            }
            .alert(
                "Custom Instruction",
                isPresented: $showCustomInstruction
            ) {

                TextField(
                    "Describe what you want AI to do",
                    text: $customInstruction
                )

                Button(role: .cancel) {
                    customInstruction = ""
                }

                Button(role: .confirm) {
                    let instruction = customInstruction
                    customInstruction = ""

                    applyCustomInstruction(instruction)
                }
                .disabled(
                    customInstruction
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
                )

            } message: {

                Text("Describe how AI should modify the node")
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedItem,
                matching: .images
            )
            #if !os(visionOS)
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
            #endif
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
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                    .clipped()

            } else {

                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .fill(.ultraThinMaterial)
                .frame(height: 240)
                .overlay {

                    Text(
                        String(localized: "Tap to add cover (optional)")
                    )
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
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .bold
                                    )
                                )
                                .frame(
                                    width: 36,
                                    height: 36
                                )
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.6))
                                )
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
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            showImageSourceDialog = true
        }
    }


    func loadImage(
        from item: PhotosPickerItem?
    ) {

        guard let item else {
            return
        }

        Task {

            if let data = try? await item.loadTransferable(
                type: Data.self
            ) {

                await MainActor.run {
                    model.images = [data]
                }
            }
        }
    }


    func submit() {

        switch model.mode {

        case .create(let position):

            let positionValue =
                position ?? SIMD3<Float>(0, 1.0, -1.5)

            appModel.createNode(
                name: model.name,
                attributedDetail: model.attributedDetail,
                position: positionValue,
                color: model.color,
                tagsRaw: model.tagsRaw,
                images: model.images
            )


        case .edit:

            guard let nodeId = model.nodeId else {
                return
            }

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

// MARK: - AI Highlight

private extension NodeEditorView {

    func aiHighlightOverlay(
        for block: AIHighlightBlock
    ) -> some View {

        Group {

            if aiHighlightBlock == block {

                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .stroke(
                    aiGlowGradient,
                    lineWidth: 4
                )
                .blur(radius: 12)
                .opacity(0.9)
                .padding(-2)
                .allowsHitTesting(false)


                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .strokeBorder(
                    aiBorderGradient,
                    lineWidth: 1.5
                )
                .padding(-2)
                .allowsHitTesting(false)


                Text(
                    aiStatus ?? String(localized: "AI")
                )
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .offset(
                    x: -12,
                    y: 12
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topTrailing
                )
                .allowsHitTesting(false)
            }
        }
    }


    func startAIAnimation() {

        animatedAIGradient = false

        DispatchQueue.main.async {

            withAnimation(
                .linear(duration: 4)
                .repeatForever(
                    autoreverses: false
                )
            ) {

                animatedAIGradient = true
            }
        }
    }


    func stopAIAnimation() {

        withAnimation(.easeOut(duration: 0.3)) {
            animatedAIGradient = false
        }
    }


    func finishAI() {

        aiStatus = nil
        aiHighlightBlock = nil
    }
}

// MARK: - AI Actions

private extension NodeEditorView {

    func improveWriting() {
        rewrite(
            task: .improveWriting,
            status: String(localized: "Improving...")
        )
    }

    func makeShorter() {
        rewrite(
            task: .makeShorter,
            status: String(localized: "Making shorter...")
        )
    }

    func makeLonger() {
        rewrite(
            task: .makeLonger,
            status: String(localized: "Expanding...")
        )
    }

    func explainBetter() {
        rewrite(
            task: .explainBetter,
            status: String(localized: "Explaining...")
        )
    }

    func simplify() {
        rewrite(
            task: .simplify,
            status: String(localized: "Simplifying...")
        )
    }

    func professionalTone() {
        rewrite(
            task: .professionalTone,
            status: String(localized: "Improving tone...")
        )
    }


    func generateTags() {

        aiHighlightBlock = .tags
        aiStatus = String(localized: "Generating tags...")


        Task {

            do {

                let tags = try await appModel.aiGenerationService
                    .generateTags(
                        title: model.name,
                        content: String(
                            model.attributedDetail.characters
                        )
                    )


                await MainActor.run {

                    withAnimation(.snappy) {
                        model.tagsRaw = tags
                    }

                    finishAI()
                }


            } catch {

                await MainActor.run {
                    finishAI()
                }

                print(error.localizedDescription)
            }
        }
    }


    func applyCustomInstruction(
        _ instruction: String
    ) {

        rewrite(
            task: .customRewrite,
            instruction: instruction,
            status: String(localized: "Applying...")
        )
    }


    func rewrite(
        task: PromptFactory.Task,
        instruction: String? = nil,
        status: String
    ) {

        aiHighlightBlock = .detail
        aiStatus = status


        Task {

            do {

                let content: String

                if let instruction {

                    content = """
                    \(String(model.attributedDetail.characters))

                    Instruction:
                    \(instruction)
                    """

                } else {

                    content = String(
                        model.attributedDetail.characters
                    )
                }


                let result = try await appModel.aiGenerationService
                    .rewriteNodeContent(
                        task: task,
                        title: model.name,
                        content: content
                    )


                await MainActor.run {

                    withAnimation(.snappy) {

                        model.attributedDetail =
                            AttributedString(result)
                    }

                    finishAI()
                }


            } catch {

                await MainActor.run {
                    finishAI()
                }

                print(error.localizedDescription)
            }
        }
    }
}
