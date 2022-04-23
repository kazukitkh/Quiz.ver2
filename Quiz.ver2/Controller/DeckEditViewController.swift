
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

class DeckEditViewController: UIViewController {
    
    var gestureEnabled: Bool = true
    private var draggingIsEnabled: Bool = false
    private var panBaseLocation: CGFloat = 0.0
    private var sideMenuShadowView: UIView!
    private var sideMenuViewController: SideMenuViewController!
    private var sideMenuRevealWidth: CGFloat = 260
    private let paddingForRotation: CGFloat = 150
    private var isExpanded: Bool = false
    private var sideMenuTrailingConstraint: NSLayoutConstraint!
    
    @objc private var revealSideMenuOnTop: Bool = true
    var folderName: String = ""
    var folderUniqueName: String = ""
    var deckUniqueName: String = ""
    var deckName: String = ""
    var numberOfAttributes: Int = 2
    var Attributes: [String] = []
    var contents: [Content] = []
    let db = Firestore.firestore()
    var colRef: CollectionReference?
    var deckDocRef: DocumentReference?
    var funcsManager = FuncsManager()
    let auth = Auth.auth()
    let actionButton = DTZFloatingActionButton()
    var userID: String = ""
    var backBarButtonItem: UIBarButtonItem!
    var moreBarButtonItem: UIBarButtonItem!
    var isShuffle: Bool = false
    var isRevise: Bool = false
    var rankedAttributes: [Int] = [0, 1]
    let sideMenu: [SideMenuModel] = [
        SideMenuModel(icon: UIImage(named: "LogOutImage")!, title: "Log Out"),
        SideMenuModel(icon: UIImage(systemName: "doc.circle")!, title: "Change Attribute Rank"),
        SideMenuModel(icon: UIImage(systemName: "pencil")!, title: "Change Attribute Names")
    ]
    
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var reviseButton: UIButton!
    @IBOutlet weak var deckTableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addButton.layer.cornerRadius = 0.5 * addButton.bounds.size.width
        if let user = auth.currentUser {
            userID = user.uid
            numberOfAttributes = rankedAttributes.count
            loadContents(userID: userID)
        } else {
            let storyboard: UIStoryboard = self.storyboard!
            let next = storyboard.instantiateViewController(withIdentifier: K.launchStoryBoardId) as! LaunchViewController
            next.modalPresentationStyle = .fullScreen
            self.present(next, animated: true, completion: nil)
        }
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        self.sideMenuViewController = storyboard.instantiateViewController(withIdentifier: K.sideMenuStoryBoardId) as? SideMenuViewController
        self.sideMenuViewController.delegate = self
        view.insertSubview(self.sideMenuViewController!.view, at: view.subviews.count)
        addChild(self.sideMenuViewController!)
        self.sideMenuViewController!.didMove(toParent: self)
        self.sideMenuShadowView = UIView(frame: self.view.bounds)
        self.sideMenuShadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.sideMenuShadowView.backgroundColor = .black
        self.sideMenuShadowView.alpha = 0.0
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TapGestureRecognizer))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
        if self.revealSideMenuOnTop {
            view.insertSubview(self.sideMenuShadowView, at: 3)
        }
        
        // Side Menu AutoLayout
        
        self.sideMenuViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        if self.revealSideMenuOnTop {
            self.sideMenuTrailingConstraint = self.sideMenuViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: self.sideMenuRevealWidth + self.paddingForRotation)
            self.sideMenuTrailingConstraint.isActive = true
        }
        NSLayoutConstraint.activate([
            self.sideMenuViewController.view.widthAnchor.constraint(equalToConstant: self.sideMenuRevealWidth),
            self.sideMenuViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.sideMenuViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        //
        //        showMenu(shouldExpand: isExpanded)
        
        backBarButtonItem = UIBarButtonItem(title: "back", style: .plain, target: self, action: #selector(goBack(_:)))
        moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "MoreIcon"), style: .plain, target: revealViewController(), action: #selector(morePressed(_:)))
        self.navigationItem.title = deckName
        self.navigationItem.leftBarButtonItem = backBarButtonItem
        self.navigationItem.rightBarButtonItem = moreBarButtonItem
        //        self.navigationItem.backButtonTitle = "Back"
        
        funcsManager.delegate = self
        deckTableView.dataSource = self
        deckTableView.delegate = self
        deckTableView.rowHeight = UITableView.automaticDimension
        deckTableView.register(UINib(nibName: K.cells.testCellNibName, bundle: nil), forCellReuseIdentifier: K.cells.testCellIdentifier)
        loadSideMenuViewController()
    }
    
    @objc func morePressed(_ sender: UIBarButtonItem) {
        self.sideMenuState(expanded: self.isExpanded ? false : true)
    }
    
    @IBAction func shuffleButtonPressed(_ sender: Any) {
        isShuffle = !isShuffle
        if isShuffle {
            shuffleButton.backgroundColor = .red.withAlphaComponent(0.3)
        } else {
            shuffleButton.backgroundColor = .red.withAlphaComponent(0)
        }
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        addButton.buttonTappedAnimation()
        self.addContent(contentName: "")
    }
    
    
    @IBAction func reviseButtonPressed(_ sender: Any) {
        isRevise = !isRevise
        if isRevise {
            reviseButton.backgroundColor = .red.withAlphaComponent(0.3)
        } else {
            reviseButton.backgroundColor = .red.withAlphaComponent(0)
        }
    }
    
    @IBAction func learnButtonPressed(_ sender: Any) {
        let storyboard: UIStoryboard = self.storyboard!
        let next = storyboard.instantiateViewController(withIdentifier: K.learnStoryBoardId) as! LearnViewController
        next.folderUniqueName = folderUniqueName
        next.folderName = folderName
        next.Attributes = Attributes
        next.deckName = deckName
        next.colRef = colRef
        next.deckDocRef = deckDocRef
        next.deckUniqueName = deckUniqueName
        next.userID = userID
        next.isRevise = isRevise
        next.isShuffle = isShuffle
        next.rankedAttributes = rankedAttributes
        next.contents = contents
        let nav = UINavigationController(rootViewController: next)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true)
    }
    
    @objc func goBack(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let next = storyboard.instantiateViewController(withIdentifier: K.folderStoryBoardId) as! FolderViewController
        next.folderName = folderName
        next.folderUniqueName = folderUniqueName
        let nav = UINavigationController(rootViewController: next)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true)
    }
    
    func loadContents(userID: String) {
        deckDocRef?.addSnapshotListener({ snapshot, err in
            if let err = err {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
            } else {
                if let doc = snapshot, doc.exists {
                    let data = doc.data()
                    if let attributes = data?[K.Fstore.data.attributes] as? [String], let rank = data?[K.Fstore.data.rank] as? [Int] {
                        self.Attributes = attributes
                        self.rankedAttributes = rank
                    }
                }
            }
        })
        colRef?.order(by: K.Fstore.data.lastMade).addSnapshotListener { querySnapshot, error in
            self.contents = []
            if let e = error {
                self.makeAlerts(title: "Error", message: e.localizedDescription, buttonName: "OK")
            } else {
                if let snapshotDocs = querySnapshot?.documents {
                    for contentDoc in snapshotDocs {
                        let data = contentDoc.data()
                        if let contentName = data[K.Fstore.data.contentName] as? String, let attributes = data[K.Fstore.data.attributes] as? [String], let groups = data[K.Fstore.data.groups] as? [Int] {
                            let newContent = Content(uniqueContentName: contentName, attributes: attributes, groups: groups)
                            self.contents.append(newContent)
                            
                            DispatchQueue.main.async {
                                self.deckTableView.reloadData()
                                //                                    let indexPath = IndexPath(row: self.contents.count - 1, section: 0)
                                //                                    self.deckTableView.scrollToRow(at: indexPath, at: .top, animated: false)
                            }
                            
                        }
                    }
                    self.deckDocRef?.updateData([
                        K.Fstore.data.numberOfContents: self.contents.count
                    ])
                }
            }
        }
    }
    
    func deleteContent(uniqueContentName: String) {
        colRef!.document(uniqueContentName).delete() {
            err in
            if let err = err {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
            }
        }
    }
    
    func sendData(uniqueContentName: String, attributeKey: Int, attributeValue: String) {
        let docRef = colRef!.document(uniqueContentName)
        docRef.getDocument { doc, error in
            if let err = error {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
            } else {
                if let doc = doc, doc.exists {
                    if let data = doc.data() {
                        if let temp = data[K.Fstore.data.attributes] as? [String] {
                            var newAttributes = temp
                            newAttributes[attributeKey] = attributeValue
                            docRef.updateData([
                                K.Fstore.data.attributes: newAttributes
                            ])
                            docRef.collection(K.Fstore.collections.term).document(String(attributeKey)).updateData([
                                K.Fstore.data.valueName: attributeValue
                            ])
                        }
                    }
                } else {
                    let newAttributes = [String](repeating: "", count: 7)
                    docRef.setData([
                        K.Fstore.data.contentName: uniqueContentName,
                        K.Fstore.data.attributes: newAttributes,
                        K.Fstore.data.lastMade: uniqueContentName,
                        K.Fstore.data.groups: []
                    ])
                    let correctOrWrongArray = [Bool](repeating: false, count: 7)
                    for i in 0...6 {
                        docRef.collection(K.Fstore.collections.term).document(String(i)).setData([
                            K.Fstore.data.uniqueName: String(i),
                            K.Fstore.data.valueName: "",
                            K.Fstore.data.correctOrWrong: correctOrWrongArray
                        ])
                    }
                }
            }
        }
    }
    
}

