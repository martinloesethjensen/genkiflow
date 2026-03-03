//
//  Item.swift
//  KanjiTrainer
//
//  Created by Martin Jensen on 03/03/2026.
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
