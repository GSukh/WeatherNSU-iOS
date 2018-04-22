//
//  NewWeatherPlot.swift
//  WeatherNSU
//
//  Created by Gregory on 22.04.2018.
//  Copyright © 2018 Sukhorukov Grigory. All rights reserved.
//

import Foundation

class Weather {
    var average: Double = 0.0
    var current: Double = 0.0
    var startTimestamp: Int = 0
    var endTimestamp: Int = 0
    var graph: [TempPoint] = []
}

class TempPoint {
    var timestamp: Int = 0
    var temp: Double = 0.0
}
