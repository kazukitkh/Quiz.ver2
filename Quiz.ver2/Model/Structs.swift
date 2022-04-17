//
//  Deck.swift
//  Quiz.ver2
//
//  Created by 武樋一樹 on 2022/03/18.
//

import Foundation
import UIKit

struct Folder {
    let uniqueName: String
    let folderName: String
    let numberOfDecks: Int
}

struct Deck: Codable {
    let uniqueName: String
    let deckName: String
    let numberOfContents: Int
    let attributes: [String]
    let rankedAttributes: [Int]
    let lastUsed: Double
}

struct Content {
    let uniqueContentName: String
    let attributes: [String]
    let groups: [Int]
}

struct Term {
    let uniqueAttributeNumber: String
    let Value: String
    let correctOrWrong: [Bool]
}

struct AttributesWithBool: Codable {
    let attributes: [nameAndUsed]
}

struct nameAndUsed: Codable {
    let name: String
    let used: Bool
    let zeroToSix: Int
}

struct SideMenuModel {
    var icon: UIImage
    var title: String
}
