//
//  ViewController.swift
//  Givnite
//
//  Created by Danny Tan  on 7/2/16.
//  Copyright © 2016 Givnite. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseAuth




class LoginViewController: UIViewController {


    @IBOutlet weak var facebookLoginButton: ZFRippleButton!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        self.facebookLogin()
     
    }
    
    @IBAction func loginButtonTapped(sender: AnyObject) {
        loginButtonClicked()
    }
    
    func facebookLogin(){
        // Handle clicks on the button
        
        facebookLoginButton.addTarget(self, action: #selector(loginButtonClicked), forControlEvents: .TouchDown)
    }
    
    // Once the button is clicked, show the login dialog
    func loginButtonClicked() {
        let login: FBSDKLoginManager = FBSDKLoginManager()
        login.logInWithReadPermissions(["public_profile", "email"], fromViewController:self, handler: { (result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
            if error != nil {
                print("Process error")
                print(error)
            }
            else if result.isCancelled {
                print("Cancelled")
            }
            else {
                print("Logged in")
                self.firebaseLogin()
                //goes to next view controller
                let nextViewController = self.storyboard!.instantiateViewControllerWithIdentifier("school_name")
                self.presentViewController(nextViewController, animated: true, completion: nil)
            }
        })
    }
    
    //logins into firebase
    func firebaseLogin(){
        let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
        FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
            print ("User logged into Firebase")
        }
        
    }
    
    
}





