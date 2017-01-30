import Foundation
import Charts

class ToZeroFillFormatter: IFillFormatter {
	func getFillLinePosition(dataSet: ILineChartDataSet, dataProvider: LineChartDataProvider) -> CGFloat {
		return 0.0
	}
}
