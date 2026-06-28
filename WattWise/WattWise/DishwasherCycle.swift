//
//  DishwasherCycle.swift
//  WattWise
//
//  Created by Emin Okic on 6/27/26.
//

import Foundation

struct DishwasherCycle {
    
    let kWh: Double
    
    let pricePerkWh: Double
    
    var estimatedCost: Double {
        
        kWh * pricePerkWh
        
    }
}
