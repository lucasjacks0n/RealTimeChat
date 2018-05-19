//
//  SocketManager.swift
//  realtimechatios
//
//  Created by Lucas Jackson on 5/14/18.
//  Copyright © 2018 Lucas Jackson. All rights reserved.
//

import Foundation
import Starscream

class SocketManager:WebSocketDelegate {
    static let shared = SocketManager()
    
    var sock:WebSocket!
    
    func connect() {
        let request = NSMutableURLRequest(url: URL(string:"ws://localhost:8000/connect")!)
        request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: HTTPCookieStorage.shared.cookies!)
        sock = WebSocket.init(request: request as URLRequest)
        sock.delegate = self
        sock.connect()
    }

    func sendMessage(_ text:String,threadId:String) {
        let payload = ["message":["text":text,"id":threadId]]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            self.sock.write(string: String(data: jsonData,encoding: .ascii)!)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: WebsocketDelegate
    func websocketDidConnect(socket: WebSocketClient) {
        NotificationCenter.default.post(name: Notification.Name("sockState"), object: 1)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        if User.current != nil {
            print("re-connecting...")
            NotificationCenter.default.post(name: NSNotification.Name.init("sockState"),object:0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.sock.connect()
            })
        } else {
            print("disconnected")
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        if let data = text.data(using: .utf8) {
            do {
                let message = try JSONDecoder().decode(Message.self, from: data)
                NotificationCenter.default.post(name: NSNotification.Name("receivedMessage"), object: message)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("received data")
    }
}
