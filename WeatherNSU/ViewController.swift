import UIKit
import RxSwift
import RxCocoa

import Charts

class ViewController: UIViewController {
	
	@IBOutlet weak var degreesLabel: UILabel!
	@IBOutlet weak var averageDegrees: UILabel!
	@IBOutlet weak var lastUpdate: UILabel!
	
	@IBOutlet weak var updateButton: UIButton!
	
	@IBOutlet weak var plotView: LineChartView!
	
	let disposeBag = DisposeBag()
	let viewModel = ViewModel()


	override func viewDidLoad() {
		super.viewDidLoad()
		
		addBindings()
		setupPlot()
	
	}
	
	@IBAction func onUpdateButtonTap(_ sender: Any) {
		viewModel.update()
		viewModel.loadPlotData()
	}
	
	func addBindings() {
		viewModel.degrees
			.map({"Температура около НГУ: \($0!)"})
			.bindTo(degreesLabel.rx.text)
			.addDisposableTo(disposeBag)
		
		viewModel.averageDegrees
			.map({"Средняя температура за 3 дня: \($0!)"})
			.bindTo(averageDegrees.rx.text)
			.addDisposableTo(disposeBag)
		
		viewModel.plotData
			.bindNext({ (yData) in
				let array: [Double] = (yData)!
				var plotXData = Array<Double>();
				
				for i in 0 ..< (array.count) {
					plotXData.append(Double(i))
				}
				
				self.setChart(dataPoints: array, values: plotXData)
			})
			.addDisposableTo(disposeBag)
		
		viewModel.lastUpdate
			.bindTo(lastUpdate.rx.text)
			.addDisposableTo(disposeBag)
	}
	
	func setupPlot() {
		plotView.setViewPortOffsets(left: 0.0, top: 20.0, right: 0.0, bottom: 0.0)
//		plotView.backgroundColor = UIColor(red: 105/255.0, green: 241/255.0, blue: 175/255.0, alpha: 0)
		
		
		plotView.chartDescription?.enabled = false
		
		
		plotView.dragEnabled = true
		plotView.setScaleEnabled(true)
		
		
		plotView.pinchZoomEnabled = false
		
		
		plotView.drawGridBackgroundEnabled = false
		plotView.maxHighlightDistance = 300.0
		
		plotView.xAxis.enabled = false
		
		let yAxis: YAxis = plotView.leftAxis
		yAxis.labelFont = UIFont.init(name: "HelveticaNeue-Light", size: 12.0)!
		yAxis.setLabelCount(6, force: false)
		yAxis.labelTextColor = .white
		yAxis.labelPosition = .insideChart//labelPosition = YAxisLabelPositionInsideChart;
		yAxis.drawGridLinesEnabled = false
		yAxis.axisLineColor = .white
		
		plotView.rightAxis.enabled = false
		plotView.legend.enabled = false
		
//		_sliderX.value = 45.0;
//		_sliderY.value = 100.0;
//		[self slidersValueChanged:nil];
		
		plotView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
		
	}
	
	func setChart(dataPoints: [Double], values: [Double]) {
		plotView.noDataText = "You need to provide data for the chart."
		
		var dataEntries: [ChartDataEntry] = []
		
		for i in 0..<dataPoints.count {
			let dataEntry = ChartDataEntry(x: values[i], y: dataPoints[i]) //(value: values[i], xIndex: i)
			dataEntries.append(dataEntry)
		}
		
		let dataSet = LineChartDataSet(values: dataEntries, label: "Temp")
		dataSet.mode = .cubicBezier
		dataSet.cubicIntensity = 0.2
		dataSet.drawCirclesEnabled = false
		dataSet.lineWidth = 1.8
		dataSet.circleRadius = 4.0
		dataSet.setCircleColor(.white)
		
		dataSet.highlightColor = UIColor(red: 244/255.0, green: 117/255.0, blue: 117/255.0, alpha: 1.0)
		dataSet.setColor(.blue)
		dataSet.fillColor = UIColor(red: 105/255.0, green: 241/255.0, blue: 175/255.0, alpha: 1.0)
		dataSet.fillAlpha = 1.0
		
		dataSet.drawHorizontalHighlightIndicatorEnabled = false
		dataSet.fillFormatter = CubicLineSampleFillFormatter()
		
		dataSet.drawFilledEnabled = true
		
//		LineChartData *data = [[LineChartData alloc] initWithDataSet:set1];
//		[data setValueFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:9.f]];
//		[data setDrawValues:NO];

		let chartData = LineChartData.init(dataSets: [dataSet])
		chartData.setValueFont(UIFont.init(name: "HelveticaNeue-Light", size: 9.0))
		chartData.setDrawValues(false)
		plotView.data = chartData
		
	}
	


}

