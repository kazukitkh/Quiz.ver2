//
//  LearnViewController.swift
//  Quiz.ver2
//
//  Created by 武樋一樹 on 2022/04/11.
//

import UIKit
import SwiftUI
import Firebase

class LearnViewController: UIViewController {
    
    var gestureEnabled: Bool = true
    private var draggingIsEnabled: Bool = false
    private var panBaseLocation: CGFloat = 0.0
    private var sideMenuShadowView: UIView!
    private var sideMenuViewController: SideMenuViewController!
    private var sideMenuRevealWidth: CGFloat = 260
    private let paddingForRotation: CGFloat = 150
    private var isExpanded: Bool = false
    private var sideMenuTrailingConstraint: NSLayoutConstraint!
    let sideMenu: [SideMenuModel] = [
        SideMenuModel(icon: UIImage(named: "LogOutImage")!, title: "Log Out"),
        SideMenuModel(icon: UIImage(systemName: "delete.left")!, title: "Delete the content"),
        SideMenuModel(icon: UIImage(systemName: "pencil")!, title: "Change Attribute Names")
    ]
    
    @objc private var revealSideMenuOnTop: Bool = true
    var isEnd: Bool = false
    var deckUniqueName: String = ""
    var isRevise: Bool = false
    var isShuffle: Bool = false
    var folderName: String = ""
    var folderUniqueName: String = ""
    var deckName: String = ""
    var numberOfAttributes: Int = 2
    var Attributes: [String] = []
    var contents: [Content] = []
    let db = Firestore.firestore()
    var colRef: CollectionReference!
    var deckDocRef: DocumentReference!
    var funcsManager = FuncsManager()
    let auth = Auth.auth()
    var userID: String = ""
    var rankedAttributes: [Int] = []
    var attributeTitles:[String] = []
    var attributeTerms:[String] = [] {
        didSet {
            showButttons()
            showTerm()
        }
    }
    var contentIdx: Int = 0 {
        didSet {
            if contentIdx >= contents.count {
                isEnd = true
                showButttons()
            } else {
                isEnd = false
                changeTerms(uniqueName: contents[contentIdx].uniqueContentName)
                showButttons()
            }
            loadSideMenuViewController()
        }
    }
    var attributeIdx: Int = 0 {
        didSet {
            showButttons()
            if !isEnd {
                showTitle()
                showTerm()
            }
        }
    }
    var backBarButtonItem: UIBarButtonItem!
    var moreBarButtonItem: UIBarButtonItem!
    
    
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var learnButton: UIButton!
    @IBOutlet weak var reviseButton: UIButton!
    
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    
    @IBOutlet weak var centerRightButton: UIButton!
    @IBOutlet weak var centerLeftButton: UIButton!
    @IBOutlet weak var goBackButton: UIButton!
    @IBOutlet weak var wrongButton: UIButton!
    @IBOutlet weak var correctButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    @IBOutlet weak var slideMenuView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = auth.currentUser {
            userID = user.uid
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
            view.insertSubview(self.sideMenuShadowView, at: 4)
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
        funcsManager.delegate = self
        backBarButtonItem = UIBarButtonItem(title: "back", style: .plain, target: self, action: #selector(goBack(_:)))
        moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "MoreIcon"), style: .plain, target: self, action: #selector(morePressed(_:)))
        self.navigationItem.title = deckName
        self.navigationItem.leftBarButtonItem = backBarButtonItem
        self.navigationItem.rightBarButtonItem = moreBarButtonItem
        if contents.count == 0 {
            goEnd()
        } else {
            initTitles()
            self.changeTerms(uniqueName: self.contents[self.contentIdx].uniqueContentName)
        }
        loadLearnViewController(learnPressed: false, isDeleted: false)
    }
    
    @IBAction func learnButtonPressed(_ sender: Any) {
        isEnd = false
        loadLearnViewController(learnPressed: true, isDeleted: false)
    }
    
    @IBAction func shuffleButtonPressed(_ sender: Any) {
        isShuffle = !isShuffle
        if isShuffle {
            shuffleButton.backgroundColor = .red.withAlphaComponent(0.3)
        } else {
            shuffleButton.backgroundColor = .red.withAlphaComponent(0)
        }
    }
    
    @IBAction func reviseButtonPressed(_ sender: Any) {
        isRevise = !isRevise
        if isRevise {
            reviseButton.backgroundColor = .red.withAlphaComponent(0.3)
        } else {
            reviseButton.backgroundColor = .red.withAlphaComponent(0)
        }
    }
    
    func fetchCards2_2(temp: [Content], completion: @escaping ([Content]) -> Void) {
        var newContents:[Content] = []
        for (cIdx, content) in temp.enumerated() {
            for (idx, num) in self.rankedAttributes.enumerated() {
                if idx == 0 {
                    continue
                }
                self.colRef.document(content.uniqueContentName).collection(K.Fstore.collections.term).document(String(num)).getDocument(completion: { snapshot, err in
                    if let err = err {
                        self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
                    } else {
                        if let doc = snapshot, doc.exists {
                            let data = doc.data()
                            if let arr = data?[K.Fstore.data.correctOrWrong] as? [Bool] {
                                print("came inside.")
                                if arr[self.rankedAttributes[0]] == false {
                                    newContents.append(content)
                                }
                            }
                        }
                    }
                    if cIdx + 1 == temp.count && idx + 1 == self.rankedAttributes.count {
                        print("Cards2_2: \(newContents.map {$0.uniqueContentName})")
                        completion(newContents)
                        return
                    }
                })
            }
        }
    }
    
