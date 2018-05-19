//
//  InboxTableViewController.swift
//  realtimechatios
//
//  Created by Lucas Jackson on 5/14/18.
//  Copyright © 2018 Lucas Jackson. All rights reserved.
//

import UIKit
import Alamofire

class InboxTableViewController:UITableViewController {
    var inboxData:InboxData?
    
    /*Add + and logout buttons to the nav bar*/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TableView rowHeight
        self.tableView.rowHeight = 58
        
        //NotificationCenter
        NotificationCenter.default.addObserver(self,selector: #selector(self.socketStateChanged(notification:)),name: NSNotification.Name("sockState"),object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(self.receivedMessage(notification:)),name: NSNotification.Name("receivedMessage"),object: nil)
        
        //BarButtonItems
        let addChatButton = UIButton(type: UIButtonType.contactAdd)
        addChatButton.addTarget(self, action: #selector(self.promptAddChat), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView:addChatButton)
        
        let logoutButton = UIButton(type: UIButtonType.system)
        logoutButton.setTitle("logout", for: .normal)
        logoutButton.addTarget(self, action: #selector(self.logout), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView:logoutButton)
        
        //Connect to socket
        SocketManager.shared.connect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        InboxData.currentThread = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ChatViewController {
            let thread = sender as! MessageThread
            InboxData.currentThread = thread
            thread.unreadCount = 0
            self.tableView.reloadData()
        }
    }
    
    /*Reload current threads for the logged in user*/
    @objc func reloadInbox() {
        Alamofire.request(API_HOST+"/messaging/load-inbox").responseData
            { response in
                switch response.result {
                case .success(let data):
                    do {
                        self.inboxData = try JSONDecoder().decode(InboxData.self, from: data)
                        self.tableView.reloadData()
                    } catch {
                        Helper.showAlert(viewController: self, title: "Oops!", message: error.localizedDescription)
                    }
                case .failure(let error):
                    Helper.showAlert(viewController: self, title: "Oops!", message: error.localizedDescription)
                }
        }
    }
    
    /*Detect when socket disconnects/connects*/
    @objc func socketStateChanged(notification:Notification) {
        if let status = notification.object as? Int {
            if status == 1 {
                self.reloadInbox()
            }
            self.title = status == 1 ? "Inbox" : "Connecting..."
        }
    }
    
    /*SocketManager received a message
     - Keeps track of other message threads even when we are inside another chat
     */
    @objc func receivedMessage(notification:Notification) {
        if let message = notification.object as? Message {
            inboxData?.receivedMessage(message)
            self.tableView.reloadData()
        }
    }
    
    /*Display alert to create/join chat thread*/
    @objc func promptAddChat() {
        let alert = UIAlertController(title: "New Chatroom", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(dismissAction)
        let addAction = UIAlertAction(title: "Add", style: .default, handler: { _ in
            self.addChatRoom(title: alert.textFields![0].text!)
        })
        alert.addAction(addAction) //lol
        self.present(alert, animated: true, completion: nil)
    }
    
    /*Add chatroom from title*/
    func addChatRoom(title:String) {
        let params = ["title":title] as [String:Any]
        Alamofire.request(API_HOST+"/messaging/add-chatroom",method:.post,parameters:params).response
            { response in
                if let err = response.error {
                    print(err.localizedDescription)
                } else {
                    self.reloadInbox()
                }
        }
    }
    
    /*Disconnect the socket and tell the server to void the login session*/
    @objc func logout() {
        User.current = nil
        SocketManager.shared.sock.disconnect()
        Alamofire.request(API_HOST+"/auth/logout")
        self.navigationController?.popToRootViewController(animated: true)
    }
}

//MARK: UITableViewDelegate
extension InboxTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "inboxToChat", sender: inboxData?[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inboxData?.values.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "thread") as! ThreadCell
        if let thread = inboxData?[indexPath.row] {
            if thread.unreadCount > 0 {
                cell.titleLabel.text = thread.title + " (" + String(thread.unreadCount) + ")"
                cell.backgroundColor = UIColor.init(red: 0xB7 / 255, green: 0xFA / 255, blue: 0xDE / 255, alpha: 0.3)
            } else {
                cell.titleLabel.text = thread.title
                cell.backgroundColor = UIColor.clear
            }
            
            cell.previewLabel.text = thread.lastMessage?.text
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
}

