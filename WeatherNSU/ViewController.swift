import UIKit
import RxSwift
import RxCocoa

import Charts

extension Reactive where Base: ViewController {
    var plotData: AnyObserver<[Double]?> {
        return UIBindingObserver(UIElement: base) { vc, data in
            vc.updateData(data)
        }.asObserver()
    }
}

extension ViewController {
    func updateData(_ data: [Double]?) {
        var array: [Double] = (data)!
        var plotXData = Array<Double>();
        
        var av = 0.0
        
        let now: Int = Int(NSDate().timeIntervalSince1970)
        let oneDay: Int = 60 * 60 * 24
        let step: Int = Int( Double(3 * oneDay) / Double(array.count) )
        
        for i in 0 ..< (array.count) {
            plotXData.append(Double(now - 3 * oneDay + step * i))
            av += array[i]
        }
        av /= Double(array.count)
        averageLimitLine.limit = av
        averageLimitLine.label = String.init(format: "В среднем %0.2f °C", av)
        
        if let currentTemp = array.last {
            degreesLimitLine.limit = currentTemp
//            degreesLimitLine.label = String.init(format: "%0.1f °C", currentTemp)

			if fabs(currentTemp - av) < 30 {
				degreesLimitLine.labelPosition = currentTemp > av ? .rightTop : .rightBottom
				averageLimitLine.labelPosition = currentTemp > av ? .rightBottom : .rightTop
			}
			else {
				degreesLimitLine.labelPosition = currentTemp > av ? .rightBottom : .rightTop
				averageLimitLine.labelPosition = currentTemp > av ? .rightTop : .rightBottom
			}
		}
		
        array[0] = av > 0 ? 0.9 : -0.9
		
        self.setChart(dataPoints: array, values: plotXData)
    }
}

class ViewController: UIViewController {

	@IBOutlet weak var degreesLabel: UILabel!
	@IBOutlet weak var avDegreesLabel: UILabel!
	
	@IBOutlet weak var linksTextView: UITextView!
	
	@IBOutlet weak var updateButton: UIButton!
	
	@IBOutlet weak var plotView: LineChartView!
    var degreesLimitLine: ChartLimitLine!
    var averageLimitLine: ChartLimitLine!
	
	let disposeBag = DisposeBag()
	let viewModel = ViewModel()


	override func viewDidLoad() {
		super.viewDidLoad()
		
		addBindings()
		setupPlot()
		setupLinks()
		
		viewModel.update()
        viewModel.loadPlotData()
	}
	
	@IBAction func onUpdateButtonTap(_ sender: Any) {
		viewModel.update()
		viewModel.loadPlotData()
	}
	
	func addBindings() {
		viewModel.plotData
            .bindTo(rx.plotData)
			.addDisposableTo(disposeBag)
		
		viewModel.plotData
			.map({ String.init(format: "Средняя температура за 3 дня %0.2f °C", self.average(values: $0!)) })
			.bindTo(avDegreesLabel.rx.text)
			.addDisposableTo(disposeBag)
		
		viewModel.degrees
			.map({ "Температура около НГУ \($0!)" })
			.bindTo(degreesLabel.rx.text)
			.addDisposableTo(disposeBag)
		
		viewModel.degrees
			.bindNext { (degreesString) in
				self.degreesLimitLine.label = degreesString!
			}
			.addDisposableTo(disposeBag)
	}
	
	func setupLinks() {
		
		let phrases = ["Прогноз Яндекс", "\nПрогноз Gismeteo", "\n\nДанные предоставленны сайтом ", "weather.nsu.ru"]
		let links = ["https://yandex.ru/pogoda/novosibirsk", "https://www.gismeteo.ru/weather-novosibirsk-4690/", "", "http://weather.nsu.ru/"]
		
		let attrString = NSMutableAttributedString()
		
		for i in 0 ... 3 {
			
			let phrase = phrases[i]
			let link = links[i]
			
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center
			
			if link == "" {
				let linkAttributes = [
					NSParagraphStyleAttributeName: paragraphStyle] as [String : Any]
				let attrPhrase = NSAttributedString.init(string: phrase, attributes: linkAttributes)
				attrString.append(attrPhrase)
			}
			else {
				let linkAttributes = [
					NSLinkAttributeName: NSURL(string: links[i])!,
					NSForegroundColorAttributeName: UIColor.blue,
					NSParagraphStyleAttributeName: paragraphStyle] as [String : Any]
				let attrPhrase = NSAttributedString.init(string: phrase, attributes: linkAttributes)
				attrString.append(attrPhrase)
			}
		}
		self.linksTextView.attributedText = attrString
	}
	
