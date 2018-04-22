//
//  Array.swift
//  WeatherNSU
//
//  Created by Gregory on 22.04.2018.
//  Copyright © 2018 Sukhorukov Grigory. All rights reserved.
//

import Foundation

extension Array where Element == Double {
    var average: Element {
        guard self.count != 0 else {
            return 0
        }
        let av = self.reduce(0.0, { return $0.0 + $0.1 })
        return (av / Double(self.count) )
    }
}
