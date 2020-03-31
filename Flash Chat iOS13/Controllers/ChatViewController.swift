//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    var messages:[Message] = []
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        loadMessages()
    }
    
    func loadMessages(){
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .addSnapshotListener { (querySnapshot, error) in
                self.messages = []
                if let e = error {
                    print("There was an issue retrieving data from fireStore.\(e)")
                } else {
                    if let snapshotDoc = querySnapshot?.documents{
                        for document in snapshotDoc {
                            let data = document.data()
                            if let messageSender = data[K.FStore.senderField] as? String ,
                                let messageBody = data[K.FStore.bodyField] as? String {
                                let newMessage = Message(sender: messageSender, body: messageBody)
                                self.messages.append(newMessage)
                                
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    let indexPath = IndexPath(row: self.messages.count-1, section: 0)
                                    self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                                }
                            }
                        }
                    }
                }
        }
    }
    
    @IBAction func signoutBtnPresed(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
    }
    @IBAction func sendPressed(_ sender: UIButton) {
        
        if let messageBody = messageTextfield.text,
            let sender = Auth.auth().currentUser?.email {
            if messageBody != "" {
                db.collection(K.FStore.collectionName).addDocument(data: [K.FStore.bodyField: messageBody,K.FStore.senderField: sender, K.FStore.dateField: Date().timeIntervalSince1970]) { (error) in
                    if let e = error {
                        print("There was a problem adding data to firestore \(e)")
                    } else {
                        print("Successfuly saved data to firestore")
                        //To run in the main thread not in the background
                        DispatchQueue.main.async {
                            self.messageTextfield.text = ""
                        }
                    }
                }
            } else {
                print("User didn't type anything.")
            }
            
        }
    }
}
//MARK: - UITabelViewDataSource
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = message.body
        
        //this is a message from the current user.
        if message.sender == Auth.auth().currentUser?.email {
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
        }
            //this is a message from another user.
        else {
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.rightImageView.isHidden = true
            cell.leftImageView.isHidden = false
        }
        
        return cell
    }
}
//MARK: - UITableViewDelegate
extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
