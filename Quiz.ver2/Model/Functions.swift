//
//  Functions.swift
//  Quiz.ver2
//
//  Created by 武樋一樹 on 2022/03/19.
//

import Foundation
import UIKit

protocol funcsManagerDelegate {
    func makeAlerts(title: String, message: String, buttonName: String)
    
}

struct FuncsManager {
    var delegate: funcsManagerDelegate?
    
}
