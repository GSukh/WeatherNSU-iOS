import Foundation

enum HistoryType {
    case three
    case ten
    case month
    
    var path: String {
        switch self {
        case .three: return "http://weather.nsu.ru/weather.xml"
        case .ten: return "http://weather.nsu.ru/weather.xml?std=ten"
        case .month: return "http://weather.nsu.ru/weather.xml?std=month"
        }
    }
}

class ViewModel: NSObject {
    
    fileprivate var _weather = Weather()
    fileprivate var _tempPoint = TempPoint()
    fileprivate var _foundCharacters: String = ""
    fileprivate var _lastUpdateDate: Date?
    
    typealias WeatherComplition = (Weather?) -> Void
    fileprivate var _complitionBlock: WeatherComplition?
	
    func update(_ historyType: HistoryType, _ complition: @escaping WeatherComplition) {

//        if let date = _lastUpdateDate, date.timeIntervalSinceNow > -60 {
//            return
//        }
        _complitionBlock = { weather in
            DispatchQueue.main.async { complition(weather) }
        }
        
        _weather = Weather()
		let url = URL(string: historyType.path)
        
		let session = URLSession(configuration: URLSessionConfiguration.default)
		let dataTask = session.dataTask(with: url!) { (data, response, error) in
			if data != nil {
                self.parseWeather(data!)
			}
            else {
                self._complitionBlock?(nil)
                self._complitionBlock = nil
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
        _lastUpdateDate = Date()
        self._complitionBlock?(_weather)
        self._complitionBlock = nil
    }

}
