//
//  ExplanationView.swift
//  LemonMath
//

import SwiftUI
import Charts

struct ExplanationView: View {
    let problem: MathProblem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var selectedTab: ExplanationTab = .steps
    @State private var expandedSteps: Set<UUID> = []
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector

                // Content
                TabView(selection: $selectedTab) {
                    stepsView
                        .tag(ExplanationTab.steps)

                    alternativesView
                        .tag(ExplanationTab.alternatives)

                    realWorldView
                        .tag(ExplanationTab.realWorld)

                    if problem.graphData != nil {
                        graphView
                            .tag(ExplanationTab.graph)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Explanation")
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
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(LemonMathColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(problem: problem)
            }
        }
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableTabs, id: \.self) { tab in
                    TabButton(
                        title: tab.title,
                        icon: tab.icon,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation {
                            selectedTab = tab
                        }
                        settingsManager.triggerHapticFeedback(.light)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.adaptiveCardBackground)
    }

    private var availableTabs: [ExplanationTab] {
        var tabs: [ExplanationTab] = [.steps, .alternatives, .realWorld]
        if problem.graphData != nil {
            tabs.append(.graph)
        }
        return tabs
    }

    // MARK: - Steps View
    private var stepsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Problem summary
                problemSummaryCard

                // Steps
                ForEach(problem.steps) { step in
                    StepCard(
                        step: step,
                        isExpanded: expandedSteps.contains(step.id),
                        onToggle: {
                            withAnimation {
                                if expandedSteps.contains(step.id) {
                                    expandedSteps.remove(step.id)
                                } else {
                                    expandedSteps.insert(step.id)
                                }
                            }
                        }
                    )
                }

