import UIKit
import NotificationCenter

import RxSwift
import RxCocoa
import Charts

extension Reactive where Base: TodayViewController {
    var plotData: AnyObserver<[Double]?> {
        return UIBindingObserver(UIElement: base) { vc, data in
            vc.updateData(data)
            }.asObserver()
    }
}

extension TodayViewController {
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
        averageLimitLine.label = String.init(format: "В среднем %0.1f °C", av)
        
        if let currentTemp = array.last {
            degreesLimitLine.limit = currentTemp
            degreesLimitLine.label = String.init(format: "%0.1f °C", currentTemp)
            
            if fabs(currentTemp - av) < 30 {
                degreesLimitLine.labelPosition = currentTemp > av ? .rightTop : .rightBottom
				averageLimitLine.labelPosition = currentTemp > av ? .rightBottom : .rightTop
            }
            else {
                degreesLimitLine.labelPosition = currentTemp > av ? .rightBottom : .rightTop
                averageLimitLine.labelPosition = currentTemp > av ? .rightTop : .rightBottom
            }
        }
        
        self.setChart(dataPoints: array, values: plotXData)
    }
}

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var plotView: LineChartView!
    var degreesLimitLine: ChartLimitLine!
    var averageLimitLine: ChartLimitLine!
    
    let disposeBag = DisposeBag()
    let viewModel = ViewModel()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        addBindings()
        setupPlot()
        viewModel.loadPlotData()
    }
    
    func addBindings() {
        viewModel.plotData
            .bindTo(rx.plotData)
            .addDisposableTo(disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {

        viewModel.loadPlotData()
        completionHandler(NCUpdateResult.newData)
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
    
    func setChart(dataPoints: [Double], values: [Double]) {
        plotView.noDataText = "You need to provide data for the chart."
        
        let coldColor: UIColor = UIColor(red: 140/255.0, green: 235/255.0, blue: 255/255.0, alpha: 0.8)
        let hotColor: UIColor = UIColor(red: 197/255.0, green: 255/255.0, blue: 140/255.0, alpha: 0.8)//UIColor(red: 105/255.0, green: 241/255.0, blue: 175/255.0, alpha: 1.0)
        let averageValue = average(values: dataPoints)
        
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
        
        dataSet.highlightColor = .clear//UIColor(red: 244/255.0, green: 117/255.0, blue: 117/255.0, alpha: 1.0)
        dataSet.setColor(.clear)//(averageValue > 0 ? hotColor : coldColor)
        
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
