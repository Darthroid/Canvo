//
//  Date.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 16.04.2026.
//

import Foundation

extension Date {
    func isWithinWeek() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)
        return self >= (sevenDaysAgo ?? now)
    }
}
