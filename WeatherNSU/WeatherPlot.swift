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
        
        let normData = findNormTemp(responseString)
		normDataWith(normData: normData)
	}
    
    func findNormTemp(_ string: String) -> Dictionary<Double, Double> {
        var result = Dictionary<Double, Double>()
        let temps: [Int] = Array(-30...30)
        for temp in temps {
            let findString = "'<b>\(temp) &deg;C</b>',"
            let numString = string.components(separatedBy: findString).last!
                .components(separatedBy: CharacterSet(charactersIn: ",) "))[3]
            
            if let num = Double(numString) {
                if num != 0 {
                    result[Double(temp)] = num
                }
            }
        }
        return result
    }
	
    func normDataWith(normData: Dictionary<Double, Double>) {
		guard yData != nil else {
			return
		}
		
        let t0 = normData.keys.min()!
        let c0 = normData[t0]!
        
        let t1 = normData.keys.max()!
        let c1 = normData[t1]!
		
		let A: Double = (t0 - t1) / (c0 - c1)
		let B: Double = t1 - A * c1
		
		for i in 0 ..< (yData?.count)! {
			yData?[i] = A * (yData?[i])! + B
		}
	}
    
}
