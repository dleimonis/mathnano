//
//  ShareSheet.swift
//  LemonMath
//

import SwiftUI
import PDFKit

struct ShareSheet: View {
    let problem: MathProblem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var achievementManager: AchievementManager

    @State private var selectedFormat: ShareFormat = .image
    @State private var includeSteps = true
    @State private var includeNotes = true
    @State private var customNote = ""
    @State private var isGenerating = false
    @State private var showShareActivity = false
    @State private var shareItems: [Any] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Format selection
                    formatSelectionSection

                    // Preview
                    previewSection

                    // Options
                    optionsSection

                    // Custom note
                    customNoteSection

                    // Share buttons
                    shareButtonsSection
                }
                .padding()
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Share Solution")
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
            }
            .sheet(isPresented: $showShareActivity) {
                ActivityViewController(items: shareItems)
            }
            .overlay {
                if isGenerating {
                    GeneratingOverlay()
                }
            }
        }
    }

    // MARK: - Format Selection
    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share Format")
                .font(.headline)
                .foregroundStyle(Color.adaptivePrimaryText)

            HStack(spacing: 12) {
                ForEach(ShareFormat.allCases) { format in
                    FormatCard(
                        format: format,
                        isSelected: selectedFormat == format
                    ) {
                        withAnimation {
                            selectedFormat = format
                        }
                        settingsManager.triggerHapticFeedback(.light)
                    }
                }
            }
        }
    }

    // MARK: - Preview
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(Color.adaptivePrimaryText)

            VStack(spacing: 16) {
                // Problem
                HStack {
                    Text("Problem:")
                        .font(.subheadline)
                        .foregroundStyle(Color.adaptiveSecondaryText)
                    Spacer()
                    Text(problem.problemText)
                        .font(.subheadline)
                        .foregroundStyle(Color.adaptivePrimaryText)
                }

                // Solution
                HStack {
                    Text("Solution:")
                        .font(.subheadline)
                        .foregroundStyle(Color.adaptiveSecondaryText)
                    Spacer()
                    Text(problem.solution)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(LemonMathColors.accent)
                }

                // Steps count
                if includeSteps {
                    HStack {
                        Text("Steps included:")
                            .font(.subheadline)
                            .foregroundStyle(Color.adaptiveSecondaryText)
                        Spacer()
                        Text("\(problem.steps.count) steps")
                            .font(.subheadline)
                            .foregroundStyle(Color.adaptivePrimaryText)
                    }
                }

                // Solved image preview
                if let image = problem.solvedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .background(Color.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Options
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Include")
                .font(.headline)
                .foregroundStyle(Color.adaptivePrimaryText)

            VStack(spacing: 8) {
                OptionToggle(
                    title: "Step-by-step solution",
                    icon: "list.number",
                    isOn: $includeSteps
                )

                if let notes = problem.userNotes, !notes.isEmpty {
                    OptionToggle(
                        title: "My notes",
                        icon: "note.text",
                        isOn: $includeNotes
                    )
                }
            }
        }
    }

    // MARK: - Custom Note
    private var customNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a message (optional)")
                .font(.headline)
                .foregroundStyle(Color.adaptivePrimaryText)

            TextEditor(text: $customNote)
                .frame(height: 80)
                .padding(8)
                .background(Color.adaptiveCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.adaptiveSecondaryText.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - Share Buttons
    private var shareButtonsSection: some View {
        VStack(spacing: 12) {
            // Main share button
            Button {
                generateAndShare()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LemonMathColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Quick share options
            HStack(spacing: 12) {
                QuickShareButton(
                    title: "Messages",
                    icon: "message.fill",
                    color: .green
                ) {
                    shareToMessages()
                }

                QuickShareButton(
                    title: "AirDrop",
                    icon: "airplayaudio",
                    color: .blue
                ) {
                    shareViaAirDrop()
                }

                QuickShareButton(
                    title: "Copy",
                    icon: "doc.on.doc.fill",
                    color: .orange
                ) {
                    copyToClipboard()
                }
            }

            // Challenge friend
            Button {
                createChallenge()
            } label: {
                HStack {
                    Image(systemName: "person.2.fill")
                    Text("Challenge a Friend")
                }
                .font(.subheadline)
                .foregroundStyle(LemonMathColors.accent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LemonMathColors.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Methods

    private func generateAndShare() {
        isGenerating = true

        Task {
            do {
                let items = try await generateShareContent()
                await MainActor.run {
                    shareItems = items
                    isGenerating = false
                    showShareActivity = true

                    // Record share for achievements
                    historyManager.incrementShareCount(for: problem)
                    achievementManager.recordShare()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    // Show error
                }
            }
        }
    }

    private func generateShareContent() async throws -> [Any] {
        var items: [Any] = []

        switch selectedFormat {
        case .image:
            if let image = generateShareImage() {
                items.append(image)
            }
        case .pdf:
            if let pdfData = generatePDF() {
                items.append(pdfData)
            }
        case .text:
            items.append(generateShareText())
        }

        if !customNote.isEmpty {
            items.append(customNote)
        }

        return items
    }

    private func generateShareImage() -> UIImage? {
        // Create a rendered image of the solution
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 600))

        return renderer.image { context in
            // Background
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 800, height: 600))

            // Draw content
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.black
            ]

            "Lemon Math Solution".draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)

            let problemAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.darkGray
            ]

            "Problem: \(problem.problemText)".draw(at: CGPoint(x: 40, y: 100), withAttributes: problemAttributes)

            let solutionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                .foregroundColor: UIColor(LemonMathColors.accent)
            ]

            "Solution: \(problem.solution)".draw(at: CGPoint(x: 40, y: 140), withAttributes: solutionAttributes)

            if includeSteps {
                var yOffset: CGFloat = 200
                for step in problem.steps {
                    let stepText = "\(step.stepNumber). \(step.title): \(step.mathExpression)"
                    stepText.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: problemAttributes)
                    yOffset += 30
                }
            }
        }
    }

    private func generatePDF() -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Lemon Math",
            kCGPDFContextTitle: "Math Solution"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageSize = CGSize(width: 612, height: 792) // Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)

        return renderer.pdfData { context in
            context.beginPage()

            // Draw PDF content
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.black
            ]

            "Lemon Math Solution".draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)

            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]

            problem.formattedDate.draw(at: CGPoint(x: 40, y: 80), withAttributes: dateAttributes)

            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]

            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]

            "Problem:".draw(at: CGPoint(x: 40, y: 120), withAttributes: labelAttributes)
            problem.problemText.draw(at: CGPoint(x: 40, y: 140), withAttributes: contentAttributes)

            "Solution:".draw(at: CGPoint(x: 40, y: 180), withAttributes: labelAttributes)
            problem.solution.draw(at: CGPoint(x: 40, y: 200), withAttributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor(LemonMathColors.accent)
            ])

            if includeSteps {
                "Steps:".draw(at: CGPoint(x: 40, y: 260), withAttributes: labelAttributes)

                var yOffset: CGFloat = 290
                for step in problem.steps {
                    let stepTitle = "\(step.stepNumber). \(step.title)"
                    stepTitle.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                        .foregroundColor: UIColor.black
                    ])
                    yOffset += 25

                    step.mathExpression.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: [
                        .font: UIFont.italicSystemFont(ofSize: 14),
                        .foregroundColor: UIColor.darkGray
                    ])
                    yOffset += 20

                    step.explanation.draw(
                        in: CGRect(x: 60, y: yOffset, width: 492, height: 100),
                        withAttributes: [
                            .font: UIFont.systemFont(ofSize: 12),
                            .foregroundColor: UIColor.gray
                        ]
                    )
                    yOffset += 50
                }
            }

            // Footer
            let footer = "Generated by Lemon Math - The magical math solver"
            footer.draw(at: CGPoint(x: 40, y: 750), withAttributes: [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.lightGray
            ])
        }
    }

    private func generateShareText() -> String {
        var text = """
        Lemon Math Solution

        Problem: \(problem.problemText)
        Solution: \(problem.solution)

        """

        if includeSteps {
            text += "\nSteps:\n"
            for step in problem.steps {
                text += "\(step.stepNumber). \(step.title)\n"
                text += "   \(step.mathExpression)\n"
                text += "   \(step.explanation)\n\n"
            }
        }

        if includeNotes, let notes = problem.userNotes {
            text += "\nNotes: \(notes)\n"
        }

        text += "\n---\nSolved with Lemon Math"

        return text
    }

    private func shareToMessages() {
        generateAndShare()
    }

    private func shareViaAirDrop() {
        generateAndShare()
    }

    private func copyToClipboard() {
        let text = generateShareText()
        UIPasteboard.general.string = text
        settingsManager.triggerSuccessHaptic()
        dismiss()
    }

    private func createChallenge() {
        // Create a shareable challenge link
        let challengeText = """
        Can you solve this? 🤔

        \(problem.problemText)

        Try to solve it with Lemon Math!
        """
        shareItems = [challengeText]
        showShareActivity = true
    }
}