    func fetchCards1_2(completion: @escaping ([Content]) -> Void) {
        colRef.order(by: K.Fstore.data.lastMade).getDocuments { snapShot, err in
            var temps: [Content] = []
            if let err = err {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
                completion([])
            } else {
                if let snapshotDocs = snapShot?.documents {
                    for (_, contentDoc) in snapshotDocs.enumerated() {
                        let data = contentDoc.data()
                        if let contentName = data[K.Fstore.data.contentName] as? String, let attributes = data[K.Fstore.data.attributes] as? [String], let groups = data[K.Fstore.data.groups] as? [Int] {
                            let newContent = Content(uniqueContentName: contentName, attributes: attributes, groups: groups)
                            temps.append(newContent)
                        }
                    }
                }
                print("Cards1_2: \(temps.map {$0.uniqueContentName})")
                completion(temps)
            }
        }
    }
    
    func fetchCards1_1() async -> [Content] {
        await withCheckedContinuation({ continuation in
            fetchCards1_2 { contents in
                continuation.resume(returning: contents)
            }
        })
    }
    
    func fetchCards2_1(temp: [Content]) async -> [Content] {
        await withCheckedContinuation({ continuation in
            fetchCards2_2(temp: temp) { contents in
                continuation.resume(returning: contents)
            }
        })
    }
    
    func loadLearnViewController(learnPressed: Bool, isDeleted: Bool) {
        Task {
            self.contents = []
            var contents1 = await fetchCards1_1()
            print("contents1: \(contents1.map {$0.uniqueContentName})")
            if self.isShuffle {
                contents1.shuffle()
            }
            if self.isRevise {
                self.contents = await fetchCards2_1(temp: contents1)
            } else {
                print("no revise")
                self.contents = contents1
            }
            if learnPressed {
                contentIdx = 0
                attributeIdx = 0
            }
            if isDeleted {
                if self.contentIdx >= self.contents.count {
                    self.isEnd = true
                    self.showButttons()
                } else {
                    self.isEnd = false
                    self.changeTerms(uniqueName: self.contents[self.contentIdx].uniqueContentName)
                    self.showButttons()
                }
                attributeIdx = 0
            } else {
                if contentIdx < contents.count {
                    self.changeTerms(uniqueName: self.contents[self.contentIdx].uniqueContentName)
                }
            }
            self.loadSideMenuViewController()
        }
    }
    
    @objc func morePressed(_ sender: UIBarButtonItem) {
        self.sideMenuState(expanded: self.isExpanded ? false : true)
    }
    
