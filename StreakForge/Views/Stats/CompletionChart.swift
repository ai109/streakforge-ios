//
//  CompletionChart.swift
//  StreakForge
//
//  Apple Charts wrapper that renders the daily-completion bar series.
//

import SwiftUI
import Charts

/// Bar chart of daily completion counts over a fixed window.
///
/// Wraps Apple's `Charts` so the rest of the app doesn't have to learn
/// the Charts DSL — and so the styling (bar gradient, axis labels,
/// y-stride) can be tuned in one place.
///
/// The series is always continuous (zero-filled) — see `StatsData`'s
/// `dailyCompletions` doc comment for why.
struct CompletionChart: View {

    let data: [StatsData.DailyCount]

    var body: some View {
        Chart(data) { point in
            BarMark(
                // `unit: .day` tells Charts each bar represents a single
                // day, which lets the framework size and space the bars
                // automatically as the window grows from 7 to 30 days.
                x: .value("Day", point.date, unit: .day),
                y: .value("Completed", point.count)
            )
            // Vertical gradient on the bars matches the brand's flame
            // language without requiring an explicit asset — bottom-up
            // primary→accent reads as "warming up" the more activity
            // there is.
            .foregroundStyle(
                LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            // Slightly rounded bar tops — softer feel, still reads as
            // a bar chart, doesn't blur the value at small heights.
            .cornerRadius(4)
        }
        // X axis: weekday-abbreviated labels (Mon/Tue/…) on the week
        // view, and dates auto-strided on the month view. Charts picks
        // a sensible cadence on its own — we just provide the format.
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: data.count <= 7 ? 7 : 6)) { value in
                AxisValueLabel(
                    format: data.count <= 7
                        ? Date.FormatStyle().weekday(.abbreviated)
                        : Date.FormatStyle().month(.defaultDigits).day()
                )
                .font(AppTypography.numericTabular)
                .foregroundStyle(AppColors.textMuted)
                AxisGridLine()
                    .foregroundStyle(AppColors.divider.opacity(0.5))
            }
        }
        // Y axis: integer ticks only (you can't half-complete a
        // challenge), and capped to a sensible default count so we
        // don't draw every integer between 0 and 4.
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel()
                    .font(AppTypography.numericTabular)
                    .foregroundStyle(AppColors.textMuted)
                AxisGridLine()
                    .foregroundStyle(AppColors.divider.opacity(0.5))
            }
        }
        // Keep at least 0…3 visible even on quiet weeks, so bars don't
        // fill the canvas just because the user did 1 challenge total.
        // 3 is the daily ceiling so a single full day reaches the top.
        .chartYScale(domain: 0...max(3, (data.map(\.count).max() ?? 0)))
    }
}

#Preview("Week") {
    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)
    let data = (0..<7).map { offset in
        StatsData.DailyCount(
            date: cal.date(byAdding: .day, value: -6 + offset, to: today)!,
            count: [1, 2, 3, 0, 1, 2, 3][offset]
        )
    }
    return CompletionChart(data: data)
        .frame(height: 220)
        .padding()
        .background(AppColors.background)
}

#Preview("Month") {
    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)
    let data = (0..<30).map { offset in
        StatsData.DailyCount(
            date: cal.date(byAdding: .day, value: -29 + offset, to: today)!,
            count: Int.random(in: 0...3)
        )
    }
    return CompletionChart(data: data)
        .frame(height: 220)
        .padding()
        .background(AppColors.background)
}
