//
//  AuthService.swift
//  netdata
//
//  Created by Arjun on 23/12/2023.
//

import Foundation
import CloudKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

@MainActor
class UserService: ObservableObject, PublicCloudService {
    public static let shared = UserService()
    
    let db = Firestore.firestore()
    var listener: ListenerRegistration? = nil
    
    @Published var userData: UserData?
    
    init() {
        Task {
            await signInUser()
        }
        
        Auth.auth().addStateDidChangeListener { (_, user) in
            if let user = user {
                print("AuthService: User found, fetching data")
                
                self.listener?.remove()
                self.listener = self.db
                    .collection("users")
                    .document(user.uid)
                    .addSnapshotListener { documentSnapshot, error in
                        guard let document = documentSnapshot else {
                            print("Error fetching user data: \(error!)")
                            return
                        }
                        guard let _ = document.data() else {
                            print("User data is missing, creating...")
                            Task {
                                try await self.db
                                    .collection("users")
                                    .document(user.uid)
                                    .setData([
                                        "api_key": UUID().uuidString.lowercased(),
                                        "enable_alert_notifications": false,
                                        "device_tokens": []
                                    ])
                            }
                            return
                        }
                        guard let data = try? document.data(as: UserData.self) else {
                            print("Failed to parse user data")
                            return
                        }
                        print("Got user data!")
                        Task {
                            self.userData = data
                        }
                    }
            }
        }
    }
    
    private func signInUser() async {
        do {
            let recordID = try await container.userRecordID()
            print("CloudKit Record ID: \(recordID.recordName)")
            let result = try await AuthAPI.createToken(uid: recordID.recordName)
            try await Auth.auth().signIn(withCustomToken: result.token)
            
            let token = try await Messaging.messaging().token()
            print("UserService: FCM registration token: \(token)")
            await self.updateDeviceToken(token: token)
            
            print("User signed in :)")
        } catch {
            print("Sign in failed: \(error)")
        }
    }
    
    func toggleAlerts(enabled: Bool) async {
        do {
            if let userId = Auth.auth().currentUser?.uid {
                try await self.db
                    .collection("users")
                    .document(userId)
                    .updateData([
                        "enable_alert_notifications": enabled
                    ])
            }
        } catch {
            print("Toggle alert failed: \(error)")
        }
    }
    
    func updateDeviceToken(token: String) async {
        do {
            if let userId = Auth.auth().currentUser?.uid,
               let tokens = self.userData?.device_tokens {
                print("Updating device tokens")
                try await self.db
                    .collection("users")
                    .document(userId)
                    .updateData([
                        "device_tokens": Array(Set(tokens + [token]))
                    ])
            }
        } catch {
            print("Toggle alert failed: \(error)")
        }
    }
}
