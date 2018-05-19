//
//  ChatViewController.swift
//  realtimechatios
//
//  Created by Lucas Jackson on 5/14/18.
//  Copyright © 2018 Lucas Jackson. All rights reserved.
//

import MessageKit
import Alamofire

class ChatViewController:MessagesViewController,MessagesDisplayDelegate {
    var messages = [Message]()
    var reachedEnd = false
    var loadLock = true
    var sender:Sender!
    
    struct ChatData:Decodable {
        var messages:[Message]
        var reachedEnd:Bool
        
        enum CodingKeys: String, CodingKey {
            case messages
            case reachedEnd = "end"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sender = Sender.init(id: User.current!.id, displayName: User.current!.username)
        //Set title from thread
        self.title = InboxData.currentThread?.title
        
        //NotificationCenter observers
        NotificationCenter.default.addObserver(self,selector: #selector(self.receivedMessage(notification:)),name: NSNotification.Name("receivedMessage"),object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(self.socketStateChanged(notification:)),name: NSNotification.Name("sockState"),object: nil)
        
        //Initially set to false
        self.scrollsToBottomOnKeybordBeginsEditing = true
        
        //Specify delegate/datasource
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messageInputBar.delegate = self
        
        //Load initial messages
        self.loadMessages()
    }

    @objc func socketStateChanged(notification:Notification) {
        if let status = notification.object as? Int {
            if status == 0 {
                self.title = "Connecting..."
                self.messageInputBar.sendButton.isEnabled = false
            } else if status == 1 {
                self.title = InboxData.currentThread?.title
                //by default, sendButton is disabled when empty
                if self.messageInputBar.inputTextView.text != "" {
                    self.messageInputBar.sendButton.isEnabled = true
                }
            }
        }
    }

    @objc func receivedMessage(notification:Notification) {
        if let message = notification.object as? Message {
            if message.threadId == InboxData.currentThread?.id {
                self.messages.append(message)
                self.messagesCollectionView.insertSections([self.messages.count - 1])
                self.messagesCollectionView.scrollToBottom(animated: true)
                //mark as read
                if message.sender != currentSender() {
                    let payload = ["read":InboxData.currentThread?.id]
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
                        SocketManager.shared.sock.write(string: String(data: jsonData,encoding: .ascii)!)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }

    @objc func loadMessages() {
        var params:[String:Any] = ["id":InboxData.currentThread!.id]
        params["before"] = messages.first?.sentDate.timeIntervalSince1970
        
        self.loadLock = true
        Alamofire.request(API_HOST+"/messaging/load-messages", method:.get,parameters:params).responseData
            { response in
                switch response.result {
                case .success(let data):
                    do {
                        let messageData = try JSONDecoder().decode(ChatData.self, from: data)
                        for item in messageData.messages {
                            self.messages.insert(item, at: 0)
                        }
                        self.reachedEnd = messageData.reachedEnd
                        if self.messages.count <= 30 {
                            //is first load
                            self.messagesCollectionView.reloadData()
                            self.messagesCollectionView.scrollToBottom()
                        } else {
                            //loading more
                            self.messagesCollectionView.reloadDataAndKeepOffset()
                        }
                    } catch {
                        Helper.showAlert(viewController: self, title: "Oops!", message: error.localizedDescription)
                    }
                case .failure(let error):
                    Helper.showAlert(viewController: self, title: "Oops", message: error.localizedDescription)
                }
                self.loadLock = false
        }
    }
    
    //MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let nav = self.navigationController,loadLock == false,reachedEnd == false {
            let offset = nav.navigationBar.frame.height + UIApplication.shared.statusBarFrame.height
            let position = scrollView.contentOffset.y + offset
            if position < 0 {
                scrollView.isScrollEnabled = false
                scrollView.isScrollEnabled = true
                scrollView.setContentOffset(.zero, animated: false)
                loadMessages()
            }
        }
    }
}

extension ChatViewController:MessagesDataSource {
    func currentSender() -> Sender {
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if message.sender == currentSender() {
            return nil
        }
        if indexPath.section - 1 >= 0 {
            let prevMessage = self.messages[indexPath.section - 1]
            if prevMessage.sender == message.sender {
                return nil
            }
        }
        return NSAttributedString(string: message.sender.displayName, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
}

extension ChatViewController:MessagesLayoutDelegate {
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
    
    func cellTopLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        return LabelAlignment.cellLeading(UIEdgeInsets.init(top: -4, left: 15, bottom: 2.5, right: 0))
    }
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return .zero
    }
}

extension ChatViewController:MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
        if SocketManager.shared.sock.isConnected == false {
            inputBar.sendButton.isEnabled = false
        }
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        if let threadId = InboxData.currentThread?.id {
            inputBar.inputTextView.text = ""
            SocketManager.shared.sendMessage(text, threadId:threadId)
        }
    }
}

