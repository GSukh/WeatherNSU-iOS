import Foundation
import RxSwift
import RxCocoa

class Weather {
	
	var degrees: Double?
	var averageDegrees: Double?
	var date: Date?
	
	init(response: Data) {
		
		let responseString: String = String.init(data: response, encoding: .utf8)!

		let degreesString = findFirst(string: responseString, tag: "current")
		degrees = Double(degreesString!)
		
		let avDegreesString = findFirst(string: responseString, tag: "average")
		averageDegrees = Double(avDegreesString!)

		date = Date()
	}
	
	func findFirst(string: String, tag: String) -> String? {
		
		let openTag = "<\(tag)>"
		let closeTag = "</\(tag)>"
		
		let result: String = string.components(separatedBy: openTag).last!
			.components(separatedBy: closeTag).first!
		
		return result
	}

}
