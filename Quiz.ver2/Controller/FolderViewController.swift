//
//  HomeViewController.swift
//  Quiz.ver2
//
//  Created by 武樋一樹 on 2022/03/17.
//

// MARK: - HomeViewController

import UIKit
import Firebase
import DTZFloatingActionButton
import SwipeCellKit
import PromiseKit
import CodableFirebase

class FolderViewController: UIViewController {
    
    var folderName: String = ""
    var folderUniqueName: String = ""
    var decks:[Deck] = []
    let db = Firestore.firestore()
    var colRef: CollectionReference?
    var funcsManager = FuncsManager()
    let auth = Auth.auth()
    let actionButton = DTZFloatingActionButton()
    var userID: String?
    var backBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var folderTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        self.title = folderName
        navigationItem.title = folderName
        backBarButtonItem = UIBarButtonItem(
            title: "Back", style: .plain, target: self, action: #selector(goBack(_:))
        )
        navigationItem.leftBarButtonItem = backBarButtonItem
        funcsManager.delegate = self
        folderTableView.dataSource = self
        folderTableView.delegate = self
        folderTableView.rowHeight = 80.0
        folderTableView.register(UINib(nibName: K.cells.folderNibName, bundle: nil), forCellReuseIdentifier: K.cells.folderCellIdentifier)
        actionButton.handler = {
            button in
            self.addDeck(deckName: "", uniqueName: String(Date().timeIntervalSince1970))
        }
        actionButton.isScrollView = true
        view.addSubview(actionButton)
        if let user = auth.currentUser {
            userID = user.uid
            loadDecks(userID: userID!)
        } else {
            let storyboard: UIStoryboard = self.storyboard!
            let next = storyboard.instantiateViewController(withIdentifier: K.launchStoryBoardId) as! LaunchViewController
            next.modalPresentationStyle = .fullScreen
            self.present(next, animated: true, completion: nil)
        }
    }
    
    @objc func goBack(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let next = storyboard.instantiateViewController(withIdentifier: K.homeStoryBoardId) as! HomeViewController
        let nav = UINavigationController(rootViewController: next)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    func loadDecks(userID: String) {
        colRef = db.collection(K.Fstore.collections.user).document(userID).collection(K.Fstore.collections.folders).document(folderUniqueName).collection(K.Fstore.collections.decks)
        //        print("colRef: \(colRef?.collectionID)")
        colRef?.order(by: K.Fstore.data.lastUsed, descending: true).addSnapshotListener { querySnapshot, error in
            self.decks = []
            if let e = error {
                self.makeAlerts(title: "Error", message: e.localizedDescription, buttonName: "OK")
            } else {
                if let snapshotDocs = querySnapshot?.documents {
                    for deckDoc in snapshotDocs {
                        let data = deckDoc.data()
                        if let attributes = data[K.Fstore.data.attributes] as? [String], let uniqueName = data[K.Fstore.data.uniqueName] as? String,
                           let deckName = data[K.Fstore.data.deckName] as? String,
                           let numberOfContents = data[K.Fstore.data.numberOfContents] as? Int,
                           let lastUsed = data[K.Fstore.data.lastUsed] as? Double,
                           let rank = data[K.Fstore.data.rank] as? [Int] {
                            self.decks.append(Deck(uniqueName: uniqueName, deckName: deckName, numberOfContents: numberOfContents, attributes: attributes, rankedAttributes: rank, lastUsed: lastUsed))
                            DispatchQueue.main.async {
                                self.folderTableView.reloadData()
                                let indexPath = IndexPath(row: self.decks.count - 1, section: 0)
                                self.folderTableView.scrollToRow(at: indexPath, at: .top, animated: false)
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    func deleteDeck(uniqueName: String) {
        colRef!.document(uniqueName).delete() {
            err in
            if let err = err {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
            }
        }
    }
    
    func sendData(uniqueName: String, oldDeckName: String, newDeckName: String) {
        if oldDeckName == newDeckName {
            self.makeAlerts(title: "Error", message: "deck name is same.", buttonName: "OK")
        } else if newDeckName == "" {
            self.makeAlerts(title: "Error", message: "please type in something.", buttonName: "OK")
        }
        
        let docRef = colRef!.document(uniqueName)
        docRef.getDocument { document, error in
            if let err = error {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
            } else {
                if let doc = document, doc.exists {
                    docRef.updateData([
                        K.Fstore.data.deckName: newDeckName
                    ])
                } else {
                    let newArray:[String] = [String](repeating: "attribute", count: 7).enumerated()
                        .map { $0.element + "\($0.offset + 1)" }
                    let rankedArray: [Int] = [0, 1]
                    docRef.setData([
                        K.Fstore.data.attributes: newArray,
                        K.Fstore.data.uniqueName: uniqueName,
                        K.Fstore.data.deckName: newDeckName,
                        K.Fstore.data.numberOfContents: 0,
                        K.Fstore.data.lastUsed: Double(uniqueName)!,
                        K.Fstore.data.rank: rankedArray
                    ])
                }
            }
        }
    }
}

// MARK: - TableView

extension FolderViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return decks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let deck = decks[indexPath.row]
        let cell = folderTableView.dequeueReusableCell(withIdentifier: K.cells.folderCellIdentifier, for: indexPath) as! FolderTableViewCell
        cell.folderName.text = deck.deckName
        cell.numberOfContent.text = String(deck.numberOfContents)
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let nextView = self.storyboard?.instantiateViewController(withIdentifier: K.deckEditStoryBoardId) as! DeckEditViewController
        nextView.folderUniqueName = folderUniqueName
        nextView.folderName = folderName
        nextView.deckName = decks[indexPath.row].deckName
        nextView.deckUniqueName = decks[indexPath.row].uniqueName
        nextView.Attributes = decks[indexPath.row].attributes
        nextView.rankedAttributes = decks[indexPath.row].rankedAttributes
        nextView.colRef = colRef?.document(decks[indexPath.row].uniqueName).collection(K.Fstore.collections.oneDeck)
        nextView.deckDocRef = colRef?.document(decks[indexPath.row].uniqueName)
        let nav = UINavigationController(rootViewController: nextView)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true)
    }
    
}

extension FolderViewController: UITableViewDelegate {
    
}

// MARK: - funcsManager

extension FolderViewController: funcsManagerDelegate {
    func makeAlerts(title: String, message: String, buttonName: String) {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: buttonName, style: .default, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
}

extension FolderViewController: UITextFieldDelegate {
    func addDeck(deckName: String, uniqueName: String) {
        print("deck name: \(deckName)")
        var alertTextField: UITextField?
        
        let alert = UIAlertController(
            title: "Make new Deck",
            message: "Enter Deck Name",
            preferredStyle: UIAlertController.Style.alert)
        alert.addTextField(
            configurationHandler: {(textField: UITextField!) in
                alertTextField = textField
            })
        alert.addAction(
            UIAlertAction(
                title: "Cancel",
                style: UIAlertAction.Style.cancel,
                handler: nil))
        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: UIAlertAction.Style.default) { _ in
                    if let text = alertTextField?.text, text != "" {
                        self.sendData(uniqueName: uniqueName, oldDeckName: deckName, newDeckName: text)
                    } else {
                        self.makeAlerts(title: "error", message: "Type in something", buttonName: "OK")
                    }
                }
        )
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension FolderViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            
            let alert = UIAlertController(
                title: "Delete Deck",
                message: "Are you sure you want to delete the deck \"\(self.decks[indexPath.row].deckName)\"",
                preferredStyle: UIAlertController.Style.alert)
            alert.addAction(
                UIAlertAction(
                    title: "Cancel",
                    style: UIAlertAction.Style.cancel,
                    handler: nil))
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: UIAlertAction.Style.default,
                    handler: { [self]
                        (action: UIAlertAction!) in
                        self.deleteDeck(uniqueName: self.decks[indexPath.row].uniqueName)
                    }))
            self.present(alert, animated: true, completion: nil)
            
        }
        
        let changeNameAction = SwipeAction(style: .default, title: "Change Name") { [self] action, indexPath in
            self.addDeck(deckName: self.decks[indexPath.row].deckName, uniqueName: self.decks[indexPath.row].uniqueName)
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(named: K.imageName.deleteIcon)
        changeNameAction.image = UIImage(named: K.imageName.changeNameIcon)
        
        return [deleteAction, changeNameAction]
    }
    
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .none
        options.transitionStyle = .border
        
        return options
    }
}

