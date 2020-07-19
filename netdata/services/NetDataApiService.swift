//
//  NetDataApiService.swift
//  netdata
//
//  Created by Arjun Komath on 12/7/20.
//

import Foundation
import Alamofire

class NetDataApiService {
    
    class func validateServerInfo(baseUrl: String, completionHandler: @escaping (_ valid: Bool) -> Void) {
        AF.request(baseUrl + "/api/v1/info")
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    completionHandler(true)
                    
                case .failure(_):
                    completionHandler(false)
                }
            }
    }
    
    class func getServerInfo(baseUrl: String, completionHandler: @escaping (_ data: Data) -> Void) {
        AF.request(baseUrl + "/api/v1/info")
            .validate()
            .responseJSON { response in
                completionHandler(response.data!)
            }
    }
    
    class func getChartData(baseUrl: String, chart: String, completionHandler: @escaping (_ data: Data) -> Void) {
        AF.request(baseUrl + "/api/v1/data?chart=" + chart)
            .validate()
            .responseJSON { response in
                completionHandler(response.data!)
            }
    }
}
