import Foundation
import RxSwift
import RxCocoa

class ViewModel {
	
	private struct Constants {
		static let URLShortWeather = "http://weather.nsu.ru/weather_brief.xml"
		static let URLWeatherPlot = "http://weather.nsu.ru/loadata.php"
	}
	
	let disposeBag = DisposeBag()

	var degrees = PublishSubject<String?>()
	var averageDegrees = PublishSubject<String?>()
	var lastUpdate = PublishSubject<String?>()
	var updating = PublishSubject<Bool?>()
	
	var plotData = PublishSubject<[Double]?>()
	
	var weatherPlot: WeatherPlot? {
		didSet {
			if let data = weatherPlot?.yData {
				DispatchQueue.main.async {
					self.plotData.onNext(data)
				}
			}
		}
	}

	var weather: Weather? {
		didSet {
			if let degrees = weather?.degrees {
				DispatchQueue.main.async {
					let degreesString = String(format: "%0.2f°C", degrees)
					self.degrees.onNext(degreesString)
				}
			}
			if let averageDegrees = weather?.averageDegrees {
				DispatchQueue.main.async {
					let averageDegreesString = String(format: "%0.2f°C", averageDegrees)
					self.averageDegrees.onNext(averageDegreesString)
				}
			}
			if let date = weather?.date {
				DispatchQueue.main.async {
					let averageDegreesString = date.description(with: nil)
					self.lastUpdate.onNext(averageDegreesString)
				}
			}
		}
	}
	
	func update() {
		let url = URL(string: Constants.URLShortWeather)
		
		let session = URLSession(configuration: URLSessionConfiguration.default)
		let dataTask = session.dataTask(with: url!) { (data, response, error) in
			print("\( response )")
			if data != nil {
				self.weather = Weather(response: data!)
			}
		}
		
		dataTask.resume()
	}
	
	func loadPlotData() {
		let url = URL(string: Constants.URLWeatherPlot)
		
		let session = URLSession(configuration: URLSessionConfiguration.default)
		let dataTask = session.dataTask(with: url!) { (data, response, error) in
			print("\( response )")
			if data != nil {
				let weatherPlotData = WeatherPlot(response: data!)
				if let currentWeather = self.weather {
					weatherPlotData.normDataWith(currentDegrees: currentWeather.degrees!, avDegrees: currentWeather.averageDegrees!)
				}
				self.weatherPlot = weatherPlotData
			}
		}
		
		dataTask.resume()
	}
	
}
