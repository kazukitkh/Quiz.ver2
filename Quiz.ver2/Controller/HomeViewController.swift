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

class HomeViewController: UIViewController {
    
    var colRef: CollectionReference?
    var folders: [Folder] = []
    let db = Firestore.firestore()
    var funcsManager = FuncsManager()
    let auth = Auth.auth()
    let actionButton = DTZFloatingActionButton()
    var userID: String?
    var logOutButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var homeTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logOutButtonItem = UIBarButtonItem(image: UIImage(named: "LogOutImageSmall")!, style: .plain, target: self, action: #selector(logOutPressed(_:)))
        navigationItem.title = "Folders"
        navigationItem.rightBarButtonItem = logOutButtonItem
        funcsManager.delegate = self
        homeTableView.dataSource = self
        homeTableView.delegate = self
        homeTableView.rowHeight = 80.0
        homeTableView.register(UINib(nibName: K.cells.folderNibName, bundle: nil), forCellReuseIdentifier: K.cells.folderCellIdentifier)
        actionButton.handler = {
            button in
            self.addFolder(uniqueName: String(Date().timeIntervalSince1970), folderName: "")
        }
        actionButton.isScrollView = true
        view.addSubview(actionButton)
        if let user = auth.currentUser {
            userID = user.uid
            loadFolders(userID: userID!)
        } else {
            let storyboard: UIStoryboard = self.storyboard!
            let next = storyboard.instantiateViewController(withIdentifier: K.homeStoryBoardId) as! LaunchViewController
            next.modalPresentationStyle = .fullScreen
            self.present(next, animated: true, completion: nil)
        }
    }
    
    @objc func logOutPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to Log Out?",
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
                handler: {_ in
                    do {
                        try self.auth.signOut()
                        let storyboard: UIStoryboard = self.storyboard!
                        let next = storyboard.instantiateViewController(withIdentifier: K.launchStoryBoardId) as! LaunchViewController
                        let nav = UINavigationController(rootViewController: next)
                        nav.modalPresentationStyle = .fullScreen
                        nav.modalTransitionStyle = .crossDissolve
                        self.present(nav, animated: true)
                    } catch let err as NSError {
                        self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
                    }
                }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func loadFolders(userID: String) {
        colRef = db.collection(K.Fstore.collections.user).document(userID).collection(K.Fstore.collections.folders)
        colRef!.order(by: K.Fstore.data.lastUsed, descending: true).addSnapshotListener { querySnapshot, error in
            self.folders = []
            
            if let e = error {
                print("error1: \(e)")
                self.makeAlerts(title: "Error", message: e.localizedDescription, buttonName: "OK")
            } else {
                if let snapshotDocs = querySnapshot?.documents {
                    for folderDoc in snapshotDocs {
                        let data = folderDoc.data()
                        if let folderName = data[K.Fstore.data.folderName] as? String, let numberOfDecks = data[K.Fstore.data.numberOfContents] as? Int, let uniqueName = data[K.Fstore.data.uniqueName] as? String {
                            let newFolder = Folder(uniqueName: uniqueName, folderName: folderName, numberOfDecks: numberOfDecks)
                            self.folders.append(newFolder)
                            DispatchQueue.main.async {
                                self.homeTableView.reloadData()
                                let indexPath = IndexPath(row: self.folders.count - 1, section: 0)
                                self.homeTableView.scrollToRow(at: indexPath, at: .top, animated: false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deleteFolder(uniqueName: String) {
        colRef!.document(uniqueName).delete() {
            err in
            if let err = err {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
            }
        }
    }
    
    func sendData(uniqueName: String, oldFolderName: String, newFolderName: String) {
        let uniqueDate = Double(uniqueName)!
        if oldFolderName == newFolderName {
            self.makeAlerts(title: "Error", message: "folder name is same.", buttonName: "OK")
        } else if newFolderName == "" {
            self.makeAlerts(title: "Error", message: "please type in something.", buttonName: "OK")
        }
        let docRef = colRef!.document(uniqueName)
        docRef.getDocument { document, error in
            if let err = error {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
            } else {
                if let doc = document, doc.exists {
                    docRef.updateData([
                        K.Fstore.data.folderName: newFolderName
                    ])
                } else {
                    docRef.setData([
                        K.Fstore.data.numberOfContents: 0,
                        K.Fstore.data.uniqueName: uniqueName,
                        K.Fstore.data.folderName: newFolderName,
                        K.Fstore.data.lastUsed: uniqueDate
                    ])
                }
            }
        }
    }
}

// MARK: - TableView

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let folder = folders[indexPath.row]
        let cell = homeTableView.dequeueReusableCell(withIdentifier: K.cells.folderCellIdentifier, for: indexPath) as! FolderTableViewCell
        cell.folderName.text = folder.folderName
        cell.numberOfContent.text = String(folder.numberOfDecks)
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        colRef!.document(folders[indexPath.row].uniqueName).updateData([
            K.Fstore.data.lastUsed: Date().timeIntervalSince1970
        ])
        let nextView = self.storyboard?.instantiateViewController(withIdentifier: K.folderStoryBoardId) as! FolderViewController
        nextView.folderName = folders[indexPath.row].folderName
        nextView.folderUniqueName = folders[indexPath.row].uniqueName
        nextView.numberOfDecks = folders[indexPath.row].numberOfDecks
        let nav = UINavigationController(rootViewController: nextView)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true)
    }
}

extension HomeViewController: UITableViewDelegate {
    
}

// MARK: - funcsManager

extension HomeViewController: funcsManagerDelegate {
    func makeAlerts(title: String, message: String, buttonName: String) {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: buttonName, style: .default, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
}

extension HomeViewController: UITextFieldDelegate {
    func addFolder(uniqueName: String, folderName: String) {
        print("folder name: \(folderName)")
        var alertTextField: UITextField?
        
        let alert = UIAlertController(
            title: "Make new Folder",
            message: "Enter Folder Name",
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
                        self.sendData(uniqueName: uniqueName, oldFolderName: folderName, newFolderName: text)
                    } else {
                        self.makeAlerts(title: "error", message: "Type in something", buttonName: "OK")
                    }
                }
        )
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension HomeViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            
            let alert = UIAlertController(
                title: "Delete Folder",
                message: "Are you sure you want to delete the folder \"\(self.folders[indexPath.row].folderName)\"",
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
                        self.deleteFolder(uniqueName: folders[indexPath.row].uniqueName)
                    }))
            self.present(alert, animated: true, completion: nil)
            
        }
        
        let changeNameAction = SwipeAction(style: .default, title: "Change Name") { [self] action, indexPath in
            self.addFolder(uniqueName: folders[indexPath.row].uniqueName, folderName: folders[indexPath.row].folderName)
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

