Workout-Pace-Calculator

An iOS app for calculating workout paces as a percentage of race pace, built for quick checks on the go.

Inspired by John Davis's Pace Percentage Calculator at Running Writings. This is an independent Swift implementation: the calculation logic is written from scratch, and the app is customized with additional features for my own training use.

Why percentages of pace?

Percentage-based workouts, popularized by coaches like Renato Canova, prescribe paces relative to a goal or race pace instead of fixed seconds-per-mile rules. That scales better across very fast and very slow runners. For example, 95% of a 5:00/mi pace is 5:15/mi, and 90% is 5:30/mi.

For background, see John Davis's writing on percentage-based training.

Features
Forward mode: enter a percentage and a reference pace to get the workout pace (e.g. 95% of 5:00/mi → 5:15/mi).
Reverse mode: enter a workout pace and a percentage to find the reference pace that would produce it.
Percent of pace: percentages are applied to pace, not speed, so each percentage step is an even step in pace.
Unit conversions: convert paces between min/mi, min/km, and per-400m splits.
How the math works

Percentages are applied to pace, not speed:

workout pace   = reference pace × (2 − percent)      // percent as a decimal, e.g. 0.95
reference pace = workout pace ÷ (2 − percent)

Unit conversions scale pace by distance (1 mile = 1,609.344 m) and do not change the percentage calculation.

Status

Early development. Build order:

Pace math and unit conversions, with unit tests
SwiftUI interface
Additional features
Requirements
Xcode 26.x
iOS (deployment target to be decided)
Credits
John Davis, Running Writings — the original web calculator and the percent-of-pace approach this project is based on.
