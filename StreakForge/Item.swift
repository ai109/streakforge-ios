//
//  Item.swift
//  StreakForge
//
//  Created by Angel Ivanov on 27.04.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
