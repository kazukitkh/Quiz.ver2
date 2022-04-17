//
//  Constant File.swift
//  QuizeNDimention
//
//  Created by 武樋一樹 on 2022/03/16.
//

import Foundation

struct K {
    static let registerIdentifier: String = "LaunchToRegister"
    static let loginIdentifier: String = "LaunchToLogin"
    static let registerStoryBoardId: String = "RegisterViewController"
    static let homeStoryBoardId: String = "HomeViewController"
    static let loginStoryBoardId: String = "LoginViewController"
    static let launchStoryBoardId: String = "LaunchViewController"
    static let folderStoryBoardId: String = "FolderViewController"
    static let deckEditStoryBoardId: String = "DeckEditViewController"
    static let learnStoryBoardId: String = "LearnViewController"
    static let sideMenuStoryBoardId: String = "SideMenuViewController"
    struct cells {
        static let folderNibName = "FolderTableViewCell"
        static let folderCellIdentifier = "HomeCell"
        static let attributesNibName: [Int: String] =  [2: "DeckViewCell2Attributes", 3: "DeckViewCell3Attributes", 4: "DeckViewCell4Attributes", 5: "DeckViewCell5Attributes", 6: "DeckViewCell6Attributes", 7: "DeckViewCell7Attributes"]
        static let attributesCellIdentifier:[Int: String] = [2: "DeckViewCell2Attributes", 3: "DeckViewCell3Attributes", 4: "DeckViewCell4Attributes", 5: "DeckViewCell5Attributes", 6: "DeckViewCell6Attributes", 7: "DeckViewCell7Attributes"]
        static let testCellNibName:String = "TestTableViewCell"
        static let testCellIdentifier:String = "TestTableViewCell"
        static let LearnCollectionCell: String = "LearnCollectionViewCell"
    }
    struct Fstore {
        struct collections {
            static let user: String = "Users"
            static let folders: String = "Folders"
            static let decks: String = "Decks"
            static let oneDeck: String = "Deck"
            static let term: String = "Terms"
        }
        struct data {
            static let rank: String = "rank"
            static let email: String = "email"
            static let userName: String = "userName"
            static let lastUsed: String = "lastUsed"
            static let lastMade: String = "lastMade"
            static let folderName: String = "folderName"
            static let numberOfContents: String = "numberOfContents"
            static let deckName: String = "deckName"
            static let contentName: String = "contentName"
            static let usingAttributes: String = "usingAttributes"// [String: Bool]
            static let groups: String = "groups"
            static let attributes: String = "attributes"
            static let uniqueName: String = "uniqueName"
            static let valueName: String = "valueName"
            static let correctOrWrong: String = "correctOrWrong"
        }
    }
    struct imageName {
        static let deleteIcon: String = "DeleteIcon"
        static let changeNameIcon: String = "ChangeNameIcon"
    }
}
