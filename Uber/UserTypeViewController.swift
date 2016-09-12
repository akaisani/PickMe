//
//  UserTypeViewController.swift
//  Uber
//
//  Created by Abid Amirali on 7/14/16.
//  Copyright © 2016 Abid Amirali. All rights reserved.
//

import UIKit
import Firebase
import JWAnimatedImage

var typeSelectuserImageURL: String = ""
var typeSelectUserName: String = ""
class UserTypeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var bgImageView: UIImageView!

    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var userTypeSwitch: UISwitch!
    @IBOutlet weak var RiderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var whoAreYouLabel: UILabel!
    var didPickImage = false
    let uid: String = (FIRAuth.auth()?.currentUser?.uid)!
    let databaseRef = FIRDatabase.database().reference().child("users")
    let storageRef = FIRStorage.storage().reference().child("userImages")
    var activityIndicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        stopSpinner()
        startSpinner()
        userName.delegate = self
        if (typeSelectuserImageURL.characters.count == 0) {
            let imageTapGestureReconsgier = UITapGestureRecognizer(target: self, action: Selector("showImagePickingOptoins"))
            userImage.addGestureRecognizer(imageTapGestureReconsgier)
            userImage.userInteractionEnabled = true
        } else {
            userName.text = typeSelectUserName
            userName.userInteractionEnabled = false
//            userName.minimumFontSize = 16.0
        }
        userImage.image = UIImage(named: "placeholder.png")
        userImage.alpha = 0
        continueButton.alpha = 0
        userTypeSwitch.alpha = 0
        RiderLabel.alpha = 0
        driverLabel.alpha = 0
        whoAreYouLabel.alpha = 0
        // Do any additional setup after loading the view.
        dispatch_async(dispatch_get_main_queue()) {
            let url = NSBundle.mainBundle().URLForResource("bg4", withExtension: "gif")
            let data = NSData(contentsOfURL: url!)
            let image = UIImage()
            image.AddGifFromData(data!)
            let jwManager = JWAnimationManager(memoryLimit: 20)
            self.bgImageView.SetGifImage(image, manager: jwManager)
            self.stopSpinner()
        }
        if (typeSelectuserImageURL.characters.count > 0) {
            let url = NSURL(string: typeSelectuserImageURL)
            let data = NSData(contentsOfURL: url!)
            let image = UIImage(data: data!)
            userImage.image = image!
        }
        UIView.animateWithDuration(0.8) {
            self.userImage.alpha = 1
            self.continueButton.alpha = 1
            self.userTypeSwitch.alpha = 1
            self.RiderLabel.alpha = 1
            self.driverLabel.alpha = 1
            self.whoAreYouLabel.alpha = 1
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(animated: Bool) {

    }

    func showImagePickingOptoins() {
        print("in picking options")
        let options = UIAlertController(title: "Image Picker", message: "Pick image from:", preferredStyle: .ActionSheet)
        options.addAction(UIAlertAction(title: "Camera", style: .Default, handler: { (action) in
            self.loadImageFromCamera()
            }))
        options.addAction(UIAlertAction(title: "Photo Library", style: .Default, handler: { (action) in
            self.loadImageFromLibrary()
            }))
        options.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(options, animated: true, completion: nil)
    }

    func loadImageFromCamera() {
        var imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }

    func loadImageFromLibrary() {
        var imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String: AnyObject]?) {
        self.dismissViewControllerAnimated(true, completion: nil)
        didPickImage = true
        userImage.image = image

    }

    @IBAction func continuePressed(sender: AnyObject) {
        var type = ""
        if (userTypeSwitch.on) {
            type = "Driver"
        } else {
            type = "Rider"
        }

        databaseRef.child("/\(uid)/type").setValue(type)

        if (didPickImage) {
            let userImageFile = UIImagePNGRepresentation(userImage.image!)
            let currUserBucket = storageRef.child("\(uid)")
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/png"
            currUserBucket.putData(userImageFile!, metadata: metadata, completion: { (metadata, error) in
                if (error != nil) {
                    self.displayAlert("Error", message: (error?.localizedDescription)!)
                } else {
                    let imageName = (metadata?.name)!
                    let name = self.userName.text!
                    let userData = [
                        "name": name,
                        "userProfilePicture": "\(imageName).png"
                    ]
                    self.databaseRef.child("/\(self.uid)").updateChildValues(userData)
                    if (type == "Rider") {
                        let typeData = [
                            "driverUID": "",
                            "driverName": ""
                        ]
                        self.databaseRef.child("/\(self.uid)").updateChildValues(typeData)
                    } else {
                        let typeData = [
                            "riderUID": "",
                            "riderName": ""
                        ]
                        self.databaseRef.child("/\(self.uid)").updateChildValues(typeData)
                    }
                }
            })
        }
        if (type == "Rider") {
            self.performSegueWithIdentifier("toRiderViewFromSignUp", sender: self)
        } else {
            // segue to driver view
            self.performSegueWithIdentifier("toDriverViewFromSignUp", sender: self)
        }

    }

    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func startSpinner() {
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0,0,50,50))
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        activityIndicator.transform = CGAffineTransformMakeScale(1.5, 1.5)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    func stopSpinner() {
        activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
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
