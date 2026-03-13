//
//  Item.swift
//  Lock-In
//
//  Created by Shaurya Tayal on 3/13/26.
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