// MARK: - TableView

extension DeckEditViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let content = contents[indexPath.row]
        let cell = deckTableView.dequeueReusableCell(withIdentifier: K.cells.testCellIdentifier, for: indexPath) as! TestTableViewCell
        
        cell.attribute1Height.constant = 40
        cell.attribute2Height.constant = 40
        cell.attribute3Height.constant = 40
        cell.attribute4Height.constant = 40
        cell.attribute5Height.constant = 40
        cell.attribute6Height.constant = 40
        cell.attribute7Height.constant = 40
        for i in 0...6 {
            var ok: Bool = false
            for att in rankedAttributes {
                if i == att {
                    ok = true
                }
            }
            if ok == false {
                switch i {
                case 6:
                    cell.attribute7Height.constant = 0
                case 5:
                    cell.attribute6Height.constant = 0
                case 4:
                    cell.attribute5Height.constant = 0
                case 3:
                    cell.attribute4Height.constant = 0
                case 2:
                    cell.attribute3Height.constant = 0
                case 1:
                    cell.attribute2Height.constant = 0
                case 0:
                    cell.attribute1Height.constant = 0
                default:
                    break
                }
            }
        }
        
        for (idx, att) in content.attributes.enumerated() {
            switch idx {
            case 0:
                cell.attribute1TextField.text = att
                cell.attribute1TextField.placeholder = Attributes[idx]
            case 1:
                cell.attribute2TextField.text = att
                cell.attribute2TextField.placeholder = Attributes[idx]
            case 2:
                cell.attribute3TextField.text = att
                cell.attribute3TextField.placeholder = Attributes[idx]
            case 3:
                cell.attribute4TextField.text = att
                cell.attribute4TextField.placeholder = Attributes[idx]
            case 4:
                cell.attribute5TextField.text = att
                cell.attribute5TextField.placeholder = Attributes[idx]
            case 5:
                cell.attribute6TextField.text = att
                cell.attribute6TextField.placeholder = Attributes[idx]
            case 6:
                cell.attribute7TextField.text = att
                cell.attribute7TextField.placeholder = Attributes[idx]
            default:
                break
            }
        }
        cell.delegate = self
        cell.delegateOriginal = self
        
        return cell
    }
}

