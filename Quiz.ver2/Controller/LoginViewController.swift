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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        logInButton.backgroundColor = .white
        logInButton.setTitle("Log In", for: .normal)
        logInButton.layer.cornerRadius = 20
    }
    
    @IBAction func logInButtonAction(_ sender: Any) {
        if let email = emailTextField.text, let pass = passwordTextField.text {
            Auth.auth().signIn(withEmail: email, password: pass) { result, error in
                if let e = error {
                    let dialog = UIAlertController(title: "Log In Failed", message: e.localizedDescription , preferredStyle: .alert)
                    dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                } else {
                    let storyboard: UIStoryboard = self.storyboard!
                    let next = storyboard.instantiateViewController(withIdentifier: K.homeStoryBoardId) as! HomeViewController
                    let nav = UINavigationController(rootViewController: next)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                }
            }
            
        }
    }
    
    
    
}
