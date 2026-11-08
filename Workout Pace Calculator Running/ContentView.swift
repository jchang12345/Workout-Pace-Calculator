import SwiftUI
 
// MARK: - Main screen
 
struct ContentView: View {
 
    enum Mode: String, CaseIterable, Identifiable {
        case forward = "Forward"
        case reverse = "Reverse"
        var id: String { rawValue }
    }
 
    private enum Field {
        case minutes, seconds, percent
    }
 
    // What the user types. Kept as text so fields can be empty while editing.
    @State private var mode: Mode = .forward
    @State private var minutesText = "6"
    @State private var secondsText = "26"
    @State private var percentText = "92"
    @State private var inputUnit: PaceUnit = .perMile
    @State private var displayUnit: PaceUnit = .perMile
    @FocusState private var focusedField: Field?
 
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
 
                    inputCard
 
                    if let band {
                        TargetCard(band: band, inputUnit: inputUnit, displayUnit: $displayUnit)
                        ProjectionGrid(band: band, inputUnit: inputUnit, displayUnit: displayUnit)
                    } else {
                        Text("Enter a pace and a percentage to see results.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 24)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout Paces")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
    }
 
    // MARK: Input card
 
    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mode == .forward ? "Reference pace" : "Workout pace")
                .font(.subheadline)
                .foregroundStyle(.secondary)
 
            HStack(spacing: 8) {
                TextField("min", text: $minutesText)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .minutes)
                    .frame(width: 64)
 
                Text(":")
                    .font(.title2.weight(.semibold))
 
                TextField("sec", text: $secondsText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .seconds)
                    .frame(width: 72)
 
                Spacer()
 
                unitMenu(selection: $inputUnit)
            }
            .font(.title2.monospacedDigit())
            .multilineTextAlignment(.center)
            .textFieldStyle(.roundedBorder)
 
            if let message = inputMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
 
            Divider()
 
            HStack {
                Text("Percent of pace")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("%", text: $percentText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .percent)
                    .multilineTextAlignment(.trailing)
                    .font(.title2.monospacedDigit())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                Text("%")
                    .font(.title2)
            }
 
            if let message = percentMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .card()
    }
 
    private func unitMenu(selection: Binding<PaceUnit>) -> some View {
        Picker("Unit", selection: selection) {
            ForEach(PaceUnit.allCases, id: \.self) { unit in
                Text(unit.label).tag(unit)
            }
        }
        .pickerStyle(.menu)
    }
 
    // MARK: Parsing and calculation
 
    /// Empty text counts as 0 (so "0:45" works with an empty minutes box). Returns nil for junk.
    private func number(_ text: String) -> Double? {
        let cleaned = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        return cleaned.isEmpty ? 0 : Double(cleaned)
    }
 
    private var percentValue: Double? {
        let cleaned = percentText
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }
 
    private var enteredPace: Double? {
        guard let minutes = number(minutesText),
              let seconds = number(secondsText),
              seconds < 60 else { return nil }
        let total = minutes * 60 + seconds
        return total > 0 ? total : nil
    }
 
    /// Red message when the percent box holds something unusable.
    /// An empty box gets no message; the gray hint further down covers that case.
    private var percentMessage: String? {
        let trimmed = percentText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
 
        // The range needs room for the +/- tolerance on both ends, and the math
        // only works strictly between 0% and 200%.
        let lower = PaceMath.defaultTolerance
        let upper = 200 - PaceMath.defaultTolerance
        if let percent = percentValue, percent > lower, percent < upper {
            return nil
        }
        return "Enter a percentage above \(formatPercent(lower)) and below \(formatPercent(upper))."
    }
 
    private var inputMessage: String? {
        if let seconds = number(secondsText), seconds >= 60 {
            return "Seconds must be under 60."
        }
        return nil
    }
 
    /// The target pace plus fast and slow ends, or nil if the inputs aren't usable yet.
    private var band: PaceBand? {
        guard let entered = enteredPace, let percent = percentValue else { return nil }
 
        let reference: Double?
        switch mode {
        case .forward:
            reference = entered
        case .reverse:
            reference = PaceMath.referencePace(workoutPace: entered, percent: percent)
        }
 
        guard let reference else { return nil }
        return PaceMath.paceBand(referencePace: reference, percent: percent)
    }
}
 
