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
    
    func fetchAlarms(server: NDServer) async -> ServerAlarms? {
            return try? await NetdataClient.shared.getAlarms(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
    }
    
    func addServer() async {
        validatingUrl = true
        
        var basicAuthBase64: String = ""
        if (enableBasicAuth == true && !basicAuthUsername.isEmpty && !basicAuthPassword.isEmpty) {
            let loginString = String(format: "%@:%@", basicAuthUsername, basicAuthPassword)
            let loginData = loginString.data(using: String.Encoding.utf8)!
            basicAuthBase64 = loginData.base64EncodedString()
        }
        
        do {
            let info = try await NetdataClient.shared.getInfo(baseUrl: url, basicAuthBase64: basicAuthBase64)
            let server = NDServer(name: self.name,
                                  description: self.description,
                                  url: self.url,
                                  serverInfo: info,
                                  basicAuthBase64: basicAuthBase64,
                                  isFavourite: self.isFavourite)
            
            async {
                ServerService.shared.add(server: server)
            }
        } catch {
            self.validatingUrl = false
            self.validationError = true
            
            guard let apiError = error as? APIError, apiError != .somethingWentWrong else {
                self.validationErrorMessage = "Invalid server URL! Please ensure Netdata has been installed on the server."
                return
            }
            
            if apiError == APIError.authenticationFailed {
                self.validationErrorMessage = "Authentication Failed"
            }
        }
    }
    
    func updateServer(editingServer: NDServer) async {
        validatingUrl = true
        
        var basicAuthBase64: String = ""
        if (enableBasicAuth == true && !basicAuthUsername.isEmpty && !basicAuthPassword.isEmpty) {
            let loginString = String(format: "%@:%@", basicAuthUsername, basicAuthPassword)
            let loginData = loginString.data(using: String.Encoding.utf8)!
            basicAuthBase64 = loginData.base64EncodedString()
        }
        
        do {
            let info = try await NetdataClient.shared.getInfo(baseUrl: url, basicAuthBase64: basicAuthBase64)
            var server = NDServer(name: self.name,
                                  description: self.description,
                                  url: self.url,
                                  serverInfo: info,
                                  basicAuthBase64: basicAuthBase64,
                                  isFavourite: self.isFavourite)
            
            if let record = editingServer.record {
                server.record = record
                
                ServerService.shared.edit(server: server)
            }
        } catch {
            FeedbackGenerator.shared.triggerNotification(type: .error)
            self.validatingUrl = false
            self.validationError = true
            
            guard let apiError = error as? APIError, apiError != .somethingWentWrong else {
                self.validationErrorMessage = "Invalid server URL! Please ensure Netdata has been installed on the server."
                return
            }
            
            if apiError == APIError.authenticationFailed {
                self.validationErrorMessage = "Authentication Failed"
            }
        }
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
