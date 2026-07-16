//
//  AddDishwasherCycleView.swift
//  WattWise
//
//  Created by Emin Okic on 6/27/26.
//

import SwiftUI
import SwiftData

struct AddUsageEntryView: View {

    enum AddEntryStep: Int, CaseIterable, Identifiable {
        case group, appliance, energy, review

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .group: return "Group"
            case .appliance: return "Appliance"
            case .energy: return "Energy"
            case .review: return "Review"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var groups: [UsageGroup]

    @State private var step: AddEntryStep = .group
    @State private var selectedGroup: UsageGroup? = nil
    @State private var selectedGroupIndex: Int = 0
    @State private var appliance: Appliance = .dishwasher
    @State private var kWh: Double = 1.20
    @State private var pricePerkWh: Double = 0.14
    @State private var showCelebration: Bool = false

    private var estimatedCost: Double {
        kWh * pricePerkWh
    }

    private var isNextButtonDisabled: Bool {
        switch step {
        case .group:
            return selectedGroup == nil
        case .appliance:
            return false // appliance always has a default value
        case .energy:
            return kWh <= 0 || pricePerkWh <= 0
        case .review:
            return false
        }
    }

    private var stepCount: Int { AddEntryStep.allCases.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                StepIndicator(currentStep: step)

                Group {
                    switch step {
                    case .group:
                        groupStepView
                            .transition(stepTransition)
                    case .appliance:
                        applianceStepView
                            .transition(stepTransition)
                    case .energy:
                        energyStepView
                            .transition(stepTransition)
                    case .review:
                        reviewStepView
                            .transition(stepTransition)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: step)
            }
            .padding([.horizontal, .top])
            .ignoresSafeArea(.keyboard)
            .navigationTitle("Add Usage")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel adding usage entry")
                }
            }
            .overlay {
                if showCelebration {
                    CelebrationOverlay(isVisible: $showCelebration)
                        .zIndex(10)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation {
                                    showCelebration = false
                                }
                                dismiss()
                            }
                        }
                }
            }
            .onAppear {
                if selectedGroup == nil {
                    if let uncIndex = groups.firstIndex(where: { $0.name == "Uncategorized" }) {
                        selectedGroupIndex = uncIndex
                        selectedGroup = groups[uncIndex]
                    } else if let homeIndex = groups.firstIndex(where: { $0.name == "Home" }) {
                        selectedGroupIndex = homeIndex
                        selectedGroup = groups[homeIndex]
                    } else if !groups.isEmpty {
                        selectedGroupIndex = 0
                        selectedGroup = groups[0]
                    }
                } else if let group = selectedGroup,
                          let idx = groups.firstIndex(where: { $0.name == group.name }) {
                    selectedGroupIndex = idx
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomToolbar
                    .background(.ultraThinMaterial)
                    .padding(.top, 6)
            }
        }
    }

    private var stepTransition: AnyTransition {
        // Determine direction of transition based on step change
        // Since animation is bound to step, direction can be deduced by comparing old and new step.
        // But here, we have just the current step, so assume forward is trailing, backward is leading.
        // For simplicity, use trailing for forward, leading for backward.
        // We will not track previous step, just use trailing always.
        // This can be improved but not required.
        .move(edge: .trailing)
    }

    private var groupStepView: some View {
        Form {
            Section("Select Group") {
                Picker("Group", selection: $selectedGroupIndex) {
                    ForEach(groups.indices, id: \.self) { idx in
                        Text(groups[idx].name).tag(idx)
                    }
                }
                .pickerStyle(.wheel)
                .onChange(of: selectedGroupIndex) { idx in
                    if groups.indices.contains(idx) {
                        selectedGroup = groups[idx]
                    } else {
                        selectedGroup = nil
                    }
                }
                .accessibilityLabel("Select usage group")
            }
        }
        .listStyle(.plain)
        .frame(maxHeight: 250)
    }

    private var applianceStepView: some View {
        Form {
            Section("Select Appliance") {
                Picker("Appliance", selection: $appliance) {
                    ForEach(Appliance.allCases, id: \.self) { appl in
                        Text(appl.rawValue).tag(appl)
                    }
                }
                .pickerStyle(.wheel)
                .accessibilityLabel("Select appliance type")
            }
        }
        .listStyle(.plain)
        .frame(maxHeight: 250)
    }

    private var energyStepView: some View {
        Form {
            Section("Energy Used (kWh)") {
                TextField("Energy Used (kWh)", value: $kWh, format: .number)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel("Energy used in kilowatt-hours")
            }
            Section("Electric Rate ($/kWh)") {
                TextField("Electric Rate ($/kWh)", value: $pricePerkWh, format: .number)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel("Electric rate per kilowatt-hour")
            }
        }
        .listStyle(.plain)
        .frame(maxHeight: 250)
    }

    private var reviewStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                HStack {
                    Text("Group:")
                        .bold()
                    Spacer()
                    Text(selectedGroup?.name ?? "—")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Appliance:")
                        .bold()
                    Spacer()
                    Text(appliance.rawValue)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Energy Used (kWh):")
                        .bold()
                    Spacer()
                    Text(kWh, format: .number.precision(.fractionLength(2)))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Price per kWh:")
                        .bold()
                    Spacer()
                    Text(pricePerkWh, format: .currency(code: "USD").precision(.fractionLength(3)))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Estimated Cost:")
                        .bold()
                    Spacer()
                    Text(estimatedCost, format: .currency(code: "USD").precision(.fractionLength(2)))
                        .foregroundColor(.accentColor)
                        .font(.title3.weight(.semibold))
                }
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .frame(maxHeight: 250)
    }

    private var bottomToolbar: some View {
        HStack {
            if step != .group {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        step = AddEntryStep(rawValue: step.rawValue - 1) ?? .group
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .accessibilityLabel("Back to previous step")
            } else {
                // To keep spacing consistent
                Spacer().frame(width: 80)
            }

            Spacer()

            if step != .review {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        step = AddEntryStep(rawValue: step.rawValue + 1) ?? .review
                    }
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .disabled(isNextButtonDisabled)
                .accessibilityLabel("Next step")
            } else {
                Button {
                    saveEntry()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .disabled(isNextButtonDisabled)
                .accessibilityLabel("Save usage entry")
            }
        }
        .font(.headline)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemBackground).opacity(0.95))
    }

    private func saveEntry() {
        guard let group = selectedGroup else { return }
        let entry = UsageEntry(appliance: appliance, kWh: kWh, pricePerkWh: pricePerkWh)
        entry.group = group
        modelContext.insert(entry)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.easeInOut(duration: 0.3)) {
            showCelebration = true
        }
    }

    struct StepIndicator: View {
        let currentStep: AddEntryStep

        var body: some View {
            HStack(spacing: 8) {
                ForEach(AddEntryStep.allCases) { step in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(step == currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 26, height: 26)
                            .overlay(
                                Text("\(step.rawValue + 1)")
                                    .font(.footnote.weight(.bold))
                                    .foregroundColor(step == currentStep ? .white : .gray)
                            )
                        Text(step.title)
                            .font(.caption2)
                            .foregroundColor(step == currentStep ? Color.accentColor : Color.gray)
                            .fixedSize()
                    }
                    if step != AddEntryStep.allCases.last {
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(step.rawValue < currentStep.rawValue ? .accentColor : .gray.opacity(0.3))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    struct CelebrationOverlay: View {
        @Binding var isVisible: Bool
        @State private var confettiOffsets: [CGSize] = []
        @State private var animateConfetti = false

        private let confettiCount = 30

        private struct ConfettiDot: View {
            let color: Color
            let offset: CGSize
            let animate: Bool
            let delay: Double

            var body: some View {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .offset(offset)
                    .opacity(animate ? 1 : 0)
                    .animation(
                        Animation
                            .easeInOut(duration: 1.4)
                            .delay(delay)
                            .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }

        var body: some View {
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isVisible = false
                        }
                    }

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(.tint)
                            .frame(width: 140, height: 140)
                            .shadow(color: Color.accentColor.opacity(0.8), radius: 15, x: 0, y: 0)
                            .glow(color: Color.accentColor.opacity(0.7), radius: 15)

                        Image(systemName: "checkmark")
                            .font(.system(size: 70, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.7), radius: 8, x: 0, y: 0)
                    }
                    .scaleEffect(isVisible ? 1.0 : 0.1)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isVisible)

                    ZStack {
                        ForEach(Array(confettiOffsets.enumerated()), id: \.offset) { index, offset in
                            ConfettiDot(
                                color: randomColor(for: index),
                                offset: offset,
                                animate: animateConfetti,
                                delay: Double(index) * 0.03
                            )
                        }
                    }
                    .frame(height: 150)
                    .onAppear {
                        resetConfetti()
                        animateConfetti = true
                    }
                }
                .padding()
            }
            .transition(.opacity.combined(with: .scale))
            .onChange(of: isVisible) { visible in
                if visible {
                    resetConfetti()
                    animateConfetti = true
                } else {
                    animateConfetti = false
                }
            }
        }

        private func resetConfetti() {
            var newOffsets: [CGSize] = []
            for _ in 0..<confettiCount {
                let x = CGFloat.random(in: -150...150)
                let y = CGFloat.random(in: -200...(-50))
                newOffsets.append(CGSize(width: x, height: y))
            }
            confettiOffsets = newOffsets
        }

        private func randomColor(for index: Int) -> Color {
            let colors: [Color] = [
                .red, .green, .blue, .yellow, .pink, .orange, .purple, .mint
            ]
            return colors[index % colors.count]
        }
    }
}

private extension View {
    func glow(color: Color, radius: CGFloat) -> some View {
        self.shadow(color: color, radius: radius)
            .shadow(color: color.opacity(0.5), radius: radius / 2)
    }
}


#Preview {
    // In-memory model container setup to preview the view with some dummy groups
    let container = try! ModelContainer(for: UsageEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    // Seed default groups if none exist (mock only for preview)
    if (try? context.fetch(FetchDescriptor<UsageGroup>()))?.contains(where: { $0.name == "Uncategorized" }) == false {
        let unc = UsageGroup(name: "Uncategorized")
        context.insert(unc)
    }
    if (try? context.fetch(FetchDescriptor<UsageGroup>()))?.contains(where: { $0.name == "Home" }) == false {
        let home = UsageGroup(name: "Home")
        context.insert(home)
    }

    return AddUsageEntryView()
        .modelContainer(container)
}
