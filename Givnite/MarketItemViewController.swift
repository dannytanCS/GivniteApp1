//
//  MarketItemViewController.swift
//  Givnite
//
//  Created by Danny Tan on 7/17/16.
//  Copyright © 2016 Givnite. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class MarketItemViewController: UIViewController {

    @IBOutlet weak var bookDescription: UITextView!
    @IBOutlet weak var bookName: UILabel!
    @IBOutlet weak var bookPrice: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var sellerName: UILabel!
    
    let storageRef = FIRStorage.storage().referenceForURL("gs://givniteapp.appspot.com")
    let databaseRef = FIRDatabase.database().referenceFromURL("https://givniteapp.firebaseio.com/")
    let user = FIRAuth.auth()!.currentUser

    
    var image = UIImage()
    
    var imageArray = [UIImage]()
    var imageNameArray = [String]()
    var userArray = [String]()
    var imageDict = [UIImage:AnyObject]()
    
    
    var imageName:String?
    var price: String?
    var name: String?
    var userID: String?
    var bkdescription: String?
    var firstTimeUsed:Bool?
    
    
    var imageList = [UIImage]()
    
    var imageNameList = [String]()
    
    var imageIndex: Int = 0
    
    var maxImages: Int = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.image = self.image
        self.imageView.layer.cornerRadius = 10
        self.imageView.clipsToBounds = true
        //self.imageView.layer.borderWidth = 2
        
        //self.imageView.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0).CGColor

        self.bookName.text = self.name
        self.bookPrice.text = self.price
        self.bookDescription.text = self.bkdescription
        self.bookDescription.editable = false
        
        
        databaseRef.child("user").child(userID!).child("name").observeSingleEventOfType(.Value, withBlock: { (snapshot)
            in
            
            if let userName = snapshot.value! as? String {
                self.sellerName.text = userName
            }
        })
    
        
        databaseRef.child("marketplace").child(imageName!).observeSingleEventOfType(.Value, withBlock: { (snapshot)
            in
            
            if let bookDescription = snapshot.value!["description"] as? String {
                self.bookDescription.text = bookDescription
            }
            
            
            let itemDictionary = snapshot.value!["images"] as! NSDictionary

            let sortKeys = itemDictionary.keysSortedByValueUsingComparator {
                (obj1: AnyObject!, obj2: AnyObject!) -> NSComparisonResult in
                let x = obj1 as! NSNumber
                let y = obj2 as! NSNumber
                return x.compare(y)
            }
                
                
            for key in sortKeys {
                self.imageNameList.append("\(key)")
            }
                
            for image in itemDictionary {
                
                let imagename = image.key
                
                let profilePicRef = self.storageRef.child(self.imageName!).child("\(imagename).jpg")
                //sets the image on profile
                profilePicRef.dataWithMaxSize(1 * 1024 * 1024) { (data, error) -> Void in
                    if (error != nil) {
                        print ("File does not exist")
                        return
                    } else {
                        if (data != nil){
                            
                            self.imageDict[UIImage(data:data!)!] = image.value
                        }
                    }
                    
                    //change image dictionary into sorted image array
                    var sortedTuples = self.imageDict.sort({ (a, b) in (a.1 as! Double) < (b.1 as! Double) })
                    
                    for tuple in sortedTuples {
                        if sortedTuples.count == self.imageNameList.count {
                            self.imageList.append(tuple.0)
                        }
                    }
                    
                    self.maxImages  = self.imageList.count - 1
                    self.pageControl.currentPage = 0
                    self.pageControl.numberOfPages = self.maxImages + 1
                }
            }
        })
    
        var swipeRight = UISwipeGestureRecognizer(target: self, action: "swiped:") // put : at the end of method name
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        
        var swipeLeft = UISwipeGestureRecognizer(target: self, action: "swiped:") // put : at the end of method name
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
    }

    
    func swiped(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            switch swipeGesture.direction {
                
            case UISwipeGestureRecognizerDirection.Right :
                
                
                // decrease index first
                
                imageIndex -= 1
                self.pageControl.currentPage -= 1
                
                // check if index is in range
                
                
                if imageIndex < 0 {
                    
                    imageIndex = maxImages
                    self.pageControl.currentPage = maxImages + 1
                    
                }
                
                imageView.image =  imageList[imageIndex]
                
            case UISwipeGestureRecognizerDirection.Left:
            
                
                // increase index first
                
                imageIndex += 1
                
                self.pageControl.currentPage += 1
                
                // check if index is in range
                
                
                if imageIndex > maxImages {
                    
                    imageIndex = 0
                    self.pageControl.currentPage = 0
                    
                }
                
                
                
                
                imageView.image = imageList[imageIndex]
                
                
                
                
            default:
                break //stops the code/codes nothing.
                
                
            }
            
        }
        
        
    }
    
    @IBAction func backButton(sender: AnyObject) {
        self.performSegueWithIdentifier("goBack", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "goBack" {
            let destinationVC = segue.destinationViewController as! MarketplaceViewController
            
            destinationVC.firstTimeUse = self.firstTimeUsed!
          
            
            destinationVC.imageNameArray = self.imageNameArray
            
            destinationVC.userArray = self.userArray
            

        }
        
    }
    

    
}