extension DeckEditViewController: UITableViewDelegate {
    
}

// MARK: - funcsManager

extension DeckEditViewController: funcsManagerDelegate {
    func makeAlerts(title: String, message: String, buttonName: String) {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: buttonName, style: .default, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
}

extension DeckEditViewController: UITextFieldDelegate {
    func addContent(contentName: String) {
        let newContentName = (contentName.isEmpty ? String(Date().timeIntervalSince1970) : contentName)
        self.sendData(uniqueContentName: newContentName, attributeKey: 0, attributeValue: "")
    }
}

// MARK: - SwipeTableViewDelegate

extension DeckEditViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            
            let alert = UIAlertController(
                title: "Delete Content",
                message: "Are you sure you want to delete the content?",
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
                        self.deleteContent(uniqueContentName: self.contents[indexPath.row].uniqueContentName)
                    }))
            self.present(alert, animated: true, completion: nil)
            
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(named: K.imageName.deleteIcon)
        
        return [deleteAction]
    }
    
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .none
        options.transitionStyle = .border
        
        return options
    }
}

// MARK: - TextFieldDelegate

extension DeckEditViewController: InputTextTableCellDelegate {
    func cellTextFieldDidEndEditing(cell: TestTableViewCell, textFieldIndex: Int, value: String) {
        if let indexPath = deckTableView.indexPathForRow(at: cell.convert(cell.bounds.origin, to: deckTableView)) {
            self.sendData(uniqueContentName: contents[indexPath.row].uniqueContentName, attributeKey: textFieldIndex, attributeValue: value)
        }
    }
}

