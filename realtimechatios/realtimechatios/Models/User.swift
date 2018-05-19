//
//  User.swift
//  realtimechatios
//
//  Created by Lucas Jackson on 5/14/18.
//  Copyright © 2018 Lucas Jackson. All rights reserved.
//


import Foundation

struct User:Codable {
    static var current:User!
    var id:String
    var username:String
}
