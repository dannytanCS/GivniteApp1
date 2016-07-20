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


class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
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
    
    
    let screenSize = UIScreen.mainScreen().bounds

    override func viewDidLoad() {
    
        super.viewDidLoad()
        self.view.bringSubviewToFront(addButton)
        self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width/2
        self.profilePicture.clipsToBounds = true
        self.profilePicture.layer.borderWidth = 2
        self.profilePicture.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0).CGColor
        loadImages()
        schoolInfo()
        self.bioTextView.editable = false
        self.doneButton.hidden = true
        
        var swipeRight = UISwipeGestureRecognizer(target: self, action: "swiped:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        
    }
    
    //layout for cell size

    func collectionView(collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.size.width - 3)/3, height: (collectionView.frame.size.width - 3)/3 )
    }

    
    
    
    //loads images from cache or firebase
    
    func loadImages() {
        dataRef.child("user").child("\(user!.uid)").observeSingleEventOfType(.Value, withBlock: { (snapshot)
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
            
            
            
            destinationVC.imageArray = self.imageArray
            destinationVC.imageCache = self.imageCache
            destinationVC.image = self.imageArray[indexPath.row]
            
            destinationVC.imageName  = self.imageNameArray[indexPath.row]
        }
    }
    
    
    var profileImageCache = NSCache()
    
    //gets and stores info from facebook
    func storesInfoFromFB(){
        let profilePicRef = storageRef.child(user!.uid+"/profile_pic.jpg")
        
        
        FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "name, id, gender, email, picture.type(large)"]).startWithCompletionHandler{(connection, result, error) -> Void in
            
            if error != nil {
                print (error)
                return
            }
            
            if let name = result ["name"] as? String {
                self.dataRef.child("user").child("\(self.user!.uid)/name").setValue(name)
                self.name.text = name
            }
            
            if let profileID = result ["id"] as? String {
                self.dataRef.child("user").child("\(self.user!.uid)/ID").setValue(profileID)
            }
            
            if let gender = result ["gender"] as? String {
                self.dataRef.child("user").child("\(self.user!.uid)/gender").setValue(gender)
            }
            
            if let picture = result["picture"] as? NSDictionary, data = picture["data"] as? NSDictionary,url = data["url"] as? String {
                
                //stores as cache
                
                if let image = self.profileImageCache.objectForKey(self.user!.uid) as? UIImage {
                    self.profilePicture.image = image
                }
                
                
                //downloads image from FB
                if let imageData = NSData(contentsOfURL: NSURL (string:url)!) {
                    let uploadTask = profilePicRef.putData(imageData, metadata: nil){
                        metadata, error in
                        if(error == nil)
                        {
                            let downloadURL = metadata!.downloadURL
                            
                            // stores the firebase url into database
                            profilePicRef.downloadURLWithCompletion { (URL, error) -> Void in
                                if (error != nil) {
                                    // Handle any errors
                                }
                                else {
                                    self.dataRef.child("user").child("\(self.user!.uid)/picture").setValue("\(URL!)")
                                }
                            }
                            
                            //sets the image on profile
                            profilePicRef.dataWithMaxSize(1 * 1024 * 1024) { (data, error) -> Void in
                                if (error != nil) {
                                    print ("File does not exist")
                                } else {
                                    if (data != nil){
                                        self.profilePicture.image = UIImage(data:data!)
                                        self.profileImageCache.setObject(UIImage(data:data!)!, forKey: self.user!.uid)
                                    }
                                }
                            }
                            
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
        storesInfoFromFB()
        dataRef.child("user").child("\(user!.uid)").observeSingleEventOfType(.Value, withBlock: { (snapshot)
            in
            
            if ("\(snapshot.value!["school"])" == "nil" || "\(snapshot.value!["graduation year"])" == "nil" || "\(snapshot.value!["major"])" == "nil") {
                return
            }
            else {
                // Get user value
                let school = snapshot.value!["school"] as! String
                self.schoolNameLabel.text = school
                let graduationYear = snapshot.value!["graduation year"] as! String
                self.graduationYearLabel.text = "Class of " + graduationYear
                let major = snapshot.value!["major"] as! String
                self.majorLabel.text = major
            }
        })
    }
    
    
    //checks user's bio
    
    @IBOutlet weak var changeBioButton: UIButton!
    
    @IBAction func changeBio(sender: AnyObject) {
            changeBioButton.hidden = true
            doneButton.hidden = false
            self.bioTextView.editable = true
    }

    //done editing bio
    
    
    @IBOutlet weak var doneButton: UIButton!
    
    
    @IBAction func doneButtonClicked(sender: AnyObject) {
        changeBioButton.hidden = false
        doneButton.hidden = true
        self.bioTextView.editable = false
        self.dataRef.child("user").child(user!.uid).child("bio").setValue(bioTextView.text)
    }
    

    
    

    
}
