import Foundation
 
// MARK: - Race distances
 
/// Standard race distances used for "if you held this pace" projections.
enum RaceDistance: CaseIterable, Equatable {
    case fiveK
    case tenK
    case halfMarathon
    case marathon
 
    /// Race distance in meters.
    var meters: Double {
        switch self {
        case .fiveK: return 5_000
        case .tenK: return 10_000
        case .halfMarathon: return 21_097.5
        case .marathon: return 42_195
        }
    }
 
    /// Short label for display.
    var label: String {
        switch self {
        case .fiveK: return "5K"
        case .tenK: return "10K"
        case .halfMarathon: return "HM"
        case .marathon: return "M"
        }
    }
}
 
// MARK: - Pace band
 
/// A target workout pace plus a fast and slow end of an acceptable range.
/// All paces are in seconds, in the same unit as the reference pace
/// that was used to build the band.
struct PaceBand: Equatable {
    let referencePace: Double
    /// Target percentage as a whole number, e.g. 92.
    let percent: Double
    /// Percentage points either side of the target, e.g. 2.
    let tolerance: Double
 
    let fastPace: Double
    let targetPace: Double
    let slowPace: Double
 
    /// The percentage at the fast end (higher percent means faster).
    var fastPercent: Double { percent + tolerance }
    /// The percentage at the slow end.
    var slowPercent: Double { percent - tolerance }
}
 
// MARK: - Logic
 
extension PaceMath {
 
    /// How far either side of the target percentage the range extends, in percentage points.
    static let defaultTolerance = 2.0
 
    /// Builds the target pace and a symmetric range around it.
    ///
    /// Example: reference 6:26, 92%, tolerance 2 gives 6:57 as the target,
    /// 6:49 (94%) at the fast end, and 7:05 (90%) at the slow end.
    ///
    /// Returns `nil` if the reference pace is invalid, the tolerance is negative,
    /// or either end of the range would fall outside 0-200%.
    static func paceBand(
        referencePace: Double,
        percent: Double,
        tolerance: Double = PaceMath.defaultTolerance
    ) -> PaceBand? {
        guard tolerance.isFinite, tolerance >= 0,
              let fast = workoutPace(referencePace: referencePace, percent: percent + tolerance),
              let target = workoutPace(referencePace: referencePace, percent: percent),
              let slow = workoutPace(referencePace: referencePace, percent: percent - tolerance)
        else { return nil }
 
        return PaceBand(
            referencePace: referencePace,
            percent: percent,
            tolerance: tolerance,
            fastPace: fast,
            targetPace: target,
            slowPace: slow
        )
    }
 
    /// Finishing time, in seconds, if `pace` were held for the whole race distance.
    /// No fatigue adjustment: this is just pace times distance.
    static func projectedTime(pace: Double, unit: PaceUnit, distance: RaceDistance) -> Double? {
        guard pace.isFinite, pace > 0 else { return nil }
        return pace * distance.meters / unit.meters
    }
 
    /// Formats a duration in seconds as "m:ss" under an hour, or "h:mm:ss" from an hour up.
    /// Rounds to the nearest second first, so 3599.6 becomes "1:00:00".
    static func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0, seconds < 360_000 else { return "--:--" }
 
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
 
        let ss = (secs < 10 ? "0" : "") + "\(secs)"
        if hours > 0 {
            let mm = (minutes < 10 ? "0" : "") + "\(minutes)"
            return "\(hours):\(mm):\(ss)"
        }
        return "\(minutes):\(ss)"
    }
}