// MARK: - SideMenuDelegate

extension DeckEditViewController: SideMenuViewDelegate {
    func loadSideMenuViewController() {
        self.sideMenuViewController.menu = self.sideMenu
        self.sideMenuViewController.attributes = self.Attributes
        self.sideMenuViewController.rankedAttribute = self.rankedAttributes
        self.sideMenuViewController.defaultHighlightedCell = 0
        self.loadContents(userID: userID)
    }
    
    func changeAttributeName(attIdx: Int, text: String) -> Bool {
        if Attributes.filter({$0 == text}).count == 0 {
            Attributes[attIdx] = text
            deckDocRef?.updateData([
                K.Fstore.data.attributes: Attributes
            ])
            loadSideMenuViewController()
            return true
        } else {
            return false
        }
    }
    
    func attributeNameSelected(attIdx: Int) {
        var alertTextField: UITextField?
        
        let alert = UIAlertController(
            title: "Change Attribute Name",
            message: "Enter Attribute Name",
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
                        if self.changeAttributeName(attIdx: attIdx, text: text) == false {
                            self.makeAlerts(title: "Error", message: "Name already in use.", buttonName: "OK")
                        }
                    } else {
                        self.makeAlerts(title: "Error", message: "Type in something.", buttonName: "OK")
                    }
                }
        )
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func logOut() {
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
                        DispatchQueue.main.async { self.sideMenuState(expanded: false) }
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
    
    func selectedCell(_ row: Int) {
        switch row {
        case 0:
            self.logOut()
        case 1:
            self.sideMenuViewController.changeAttributeRank = true
        case 2:
            self.sideMenuViewController.changeAttributeName = true
        default:
            break
        }
    }
    
    func attributeRankSelected(rank: [Int]) {
        self.rankedAttributes = rank
        deckDocRef?.updateData([
            K.Fstore.data.rank: rank
        ])
        self.loadSideMenuViewController()
    }
    
    func showViewController<T: UIViewController>(viewController: T.Type, storyboardId: String) -> () {
        // Remove the previous View
        for subview in view.subviews {
            if subview.tag == 99 {
                subview.removeFromSuperview()
            }
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: storyboardId) as! T
        vc.view.tag = 99
        view.insertSubview(vc.view, at: self.revealSideMenuOnTop ? 0 : 1)
        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            vc.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            vc.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        if !self.revealSideMenuOnTop {
            if isExpanded {
                vc.view.frame.origin.x = self.sideMenuRevealWidth
            }
            if self.sideMenuShadowView != nil {
                vc.view.addSubview(self.sideMenuShadowView)
            }
        }
        vc.didMove(toParent: self)
    }
    
    func sideMenuState(expanded: Bool) {
        if expanded {
            self.animateSideMenu(targetPosition: self.revealSideMenuOnTop ? 0 : self.sideMenuRevealWidth) { _ in
                self.isExpanded = true
            }
            // Animate Shadow (Fade In)
            UIView.animate(withDuration: 0.5) { self.sideMenuShadowView.alpha = 0.6 }
        }
        else {
            self.sideMenuViewController.changeAttributeRank = false
            self.sideMenuViewController.changeAttributeName = false
            self.animateSideMenu(targetPosition: self.revealSideMenuOnTop ? UIScreen.main.bounds.width : 0) { _ in
                self.isExpanded = false
            }
            // Animate Shadow (Fade Out)
            UIView.animate(withDuration: 0.5) { self.sideMenuShadowView.alpha = 0.0 }
        }
    }
    
    func animateSideMenu(targetPosition: CGFloat, completion: @escaping (Bool) -> ()) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .layoutSubviews, animations: {
            if self.revealSideMenuOnTop {
                self.sideMenuTrailingConstraint.constant = targetPosition
                self.view.layoutIfNeeded()
            }
            else {
                self.view.subviews[1].frame.origin.x = targetPosition
            }
        }, completion: completion)
    }
}

extension UIViewController {
    
