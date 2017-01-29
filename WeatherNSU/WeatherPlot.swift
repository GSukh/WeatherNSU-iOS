import Foundation
import RxSwift
import RxCocoa

class WeatherPlot {
	
	var xData: Array<Double>? = Array()
	var yData: Array<Double>? = Array()
	
	init(response: Data) {
		
		let responseString: String = String.init(data: response, encoding: .utf8)!
		
		let xString: String = responseString.components(separatedBy: "document.Xpoints = [ ").last!
			.components(separatedBy: " ];").first!
		for string in xString.components(separatedBy: ",") {
			xData?.append(Double(string)!)
		}

		let yString: String = responseString.components(separatedBy: "document.Ypoints = [ ").last!
			.components(separatedBy: " ];").first!
		for string in yString.components(separatedBy: ",") {
			yData?.append(Double(string)!)
		}
		
	}
	
	public func normDataWith(currentDegrees: Double, avDegrees: Double) {
		
		guard yData != nil else {
			return
		}
		
		let max: Double = (yData?.max())!
		var av: Double = 0.0
		
		for i in 0 ..< (yData?.count)! {
			yData?[i] = max - (yData?[i])!
			av += (yData?[i])!
		}
		av /= Double((yData?.count)!)
		
		let A: Double = (avDegrees - currentDegrees) / (av - (yData?.last!)!)
		let B: Double = currentDegrees - A * (yData?.last!)!
		
		for i in 0 ..< (yData?.count)! {
			yData?[i] = A * (yData?[i])! + B
		}
		
	}

}
