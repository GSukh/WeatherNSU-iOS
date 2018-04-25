import UIKit

import Charts

extension ViewController {
    func updateData(_ data: [TempPoint]?) {
        guard let data = data else { return }
        
        let sortedData = data.sorted(by: { $0.0.timestamp < $0.1.timestamp }).filter({ $0.temp > -273.0 })
        
        var temps = sortedData.map({ $0.temp })
        var times = sortedData.map({ Double($0.timestamp) })
        
        let av = temps.average
        
        averageLimitLine.limit = av
        averageLimitLine.label = String.init(format: "В среднем %0.2f °C", av)
        
        avDegreesLabel.text = String.init(format: "Средняя температура за 3 дня %0.2f °C", av)
        
        if let currentTemp = temps.last {
            degreesLabel.text = String.init(format: "Температура около НГУ %0.2f °C", currentTemp)
            degreesLimitLine.limit = currentTemp
            degreesLimitLine.label = String.init(format: "%0.2f °C", currentTemp)

            let higher = temps.max()!
            let lower = temps.min()!
            let gap = higher - lower

            if fabs(currentTemp - av) / gap < 0.25 {
                degreesLimitLine.labelPosition = currentTemp > av ? .rightTop : .rightBottom
                averageLimitLine.labelPosition = currentTemp > av ? .rightBottom : .rightTop
            }
            else {
                degreesLimitLine.labelPosition = currentTemp > av ? .rightBottom : .rightTop
                averageLimitLine.labelPosition = currentTemp > av ? .rightTop : .rightBottom
            }
		}
        
        temps.insert(av > 0 ? 0.5 : -0.5, at: 0)
		times.insert(times[0]-1, at: 0)
        
        self.setChart(dataPoints: temps, values: times)
    }
}

class ViewController: UIViewController {

	@IBOutlet weak var degreesLabel: UILabel!
	@IBOutlet weak var avDegreesLabel: UILabel!
	
	@IBOutlet weak var linksTextView: UITextView!
		
	@IBOutlet weak var plotView: LineChartView!
    var degreesLimitLine: ChartLimitLine!
    var averageLimitLine: ChartLimitLine!
	
	let viewModel = ViewModel()


	override func viewDidLoad() {
		super.viewDidLoad()
        setupPlot()
        setupLinks()
	}
    
    override func viewDidAppear(_ animated: Bool) {

        viewModel.update() { (weather) in
            self.updateData(weather?.graph)
        }
    }

	
	func setupLinks() {
        let color: UIColor = UIColor(red: 140/255.0, green: 235/255.0, blue: 255/255.0, alpha: 1.0)

        let phrases = ["Прогноз Яндекс", "\nПрогноз Gismeteo", "\n\nДанные предоставленны сайтом ", "weather.nsu.ru", "\nSupport & Production"]
		let links = ["https://yandex.ru/pogoda/novosibirsk", "https://www.gismeteo.ru/weather-novosibirsk-4690/", "", "http://weather.nsu.ru/", "https://vk.com/gsukh"]
		
		let attrString = NSMutableAttributedString()
		
		for i in 0..<phrases.count {
			
			let phrase = phrases[i]
			let link = links[i]
			
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center
			
			if link == "" {
				let linkAttributes = [
					NSParagraphStyleAttributeName: paragraphStyle,
                    NSFontAttributeName: UIFont.systemFont(ofSize: 12)] as [String : Any]
				let attrPhrase = NSAttributedString.init(string: phrase, attributes: linkAttributes)
				attrString.append(attrPhrase)
			}
			else {
				let linkAttributes = [
					NSLinkAttributeName: NSURL(string: links[i])!,
					NSForegroundColorAttributeName: color,
					NSParagraphStyleAttributeName: paragraphStyle,
                    NSFontAttributeName: UIFont.systemFont(ofSize: 12)] as [String : Any]
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
		yAxis.labelFont = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightLight)
		yAxis.setLabelCount(12, force: false)
		yAxis.labelTextColor = .black
		yAxis.labelPosition = .insideChart
		yAxis.drawGridLinesEnabled = true
        
        yAxis.gridLineDashPhase = CGFloat(1)
        yAxis.gridLineDashLengths = [1, 27, 1000]
		yAxis.axisLineColor = .black
        
        degreesLimitLine = ChartLimitLine.init(limit: 0, label: "")
        degreesLimitLine.labelPosition = .rightTop
        degreesLimitLine.valueFont = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightBold)
        degreesLimitLine.lineColor = .black
        degreesLimitLine.lineWidth = 0.75
        yAxis.addLimitLine(degreesLimitLine)
        
        averageLimitLine = ChartLimitLine.init(limit: 0, label: "Среднее")
        averageLimitLine.labelPosition = .rightTop
        averageLimitLine.valueFont = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightLight)
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
            limitLine.valueFont = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightLight)
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
        let coldBorderColor: UIColor = UIColor(red: 120/255.0, green: 215/255.0, blue: 235/255.0, alpha: 1)

        let hotColor: UIColor = UIColor(red: 197/255.0, green: 255/255.0, blue: 140/255.0, alpha: 0.8)
        let hotBorderColor: UIColor = UIColor(red: 177/255.0, green: 235/255.0, blue: 120/255.0, alpha: 1)

        let averageValue = dataPoints.average
		
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
		
        let borderColor = averageValue > 0 ? hotBorderColor : coldBorderColor
		dataSet.highlightColor = borderColor
		dataSet.setColor(borderColor)
        
        dataSet.fillColor = averageValue > 0 ? hotColor : coldColor
		dataSet.fillAlpha = 1.0
		
		dataSet.drawHorizontalHighlightIndicatorEnabled = false
		dataSet.fillFormatter = ToZeroFillFormatter()
		
		dataSet.drawFilledEnabled = true

		let chartData = LineChartData.init(dataSets: [dataSet])
		chartData.setValueFont(UIFont.systemFont(ofSize: 9.0, weight: UIFontWeightLight))
		chartData.setDrawValues(false)
		plotView.data = chartData
        
        plotView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
	}
}