// MARK: - Share Format
enum ShareFormat: String, CaseIterable, Identifiable {
    case image
    case pdf
    case text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .image: return "Image"
        case .pdf: return "PDF"
        case .text: return "Text"
        }
    }

    var icon: String {
        switch self {
        case .image: return "photo"
        case .pdf: return "doc.fill"
        case .text: return "doc.plaintext"
        }
    }

    var color: Color {
        switch self {
        case .image: return .blue
        case .pdf: return .red
        case .text: return .green
        }
    }
}

// MARK: - Format Card
struct FormatCard: View {
    let format: ShareFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: format.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : format.color)

                Text(format.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : Color.adaptivePrimaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? format.color : format.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Option Toggle
struct OptionToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.adaptiveSecondaryText)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(Color.adaptivePrimaryText)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(LemonMathColors.accent)
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Quick Share Button
struct QuickShareButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption2)
                    .foregroundStyle(Color.adaptiveSecondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Generating Overlay
struct GeneratingOverlay: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.largeTitle)
                    .foregroundStyle(LemonMathColors.lemonYellow)
                    .rotationEffect(.degrees(rotation))

                Text("Generating...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Activity View Controller
struct ActivityViewController: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ShareSheet(
        problem: MathProblem(
            problemText: "2x + 5 = 15",
            problemType: .algebra,
            solution: "x = 5",
            steps: [
                SolutionStep(stepNumber: 1, title: "Subtract 5", explanation: "Subtract 5 from both sides", mathExpression: "2x = 10"),
                SolutionStep(stepNumber: 2, title: "Divide by 2", explanation: "Divide both sides by 2", mathExpression: "x = 5")
            ]
        )
    )
    .environmentObject(SettingsManager())
    .environmentObject(HistoryManager())
    .environmentObject(AchievementManager())
}
