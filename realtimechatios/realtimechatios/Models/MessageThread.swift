//
//  MessageThread.swift
//  realtimechatios
//
//  Created by Lucas Jackson on 5/14/18.
//  Copyright © 2018 Lucas Jackson. All rights reserved.
//

import Foundation

class MessageThread:Decodable {
    var id:String
    var title:String
    var unreadCount:Int
    var lastMessage:Message?
    static var currentThread:MessageThread?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(String.self, forKey: .id)
        self.title = try values.decode(String.self, forKey: .title)
        self.unreadCount = try values.decode(Int.self, forKey: .unreadCount)
        //last message won't contain data if we have a blank chat
        self.lastMessage = try values.decodeIfPresent(Message.self, forKey: .lastMessage)
    }
}
