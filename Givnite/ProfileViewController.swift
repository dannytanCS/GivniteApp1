//
//  ProfileViewController.swift
//  Givnite
//
//  Created by Danny Tan  on 7/3/16.
//  Copyright © 2016 Givnite. All rights reserved.
//



import UIKit
import FBSDKCoreKit
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase


class ProfileViewController: UIViewController, UITextViewDelegate,UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var profilePicture: UIImageView!
    
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var schoolNameLabel: UILabel!
    
    
    @IBOutlet weak var graduationYearLabel: UILabel!
    
    
    @IBOutlet weak var majorLabel: UILabel!
    
    @IBOutlet weak var bioTextView: UITextView!
    
    let storageRef = FIRStorage.storage().referenceForURL("gs://givniteapp.appspot.com")

    let dataRef = FIRDatabase.database().referenceFromURL("https://givniteapp.firebaseio.com/")
    let user = FIRAuth.auth()!.currentUser

    
    var imageNameArray = [String]()
    
    var imageArray = [UIImage]()
    
    var userID: String?
    
    var firstTimeUse: Bool = true
    
    
    let screenSize = UIScreen.mainScreen().bounds

    @IBOutlet weak var secondView: UIView!
    
    override func viewDidLoad() {
        
        
        if firstTimeUse {
            userID = self.user?.uid
            storesInfoFromFB()
        }
        
    
        super.viewDidLoad()
        self.view.sendSubviewToBack(secondView)
        self.view.bringSubviewToFront(name)
        self.view.bringSubviewToFront(addButton)
        self.view.bringSubviewToFront(changeBioButton)
        self.view.bringSubviewToFront(doneButton)
        self.bioTextView.delegate = self
        secondView.hidden = true
        self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width/2
        self.profilePicture.clipsToBounds = true
        self.profilePicture.layer.borderWidth = 2
        self.profilePicture.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0).CGColor
    
        
        loadImages()
        getProfileImage()
        schoolInfo()
        
        
        self.bioTextView.editable = false
        self.doneButton.hidden = true
        
        
        
    
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        secondView.addGestureRecognizer(tap)
        
        
        var swipeRight = UISwipeGestureRecognizer(target: self, action: "swiped:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        
    }
    
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    //layout for cell size

    func collectionView(collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.size.width - 3)/3, height: (collectionView.frame.size.width - 3)/3 )
    }

    
    
    
    //loads images from cache or firebase
    
    func loadImages() {
        dataRef.child("user").child(userID!).observeSingleEventOfType(.Value, withBlock: { (snapshot)
            in
            
        
            //adds image name from firebase database to an array
            
            if let itemDictionary = snapshot.value!["items"] as? NSDictionary {
            
                let sortKeys = itemDictionary.keysSortedByValueUsingComparator {
                    (obj1: AnyObject!, obj2: AnyObject!) -> NSComparisonResult in
                    let x = obj1 as! NSNumber
                    let y = obj2 as! NSNumber
                    return y.compare(x)
                }
            
                for key in sortKeys {
                    self.imageNameArray.append("\(key)")
                }
            
                if (self.imageArray.count == 0){
                    for index in 0..<self.imageNameArray.count {
                        self.imageArray.append(UIImage(named: "Examples")!)
                    }
                }
            
                dispatch_async(dispatch_get_main_queue(),{
                    self.collectionView.reloadData()
                })
            }
        })
    
    }
    
    //sets up the collection view
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageNameArray.count
    }
    
    //hides keyboard when return is pressed for text view
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            changeBioButton.hidden = false
            doneButton.hidden = true
            self.bioTextView.editable = false
            self.dataRef.child("user").child(userID!).child("bio").setValue(bioTextView.text)
            self.secondView.hidden = true
            return false
        }
        return true
    }

    
    
    var imageCache = [String:UIImage] ()
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as!
        CollectionViewCell
        
        
        if let imageName = self.imageNameArray[indexPath.row] as? String {
            var num = indexPath.row
            cell.imageView.image = nil
            
        
            if let image = imageCache[imageName]  {
                cell.imageView.image = image
            }
        
            else {

                var profilePicRef = storageRef.child(imageName).child("\(imageName).jpg")
                //sets the image on profile
                profilePicRef.dataWithMaxSize(1 * 1024 * 1024) { (data, error) -> Void in
                    if (error != nil) {
                        print ("File does not exist")
                        return
                    } else {
                        if (data != nil){
                            let imageToCache = UIImage(data:data!)
                            self.imageCache[imageName] = imageToCache
                            //update to the correct cell
                            if (indexPath.row == num){
                                dispatch_async(dispatch_get_main_queue(),{
                                    cell.imageView.image = imageToCache
                                    self.imageArray[indexPath.row] = imageToCache!

                                })
                            }
                        }
                    }
                }.resume()
            }
        }
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("showImage", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showImage" {
            
            let indexPaths = self.collectionView!.indexPathsForSelectedItems()!
            let indexPath = indexPaths[0] as NSIndexPath
            let destinationVC = segue.destinationViewController as! ItemViewController
            
            
            destinationVC.image = self.imageArray[indexPath.row]
            
            destinationVC.imageName  = self.imageNameArray[indexPath.row]
            
            destinationVC.userName = self.name.text!
        }
    }
    
    
    var profileImageCache = NSCache()
    
    //gets and stores info from facebook
    func storesInfoFromFB(){
        
        let profilePicRef = storageRef.child(userID!+"/profile_pic.jpg")
        FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "name, id, gender, email, picture.type(large)"]).startWithCompletionHandler{(connection, result, error) -> Void in
            
            if error != nil {
                print (error)
                return
            }
            
            if let name = result ["name"] as? String {
                self.dataRef.child("user").child(self.userID!).child("name").setValue(name)
                
            }
            
            if let profileID = result ["id"] as? String {
                self.dataRef.child("user").child(self.userID!).child("ID").setValue(profileID)
            }
            
            if let gender = result ["gender"] as? String {
                self.dataRef.child("user").child(self.userID!).child("gender").setValue(gender)
            }
            
            if let picture = result["picture"] as? NSDictionary, data = picture["data"] as? NSDictionary,url = data["url"] as? String {
            
                if let imageData = NSData(contentsOfURL: NSURL (string:url)!) {
                    let uploadTask = profilePicRef.putData(imageData, metadata: nil){
                        metadata, error in
                            
                        if(error == nil) {
                            let downloadURL = metadata!.downloadURL
                        }
                        else{
                            print ("Error in downloading image")
                        }
                    }
                }
            }
        }
    }
    
    
    //swipe to the right for marketplace
    
    
    func swiped(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            switch swipeGesture.direction {
                
            case UISwipeGestureRecognizerDirection.Right :
                print("User swiped right")
                
                let marketViewController: UIViewController = self.storyboard!.instantiateViewControllerWithIdentifier("marketplace")
                let transition = CATransition()
                transition.duration = 0.3
                transition.type = kCATransitionPush
                transition.subtype = kCATransitionFromLeft
                view.window!.layer.addAnimation(transition, forKey: kCATransition)
                self.presentViewController(marketViewController, animated: false, completion: nil)
                
            default:
                break //stops the code/codes nothing.
            
            }
        }
    }
    
    func schoolInfo() {
        dataRef.child("user").child(userID!).observeSingleEventOfType(.Value, withBlock: { (snapshot)
            in
            
         
            // Get user value
            if let name = snapshot.value!["name"] as? String {
                self.name.text = name
            }
            if let school = snapshot.value!["school"] as? String {
                self.schoolNameLabel.text = school
            }
            if let graduationYear = snapshot.value!["graduation year"] as? String {
                self.graduationYearLabel.text = "Class of " + graduationYear
            }
            if let major = snapshot.value!["major"] as? String {
                self.majorLabel.text = major
            }
            
            if let bioDescription = snapshot.value!["bio"] as? String {
                self.bioTextView.text = bioDescription
            }
        })
    }
    
    
    func getProfileImage() {
        
        let profilePicRef = storageRef.child(userID!+"/profile_pic.jpg")
        profilePicRef.dataWithMaxSize(1 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                // Uh-oh, an error occurred!
            } else {
               self.profilePicture.image = UIImage(data: data!)
            }
        }
    }
    
    
    //checks user's bio
    
    @IBOutlet weak var changeBioButton: UIButton!
    
    @IBAction func changeBio(sender: AnyObject) {
        changeBioButton.hidden = true
        doneButton.hidden = false
        self.bioTextView.editable = true
        self.secondView.hidden = false
    }

    //done editing bio
    
    
    @IBOutlet weak var doneButton: UIButton!
    
    
    @IBAction func doneButtonClicked(sender: AnyObject) {
        changeBioButton.hidden = false
        doneButton.hidden = true
        self.bioTextView.editable = false
        self.dataRef.child("user").child(user!.uid).child("bio").setValue(bioTextView.text)
        self.secondView.hidden = true
        }

    
}