    // With this extension you can access the MainViewController from the child view controllers.
    func revealViewController() -> DeckEditViewController? {
        var viewController: UIViewController? = self
        
        if viewController != nil && viewController is DeckEditViewController {
            return viewController! as? DeckEditViewController
        }
        while (!(viewController is DeckEditViewController) && viewController?.parent != nil) {
            viewController = viewController?.parent
        }
        if viewController is DeckEditViewController {
            return viewController as? DeckEditViewController
        }
        return nil
    }
    
}



extension DeckEditViewController: UIGestureRecognizerDelegate {
    
    @objc func TapGestureRecognizer(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            if self.isExpanded {
                self.sideMenuState(expanded: false)
            }
        }
    }
    
    // Close side menu when you tap on the shadow background view
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view?.isDescendant(of: self.sideMenuViewController.view))! {
            return false
        }
        return true
    }
    
    // Dragging Side Menu
    @objc private func handlePanGesture(sender: UIPanGestureRecognizer) {
        
        // ...
        
        let position: CGFloat = sender.translation(in: self.view).x
        let velocity: CGFloat = sender.velocity(in: self.view).x
        
        switch sender.state {
        case .began:
            
            // If the user tries to expand the menu more than the reveal width, then cancel the pan gesture
            if velocity > 0, self.isExpanded {
                sender.state = .cancelled
            }
            
            // If the user swipes right but the side menu hasn't expanded yet, enable dragging
            if velocity > 0, !self.isExpanded {
                self.draggingIsEnabled = true
            }
            // If user swipes left and the side menu is already expanded, enable dragging they collapsing the side menu)
            else if velocity < 0, self.isExpanded {
                self.draggingIsEnabled = true
            }
            
            if self.draggingIsEnabled {
                // If swipe is fast, Expand/Collapse the side menu with animation instead of dragging
                let velocityThreshold: CGFloat = 550
                if abs(velocity) > velocityThreshold {
                    self.sideMenuState(expanded: self.isExpanded ? false : true)
                    self.draggingIsEnabled = false
                    return
                }
                
                if self.revealSideMenuOnTop {
                    self.panBaseLocation = 0.0
                    if self.isExpanded {
                        self.panBaseLocation = self.sideMenuRevealWidth
                    }
                }
            }
            
        case .changed:
            
            // Expand/Collapse side menu while dragging
            if self.draggingIsEnabled {
                if self.revealSideMenuOnTop {
                    // Show/Hide shadow background view while dragging
                    let xLocation: CGFloat = self.panBaseLocation + position
                    let percentage = (xLocation * 150 / self.sideMenuRevealWidth) / self.sideMenuRevealWidth
                    
                    let alpha = percentage >= 0.6 ? 0.6 : percentage
                    self.sideMenuShadowView.alpha = alpha
                    
                    // Move side menu while dragging
                    if xLocation <= self.sideMenuRevealWidth {
                        self.sideMenuTrailingConstraint.constant = xLocation - self.sideMenuRevealWidth
                    }
                }
                else {
                    if let recogView = sender.view?.subviews[1] {
                        // Show/Hide shadow background view while dragging
                        let percentage = (recogView.frame.origin.x * 150 / self.sideMenuRevealWidth) / self.sideMenuRevealWidth
                        
                        let alpha = percentage >= 0.6 ? 0.6 : percentage
                        self.sideMenuShadowView.alpha = alpha
                        
                        // Move side menu while dragging
                        if recogView.frame.origin.x <= self.sideMenuRevealWidth, recogView.frame.origin.x >= 0 {
                            recogView.frame.origin.x = recogView.frame.origin.x + position
                            sender.setTranslation(CGPoint.zero, in: view)
                        }
                    }
                }
            }
        case .ended:
            self.draggingIsEnabled = false
            // If the side menu is half Open/Close, then Expand/Collapse with animationse with animation
            if self.revealSideMenuOnTop {
                let movedMoreThanHalf = self.sideMenuTrailingConstraint.constant > -(self.sideMenuRevealWidth * 0.5)
                self.sideMenuState(expanded: movedMoreThanHalf)
            }
            else {
                if let recogView = sender.view?.subviews[1] {
                    let movedMoreThanHalf = recogView.frame.origin.x > self.sideMenuRevealWidth * 0.5
                    self.sideMenuState(expanded: movedMoreThanHalf)
                }
            }
        default:
            break
        }
    }
}
