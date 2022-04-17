//
//  RegisterViewController.swift
//  QuizeNDimention
//
//  Created by 武樋一樹 on 2022/03/16.
//

import UIKit
import Firebase

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    var email: String = ""
    var userName: String = ""
    let db = Firestore.firestore()
    var auth: Auth!
    var funcsManager = FuncsManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        auth = Auth.auth()
        registerButton.layer.cornerRadius = 10
        registerButton.setTitle("Register", for: .normal)
        emailTextField.delegate = self
        passwordTextField.delegate = self
        funcsManager.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let user = auth.currentUser {
            user.reload(completion: { error in
                if let err = error {
                    self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
                } else {
                    if user.isEmailVerified == true {
                        self.db.collection(K.Fstore.collections.user).document(user.uid).setData([
                            K.Fstore.data.userName: self.userName,
                            K.Fstore.data.email: self.email
                        ])
                        let storyboard: UIStoryboard = self.storyboard!
                        let next = storyboard.instantiateViewController(withIdentifier: K.homeStoryBoardId) as! HomeViewController
                        next.modalPresentationStyle = .fullScreen
                        self.present(next, animated: true, completion: nil)
                    }
                }
            })
        }
    }
    
    @IBAction func registerButtonAction(_ sender: UIButton) {
        emailTextField.endEditing(true)
        passwordTextField.endEditing(true)
        userNameTextField.endEditing(true)
        if let em = emailTextField.text, let password = passwordTextField.text, let uname = userNameTextField.text {
            email = em
            userName = uname
            auth.createUser(withEmail: email, password: password) { result, error in
                if let err = error {
                    self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
                } else if let user = result?.user {
                    user.sendEmailVerification { error in
                        if let err = error {
                            self.makeAlerts(title: "Error", message: err.localizedDescription, buttonName: "OK")
                        } else {
                            self.makeAlerts(title: "Verification Sent", message: "Please open your email.", buttonName: "OK")
                            self.db.collection(K.Fstore.collections.user).document(user.uid).setData([
                                K.Fstore.data.userName: self.userName,
                                K.Fstore.data.email: self.email
                            ])
                        }
                    }
                }
            }
        } else {
            makeAlerts(title: "Register Failed", message: "Please enter all the informations", buttonName: "OK")
        }
    }
    
    
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}

extension RegisterViewController: funcsManagerDelegate {
    func makeAlerts(title: String, message: String, buttonName: String) {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: buttonName, style: .default, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
}

