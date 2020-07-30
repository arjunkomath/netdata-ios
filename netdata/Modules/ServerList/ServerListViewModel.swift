//
//  ServerListViewModel.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import Foundation
import Combine

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
                    
                    debugPrint(error)
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
                        self.validationErrorMessage = "Invalid server URL"
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
}
