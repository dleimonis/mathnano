//
//  PencilInputView.swift
//  LemonMath
//
//  Apple Pencil/iPad integration for direct math problem input
//

import SwiftUI
import PencilKit

struct PencilInputView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var historyManager: HistoryManager

    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var showProcessing = false
    @State private var showClearConfirmation = false
    @State private var hasDrawing = false

    let onComplete: (UIImage) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.adaptiveBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Instructions header
                    instructionsHeader

                    // Drawing canvas
                    PencilCanvasViewRepresentable(
                        canvasView: $canvasView,
                        toolPicker: toolPicker,
                        onDrawingChanged: {
                            hasDrawing = !canvasView.drawing.bounds.isEmpty
                        }
                    )
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()
                    .shadow(color: .black.opacity(0.1), radius: 10)

                    // Bottom toolbar
                    bottomToolbar
                }

                // Processing overlay
                if showProcessing {
                    ProcessingOverlayView()
                }
            }
            .navigationTitle("Write Problem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.adaptiveSecondaryText)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Undo
                        Button {
                            undoManager?.undo()
                            settingsManager.triggerHapticFeedback(.light)
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .foregroundStyle(Color.adaptiveSecondaryText)
                        }
                        .disabled(!canView(\.canUndo))

                        // Redo
                        Button {
                            undoManager?.redo()
                            settingsManager.triggerHapticFeedback(.light)
                        } label: {
                            Image(systemName: "arrow.uturn.forward")
                                .foregroundStyle(Color.adaptiveSecondaryText)
                        }
                        .disabled(!canView(\.canRedo))
                    }
                }
            }
            .alert("Clear Canvas?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearCanvas()
                }
            } message: {
                Text("This will erase everything you've drawn.")
            }
        }
    }

    @Environment(\.undoManager) private var undoManager

    private func canView(_ keyPath: KeyPath<UndoManager, Bool>) -> Bool {
        undoManager?[keyPath: keyPath] ?? false
    }

    // MARK: - Instructions Header
    private var instructionsHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil.tip")
                .font(.title2)
                .foregroundStyle(LemonMathColors.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Write your math problem")
                    .font(.headline)
                    .foregroundStyle(Color.adaptivePrimaryText)

                Text("Use Apple Pencil or finger to draw")
                    .font(.caption)
                    .foregroundStyle(Color.adaptiveSecondaryText)
            }

            Spacer()

            // Pencil status indicator
            PencilStatusIndicator()
        }
        .padding()
        .background(Color.adaptiveCardBackground)
    }

    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack(spacing: 16) {
            // Clear button
            Button {
                if hasDrawing {
                    showClearConfirmation = true
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.title3)
                    Text("Clear")
                        .font(.caption2)
                }
                .foregroundStyle(hasDrawing ? .red : Color.adaptiveSecondaryText.opacity(0.5))
            }
            .disabled(!hasDrawing)

            Spacer()

            // Pen selector shortcuts
            HStack(spacing: 12) {
                PenButton(icon: "pencil.tip", isSelected: true) {
                    selectTool(.pen)
                }

                PenButton(icon: "highlighter", isSelected: false) {
                    selectTool(.marker)
                }

                PenButton(icon: "eraser", isSelected: false) {
                    selectTool(.eraser)
                }
            }

            Spacer()

            // Solve button
            Button {
                solveDrawing()
            } label: {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Solve")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(hasDrawing ? LemonMathColors.accent : Color.gray)
                .clipShape(Capsule())
            }
            .disabled(!hasDrawing)
        }
        .padding()
        .background(Color.adaptiveCardBackground)
    }

    // MARK: - Methods

    private func selectTool(_ toolType: PKInkingTool.InkType) {
        let tool = PKInkingTool(toolType, color: .black, width: 3)
        canvasView.tool = tool
    }

    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        hasDrawing = false
        settingsManager.triggerHapticFeedback(.medium)
    }

    private func solveDrawing() {
        showProcessing = true
        settingsManager.triggerHapticFeedback(.medium)

        // Capture the drawing as an image
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)

        // Small delay for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete(image)
            dismiss()
        }
    }
}

