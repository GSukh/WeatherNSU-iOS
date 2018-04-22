import Foundation
import RxSwift
import RxCocoa

class ViewModel: NSObject {
	
	private struct Constants {
		static let URLShortWeather = "http://weather.nsu.ru/weather_brief.xml"
		static let URLWeatherPlot = "http://weather.nsu.ru/weather.xml"
	}
	
	let disposeBag = DisposeBag()
	
	fileprivate var publishWeather = PublishSubject<Weather>()
    var observableWeather: Observable<Weather> {
        return publishWeather.asObserver().observeOn(MainScheduler.instance)
    }
    
    fileprivate var _weather = Weather()
    fileprivate var _tempPoint = TempPoint()
    fileprivate var _foundCharacters: String = ""
	
	func update() {
		let url = URL(string: Constants.URLWeatherPlot)
		
		let session = URLSession(configuration: URLSessionConfiguration.default)
		let dataTask = session.dataTask(with: url!) { (data, response, error) in
			if data != nil {
                self.parseWeather(data!)
			}
		}
		
		dataTask.resume()
	}
	
    fileprivate func parseWeather(_ data: Data) {
        let parser = XMLParser(data: data)
        
        parser.delegate = self
        parser.parse()
    }
}

extension ViewModel: XMLParserDelegate {
    
    public func parserDidStartDocument(_ parser: XMLParser) {
        _weather = Weather()
    }

    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "temp" {
            _tempPoint = TempPoint()
            
            if let timestampString = attributeDict["timestamp"],
                let timestampFloat = Double.init(timestampString) {
                _tempPoint.timestamp = Int(timestampFloat)
            }
        }
        
        if elementName == "weather" {
            if let startTimestampString = attributeDict["start_timestamp"],
                let startTimestampFloat = Double.init(startTimestampString) {
                _weather.startTimestamp = Int(startTimestampFloat)
            }
            
            if let endTimestampString = attributeDict["stop_timestamp"],
                let endTimestampFloat = Double.init(endTimestampString) {
                _weather.endTimestamp = Int(endTimestampFloat)
            }
        }
        _foundCharacters = ""
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        _foundCharacters += string
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "temp" {
            if let temp = Double(_foundCharacters) {
                _tempPoint.temp = temp
                _weather.graph.append(_tempPoint)
            }
        }
        
        if elementName == "average" {
            if let temp = Double(_foundCharacters) {
                _weather.average = temp
            }
        }
        
        if elementName == "current" {
            if let temp = Double(_foundCharacters) {
                _weather.current = temp
            }
        }

        _foundCharacters = ""
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
//        print("\(_weather.average)\n\(_weather.current)");
//        for temp in self._weather.graph {
//            print("\(temp.timestamp):    \(temp.temp)");
//        }
        self.publishWeather.onNext(_weather)
    }

}