	func setupPlot() {
		plotView.setViewPortOffsets(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0)
		
		
		plotView.chartDescription?.enabled = false
		
		
		plotView.dragEnabled = true
		plotView.setScaleEnabled(true)
		
		
		plotView.pinchZoomEnabled = false
		
		
		plotView.drawGridBackgroundEnabled = false
		plotView.maxHighlightDistance = 300.0
		
		plotView.xAxis.enabled = true
        let xAxis = plotView.xAxis
        xAxis.labelPosition = .top
        xAxis.drawGridLinesEnabled = false
        
        addXLimitLines()
        
		
		let yAxis: YAxis = plotView.leftAxis
		yAxis.labelFont = UIFont.init(name: "HelveticaNeue-Light", size: 12.0)!
		yAxis.setLabelCount(12, force: false)
		yAxis.labelTextColor = .black
		yAxis.labelPosition = .insideChart
		yAxis.drawGridLinesEnabled = true
        
        yAxis.gridLineDashPhase = CGFloat(1)
        yAxis.gridLineDashLengths = [1, 27, 1000]
		yAxis.axisLineColor = .black
        
        degreesLimitLine = ChartLimitLine.init(limit: 0, label: "")
        degreesLimitLine.labelPosition = .rightTop
        degreesLimitLine.valueFont = UIFont.init(name: "HelveticaNeue-Bold", size: 14.0)!
        degreesLimitLine.lineColor = .black
        degreesLimitLine.lineWidth = 0.75
        yAxis.addLimitLine(degreesLimitLine)
        
        averageLimitLine = ChartLimitLine.init(limit: 0, label: "Среднее")
        averageLimitLine.labelPosition = .rightTop
        averageLimitLine.valueFont = UIFont.init(name: "HelveticaNeue-Light", size: 14.0)!
        averageLimitLine.lineColor = .black
        averageLimitLine.lineWidth = 0.75
        yAxis.addLimitLine(averageLimitLine)

		plotView.rightAxis.enabled = false
		plotView.legend.enabled = false
		
		plotView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
	}
    
    func addXLimitLines() {
		let xAxis = plotView.xAxis
        xAxis.removeAllLimitLines()
        
        let now = Date()
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents(in: TimeZone.current, from: now)
        
        let hour = dateComponents.hour! * 60 * 60
        let min = dateComponents.minute! * 60
        let sec = dateComponents.second!
        let nowSec = Int(now.timeIntervalSince1970)
        
        let lastMidnight = nowSec - sec - min - hour
        let oneDay: Int = 60 * 60 * 24
        
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMM")
        
        for i in 0 ... 2 {
            let interval = lastMidnight - i * oneDay
            let dateString = formatter.string(from: Date.init(timeIntervalSince1970: TimeInterval(interval)))
            let limitLine = ChartLimitLine.init(limit: Double(interval), label: dateString)
            limitLine.valueFont = UIFont.init(name: "HelveticaNeue-Light", size: 12.0)!
            limitLine.lineColor = .black
            limitLine.lineWidth = 0.5
            limitLine.labelPosition = .rightTop
            limitLine.yOffset = 0;
            xAxis.addLimitLine(limitLine)
        }
        
        let startInterval = lastMidnight - 2 * oneDay
        let step = 60 * 60 * 6
        for i in 1 ... 12 {
            let interval = startInterval + i * step

            let limitLine = ChartLimitLine.init(limit: Double(interval), label: "")
            limitLine.lineColor = .darkGray
            limitLine.lineWidth = 0.25
            
            xAxis.addLimitLine(limitLine)
        }
    }
	
	func setChart(dataPoints: [Double], values: [Double]) {
		plotView.noDataText = "You need to provide data for the chart."
        
        let coldColor: UIColor = UIColor(red: 140/255.0, green: 235/255.0, blue: 255/255.0, alpha: 0.8)
        let hotColor: UIColor = UIColor(red: 197/255.0, green: 255/255.0, blue: 140/255.0, alpha: 0.8)
        let averageValue = average(values: dataPoints)
		
		var dataEntries: [ChartDataEntry] = []
		
		for i in 0..<dataPoints.count {
			let dataEntry = ChartDataEntry(x: values[i], y: dataPoints[i])
			dataEntries.append(dataEntry)
		}
		
		let dataSet = LineChartDataSet(values: dataEntries, label: "Temp")
		dataSet.mode = .cubicBezier
		dataSet.cubicIntensity = 0.2
		dataSet.drawCirclesEnabled = false
		dataSet.lineWidth = 1.8
		dataSet.circleRadius = 4.0
		dataSet.setCircleColor(.white)
		
		dataSet.highlightColor = .clear
		dataSet.setColor(.clear)
        
        dataSet.fillColor = averageValue > 0 ? hotColor : coldColor
		dataSet.fillAlpha = 1.0
		
		dataSet.drawHorizontalHighlightIndicatorEnabled = false
		dataSet.fillFormatter = ToZeroFillFormatter()
		
		dataSet.drawFilledEnabled = true

		let chartData = LineChartData.init(dataSets: [dataSet])
		chartData.setValueFont(UIFont.init(name: "HelveticaNeue-Light", size: 9.0))
		chartData.setDrawValues(false)
		plotView.data = chartData
        
        plotView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
	}
    
    func average(values: Array<Double>) -> Double {
        guard values.count != 0 else {
            return 0
        }
        var av = 0.0;
        for num in values {
            av += num
        }
        return (av / Double(values.count) )
    }
}

