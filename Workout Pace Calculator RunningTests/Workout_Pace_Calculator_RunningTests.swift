import XCTest
@testable import Workout_Pace_Calculator_Running
 
final class PaceMathTests: XCTestCase {
 
    // MARK: Forward mode
 
    func testWorkoutPaceMatchesWebAppExamples() throws {
        // From the original calculator: 95% of 5:00 is 5:15, 90% is 5:30, 80% is 6:00.
        XCTAssertEqual(try XCTUnwrap(PaceMath.workoutPace(referencePace: 300, percent: 95)), 315, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(PaceMath.workoutPace(referencePace: 300, percent: 90)), 330, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(PaceMath.workoutPace(referencePace: 300, percent: 80)), 360, accuracy: 1e-9)
    }
 
    func testHundredPercentIsIdentity() throws {
        XCTAssertEqual(try XCTUnwrap(PaceMath.workoutPace(referencePace: 287.5, percent: 100)), 287.5, accuracy: 1e-9)
    }
 
    // MARK: Reverse mode
 
    func testReversePaceMatchesWebAppExample() throws {
        // From the original calculator: 5:24 at 90% comes from a 4:55 reference pace.
        let reference = try XCTUnwrap(PaceMath.referencePace(workoutPace: 324, percent: 90))
        XCTAssertEqual(reference, 294.5454545, accuracy: 1e-6)
        XCTAssertEqual(PaceMath.format(reference), "4:55")
    }
 
    func testForwardThenReverseRoundTrips() throws {
        for percent in [75.0, 85, 91.5, 95, 100, 102] {
            let workout = try XCTUnwrap(PaceMath.workoutPace(referencePace: 312.3, percent: percent))
            let back = try XCTUnwrap(PaceMath.referencePace(workoutPace: workout, percent: percent))
            XCTAssertEqual(back, 312.3, accuracy: 1e-9, "round trip failed at \(percent)%")
        }
    }
 
    // MARK: Invalid input
 
    func testInvalidInputReturnsNil() {
        XCTAssertNil(PaceMath.workoutPace(referencePace: 0, percent: 95))
        XCTAssertNil(PaceMath.workoutPace(referencePace: -300, percent: 95))
        XCTAssertNil(PaceMath.workoutPace(referencePace: .nan, percent: 95))
        XCTAssertNil(PaceMath.workoutPace(referencePace: 300, percent: 0))
        XCTAssertNil(PaceMath.workoutPace(referencePace: 300, percent: 200))
        XCTAssertNil(PaceMath.workoutPace(referencePace: 300, percent: 250))
        XCTAssertNil(PaceMath.referencePace(workoutPace: 300, percent: 200))
        XCTAssertNil(PaceMath.referencePace(workoutPace: .infinity, percent: 90))
    }
 
    // MARK: Unit conversion
 
    func testConvertSameUnitIsIdentity() {
        XCTAssertEqual(PaceMath.convert(300, from: .perMile, to: .perMile), 300, accuracy: 1e-9)
    }
 
    func testConvertMileToKilometerAndQuarterMile() {
        // 8:00/mi is about 4:58/km and 1:59 per 400m.
        let perKm = PaceMath.convert(480, from: .perMile, to: .perKilometer)
        let per400 = PaceMath.convert(480, from: .perMile, to: .per400m)
        XCTAssertEqual(PaceMath.format(perKm), "4:58")
        XCTAssertEqual(PaceMath.format(per400), "1:59")
    }
 
    func testConvertKilometerToMileAndQuarterMile() {
        // 5:00/km is about 8:03/mi and exactly 2:00 per 400m.
        let perMile = PaceMath.convert(300, from: .perKilometer, to: .perMile)
        let per400 = PaceMath.convert(300, from: .perKilometer, to: .per400m)
        XCTAssertEqual(PaceMath.format(perMile), "8:03")
        XCTAssertEqual(per400, 120, accuracy: 1e-9)
    }
 
    func testConvertTo200m() {
        // 5:00/km and 2:00 per 400m are both 1:00 per 200m.
        XCTAssertEqual(PaceMath.convert(300, from: .perKilometer, to: .per200m), 60, accuracy: 1e-9)
        XCTAssertEqual(PaceMath.convert(120, from: .per400m, to: .per200m), 60, accuracy: 1e-9)
        // 8:00/mi is about 59.7 seconds per 200m.
        let perMileTo200 = PaceMath.convert(480, from: .perMile, to: .per200m)
        XCTAssertEqual(PaceMath.format(perMileTo200, decimals: true), "0:59.7")
    }
 
    func testConvertTo100m() {
        // 5:00/km is 30 seconds per 100m, and half of a 200m split.
        XCTAssertEqual(PaceMath.convert(300, from: .perKilometer, to: .per100m), 30, accuracy: 1e-9)
        XCTAssertEqual(PaceMath.convert(60, from: .per200m, to: .per100m), 30, accuracy: 1e-9)
        XCTAssertEqual(PaceMath.format(30), "0:30")
    }
 
    func testConversionRoundTrips() {
        let original = 337.0
        let there = PaceMath.convert(original, from: .perMile, to: .per400m)
        let back = PaceMath.convert(there, from: .per400m, to: .perMile)
        XCTAssertEqual(back, original, accuracy: 1e-9)
    }
 
    func testPercentIsUnitIndependent() throws {
        // 95% of 8:00/mi, converted to /km, equals 95% of the /km version of 8:00/mi.
        let ref = 480.0
        let workoutThenConvert = PaceMath.convert(
            try XCTUnwrap(PaceMath.workoutPace(referencePace: ref, percent: 95)),
            from: .perMile, to: .perKilometer)
        let convertThenWorkout = try XCTUnwrap(PaceMath.workoutPace(
            referencePace: PaceMath.convert(ref, from: .perMile, to: .perKilometer),
            percent: 95))
        XCTAssertEqual(workoutThenConvert, convertThenWorkout, accuracy: 1e-9)
    }
 
    // MARK: Formatting
 
    func testFormatBasics() {
        XCTAssertEqual(PaceMath.format(315), "5:15")
        XCTAssertEqual(PaceMath.format(305), "5:05")
        XCTAssertEqual(PaceMath.format(0), "0:00")
    }
 
    func testFormatRoundsInsteadOfTruncating() {
        XCTAssertEqual(PaceMath.format(294.54), "4:55")
    }
 
    func testFormatRolloverNeverShowsSixty() {
        XCTAssertEqual(PaceMath.format(59.6), "1:00")
        XCTAssertEqual(PaceMath.format(299.7), "5:00")
        XCTAssertEqual(PaceMath.format(59.96, decimals: true), "1:00.0")
    }
 
    func testFormatDecimals() {
        XCTAssertEqual(PaceMath.format(315.84, decimals: true), "5:15.8")
        XCTAssertEqual(PaceMath.format(315, decimals: true), "5:15.0")
    }
 
    func testFormatInvalidValues() {
        XCTAssertEqual(PaceMath.format(-5), "--:--")
        XCTAssertEqual(PaceMath.format(.nan), "--:--")
        XCTAssertEqual(PaceMath.format(.infinity), "--:--")
    }
}