                // Final answer
                finalAnswerCard
            }
            .padding()
        }
    }

    private var problemSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: problem.problemType.icon)
                    .foregroundStyle(problem.problemType.color)

                Text("Problem")
                    .font(.headline)
                    .foregroundStyle(Color.adaptivePrimaryText)

                Spacer()

                Text(problem.problemType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(problem.problemType.color.opacity(0.2))
                    .clipShape(Capsule())
            }

            Text(problem.problemText)
                .font(.title3)
                .foregroundStyle(Color.adaptivePrimaryText)
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var finalAnswerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(LemonMathColors.success)

            Text("Final Answer")
                .font(.subheadline)
                .foregroundStyle(Color.adaptiveSecondaryText)

            Text(problem.solution)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(LemonMathColors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [
                    LemonMathColors.accent.opacity(0.1),
                    LemonMathColors.lemonLight.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Alternatives View
    private var alternativesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if problem.alternativeMethods.isEmpty {
                    EmptyStateCard(
                        icon: "lightbulb",
                        title: "No Alternatives",
                        subtitle: "This problem has one standard solution method"
                    )
                } else {
                    ForEach(problem.alternativeMethods) { method in
                        AlternativeMethodCard(method: method)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Real World View
    private var realWorldView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if problem.realWorldExamples.isEmpty {
                    EmptyStateCard(
                        icon: "globe",
                        title: "No Examples Yet",
                        subtitle: "Real-world applications coming soon"
                    )
                } else {
                    ForEach(problem.realWorldExamples) { example in
                        RealWorldExampleCard(example: example)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Graph View
    private var graphView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let graphData = problem.graphData {
                    GraphCard(graphData: graphData)
                }
            }
            .padding()
        }
    }
}

// MARK: - Explanation Tab
enum ExplanationTab: String, CaseIterable {
    case steps
    case alternatives
    case realWorld
    case graph

    var title: String {
        switch self {
        case .steps: return String(localized: "Steps")
        case .alternatives: return String(localized: "Other Methods")
        case .realWorld: return String(localized: "Real World")
        case .graph: return String(localized: "Graph")
        }
    }

    var icon: String {
        switch self {
        case .steps: return "list.number"
        case .alternatives: return "arrow.triangle.branch"
        case .realWorld: return "globe"
        case .graph: return "chart.xyaxis.line"
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? .white : Color.adaptivePrimaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? LemonMathColors.accent : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.adaptiveSecondaryText.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Step Card
struct StepCard: View {
    let step: SolutionStep
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Step number
                    ZStack {
                        Circle()
                            .fill(LemonMathColors.accent)
                            .frame(width: 36, height: 36)

                        Text("\(step.stepNumber)")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.headline)
                            .foregroundStyle(Color.adaptivePrimaryText)

                        Text(step.mathExpression)
                            .font(.subheadline)
                            .foregroundStyle(LemonMathColors.accent)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Color.adaptiveSecondaryText)
                }
                .padding()
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()

                    // Explanation
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Explanation", systemImage: "text.quote")
                            .font(.subheadline)
                            .foregroundStyle(Color.adaptiveSecondaryText)

                        Text(step.explanation)
                            .font(.body)
                            .foregroundStyle(Color.adaptivePrimaryText)
                    }

                    // Concept used
                    if let concept = step.conceptUsed {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Concept", systemImage: "lightbulb")
                                .font(.subheadline)
                                .foregroundStyle(Color.adaptiveSecondaryText)

                            Text(concept)
                                .font(.body)
                                .foregroundStyle(Color.adaptivePrimaryText)
                                .padding()
                                .background(LemonMathColors.lemonLight.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Hint
                    if let hint = step.hint {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.point.right.fill")
                                .foregroundStyle(LemonMathColors.lemonDark)

                            Text(hint)
                                .font(.callout)
                                .italic()
                                .foregroundStyle(Color.adaptiveSecondaryText)
                        }
                        .padding()
                        .background(LemonMathColors.lemonYellow.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Alternative Method Card
struct AlternativeMethodCard: View {
    let method: AlternativeMethod
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(method.name)
                            .font(.headline)
                            .foregroundStyle(Color.adaptivePrimaryText)

                        HStack(spacing: 8) {
                            Text(method.difficulty.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(method.difficulty.color.opacity(0.2))
                                .foregroundStyle(method.difficulty.color)
                                .clipShape(Capsule())

                            Text("\(method.steps.count) steps")
                                .font(.caption)
                                .foregroundStyle(Color.adaptiveSecondaryText)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Color.adaptiveSecondaryText)
                }
            }

            Text(method.description)
                .font(.subheadline)
                .foregroundStyle(Color.adaptiveSecondaryText)

            if isExpanded {
                Divider()

                ForEach(method.steps) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(step.stepNumber).")
                            .font(.caption)
                            .foregroundStyle(Color.adaptiveSecondaryText)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(step.mathExpression)
                                .font(.caption)
                                .foregroundStyle(LemonMathColors.accent)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Real World Example Card
struct RealWorldExampleCard: View {
    let example: RealWorldExample

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: example.icon)
                    .font(.title2)
                    .foregroundStyle(LemonMathColors.accent)

                Text(example.title)
                    .font(.headline)
                    .foregroundStyle(Color.adaptivePrimaryText)
            }

            Text(example.scenario)
                .font(.body)
                .foregroundStyle(Color.adaptivePrimaryText)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("How it applies")
                    .font(.caption)
                    .foregroundStyle(Color.adaptiveSecondaryText)

                Text(example.application)
                    .font(.subheadline)
                    .foregroundStyle(Color.adaptivePrimaryText)
            }
            .padding()
            .background(LemonMathColors.lemonLight.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Graph Card
struct GraphCard: View {
    let graphData: GraphData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(graphData.title)
                .font(.headline)
                .foregroundStyle(Color.adaptivePrimaryText)

            Chart {
                ForEach(graphData.points, id: \.x) { point in
                    switch graphData.type {
                    case .line:
                        LineMark(
                            x: .value(graphData.xAxisLabel, point.x),
                            y: .value(graphData.yAxisLabel, point.y)
                        )
                        .foregroundStyle(LemonMathColors.accent)

                    case .scatter:
                        PointMark(
                            x: .value(graphData.xAxisLabel, point.x),
                            y: .value(graphData.yAxisLabel, point.y)
                        )
                        .foregroundStyle(LemonMathColors.accent)

                    case .bar:
                        BarMark(
                            x: .value(graphData.xAxisLabel, point.x),
                            y: .value(graphData.yAxisLabel, point.y)
                        )
                        .foregroundStyle(LemonMathColors.accent)

                    case .area:
                        AreaMark(
                            x: .value(graphData.xAxisLabel, point.x),
                            y: .value(graphData.yAxisLabel, point.y)
                        )
                        .foregroundStyle(LemonMathColors.accent.opacity(0.3))
                    }
                }
            }
            .frame(height: 250)
            .chartXAxisLabel(graphData.xAxisLabel)
            .chartYAxisLabel(graphData.yAxisLabel)
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ExplanationView(
        problem: MathProblem(
            problemText: "2x + 5 = 15",
            problemType: .algebra,
            solution: "x = 5",
            steps: [
                SolutionStep(
                    stepNumber: 1,
                    title: "Subtract 5 from both sides",
                    explanation: "To isolate the variable term, we subtract 5 from both sides of the equation. This keeps the equation balanced.",
                    mathExpression: "2x + 5 - 5 = 15 - 5",
                    hint: "Always do the same operation to both sides!",
                    conceptUsed: "Additive Inverse Property"
                ),
                SolutionStep(
                    stepNumber: 2,
                    title: "Simplify",
                    explanation: "5 - 5 = 0 on the left side, and 15 - 5 = 10 on the right side.",
                    mathExpression: "2x = 10",
                    hint: nil,
                    conceptUsed: nil
                ),
                SolutionStep(
                    stepNumber: 3,
                    title: "Divide both sides by 2",
                    explanation: "To solve for x, we divide both sides by 2 (the coefficient of x).",
                    mathExpression: "x = 5",
                    hint: nil,
                    conceptUsed: "Division Property of Equality"
                )
            ],
            realWorldExamples: [
                RealWorldExample(
                    title: "Shopping Budget",
                    scenario: "You have $15 to spend. Each item costs $2 plus a $5 membership fee. How many items can you buy?",
                    application: "This equation models situations where you have a fixed cost plus a variable cost per item.",
                    icon: "cart"
                )
            ]
        )
    )
    .environmentObject(SettingsManager())
}
