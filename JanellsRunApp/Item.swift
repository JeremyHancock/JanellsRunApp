//
//  Item.swift
//  JanellsRunApp
//
//  Created by Jeremy Hancock on 5/23/26.
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
