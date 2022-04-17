//
//  LaunchViewController.swift
//  QuizeNDimention
//
//  Created by 武樋一樹 on 2022/03/15.
//

import UIKit
import Firebase

class LaunchViewController: UIViewController {

    @IBOutlet weak var LogInButton: UIButton!
    @IBOutlet weak var RegisterButton: UIButton!
    var db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let user = Auth.auth().currentUser, user.isEmailVerified {
            let storyboard: UIStoryboard = self.storyboard!
            let next = storyboard.instantiateViewController(withIdentifier: K.homeStoryBoardId) as! HomeViewController
            let nav = UINavigationController(rootViewController: next)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true)
        } else {
            do {
                try Auth.auth().signOut()
            } catch let err as NSError {
                self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
            }
        }
        LogInButton.layer.cornerRadius = 10
        LogInButton.setTitle("Log in", for: .normal)
        RegisterButton.layer.cornerRadius = 10
        RegisterButton.setTitle("Register", for: .normal)
    }
    
    @IBAction func registerButtonAction(_ sender: UIButton) {
        let storyboard: UIStoryboard = self.storyboard!
        let next = storyboard.instantiateViewController(withIdentifier: K.registerStoryBoardId) as! RegisterViewController
        let nav = UINavigationController(rootViewController: next)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    func makeAlerts(title: String, message: String, buttonName: String) {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: buttonName, style: .default, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }

}
