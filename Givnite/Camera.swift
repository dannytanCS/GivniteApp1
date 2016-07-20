//
//  Camera.swift
//  Givnite
//
//  Created by Danny Tan on 7/8/16.
//  Copyright © 2016 Givnite. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class Camera: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    var captureSession: AVCaptureSession?
    var stillImageOutput : AVCaptureStillImageOutput?
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    var imageTaken = UIImage()
    
    var nameOfImage = ""
    
    var imageURL = ""

    
    @IBOutlet weak var photoLibraryButton: UIButton!
    
    //goes to library
    @IBAction func photoLibrary(sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .PhotoLibrary
        presentViewController(picker,animated: true, completion:nil)
    }
    
  
    //takes picture 
    
    
    @IBAction func takePicture(sender: AnyObject) {
        if let videoConnection = stillImageOutput?.connectionWithMediaType(AVMediaTypeVideo){
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {
                (sampleBuffer, error) in
                
                if sampleBuffer != nil {
                    var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    
                    var dataProvider = CGDataProviderCreateWithCFData(imageData)
                    var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                    
                    
                    //images we want to store
                    var image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: .Right)
                    
                    self.imageTaken = image
                    self.addImageToFirebase(image)
                    
                }
            })
        }
    }

    @IBOutlet weak var imageView: UIImageView!
    
    //done picking from library
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.imageTaken = image!
        addImageToFirebase(image!)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    //adds image to firebase
    func addImageToFirebase(image: UIImage)
    {
        let user = FIRAuth.auth()?.currentUser
        let storageRef = FIRStorage.storage().referenceForURL("gs://givniteapp.appspot.com")
        let databaseRef = FIRDatabase.database().referenceFromURL("https://givniteapp.firebaseio.com/")
        
        let imageName = NSUUID().UUIDString
        self.nameOfImage = imageName
        
        let profilePicRef = storageRef.child(imageName).child("\(imageName).jpg")

        databaseRef.child("user").child("\(user!.uid)/items/\(imageName)").setValue(FIRServerValue.timestamp())
        databaseRef.child("marketplace").child(imageName).child("images").child(imageName).setValue(FIRServerValue.timestamp())
        databaseRef.child("marketplace").child(imageName).child("time").setValue(FIRServerValue.timestamp())
        databaseRef.child("marketplace").child(imageName).child("user").setValue(user!.uid)
        self.captureSession?.stopRunning()
        if let uploadData = UIImageJPEGRepresentation(image, 0){
            profilePicRef.putData(uploadData, metadata: nil, completion: { (meta, error) in
                if error != nil {
                    print (error)
                }
                else{
                    self.performSegueWithIdentifier("addDescription", sender: self)
                }
            })
        }
    }
    
    
    
    
    
    
    @IBAction func doneButtonClicked(sender: AnyObject) {
    
    }
    
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addDescription" {
            let destinationVC = segue.destinationViewController as! DescriptionViewController
            
            destinationVC.image = self.imageTaken
            destinationVC.imageName = self.nameOfImage
        }
    }

    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
     //   previewLayer!.frame  = imageView.bounds
        
    }
    
    //shows camera
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if UIImagePickerController.isSourceTypeAvailable(.Camera){
            captureSession = AVCaptureSession()
            captureSession?.sessionPreset = AVCaptureSessionPreset1920x1080
            var backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
            
            var error: NSError?
            var input = AVCaptureDeviceInput()
            do {
                input = try AVCaptureDeviceInput(device: backCamera)
                if error == nil && (captureSession?.canAddInput(input))!{
                    captureSession?.addInput(input)
                    
                    stillImageOutput = AVCaptureStillImageOutput()
                    stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                    
                    if captureSession!.canAddOutput(stillImageOutput){
                        captureSession?.addOutput(stillImageOutput)
                        
                        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                        previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
                        imageView.layer.addSublayer(previewLayer!)
                        captureSession?.startRunning()
                    }
                }
                
            } catch {
                print (error)
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