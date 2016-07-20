//
//  DescriptionViewController.swift
//  Givnite
//
//  Created by Danny Tan on 7/9/16.
//  Copyright © 2016 Givnite. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class DescriptionViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var bookName: UITextField!
    
    
    @IBOutlet weak var bookPrice: UITextField!
    
    @IBOutlet weak var bookDescription: UITextView!
    
    
    var image = UIImage()
    var imageName = ""


    var imageList = [UIImage]()
    
    var imageNameList = [String]()
    
    var imageIndex: Int = 0
    
    var maxImages: Int = 0
    
    var imageDict = [UIImage:AnyObject]()

    
    
    let databaseRef = FIRDatabase.database().referenceFromURL("https://givniteapp.firebaseio.com/")
    
    let storageRef = FIRStorage.storage().referenceForURL("gs://givniteapp.appspot.com")
    let user = FIRAuth.auth()!.currentUser

    @IBOutlet weak var pageControl: UIPageControl!
    
    
    @IBOutlet weak var label: UILabel!
    
    @IBAction func doneButtonClicked(sender: AnyObject) {
        databaseRef.child("marketplace").child(imageName).child("price").setValue(bookPrice.text)
        databaseRef.child("marketplace").child(imageName).child("book name").setValue(bookName.text)
        databaseRef.child("marketplace").child(imageName).child("description").setValue(bookDescription.text)
    }
    
    
    //adds additional picture
    
    @IBAction func cameraButton(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Upload from Photo Library", style:.Default, handler: { action in
            
            
            let picker = UIImagePickerController()
            picker.sourceType = .PhotoLibrary
            picker.delegate = self
            self.presentViewController(picker,animated: true, completion:nil)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Take a photo", style:.Default, handler: { action in
            
            
            let picker = UIImagePickerController()
            picker.sourceType = .Camera
            picker.delegate = self
            self.presentViewController(picker,animated: true, completion:nil)
            
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style:.Cancel, handler: { action in
            print("No photo added")
            
        }))
        
        
        self.presentViewController(actionSheet, animated: true, completion: nil)

    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        let imageRandomName = NSUUID().UUIDString
        
        var picRef = storageRef.child(imageName).child("\(imageRandomName).jpg")
        var imageData: NSData = UIImageJPEGRepresentation(image!, 0)!
        let uploadTask = picRef.putData(imageData, metadata: nil) { metadata, error in
            if (error != nil) {
                // Uh-oh, an error occurred!
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL
                self.databaseRef.child("marketplace").child(self.imageName).child("images").child(imageRandomName).setValue(FIRServerValue.timestamp())
                self.dismissViewControllerAnimated(true, completion: nil)
                self.imageList.append(image!)
                self.maxImages += 1
                self.pageControl.numberOfPages += 1
                self.loadsImages()
            }
        }

    }

    
    
    //deletes the item
    
    @IBAction func deleteItem(sender: AnyObject) {
    
        let alert = UIAlertController(title: "Delete this photo", message: "Deleting this photo will also delete all of its data", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
            print("Click of cancel button")
        }))
        
        alert.addAction(UIAlertAction(title: "Delete", style:.Default, handler: { action in
            self.storageRef.child(self.imageName).deleteWithCompletion { (error) -> Void in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                } else {
                    // File deleted successfully
                    print("file deleted")
                }
            }
            
            self.databaseRef.child("user").child(self.user!.uid).child("items").child(self.imageName).removeValue()
            
             self.performSegueWithIdentifier("mainMenu", sender: self)
            
        }))
        
        
        
        alert.view.tintColor = UIColor(red: 0.984314, green: 0.211765, blue: 0.266667, alpha: 1)
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        
    }
    
    
    
    
    
    //changes the keyboard
    
    
    func keyboardWillHide(sender: NSNotification) {
        let userInfo: [NSObject : AnyObject] = sender.userInfo!
        let keyboardSize: CGSize = userInfo[UIKeyboardFrameBeginUserInfoKey]!.CGRectValue.size
        self.view.frame.origin.y += keyboardSize.height
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: self.view.window)
    }
    
    //shift the screen when there is a keyboard
    func keyboardWillShow(sender: NSNotification) {
        
        let userInfo: [NSObject : AnyObject] = sender.userInfo!
        
        let keyboardSize: CGSize = userInfo[UIKeyboardFrameBeginUserInfoKey]!.CGRectValue.size
        let offset: CGSize = userInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue.size
        
        if keyboardSize.height == offset.height {
            if self.view.frame.origin.y == 0 {

                    self.view.frame.origin.y -= keyboardSize.height
            }
        } else {
           
                self.view.frame.origin.y += keyboardSize.height - offset.height
        }
    }
    
    //hides keyboard when return is pressed for text field
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if bookName.text != "" && bookPrice.text != "" {
            doneButton.hidden = false
        }
        
        if bookName.text == "" || bookPrice.text == "" {
            doneButton.hidden = true
        }
        return true
    }
    
    
    //hides keyboard when return is pressed for text view

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            if bookName.text != "" && bookPrice.text != "" {
                doneButton.hidden = false
            }
            
            if bookName.text == "" || bookPrice.text == "" {
                doneButton.hidden = true
            }
            return false
        }
        return true
    }

    
    @IBOutlet weak var doneButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = self.image
        self.imageView.layer.cornerRadius = 10
        self.imageView.clipsToBounds = true
        bookName.delegate = self
        bookDescription.delegate = self
        bookPrice.delegate = self
        
        doneButton.hidden = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        
        
        
        
        var swipeRight = UISwipeGestureRecognizer(target: self, action: "swiped:") // put : at the end of method name
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        
        var swipeLeft = UISwipeGestureRecognizer(target: self, action: "swiped:") // put : at the end of method name
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)

        loadsImages()
    }
    
    
    func loadsImages() {
        if imageNameList.count == 0 {
            databaseRef.child("marketplace").child(imageName).child("images").observeSingleEventOfType(.Value, withBlock: { (snapshot)
                in
                
                let itemDictionary = snapshot.value! as! NSDictionary
                
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
                    
                    let profilePicRef = self.storageRef.child(self.imageName).child("\(imagename).jpg")
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
            
        }
        
        
        
        self.imageView.image = self.image

    }
    
    func swiped(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            switch swipeGesture.direction {
                
            case UISwipeGestureRecognizerDirection.Right :
                print("User swiped right")
                
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
                print("User swiped Left")
                
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
    
    
    
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        
        if bookName.text != "" && bookPrice.text != "" {
            doneButton.hidden = false
        }

        if bookName.text == "" || bookPrice.text == "" {
            doneButton.hidden = true
        }
        view.endEditing(true)
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
