import Foundation
import RoomPlan

// MARK: - Room Scan Result

struct RoomScanResult: Identifiable, Codable {
    let id: UUID
    let date: Date
    let roomName: String
    var walls: [WallSurface]
    var ceiling: CeilingSurface?
    var openings: [Opening] // doors + windows
    var customRate: Double // $ per sqft

    // Computed paintable areas
    var totalWallArea: Double {
        walls.reduce(0) { $0 + $1.paintableArea }
    }

    var totalCeilingArea: Double {
        ceiling?.area ?? 0
    }

    var totalOpeningArea: Double {
        openings.reduce(0) { $0 + $1.area }
    }

    var totalPaintableArea: Double {
        totalWallArea + totalCeilingArea - totalOpeningArea
    }

    var estimatedBid: Double {
        totalPaintableArea * customRate
    }

    init(roomName: String = "Room", rate: Double = 1.95) {
        self.id = UUID()
        self.date = Date()
        self.roomName = roomName
        self.walls = []
        self.ceiling = nil
        self.openings = []
        self.customRate = rate
    }
}

struct WallSurface: Identifiable, Codable {
    let id: UUID
    var width: Double  // meters
    var height: Double // meters
    var label: String

    var area: Double { width * height }

    // Subtract openings on this wall
    var paintableArea: Double { area }

    init(width: Double, height: Double, label: String = "Wall") {
        self.id = UUID()
        self.width = width
        self.height = height
        self.label = label
    }
}

struct CeilingSurface: Codable {
    var width: Double
    var length: Double
    var area: Double { width * length }
}

struct Opening: Identifiable, Codable {
    enum OpeningType: String, Codable {
        case door = "Door"
        case window = "Window"
    }

    let id: UUID
    var type: OpeningType
    var width: Double
    var height: Double
    var area: Double { width * height }

    init(type: OpeningType, width: Double, height: Double) {
        self.id = UUID()
        self.type = type
        self.width = width
        self.height = height
    }
}

// MARK: - Unit Helpers

extension Double {
    /// Convert square meters to square feet
    var sqFeet: Double { self * 10.7639 }

    /// Format as currency
    var currency: String {
        String(format: "$%.2f", self)
    }

    /// Format as sqft
    var sqftFormatted: String {
        String(format: "%.1f sqft", self.sqFeet)
    }
}
