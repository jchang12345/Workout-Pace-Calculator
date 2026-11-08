import XCTest
@testable import Workout_Pace_Calculator_Running
 
final class PaceProjectionTests: XCTestCase {
 
    // MARK: Pace band
 
    func testBandForExampleRunner() throws {
        // 6:26 reference (386 s) at 92%, +/- 2 points.
        let band = try XCTUnwrap(PaceMath.paceBand(referencePace: 386, percent: 92))
 
        XCTAssertEqual(band.targetPace, 416.88, accuracy: 1e-9)
        XCTAssertEqual(band.fastPace, 409.16, accuracy: 1e-9)
        XCTAssertEqual(band.slowPace, 424.6, accuracy: 1e-9)
 
        XCTAssertEqual(PaceMath.format(band.fastPace), "6:49")
        XCTAssertEqual(PaceMath.format(band.targetPace), "6:57")
        XCTAssertEqual(PaceMath.format(band.slowPace), "7:05")
    }
 
    func testBandPercentages() throws {
        let band = try XCTUnwrap(PaceMath.paceBand(referencePace: 386, percent: 92))
        XCTAssertEqual(band.fastPercent, 94, accuracy: 1e-9)
        XCTAssertEqual(band.slowPercent, 90, accuracy: 1e-9)
    }
 
    func testBandIsSymmetricInSeconds() throws {
        let band = try XCTUnwrap(PaceMath.paceBand(referencePace: 312.7, percent: 88))
        XCTAssertEqual(band.targetPace - band.fastPace, band.slowPace - band.targetPace, accuracy: 1e-9)
    }
 
    func testCustomTolerance() throws {
        // 1 point either side of 92% on 386 s: 386 x 1.07 and 386 x 1.09.
        let band = try XCTUnwrap(PaceMath.paceBand(referencePace: 386, percent: 92, tolerance: 1))
        XCTAssertEqual(band.fastPace, 413.02, accuracy: 1e-9)
        XCTAssertEqual(band.slowPace, 420.74, accuracy: 1e-9)
    }
 
    func testZeroToleranceCollapsesToTarget() throws {
        let band = try XCTUnwrap(PaceMath.paceBand(referencePace: 386, percent: 92, tolerance: 0))
        XCTAssertEqual(band.fastPace, band.targetPace, accuracy: 1e-9)
        XCTAssertEqual(band.slowPace, band.targetPace, accuracy: 1e-9)
    }
 
    func testBandInvalidInputReturnsNil() {
        XCTAssertNil(PaceMath.paceBand(referencePace: 0, percent: 92))
        XCTAssertNil(PaceMath.paceBand(referencePace: 386, percent: 92, tolerance: -1))
        // Fast end would hit 200% or more.
        XCTAssertNil(PaceMath.paceBand(referencePace: 386, percent: 199))
        // Slow end would hit 0% or less.
        XCTAssertNil(PaceMath.paceBand(referencePace: 386, percent: 1))
    }
 
    // MARK: Projected times
 
    func testProjectedTimesAtFiveMinutesPerKm() throws {
        let pace = 300.0
        let five = try XCTUnwrap(PaceMath.projectedTime(pace: pace, unit: .perKilometer, distance: .fiveK))
        let ten = try XCTUnwrap(PaceMath.projectedTime(pace: pace, unit: .perKilometer, distance: .tenK))
        let half = try XCTUnwrap(PaceMath.projectedTime(pace: pace, unit: .perKilometer, distance: .halfMarathon))
        let full = try XCTUnwrap(PaceMath.projectedTime(pace: pace, unit: .perKilometer, distance: .marathon))
 
        XCTAssertEqual(five, 1500, accuracy: 1e-9)
        XCTAssertEqual(ten, 3000, accuracy: 1e-9)
        XCTAssertEqual(half, 6329.25, accuracy: 1e-9)
        XCTAssertEqual(full, 12658.5, accuracy: 1e-9)
 
        XCTAssertEqual(PaceMath.formatTime(five), "25:00")
        XCTAssertEqual(PaceMath.formatTime(ten), "50:00")
        XCTAssertEqual(PaceMath.formatTime(half), "1:45:29")
    }
 
