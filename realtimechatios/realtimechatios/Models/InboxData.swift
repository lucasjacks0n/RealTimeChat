//
//  InboxData.swift
//  realtimechatios
//
//  Created by Lucas Jackson on 5/14/18.
//  Copyright © 2018 Lucas Jackson. All rights reserved.
//

// Models/InboxData.swift

import Foundation

class InboxData:Decodable {
    var keys: [String]
    var values:[String:MessageThread]
    static var currentThread:MessageThread?
    
    enum CodingKeys: String, CodingKey {
        case threads
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let threads = try values.decode([MessageThread].self, forKey: .threads)
        /*take array of MessageThreads and convert into a dict ['id':MessageThread]
         with reduce */
        self.values = threads.reduce([String:MessageThread]()) { (dict, thread) -> [String:MessageThread] in
            var dict = dict
            dict[thread.id] = thread
            return dict
        }
        /* sort thread keys based on lastMessage.date */
        let sortedThreads = self.values.sorted(by: ({$0.value.lastMessage?.sentDate ?? .distantPast > $1.value.lastMessage?.sentDate ?? .distantPast}))
        self.keys = sortedThreads.map { $0.value.id }
    }
    
    /*Update the thread's lastMessage and update position (worst O(n))*/
    func receivedMessage(_ message:Message) {
        if let thread = self[message.threadId] {
            thread.lastMessage = message
            if InboxData.currentThread?.id != thread.id {
                thread.unreadCount += 1
            }
            self.keys = keys.filter{$0 != thread.id}
            self.keys.insert(thread.id, at: 0)
        }
    }
    
    /*retreive ordered thread at index O(1)*/
    subscript(key:Int) -> MessageThread {
        get {
            return values[keys[key]]!
        }
    }
    
    /*retreive thread from id O(1)*/
    subscript(key:String) -> MessageThread? {
        get {
            return values[key]
        }
    }
}
