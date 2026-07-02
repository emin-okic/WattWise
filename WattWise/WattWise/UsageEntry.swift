//
//  UsageEntry.swift
//  WattWise
//
//  Created by Emin Okic on 6/27/26.
//

import Foundation

// Importing swift data since that is how the data is stored
import SwiftData

// Defining the model class now for energy usage events at home
@Model
final class UsageEntry {
    
    // Defining a timestamp for the energy usage event
    var timestamp: Date
    
    var appliance: Appliance
    
    // Energy consumed by something like a dishwasher
    var kWh: Double
    
    // This is the utility rate
    var pricePerkWh: Double
    
    // Creating an initializer
    init(
        timestamp: Date = .now,
        appliance: Appliance,
        kWh: Double = 0,
        pricePerkWh: Double = 0
    ) {
        
        self.timestamp = timestamp
        
        self.appliance = appliance
        
        self.kWh = kWh
        
        self.pricePerkWh = pricePerkWh
        
    }
    
    var estimatedCost: Double {
        
        kWh * pricePerkWh
        
    }
    
}
