import Foundation
 
// MARK: - Units
 
/// A distance basis for expressing pace (e.g. minutes per mile).
/// To add another unit later, add a case and its `meters` and `label`.
enum PaceUnit: CaseIterable, Equatable {
    case perMile
    case perKilometer
    case per400m
    case per200m
    case per100m
 
    /// Distance this pace is measured over, in meters.
    var meters: Double {
        switch self {
        case .perMile: return 1609.344
        case .perKilometer: return 1000
        case .per400m: return 400
        case .per200m: return 200
        case .per100m: return 100
        }
    }
 
    /// Short label for display, e.g. "/mi".
    var label: String {
        switch self {
        case .perMile: return "/mi"
        case .perKilometer: return "/km"
        case .per400m: return "/400m"
        case .per200m: return "/200m"
        case .per100m: return "/100m"
        }
    }
}
 
// MARK: - Math
 
/// Pure pace calculations. Paces are plain `Double` seconds in whatever unit
/// the caller is using (seconds per mile, per km, etc.), so the percentage
/// math works the same regardless of unit.
enum PaceMath {
 
    // MARK: Percent of pace
 
    /// Workout pace for a given percentage of a reference pace.
    /// Percentages apply to pace (not speed): 90% of 5:00 is 5:30.
    ///
    /// - Parameters:
    ///   - referencePace: reference (e.g. race) pace in seconds.
    ///   - percent: percentage as a whole number, e.g. 95 for 95%.
    /// - Returns: workout pace in seconds, or `nil` for invalid input.
    static func workoutPace(referencePace: Double, percent: Double) -> Double? {
        guard isValidPace(referencePace), isValidPercent(percent) else { return nil }
        return referencePace * (2 - percent / 100)
    }
 
    /// Reverse of `workoutPace`: the reference pace that would produce
    /// `workoutPace` at the given percentage.
    static func referencePace(workoutPace: Double, percent: Double) -> Double? {
        guard isValidPace(workoutPace), isValidPercent(percent) else { return nil }
        return workoutPace / (2 - percent / 100)
    }
 
    // MARK: Unit conversion
 
    /// Converts a pace between units. Percentages are unaffected by unit.
    static func convert(_ pace: Double, from: PaceUnit, to: PaceUnit) -> Double {
        pace * to.meters / from.meters
    }
 
    // MARK: Formatting
 
    /// Formats seconds as "m:ss", or "m:ss.s" when `decimals` is true.
    /// Rounds to the nearest second (or tenth) first, so 59.6 becomes "1:00",
    /// never "0:60".
    static func format(_ seconds: Double, decimals: Bool = false) -> String {
        guard seconds.isFinite, seconds >= 0, seconds < 360_000 else { return "--:--" }
 
        let scale = decimals ? 10 : 1
        let total = Int((seconds * Double(scale)).rounded())
        let minutes = total / (60 * scale)
        let remainder = total % (60 * scale)
        let wholeSeconds = remainder / scale
        let tenths = remainder % scale
 
        let base = "\(minutes):" + (wholeSeconds < 10 ? "0" : "") + "\(wholeSeconds)"
        return decimals ? base + ".\(tenths)" : base
    }
 
    // MARK: Validation
 
    private static func isValidPace(_ pace: Double) -> Bool {
        pace.isFinite && pace > 0
    }
 
    /// Valid range is 0% to 200% exclusive. At 200% the formula gives a
    /// pace of zero, and beyond that it goes negative, so those make no sense.
    private static func isValidPercent(_ percent: Double) -> Bool {
        percent.isFinite && percent > 0 && percent < 200
    }
}