    @objc func goBack(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let next = storyboard.instantiateViewController(withIdentifier: K.deckEditStoryBoardId) as! DeckEditViewController
        next.folderName = folderName
        next.folderUniqueName = folderUniqueName
        next.deckUniqueName = deckUniqueName
        next.deckName = deckName
        next.Attributes = Attributes
        next.rankedAttributes = rankedAttributes
        next.colRef = colRef
        next.deckDocRef = deckDocRef
        let nav = UINavigationController(rootViewController: next)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true)
    }
    
    func deleteContent() {
        colRef!.document(contents[contentIdx].uniqueContentName).delete() {
            err in
            if let err = err {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
            } else {
                self.loadLearnViewController(learnPressed: false, isDeleted: true)
                let temp = [self.contentIdx, self.attributeIdx]
                self.contentIdx = temp[0]
                self.attributeIdx = temp[1]
                self.loadSideMenuViewController()
            }
        }
    }
    
    func showButttons() {
        shuffleButton.isHidden = true
        learnButton.isHidden = true
        reviseButton.isHidden = true
        goBackButton.isHidden = false
        correctButton.isHidden = false
        wrongButton.isHidden = false
        skipButton.isHidden = false
        centerLeftButton.isHidden = false
        centerRightButton.isHidden = false
        if self.isEnd {
            correctButton.isHidden = true
            wrongButton.isHidden = true
            skipButton.isHidden = true
            centerLeftButton.isHidden = true
            centerRightButton.isHidden = true
            reviseButton.isHidden = false
            shuffleButton.isHidden = false
            learnButton.isHidden = false
            goEnd()
            return
        } else if contentIdx == 0 {
            goBackButton.isHidden = true
        }
        if attributeIdx == 0 {
            correctButton.isHidden = true
            wrongButton.isHidden = true
        }
    }
    
    func initTitles() {
        for att in rankedAttributes {
            attributeTitles.append(Attributes[att])
        }
        numberOfAttributes = rankedAttributes.count
    }
    
    func changeTerms(uniqueName: String) {
        colRef.document(uniqueName).getDocument { snapShot, err in
            if let err = err {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
            } else {
                if let doc = snapShot, doc.exists {
                    if let data = doc.data() {
                        if let terms = data[K.Fstore.data.attributes] as? [String] {
                            var temp: [String] = []
                            for attIdx in self.rankedAttributes {
                                temp.append(terms[attIdx])
                            }
                            self.attributeTerms = temp
                            self.showTitle()
                            self.showTerm()
                        }
                    }
                }
            }
        }
    }
    
    func goEnd() {
        titleLable.text = ""
        contentLabel.text = "Finished"
        self.isEnd = true
        self.sideMenuViewController.isLearnEnd = true
    }
    
    func showTitle() {
        titleLable.text = attributeTitles[attributeIdx]
    }
    
    func showTerm() {
        contentLabel.text = attributeTerms[attributeIdx]
    }
    
    func goRight(justMove: Bool) {
        if attributeIdx < numberOfAttributes - 1 {
            attributeIdx += 1
        } else if justMove == false {
            contentIdx += 1
            if contentIdx < contents.count {
                attributeIdx = 0
            }
        }
    }
    
    func changeCorrectOrWrong(isCorrect: Bool) {
        let docRef = colRef.document(contents[contentIdx].uniqueContentName).collection(K.Fstore.collections.term).document(String(attributeIdx))
        docRef.getDocument { snapShot, err in
            if let err = err {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
            } else {
                if let doc = snapShot, doc.exists {
                    if let data = doc.data() {
                        if let cOw = data[K.Fstore.data.correctOrWrong] as? [Bool] {
                            var tmpCOW = cOw
                            tmpCOW[self.rankedAttributes[0]] = true
                            docRef.updateData([
                                K.Fstore.data.correctOrWrong: tmpCOW
                            ])
                        }
                    }
                }
            }
        }
    }
    
    
    
    @IBAction func centerRightButtonAction(_ sender: Any) {
        centerRightButton.buttonBackgroundAnimation()
//        centerRightButton.backgroundColor = UIColor.black.withAlphaComponent(0.1)
//        Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(clearButtonBackGround), userInfo: nil, repeats: false)
        goRight(justMove: true)
    }
    
    @IBAction func centerLeftButtonAction(_ sender: Any) {
        centerLeftButton.buttonBackgroundAnimation()
//        centerLeftButton.backgroundColor = UIColor.black.withAlphaComponent(0.1)
//        Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(clearButtonBackGround), userInfo: nil, repeats: false)
        if attributeIdx > 0 {
            attributeIdx -= 1
        }
    }
    
    @IBAction func correctButtonAction(_ sender: Any) {
        correctButton.buttonTappedAnimation()
        changeCorrectOrWrong(isCorrect: true)
        goRight(justMove: false)
    }
    
    
    @IBAction func wrongButtonAction(_ sender: Any) {
        wrongButton.buttonTappedAnimation()
        changeCorrectOrWrong(isCorrect: false)
        goRight(justMove: false)
    }
    
    
    @IBAction func backButtonAction(_ sender: Any) {
        goBackButton.buttonTappedAnimation()
        if contentIdx > 0 {
            contentIdx -= 1
            attributeIdx = 0
        }
    }
    
    
    @IBAction func skipButtonPressed(_ sender: Any) {
        skipButton.buttonTappedAnimation()
        attributeIdx = numberOfAttributes - 1
        goRight(justMove: false)
    }
    
    @objc func clearButtonBackGround() {
        centerLeftButton.backgroundColor = UIColor.clear
        centerRightButton.backgroundColor = UIColor.clear
    }
}

extension LearnViewController: funcsManagerDelegate {
    func makeAlerts(title: String, message: String, buttonName: String) {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: buttonName, style: .default, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
}

// MARK: - SideMenuView

extension LearnViewController: SideMenuViewDelegate {
    func loadSideMenuViewController() {
        self.sideMenuViewController.menu = self.sideMenu
        if contentIdx < contents.count {
            self.sideMenuViewController.attributes = self.contents[contentIdx].attributes
        }
        self.sideMenuViewController.rankedAttribute = self.rankedAttributes
        self.sideMenuViewController.defaultHighlightedCell = 0
    }
    
    func changeAttributeName(attIdx: Int, text: String) {
        var newAttributes: [String] = contents[contentIdx].attributes
        newAttributes[attIdx] = text
        colRef.document(contents[contentIdx].uniqueContentName).updateData([
            K.Fstore.data.attributes: newAttributes
        ])
        self.loadLearnViewController(learnPressed: false, isDeleted: false)
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
                        self.changeAttributeName(attIdx: attIdx, text: text)
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
            self.deleteContent()
        case 2:
            self.sideMenuViewController.changeAttributeName = true
        default:
            break
        }
    }
    
    func attributeRankSelected(rank: [Int]) {
        print("rank selected.")
        self.rankedAttributes = rank
        deckDocRef?.updateData([
            K.Fstore.data.rank: rank
        ])
        self.loadLearnViewController(learnPressed: false, isDeleted: false)
//        self.loadSideMenuViewController()
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
            self.sideMenuViewController.isLearnEnd = false
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

extension LearnViewController: UIGestureRecognizerDelegate {
    
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