// MARK: - Pencil Canvas View Representable
struct PencilCanvasViewRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let toolPicker: PKToolPicker
    let onDrawingChanged: () -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput // Allow finger or pencil
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true

        // Configure for Apple Pencil
        canvasView.allowsFingerDrawing = true

        // Set default tool
        let pen = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.tool = pen

        // Show tool picker
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()

        // Add grid lines for math paper effect
        addGridLines(to: canvasView)

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }

    private func addGridLines(to view: PKCanvasView) {
        let gridLayer = CAShapeLayer()
        let path = UIBezierPath()

        let spacing: CGFloat = 30
        let bounds = UIScreen.main.bounds

        // Vertical lines
        for x in stride(from: spacing, to: bounds.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: bounds.height))
        }

        // Horizontal lines
        for y in stride(from: spacing, to: bounds.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: bounds.width, y: y))
        }

        gridLayer.path = path.cgPath
        gridLayer.strokeColor = UIColor.systemGray5.cgColor
        gridLayer.lineWidth = 0.5

        view.layer.insertSublayer(gridLayer, at: 0)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChanged: () -> Void

        init(onDrawingChanged: @escaping () -> Void) {
            self.onDrawingChanged = onDrawingChanged
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChanged()
        }
    }
}

// MARK: - Pencil Status Indicator
struct PencilStatusIndicator: View {
    @State private var isPencilConnected = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isPencilConnected ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            Text(isPencilConnected ? "Pencil Ready" : "No Pencil")
                .font(.caption)
                .foregroundStyle(Color.adaptiveSecondaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.adaptiveCardBackground)
        .clipShape(Capsule())
        .onAppear {
            // Check for Apple Pencil connection
            // In a real app, you'd observe GCMouse.mice() or use UIPencilInteraction
            checkPencilStatus()
        }
    }

    private func checkPencilStatus() {
        // This is a simplified check - in production you'd use proper API
        isPencilConnected = UIDevice.current.userInterfaceIdiom == .pad
    }
}

// MARK: - Pen Button
struct PenButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isSelected ? .white : Color.adaptivePrimaryText)
                .frame(width: 44, height: 44)
                .background(isSelected ? LemonMathColors.accent : Color.adaptiveCardBackground)
                .clipShape(Circle())
        }
    }
}

// MARK: - Drawing Templates
struct DrawingTemplateSelector: View {
    @Binding var selectedTemplate: DrawingTemplate

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DrawingTemplate.allCases) { template in
                    TemplateButton(
                        template: template,
                        isSelected: selectedTemplate == template
                    ) {
                        selectedTemplate = template
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct TemplateButton: View {
    let template: DrawingTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: template.icon)
                    .font(.title3)

                Text(template.title)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .white : Color.adaptivePrimaryText)
            .frame(width: 60, height: 60)
            .background(isSelected ? LemonMathColors.accent : Color.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

enum DrawingTemplate: String, CaseIterable, Identifiable {
    case blank
    case graphPaper
    case coordinatePlane
    case numberLine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blank: return "Blank"
        case .graphPaper: return "Grid"
        case .coordinatePlane: return "X-Y Plane"
        case .numberLine: return "Number Line"
        }
    }

    var icon: String {
        switch self {
        case .blank: return "doc"
        case .graphPaper: return "square.grid.3x3"
        case .coordinatePlane: return "chart.xyaxis.line"
        case .numberLine: return "line.horizontal.3"
        }
    }
}

// MARK: - Pencil Gestures Support
struct PencilGestureModifier: ViewModifier {
    @State private var isDoubleTapEnabled = true

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIPencilInteraction.didTapNotification)) { _ in
                handlePencilTap()
            }
    }

    private func handlePencilTap() {
        // Handle Apple Pencil double-tap gesture
        // Common actions: switch tools, undo, etc.
    }
}

extension View {
    func pencilGestureSupport() -> some View {
        modifier(PencilGestureModifier())
    }
}

#Preview {
    PencilInputView { _ in }
        .environmentObject(SettingsManager())
        .environmentObject(HistoryManager())
}
