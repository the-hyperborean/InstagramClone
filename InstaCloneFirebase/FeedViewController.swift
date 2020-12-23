//
//  FeedViewController.swift
//  InstaCloneFirebase
//
//  Created by Jack Brennan on 11/12/20.
//

import UIKit
import Firebase
import SDWebImage
import OneSignal

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var userEmailArray = [String]()
    var userCommentArray = [String]()
    var likeArray = [Int]()
    var userImageArray = [String]()
    var documentIdArray = [String]()
    
    let fireStoreDatabase = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        getDataFromFirestore()
        
        // Push Notification
        //OneSignal.postNotification(["contents": ["en": "Test Message"], "include_player_ids": ["a66fb8ed-0927-4423-8ec8-a337353db6d6"]])
        
        if let deviceState = OneSignal.getDeviceState() {
            let userId = deviceState.userId
            print("user Id: " + userId!)
            
            fireStoreDatabase.collection("PlayerId").whereField("email", isEqualTo: Auth.auth().currentUser!.email!).getDocuments { (snapshot, error) in
                if error == nil {
                    if snapshot?.isEmpty == false && snapshot != nil {
                        for document in snapshot!.documents {
                            if let playerIDFromFirebase = document.get("player_id") as? String {
                                let documentId = document.documentID
                                print("playerID From Firebase: " + playerIDFromFirebase)
                                
                                if userId != playerIDFromFirebase {
                                    
                                    let playerIdDictionary = ["email": Auth.auth().currentUser!.email!, "player_id": userId] as! [String: Any]
                                    
                                    self.fireStoreDatabase.collection("PlayerId").addDocument(data: playerIdDictionary) { (error) in
                                        if error != nil {
                                            print(error?.localizedDescription)
                                        }
                                    }
                                    
                                }
                            }
                            
                        }
                    } else {
                        
                        let playerIdDictionary = ["email": Auth.auth().currentUser!.email!, "player_id": userId] as! [String: Any]
                        
                        self.fireStoreDatabase.collection("PlayerId").addDocument(data: playerIdDictionary) { (error) in
                            if error != nil {
                                print(error?.localizedDescription)
                            }
                        }
                        
                    }
                }
            }
            
            
            
            
        }
        
        

        
    }
    
    func getDataFromFirestore() {
             
        fireStoreDatabase.collection("Posts").order(by: "date", descending: true).addSnapshotListener { (snapshot, error) in
            if error != nil {
                print(error?.localizedDescription)
            } else {
                if snapshot?.isEmpty != true && snapshot != nil {
                    
                    self.userEmailArray.removeAll(keepingCapacity: false)
                    self.userCommentArray.removeAll(keepingCapacity: false)
                    self.likeArray.removeAll(keepingCapacity: false)
                    self.userImageArray.removeAll(keepingCapacity: false)
                    self.documentIdArray.removeAll(keepingCapacity: false)
                        
                    for document in snapshot!.documents {
                        let documentID = document.documentID
                        self.documentIdArray.append(documentID)
                        
                        if let postedBy = document.get("postedBy") as? String {
                            self.userEmailArray.append(postedBy)
                        }
                        
                        if let postComment = document.get("postComment") as? String {
                            self.userCommentArray.append(postComment)
                        }
                        
                        if let likes = document.get("likes") as? Int {
                            self.likeArray.append(likes)
                        }
                        
                        if let imageUrl = document.get("imageURL") as? String {
                            self.userImageArray.append(imageUrl)
                        }
                    }
                    
                    self.tableView.reloadData()
                    
                }
                
                
            }
        }
                
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userEmailArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FeedCell
        cell.userEmailLabel.text = userEmailArray[indexPath.row]
        cell.likeLabel.text = String(likeArray[indexPath.row])
        cell.commentLabel.text = userCommentArray[indexPath.row]
        cell.userImageView.sd_setImage(with: URL(string: self.userImageArray[indexPath.row]))
        cell.documentIdLabel.text = documentIdArray[indexPath.row]
        return cell
    }

}
