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
    
    @Published var validatingUrl = false
    @Published var validationError = false
    @Published var validationErrorMessage = ""
    
    func fetchAlarms(server: NDServer, completion: @escaping (ServerAlarms) -> ()) {
        NetDataAPI
            .getAlarms(baseUrl: server.url)
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
        
        NetDataAPI
            .getInfo(baseUrl: url)
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
                                      isFavourite: 0)
                
                ServerService.shared.add(server: server)
                
                completion(server)
            })
            .store(in: &cancellable)
    }
    
    func updateServer(editingServer: NDServer, completion: @escaping (NDServer) -> ()) {
        validatingUrl = true
        
        NetDataAPI
            .getInfo(baseUrl: url)
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
                                      isFavourite: 0)
                
                if let record = editingServer.record {
                    server.record = record
                    
                    ServerService.shared.edit(server: server)
                    
                    completion(server)
                }
            })
            .store(in: &self.cancellable)
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
