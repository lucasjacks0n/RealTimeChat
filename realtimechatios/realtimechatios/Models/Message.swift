//
//  Message.swift
//  realtimechatios
//
//  Created by Lucas Jackson on 5/14/18.
//  Copyright © 2018 Lucas Jackson. All rights reserved.
//

import Foundation
import MessageKit

struct Message:MessageType,Decodable {
    var sender: Sender
    var messageId: String
    var threadId: String
    var sentDate: Date
    var data: MessageData
    var text: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case date
        case senderId = "sender_id"
        case threadId = "thread_id"
        case senderName = "sender_name"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let senderId = try values.decode(String.self, forKey: .senderId)
        let senderName = try values.decode(String.self, forKey: .senderName)
        self.sender = Sender.init(id: senderId, displayName: senderName)
        let timeStamp = try values.decode(Int.self, forKey: .date)
        self.sentDate = Date.init(timeIntervalSince1970: TimeInterval(timeStamp))
        self.text = try values.decode(String.self, forKey: .text)
        self.data = MessageData.text(self.text)
        self.messageId = try values.decode(String.self, forKey: .id)
        self.threadId = try values.decode(String.self, forKey: .threadId)
    }
}
