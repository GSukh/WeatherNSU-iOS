//
//  CubicLineSampleFillFormatter.swift
//  WeatherNSU
//
//  Created by Sukhorukov Grigory on 29.01.17.
//  Copyright © 2017 Sukhorukov Grigory. All rights reserved.
//

import Foundation
import Charts

class CubicLineSampleFillFormatter: IFillFormatter {
	func getFillLinePosition(dataSet: ILineChartDataSet, dataProvider: LineChartDataProvider) -> CGFloat {
		return 0.0
	}
}
