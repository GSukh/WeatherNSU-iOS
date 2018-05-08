import UIKit

import Charts
import Framezilla

extension HistoryType {
    var dateFormat: String {
        switch self {
        case .three:        return "dMMMM"
        case .ten, .month:  return "d"
        }
    }
    
    var days: Int {
        switch self {
        case .three:        return 3
        case .ten:          return 20
        case .month:        return 30
        }
    }
    
    var lineInterval: Int {
        let day = 24 * 60 * 60
        switch self {
        case .three:  return day
        case .ten:    return 2 * day
        case .month:  return 7 * day
        }
    }
    
    var sublineInterval: Int? {
        let hour = 60 * 60
        switch self {
        case .three:  return 6 * hour
        case .ten:    return 12 * hour
        case .month:  return 24 * hour
        }
    }
    
    var averageTitle: String {
        switch self {
        case .three:    return "Средняя температура за 3 дня %0.1f °C"
        case .ten:      return "Средняя температура за 10 дней %0.1f °C"
        case .month:    return "Средняя температура за месяц %0.1f °C"
        }
    }
}

extension ViewController {
    func updateWeather(_ weather: Weather, _ type: HistoryType) {
        
        let sortedData = weather.graph.sorted(by: { $0.0.timestamp < $0.1.timestamp }).filter({ $0.temp > -273.0 })
        guard !sortedData.isEmpty else { return }
        
        var temps = sortedData.map({ $0.temp })
        var times = sortedData.map({ Double($0.timestamp) })
        
        let av = temps.average
        
        averageLimitLine.limit = av
        averageLimitLine.label = String.init(format: "В среднем %0.1f °C", av)
        
        avDegreesLabel.text = String.init(format: type.averageTitle, av)
        
        let currentTemp = weather.current
        degreesLabel.text = String.init(format: "Температура около НГУ %0.1f °C", currentTemp)
        degreesLimitLine.limit = currentTemp
        degreesLimitLine.label = String.init(format: "%0.1f °C", currentTemp)
        
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
        
        temps.insert(av > 0 ? 0.5 : -0.5, at: 0)
        times.insert(times[0]-1, at: 0)
        
        self.setChart(type, temps: temps, times: times)
    }
}

class ViewController: UIViewController {

	lazy var degreesLabel: UILabel = self.getTempLabel()
	lazy var avDegreesLabel: UILabel = self.getAverageTempLabel()
	
	lazy var linksTextView: UITextView = UITextView()
		
    lazy var historyTypeSwitcher: UISegmentedControl = self.getSwitcherView()
    lazy var plotView: LineChartView = LineChartView()
    
    lazy var labelsContainerView: UIView = UIView()
    lazy var plotContainerView: UIView = UIView()
    
    var degreesLimitLine: ChartLimitLine!
    var averageLimitLine: ChartLimitLine!
    
	let viewModel = ViewModel()

	override func viewDidLoad() {
		super.viewDidLoad()
        setupUI()
        setupPlot()
        setupLinks()
        layoutViews()
	}
    
    override func viewDidAppear(_ animated: Bool) {

        viewModel.update(.three) { (weather) in
            guard let weather = weather else { return }
            self.updateWeather(weather, .three)
        }
    }
    
    override func viewDidLayoutSubviews() {
        layoutViews()
        super .viewDidLayoutSubviews()
    }
    
    func layoutViews() {
        if self.view.frame.height > self.view.frame.width {
            layoutViewsPortrait()
        }
        else {
            layoutViewsLandscape()
        }
    }
    
    func layoutViewsPortrait() {
        labelsContainerView.configureFrame { (maker) in
            maker.top(inset: 20)
            maker.left().right()
            maker.height(150)
        }
        
        degreesLabel.configureFrame { (maker) in
            maker.left().right()
            maker.bottom(to: labelsContainerView.nui_centerY)
            maker.height(20)
        }
        
        avDegreesLabel.configureFrame { (maker) in
            maker.top(to: labelsContainerView.nui_centerY)
            maker.left().right()
            maker.height(20)
        }
        
        linksTextView.configureFrame { (maker) in
            maker.bottom()
            maker.left(inset: 30).right(inset: 30)
            maker.height(90)
        }
        
        plotContainerView.configureFrame { (maker) in
            maker.top(to: avDegreesLabel.nui_bottom, inset: 50)
            maker.bottom(to: linksTextView.nui_top, inset: 30)
            maker.left().right()
        }
        
        historyTypeSwitcher.configureFrame { (maker) in
            maker.centerX()
            maker.bottom()
            maker.heightToFit()
        }
        
        plotView.configureFrame { (maker) in
            maker.top().left().right()
            maker.bottom(to: historyTypeSwitcher.nui_top, inset: 5)
        }
    }
    
