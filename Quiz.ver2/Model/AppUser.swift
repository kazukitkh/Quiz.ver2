//
//  User.swift
//  Quiz.ver2
//
//  Created by 武樋一樹 on 2022/03/18.
//

import Foundation
import Firebase

struct AppUser {
    let name: String?
    let email: String?
    let userId: String

    init(data: [String: Any]) {
        userId = data["userId"] as! String
        email = data["email"] as? String
        name = data["name"] as? String
    }
}
