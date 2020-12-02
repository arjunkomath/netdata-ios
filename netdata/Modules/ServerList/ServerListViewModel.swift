//
//  ServerListViewModel.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import Foundation
import Combine
import SwiftUI

final class ServerListViewModel: ObservableObject {
    
    private var cancellable = Set<AnyCancellable>()
    
    @Published var name = ""
    @Published var description = ""
    @Published var url = ""
    @Published var isFavourite = 0
    
    @Published var enableBasicAuth = false
    @Published var basicAuthUsername = ""
    @Published var basicAuthPassword = ""
    @Published var basicAuthvalidationError = false
    @Published var basicAuthvalidationErrorMessage = ""
    
    @Published var validatingUrl = false
    @Published var invalidUrlAlert = false
    @Published var validationError = false
    @Published var validationErrorMessage = ""
    
    func fetchAlarms(server: NDServer, completion: @escaping (ServerAlarms) -> ()) {
        NetDataAPI
            .getAlarms(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    debugPrint("getAlarms", server.name, error)
                }
            },
            receiveValue: { alarms in
                completion(alarms)
            })
            .store(in: &cancellable)
    }
    
    func addServer(completion: @escaping (NDServer) -> ()) {
        validatingUrl = true
        
        var basicAuthBase64: String = ""
        if (enableBasicAuth == true && !basicAuthUsername.isEmpty && !basicAuthPassword.isEmpty) {
            let loginString = String(format: "%@:%@", basicAuthUsername, basicAuthPassword)
            let loginData = loginString.data(using: String.Encoding.utf8)!
            basicAuthBase64 = loginData.base64EncodedString()
        }
        
        NetDataAPI
            .getInfo(baseUrl: url, basicAuthBase64: basicAuthBase64)
            .sink(receiveCompletion: { completion in
                print(completion)
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.validatingUrl = false
                        self.validationError = true
                        self.validationErrorMessage = "Invalid server URL! Please ensure Netdata has been installed on the server."
                    }
                    
                    FeedbackGenerator.shared.triggerNotification(type: .error)
                    debugPrint(error)
                }
            },
            receiveValue: { info in
                let server = NDServer(name: self.name,
                                      description: self.description,
                                      url: self.url,
                                      serverInfo: info,
                                      basicAuthBase64: basicAuthBase64,
                                      isFavourite: self.isFavourite)
                
                ServerService.shared.add(server: server)
                
                completion(server)
            })
            .store(in: &cancellable)
    }
    
    func updateServer(editingServer: NDServer, completion: @escaping (NDServer) -> ()) {
        validatingUrl = true
        
        var basicAuthBase64: String = ""
        if (enableBasicAuth == true && !basicAuthUsername.isEmpty && !basicAuthPassword.isEmpty) {
            let loginString = String(format: "%@:%@", basicAuthUsername, basicAuthPassword)
            let loginData = loginString.data(using: String.Encoding.utf8)!
            basicAuthBase64 = loginData.base64EncodedString()
        }
        
        NetDataAPI
            .getInfo(baseUrl: url, basicAuthBase64: basicAuthBase64)
            .sink(receiveCompletion: { completion in
                print(completion)
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.validatingUrl = false
                        self.validationError = true
                        self.validationErrorMessage = "Invalid server URL"
                    }
                    
                    FeedbackGenerator.shared.triggerNotification(type: .error)
                    debugPrint(error)
                }
            },
            receiveValue: { info in
                var server = NDServer(name: self.name,
                                      description: self.description,
                                      url: self.url,
                                      serverInfo: info,
                                      basicAuthBase64: basicAuthBase64,
                                      isFavourite: self.isFavourite)
                
                if let record = editingServer.record {
                    server.record = record
                    
                    ServerService.shared.edit(server: server)
                    
                    completion(server)
                }
            })
            .store(in: &self.cancellable)
    }
    
    func validateForm() -> Bool {
        if (name.isEmpty || description.isEmpty || url.isEmpty) {
            validationError = true
            validationErrorMessage = "Please fill all the fields"
            return false
        }
        self.validationError = false
        
        if (enableBasicAuth == true && basicAuthUsername.isEmpty && basicAuthPassword.isEmpty) {
            basicAuthvalidationError = true
            basicAuthvalidationErrorMessage = "Please fill all the fields"
            return false
        }
        self.basicAuthvalidationError = false
        
        if (!validateUrl(urlString: self.url)) {
            invalidUrlAlert = true
            return false
        }
        
        self.validationError = false
        self.validationErrorMessage = ""
        return true
    }
    
    func validateUrl(urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url = NSURL(string: urlString) {
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
}