    func testProjectedTimesInMiles() throws {
        // 8:00/mi.
        let five = try XCTUnwrap(PaceMath.projectedTime(pace: 480, unit: .perMile, distance: .fiveK))
        let full = try XCTUnwrap(PaceMath.projectedTime(pace: 480, unit: .perMile, distance: .marathon))
        XCTAssertEqual(PaceMath.formatTime(five), "24:51")
        XCTAssertEqual(PaceMath.formatTime(full), "3:29:45")
    }
 
    func testProjectionsForExampleBand() throws {
        // 6:26 reference at 92% +/- 2, projected from the per-mile paces.
        let band = try XCTUnwrap(PaceMath.paceBand(referencePace: 386, percent: 92))
 
        func time(_ pace: Double, _ distance: RaceDistance) throws -> String {
            PaceMath.formatTime(try XCTUnwrap(PaceMath.projectedTime(pace: pace, unit: .perMile, distance: distance)))
        }
 
        XCTAssertEqual(try time(band.targetPace, .fiveK), "21:35")
        XCTAssertEqual(try time(band.targetPace, .tenK), "43:10")
        XCTAssertEqual(try time(band.targetPace, .halfMarathon), "1:31:05")
        XCTAssertEqual(try time(band.targetPace, .marathon), "3:02:10")
 
        XCTAssertEqual(try time(band.fastPace, .fiveK), "21:11")
        XCTAssertEqual(try time(band.fastPace, .marathon), "2:58:48")
 
        XCTAssertEqual(try time(band.slowPace, .fiveK), "21:59")
        XCTAssertEqual(try time(band.slowPace, .marathon), "3:05:32")
    }
 
    func testProjectionIsUnitIndependent() throws {
        // The same real-world pace in /mi and /km must give the same finishing time.
        let perMile = 480.0
        let perKm = PaceMath.convert(perMile, from: .perMile, to: .perKilometer)
        let fromMile = try XCTUnwrap(PaceMath.projectedTime(pace: perMile, unit: .perMile, distance: .tenK))
        let fromKm = try XCTUnwrap(PaceMath.projectedTime(pace: perKm, unit: .perKilometer, distance: .tenK))
        XCTAssertEqual(fromMile, fromKm, accuracy: 1e-9)
    }
 
    func testProjectedTimeInvalidInputReturnsNil() {
        XCTAssertNil(PaceMath.projectedTime(pace: 0, unit: .perMile, distance: .fiveK))
        XCTAssertNil(PaceMath.projectedTime(pace: -10, unit: .perMile, distance: .fiveK))
        XCTAssertNil(PaceMath.projectedTime(pace: .nan, unit: .perMile, distance: .fiveK))
    }
 
    // MARK: Time formatting
 
    func testFormatTimeUnderAnHour() {
        XCTAssertEqual(PaceMath.formatTime(1295), "21:35")
        XCTAssertEqual(PaceMath.formatTime(59.4), "0:59")
        XCTAssertEqual(PaceMath.formatTime(0), "0:00")
    }
 
    func testFormatTimeWithHours() {
        XCTAssertEqual(PaceMath.formatTime(3725), "1:02:05")
        XCTAssertEqual(PaceMath.formatTime(10930), "3:02:10")
    }
 
    func testFormatTimeRolloverIntoHour() {
        XCTAssertEqual(PaceMath.formatTime(3599.6), "1:00:00")
    }
 
    func testFormatTimeInvalidValues() {
        XCTAssertEqual(PaceMath.formatTime(-1), "--:--")
        XCTAssertEqual(PaceMath.formatTime(.nan), "--:--")
        XCTAssertEqual(PaceMath.formatTime(.infinity), "--:--")
    }
}