    func layoutViewsLandscape() {
        labelsContainerView.configureFrame { (maker) in
            maker.top(inset: 20).left()
            maker.height(150).width(280)
        }
        
        degreesLabel.configureFrame { (maker) in
            maker.left().right()
            maker.bottom(to: labelsContainerView.nui_centerY)
            maker.height(20)
        }
        
        avDegreesLabel.configureFrame { (maker) in
            maker.top(to: labelsContainerView.nui_centerY)
            maker.left().right()
            maker.height(20)
        }
        
        linksTextView.configureFrame { (maker) in
            maker.bottom().left()
            maker.width(280)
            maker.heightToFit()
        }
        
        plotContainerView.configureFrame { (maker) in
            maker.top(inset: 20).bottom(inset: 5)
            maker.left(inset: 280).right()
        }
        
        historyTypeSwitcher.configureFrame { (maker) in
            maker.centerX()
            maker.bottom()
            maker.heightToFit()
        }
        
        plotView.configureFrame { (maker) in
            maker.top().left().right()
            maker.bottom(to: historyTypeSwitcher.nui_top, inset: 5)
        }
    }

    func actionDynamicTypeChanged() {
        var dynamicType: HistoryType = .three
        switch historyTypeSwitcher.selectedSegmentIndex {
        case 1: dynamicType = .ten
        case 2: dynamicType = .month
        default: break
        }
        
        viewModel.update(dynamicType) { (weather) in
            guard let weather = weather else { return }
            self.updateWeather(weather, dynamicType)
        }
    }
    
    func setupUI() {
        self.view.backgroundColor = .white
        
        self.view.addSubview(plotContainerView)
        plotContainerView.addSubview(plotView)
        plotContainerView.addSubview(historyTypeSwitcher)
        
        self.view.addSubview(labelsContainerView)
        labelsContainerView.addSubview(degreesLabel)
        labelsContainerView.addSubview(avDegreesLabel)
        self.view.addSubview(linksTextView)
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
        
        addXLimitLines(.three)

        
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
    
    func addXLimitLines(_ type: HistoryType) {
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
        formatter.setLocalizedDateFormatFromTemplate(type.dateFormat)
        
        let days = type.days
        let lineStep = type.lineInterval
        let lineTicks = Int(days * oneDay / lineStep)
        
        for i in 0 ... lineTicks {
            let interval = lastMidnight - i * lineStep
            let dateString = formatter.string(from: Date.init(timeIntervalSince1970: TimeInterval(interval)))
            let limitLine = ChartLimitLine.init(limit: Double(interval), label: dateString)
            limitLine.valueFont = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightLight)
            limitLine.lineColor = .black
            limitLine.lineWidth = 0.5
            limitLine.labelPosition = .rightTop
            limitLine.yOffset = 0;
            xAxis.addLimitLine(limitLine)
        }
        
        if let step = type.sublineInterval {
            let startInterval = lastMidnight - days * oneDay
            let ticks = Int((days + 1) * oneDay / step)
            
            for i in 0 ... ticks {
                let interval = startInterval + i * step
                
                let limitLine = ChartLimitLine.init(limit: Double(interval), label: "")
                limitLine.lineColor = .darkGray
                limitLine.lineWidth = 0.25
                
                xAxis.addLimitLine(limitLine)
            }
        }
        

    }
	
    func setChart(_ type: HistoryType, temps: [Double], times: [Double]) {
		plotView.noDataText = "You need to provide data for the chart."
        
        addXLimitLines(type)
        
        let coldColor: UIColor = UIColor(red: 140/255.0, green: 235/255.0, blue: 255/255.0, alpha: 0.8)
        let coldBorderColor: UIColor = UIColor(red: 120/255.0, green: 215/255.0, blue: 235/255.0, alpha: 1)

        let hotColor: UIColor = UIColor(red: 197/255.0, green: 255/255.0, blue: 140/255.0, alpha: 0.8)
        let hotBorderColor: UIColor = UIColor(red: 177/255.0, green: 235/255.0, blue: 120/255.0, alpha: 1)
        
        let averageValue = temps.average
		var dataEntries: [ChartDataEntry] = []
		
		for i in 0..<temps.count {
			let dataEntry = ChartDataEntry(x: times[i], y: temps[i])
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

fileprivate extension ViewController {
    func getSwitcherView() -> UISegmentedControl {
        let segments = ["3 дня", "10 дней", "месяц"]
        let view = UISegmentedControl.init(items: segments)
        view.selectedSegmentIndex = 0
        
        view.addTarget(self, action: #selector(actionDynamicTypeChanged), for: .valueChanged)

        return view
    }
    
    func getTempLabel() -> UILabel {
        let view = UILabel()
        
        view.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightRegular)
        view.textColor = .black
        view.numberOfLines = 2
        view.textAlignment = .center
        
        return view
    }
    
    func getAverageTempLabel() -> UILabel {
        let view = UILabel()
        
        view.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightThin)
        view.textColor = .black
        view.numberOfLines = 2
        view.textAlignment = .center
        
        return view
    }
}