// MARK: - Target pace card (the main event)
 
private struct TargetCard: View {
    let band: PaceBand
    let inputUnit: PaceUnit
    @Binding var displayUnit: PaceUnit
    @Environment(\.colorScheme) private var colorScheme
 
    /// A gentle top-left to bottom-right blue gradient. Dark mode uses deeper,
    /// calmer blues so the card is less glaring in a dark room (and white text stays crisp).
    private var gradient: LinearGradient {
        let colors: [Color] = colorScheme == .dark
            ? [Color(red: 0.07, green: 0.33, blue: 0.78), Color(red: 0.03, green: 0.18, blue: 0.52)]
            : [Color(red: 0.18, green: 0.52, blue: 0.98), Color(red: 0.06, green: 0.33, blue: 0.84)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
 
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("TARGET PACE")
                    .font(.caption.weight(.semibold))
                    .opacity(0.85)
                Spacer()
                Picker("Show in", selection: $displayUnit) {
                    ForEach(PaceUnit.allCases, id: \.self) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)
            }
 
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(displayPace(band.targetPace, from: inputUnit, to: displayUnit))
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(displayUnit.label)
                    .font(.title3.weight(.semibold))
            }
 
            Text("\(formatPercent(band.percent))% of \(displayPace(band.referencePace, from: inputUnit, to: inputUnit)) \(inputUnit.label)")
                .font(.subheadline)
                .opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
 
// MARK: - Fast / target / slow paces with projected race times
 
private struct ProjectionGrid: View {
    let band: PaceBand
    let inputUnit: PaceUnit
    let displayUnit: PaceUnit
 
    private struct RangeColumn: Identifiable {
        let id: String
        let title: String
        let pace: Double
        let percent: Double
        let isTarget: Bool
    }
 
    private var columns: [RangeColumn] {
        [
            RangeColumn(id: "fast", title: "Fast", pace: band.fastPace, percent: band.fastPercent, isTarget: false),
            RangeColumn(id: "target", title: "Target", pace: band.targetPace, percent: band.percent, isTarget: true),
            RangeColumn(id: "slow", title: "Slow", pace: band.slowPace, percent: band.slowPercent, isTarget: false)
        ]
    }
 
    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 12) {
            // Header: each column's pace and percentage.
            GridRow {
                Text("")
                    .frame(width: 36)
                ForEach(columns) { column in
                    VStack(spacing: 2) {
                        Text(column.title.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(column.isTarget ? Color.accentColor : .secondary)
                        Text(displayPace(column.pace, from: inputUnit, to: displayUnit))
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(column.isTarget ? Color.accentColor : .primary)
                        Text("\(formatPercent(column.percent))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
 
            Divider()
 
            // One row per race distance: finish time if that pace were held the whole way.
            ForEach(RaceDistance.allCases, id: \.self) { distance in
                GridRow {
                    Text(distance.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .leading)
                    ForEach(columns) { column in
                        Text(finishTime(pace: column.pace, distance: distance))
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(column.isTarget ? .bold : .regular)
                            .monospacedDigit()
                            .foregroundStyle(column.isTarget ? Color.accentColor : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .card()
    }
 
    private func finishTime(pace: Double, distance: RaceDistance) -> String {
        guard let seconds = PaceMath.projectedTime(pace: pace, unit: inputUnit, distance: distance) else {
            return "--:--"
        }
        return PaceMath.formatTime(seconds)
    }
}
 
// MARK: - Small helpers
 
/// Short splits (400m and under) need a decimal place to be meaningful.
private extension PaceUnit {
    var showsDecimals: Bool {
        switch self {
        case .per400m, .per200m, .per100m: return true
        case .perMile, .perKilometer: return false
        }
    }
}
 
/// Converts a pace between units and formats it for display.
private func displayPace(_ seconds: Double, from: PaceUnit, to: PaceUnit) -> String {
    let converted = PaceMath.convert(seconds, from: from, to: to)
    return PaceMath.format(converted, decimals: to.showsDecimals)
}
 
/// 92 -> "92", 92.5 -> "92.5"
private func formatPercent(_ percent: Double) -> String {
    String(format: "%g", percent)
}
 
private extension View {
    /// White (or dark-mode equivalent) rounded card used for the input and grid sections.
    func card() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
 
#Preview {
    ContentView()
}
