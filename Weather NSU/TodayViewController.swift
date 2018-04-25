import UIKit
import NotificationCenter

import Charts

extension TodayViewController {
    func updateData(_ data: [TempPoint]?) {
        guard let data = data else { return }
        let sortedData = data.sorted(by: { $0.0.timestamp < $0.1.timestamp }).filter({ $0.temp > -273.0 })

        let temps = sortedData.flatMap({ $0.temp })
        let times = sortedData.flatMap({ Double($0.timestamp) })
        
        let av = temps.average
        
        averageLimitLine.limit = av
        averageLimitLine.label = String.init(format: "В среднем %0.2f °C", av)
        
        if let currentTemp = temps.last {
            degreesLimitLine.limit = currentTemp
            degreesLimitLine.label = String.init(format: "%0.2f °C", currentTemp)
            
            let higher = temps.max()!
            let lower = temps.min()!
            let gap = higher - lower
            
            let currentOnTop = (higher - currentTemp) / gap < 0.25
            let currentOnBot = (currentTemp - lower) / gap < 0.25
            
            let greaterThanAverage = currentTemp > av
            switch (greaterThanAverage, currentOnTop, currentOnBot) {
            case (true, true, false):
                degreesLimitLine.labelPosition = .rightBottom
                averageLimitLine.labelPosition = .rightBottom
            case (true, false, false):
                degreesLimitLine.labelPosition = .rightTop
                averageLimitLine.labelPosition = .rightBottom
            case (false, false, false):
                degreesLimitLine.labelPosition = .rightBottom
                averageLimitLine.labelPosition = .rightTop
            case (false, false, true):
                degreesLimitLine.labelPosition = .rightTop
                averageLimitLine.labelPosition = .rightTop
            default: break
            }
        }
        
        self.setChart(temps: temps, timestamps: times)
    }
}

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var plotView: LineChartView!
    var degreesLimitLine: ChartLimitLine!
    var averageLimitLine: ChartLimitLine!
    
    let viewModel = ViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlot()
    }
    
    override func viewDidAppear(_ animated: Bool) {

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {

        print(self.plotView.frame)
        viewModel.update() { [weak self] (weather) in
            if let weather = weather {
                self?.updateData(weather.graph)
                completionHandler(NCUpdateResult.newData)
            }
            completionHandler(NCUpdateResult.noData)
        }
    }
    
    
    func setupPlot() {
        plotView.setViewPortOffsets(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0)
        
        
        plotView.chartDescription?.enabled = false
        plotView.backgroundColor = .clear
        
        
		plotView.dragEnabled = false
		plotView.setScaleEnabled(false)
        
        
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
        yAxis.setLabelCount(6, force: false)
        yAxis.labelTextColor = .black
        yAxis.labelPosition = .insideChart
        yAxis.drawGridLinesEnabled = true
        
        yAxis.gridLineDashPhase = CGFloat(1)
        yAxis.gridLineDashLengths = [1, 27, 1000]
        yAxis.axisLineColor = .black
        
        degreesLimitLine = ChartLimitLine.init(limit: 0, label: "")
        degreesLimitLine.labelPosition = .rightTop
        degreesLimitLine.valueFont = UIFont.init(name: "HelveticaNeue-Bold", size: 12.0)!
        degreesLimitLine.lineColor = .black
        degreesLimitLine.lineWidth = 0.5
        yAxis.addLimitLine(degreesLimitLine)
        
        averageLimitLine = ChartLimitLine.init(limit: 0, label: "Среднее")
        averageLimitLine.labelPosition = .rightTop
        averageLimitLine.valueFont = UIFont.init(name: "HelveticaNeue-Light", size: 12.0)!
        averageLimitLine.lineColor = .black
        averageLimitLine.lineWidth = 0.5
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
    
    func setChart(temps: [Double], timestamps: [Double]) {
        plotView.noDataText = "You need to provide data for the chart."
        
        let coldColor: UIColor = UIColor(red: 140/255.0, green: 235/255.0, blue: 255/255.0, alpha: 0.8)
        let coldBorderColor: UIColor = UIColor(red: 120/255.0, green: 215/255.0, blue: 235/255.0, alpha: 1)
        
        let hotColor: UIColor = UIColor(red: 197/255.0, green: 255/255.0, blue: 140/255.0, alpha: 0.8)
        let hotBorderColor: UIColor = UIColor(red: 177/255.0, green: 235/255.0, blue: 120/255.0, alpha: 1)
        
        let averageValue = temps.average
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<temps.count {
            let dataEntry = ChartDataEntry(x: timestamps[i], y: temps[i])
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
        chartData.setValueFont(UIFont.init(name: "HelveticaNeue-Light", size: 9.0))
        chartData.setDrawValues(false)
        plotView.data = chartData
        
        let xAxis = plotView.xAxis
        xAxis.axisMinimum = timestamps.min()!
        xAxis.axisMaximum = timestamps.max()!

        plotView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
    }
    
}
