//
//  ViewController.swift
//  Givnite
//
//  Created by Danny Tan on 7/19/16.
//  Copyright © 2016 Givnite. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FBSDKCoreKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        loadingIndicator.startAnimating()
        
        //sign out
        try! FIRAuth.auth()!.signOut()
        FBSDKAccessToken.setCurrentAccessToken(nil)
        
        
        super.viewDidLoad()
        let dataRef = FIRDatabase.database().referenceFromURL("https://givniteapp.firebaseio.com/")
        
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                dataRef.child("user").child(user.uid).child("graduation year").observeSingleEventOfType(.Value, withBlock: { (snapshot)
                    in
                    
                    if let login = snapshot.value! as? NSString {
                        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let profileViewController: UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("profile")
                        self.presentViewController(profileViewController, animated: false, completion: nil)
                        self.loadingIndicator.stopAnimating()
                    }
                    
                    else {
                        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let loginViewController: UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("login")
                        self.presentViewController(loginViewController, animated: false, completion: nil)
                        self.loadingIndicator.stopAnimating()
                    }

                })
            }
                
            else {
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let loginViewController: UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("login")
                    self.presentViewController(loginViewController, animated: false, completion: nil)
                    self.loadingIndicator.stopAnimating()
            }

        }

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
