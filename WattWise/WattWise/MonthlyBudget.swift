// MonthlyBudget.swift
// WattWise
//
// Created for month-by-month electric usage budgeting

import Foundation
import SwiftData

@Model
final class MonthlyBudget {
    var month: Int // 1 = January
    var year: Int
    var spendGoal: Double
    
    init(month: Int, year: Int, spendGoal: Double) {
        self.month = month
        self.year = year
        self.spendGoal = spendGoal
    }
    
    // For easier matching/comparison
    var identifier: String {
        "\(year)-\(String(format: "%02d", month))"
    }
}
