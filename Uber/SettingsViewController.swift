
//
//  SettingsViewController.swift
//  Uber
//
//  Created by Abid Amirali on 7/23/16.
//  Copyright © 2016 Abid Amirali. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase
import JWAnimatedImage

class SettingsViewController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userTypeSwitch: UISwitch!
    @IBOutlet weak var fbPlaceHolderLabel: UILabel!
    @IBOutlet weak var uberSignOutButton: UIButton!
    var imageString = ""
    var userName: String!
    var isFbLogin: Bool!
    var isRider: Bool!
    let currUID = (FIRAuth.auth()?.currentUser?.uid)!
    let databaseRef = FIRDatabase.database().reference().child("users")
    var activityIndicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        startSpinner()
        userNameLabel.text = userName
        self.navigationController?.navigationBarHidden = true
        dispatch_async(dispatch_get_main_queue()) {
            let url = NSBundle.mainBundle().URLForResource("bg4", withExtension: "gif")
            let data = NSData(contentsOfURL: url!)
            let image = UIImage()
            image.AddGifFromData(data!)
            let jwManager = JWAnimationManager(memoryLimit: 20)
            self.bgImageView.SetGifImage(image, manager: jwManager)
        }
        let fbLoginButton = FBSDKLoginButton()
        fbLoginButton.readPermissions = ["public_profile", "email", "user_friends"]
        fbLoginButton.frame.size.width = uberSignOutButton.bounds.width
        fbLoginButton.frame.size.height = uberSignOutButton.bounds.height
        fbLoginButton.center = fbPlaceHolderLabel.center
        self.view.addSubview(fbLoginButton)
        fbLoginButton.delegate = self
        uberSignOutButton.layer.cornerRadius = 5
        uberSignOutButton.layer.borderWidth = 2
        uberSignOutButton.layer.borderColor = UIColor.whiteColor().CGColor
        userImageView.layer.cornerRadius = 5
        userImageView.layer.borderWidth = 2
        userImageView.layer.borderColor = UIColor.whiteColor().CGColor
        userImageView.backgroundColor = UIColor.lightGrayColor()
//        print(userImage)
        if (isFbLogin == true) {
            uberSignOutButton.alpha = 0
            uberSignOutButton.userInteractionEnabled = false
        } else {
            fbLoginButton.userInteractionEnabled = false
            fbLoginButton.alpha = 0
        }
        getUserImage()
        if (!isRider) {
            userTypeSwitch.on = true
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func uberSignOutPressed(sender: AnyObject) {
        uberSignOut()
    }

    @IBAction func backToVIew(sender: AnyObject) {
        var type = ""
        if (userTypeSwitch.on) {
            type = "Driver"
            isRider = false
        } else {
            type = "Rider"
            isRider = true
        }

        let updatedData = [
            "type": type
        ]

        databaseRef.child(currUID).updateChildValues(updatedData)

        if (isRider == true) {
            self.performSegueWithIdentifier("settingsToRider", sender: self)
        } else {
            self.performSegueWithIdentifier("settingsToDriver", sender: self)
        }
    }

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print(error)
        displayAlert("Error", message: error.localizedDescription)
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("fb logout")
        uberSignOut()
    }

    func uberSignOut() {
        if (FIRAuth.auth()?.currentUser != nil) {
            do {
                try FIRAuth.auth()?.signOut()
//                let vc = self.storyboard?.instantiateViewControllerWithIdentifier("loginScreen")
//                self.presentViewController(vc!, animated: true, completion: nil)
                self.performSegueWithIdentifier("userDidSignOut", sender: self)
            } catch {
                // code to display error
                displayAlert("Error", message: "Sorry but we couldn't sign you out.\nPlease try again.")
            }
        }
    }

    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
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

    func getUserImage() {
        if (!isFbLogin) {
            let newDir = NSURL(fileURLWithPath: NSTemporaryDirectory())
            let fileDir = newDir.URLByAppendingPathComponent("image").URLByAppendingPathExtension("png")
            // print("\n\n\n PRINTING DIR\n\(fileDir)\n\n\n")
            let storageRef = FIRStorage.storage().referenceForURL("gs://uber-8fbec.appspot.com")
            let fileDatabaseRef = storageRef.child("userImages").child("\(currUID)")
            fileDatabaseRef.writeToFile(fileDir, completion: { (url, error) in
                if (error != nil) {
                    print("\n\n\n", error!)
                    self.displayAlert("error", message: "Sorry we could not get your image.")
                } else {
                    print(url)
                    let data = NSData(contentsOfURL: url!)
                    let image = UIImage(data: data!)
                    self.userImageView.image = image
                    self.stopSpinner()
                }
            })
        } else {
            // getting UserImage
            let url = NSURL(string: imageString)
            let data = NSData(contentsOfURL: url!)
            let image = UIImage(data: data!)
            userImageView.image = image
            stopSpinner()
        }
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
