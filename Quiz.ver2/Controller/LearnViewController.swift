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

    var folderName: String = ""
    var folderUniqueName: String = ""
    var deckName: String = ""
    var numberOfAttributes: Int = 2
    var usingAttributes: [String] = []
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
            showButttons(isEnd: false)
            showTerm()
        }
    }
    var contentIdx: Int = 0 {
        didSet {
            if contentIdx == contents.count {
                showButttons(isEnd: true)
            } else {
                changeTerms(uniqueName: contents[contentIdx].uniqueContentName)
            }
        }
    }
    var attributeIdx: Int = 0 {
        didSet {
            showButttons(isEnd: false)
            showTitle()
            showTerm()
        }
    }
    var isExpanded: Bool = false
    var backBarButtonItem: UIBarButtonItem!
    var moreBarButtonItem: UIBarButtonItem!
    
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
        
        funcsManager.delegate = self
        backBarButtonItem = UIBarButtonItem(title: "back", style: .plain, target: self, action: #selector(goBack(_:)))
        moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "MoreIcon"), style: .plain, target: self, action: #selector(morePressed(_:)))
        self.navigationItem.title = deckName
        self.navigationItem.leftBarButtonItem = backBarButtonItem
        self.navigationItem.rightBarButtonItem = moreBarButtonItem
        if contents.count == 0 {
            goEnd()
        } else {
            print("contents: \(contents)")
            initTitles()
            
            self.changeTerms(uniqueName: self.contents[self.contentIdx].uniqueContentName)
        }
        showButttons(isEnd: false)
        
    }
    
    @objc func morePressed(_ sender: UIBarButtonItem) {
        isExpanded = !isExpanded
//        showMenu(shouldExpand: isExpanded)
    }
    
    @objc func goBack(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let next = storyboard.instantiateViewController(withIdentifier: K.folderStoryBoardId) as! FolderViewController
        next.folderName = folderName
        next.folderUniqueName = folderUniqueName
        let nav = UINavigationController(rootViewController: next)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
 
    func showButttons(isEnd: Bool) {
        goBackButton.isHidden = false
        correctButton.isHidden = false
        wrongButton.isHidden = false
        skipButton.isHidden = false
        centerLeftButton.isHidden = false
        centerRightButton.isHidden = false
        if isEnd {
            correctButton.isHidden = true
            wrongButton.isHidden = true
            skipButton.isHidden = true
            centerLeftButton.isHidden = true
            centerRightButton.isHidden = true
            print("goEnd")
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
            attributeTitles.append(usingAttributes[att])
        }
    }
    
    func changeTerms(uniqueName: String) {
        print("colRef: \(colRef.document(uniqueName).path)")
//        let semaphore = DispatchSemaphore(value: 0)
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
                            print("attributeTerms: \(self.attributeTerms)")

                            self.showTitle()
                            self.showTerm()
                        }
                    }
                }
            }
//            semaphore.signal()
        }
//        semaphore.wait()
    }
    
    func goEnd() {
        titleLable.text = ""
        contentLabel.text = "Finished"
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
        goRight(justMove: true)
    }
    
    @IBAction func centerLeftButtonAction(_ sender: Any) {
        if attributeIdx > 0 {
            attributeIdx -= 1
        }
    }
    
    @IBAction func correctButtonAction(_ sender: Any) {
        changeCorrectOrWrong(isCorrect: true)
        goRight(justMove: false)
    }
    
    
    @IBAction func wrongButtonAction(_ sender: Any) {
        changeCorrectOrWrong(isCorrect: false)
        goRight(justMove: false)
    }
    
    
    @IBAction func backButtonAction(_ sender: Any) {
        if contentIdx > 0 {
            contentIdx -= 1
            attributeIdx = 0
        }
    }
    

    @IBAction func skipButtonPressed(_ sender: Any) {
        attributeIdx = numberOfAttributes - 1
        goRight(justMove: false)
    }
    
    
}

extension LearnViewController: funcsManagerDelegate {
    func makeAlerts(title: String, message: String, buttonName: String) {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: buttonName, style: .default, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
}
