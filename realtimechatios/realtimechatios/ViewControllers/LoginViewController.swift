//
//  LoginViewController.swift
//  realtimechatios
//
//  Created by Lucas Jackson on 5/14/18.
//  Copyright © 2018 Lucas Jackson. All rights reserved.
//

import UIKit
import Alamofire

class LoginViewController: UIViewController,UITextFieldDelegate {
    @IBOutlet var usernameTextField:UITextField!
    @IBOutlet var passwordTextField:UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Check if we are logged in on load
        Alamofire.request(API_HOST+"/auth/login").responseData
            { response in switch response.result {
            case .success(let data):
                if response.response?.statusCode == 200 {
                    self.didLogin(userData: data)
                }
            case .failure(let error):
                Helper.showAlert(viewController: self,title: "Oops!",message: error.localizedDescription)
                }
        }
    }
    
    /*Perform actions when the return key is pressed*/
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            //change cursor from username to password textfield
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            //attempt to login when we press enter on password field
            login(username: self.usernameTextField.text!, password: self.passwordTextField.text!)
        }
        return true
    }
    
    /*Login with username and password*/
    func login(username:String,password:String) {
        let params = ["username":username,"password":password] as [String:Any]
        Alamofire.request(API_HOST+"/auth/login",method:.post,parameters:params).responseData
            { response in switch response.result {
            case .success(let data):
                switch response.response?.statusCode ?? -1 {
                case 200:
                    self.didLogin(userData: data)
                case 401:
                    Helper.showAlert(viewController: self, title: "Oops", message: "Username or Password Incorrect")
                default:
                    Helper.showAlert(viewController: self, title: "Oops", message: "Unexpected Error")
                }
            case .failure(let error):
                Helper.showAlert(viewController: self,title: "Oops!",message: error.localizedDescription)
                }
        }
    }
    
    /*User login was successful
     - we segue to inbox and initialize User.current*/
    func didLogin(userData:Data) {
        do {
            //decode data into user object
            User.current = try JSONDecoder().decode(User.self, from: userData)
            usernameTextField.text = ""
            passwordTextField.text = ""
            self.view.endEditing(false)
            self.performSegue(withIdentifier: "loginToInbox", sender: nil)
        } catch {
            Helper.showAlert(viewController: self,title: "Oops!",message: error.localizedDescription)
        }
    }
    
    /*Segue from Login to Signup*/
    @IBAction func goToSignUp(sender:UIButton) {
        self.performSegue(withIdentifier: "loginToSignup", sender: nil)
    }
}
