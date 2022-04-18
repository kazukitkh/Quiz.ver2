//
//  LoginViewController.swift
//  QuizeNDimention
//
//  Created by 武樋一樹 on 2022/03/16.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var logInButton: UIButton!
    var backBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        backBarButtonItem = UIBarButtonItem(
            title: "Back", style: .plain, target: self, action: #selector(goBack(_:))
        )
        navigationItem.leftBarButtonItem = backBarButtonItem
        logInButton.backgroundColor = .white
        logInButton.setTitle("Log In", for: .normal)
        logInButton.layer.cornerRadius = 20
    }
    
    @objc func goBack(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let next = storyboard.instantiateViewController(withIdentifier: K.launchStoryBoardId) as! LaunchViewController
        let nav = UINavigationController(rootViewController: next)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true)
    }
    
    @IBAction func logInButtonAction(_ sender: Any) {
        if let email = emailTextField.text, let pass = passwordTextField.text {
            Auth.auth().signIn(withEmail: email, password: pass) { result, error in
                if let e = error {
                    self.makeAlerts(title: "Error", message: e.localizedDescription, buttonName: "OK")
                } else {
                    let storyboard: UIStoryboard = self.storyboard!
                    let next = storyboard.instantiateViewController(withIdentifier: K.homeStoryBoardId) as! HomeViewController
                    let nav = UINavigationController(rootViewController: next)
                    nav.modalPresentationStyle = .fullScreen
                    nav.modalTransitionStyle = .crossDissolve
                    self.present(nav, animated: true)
                }
            }
            
        }
    }
    
    func makeAlerts(title: String, message: String, buttonName: String) {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: buttonName, style: .default, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
    
    
}
