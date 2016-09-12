//
//  SignUpViewController.swift
//  PickMe
//
//  Created by Abid Amirali on 7/12/16.
//  Copyright © 2016 Abid Amirali. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import JWAnimatedImage

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, UITextFieldDelegate {

    @IBOutlet weak var fbLoginPlaceholder: UILabel!

    @IBOutlet weak var signUpButton: UIButton!

    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var uberLoginButton: UIButton!
    @IBOutlet weak var wouldSignUpButton: UIButton!

    @IBOutlet weak var signUpPrompt: UILabel!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var userNameField: UITextField!
    var activityIndicator = UIActivityIndicatorView()
    var riderWantsRide = false
    var riderHasRide = false
    let databaseRef = FIRDatabase.database().reference().child("users")

    @IBAction func signUpWithUber(sender: AnyObject) {
        if (hasValidCredentials(userNameField.text!, password: passwordField.text!)) {
            FIRAuth.auth()?.createUserWithEmail(userNameField.text!, password: passwordField.text!, completion: { (user, error) in
                if (error != nil) {
                    self.displayAlert("Error", message: (error?.localizedDescription)!)
                } else {
                    self.loginWithUber(self)
                }
            })
        }
    }

    @IBAction func uberIdOption(sender: AnyObject) {
        UIView.animateWithDuration(0.8) {
            self.orLabel.alpha = 0
            self.uberLoginButton.alpha = 0
            self.uberLoginButton.userInteractionEnabled = false
            self.loginButton.alpha = 0
            self.loginButton.userInteractionEnabled = false
            self.userNameField.alpha = 1
            self.userNameField.userInteractionEnabled = true
            self.passwordField.alpha = 1
            self.passwordField.userInteractionEnabled = true
            self.uberLoginButtonBottom.alpha = 1
            self.uberLoginButtonBottom.userInteractionEnabled = true
            self.wouldSignUpButton.alpha = 1
            self.wouldSignUpButton.userInteractionEnabled = true
            self.signUpPrompt.alpha = 1
        }
    }

    @IBOutlet weak var passwordField: UITextField!
    @IBAction func loginWithUber(sender: AnyObject) {
        print("login pressed")
        if (hasValidCredentials(userNameField.text!, password: passwordField.text!)) {
            FIRAuth.auth()?.signInWithEmail(userNameField.text!, password: passwordField.text!, completion: { (user, error) in
                if (error != nil) {
                    self.displayAlert("Error", message: (error?.localizedDescription)!)
                } else {
                    // code for login
                    let userPath = self.databaseRef.child("\((FIRAuth.auth()?.currentUser?.uid)!)")
                    print(userPath)
                    userPath.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
                        print(snapshot)
                        if (snapshot.exists()) {
                            if let type = snapshot.value?.objectForKey("type") as? String {
                                self.toDesginatedView()
                            } else {
                                let id = (FIRAuth.auth()?.currentUser?.uid)!
                                let userData = [
                                    "email": (user?.email)!,
                                    "uid": (user?.uid)!,
                                    "FBID": id
                                ]
                                self.databaseRef.child("\(id)").setValue(userData)

                                self.toDesginatedView()
                            }
                        } else {
                            let id = (FIRAuth.auth()?.currentUser?.uid)!
                            let userData = [
                                "email": (user?.email)!,
                                "uid": (user?.uid)!,
                                "FBID": id
                            ]
                            self.databaseRef.child("\(id)").setValue(userData)

                            self.toDesginatedView()
                        }
                    })
                }
            })
        }
    }
    var loginButton: FBSDKLoginButton!
    @IBOutlet weak var uberLoginButtonBottom: UIButton!

    @IBAction func wouldSignUP(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()) {
            let url = NSBundle.mainBundle().URLForResource("bg4", withExtension: "gif")!
            let imageData = NSData(contentsOfURL: url)
            let image = UIImage()
            image.AddGifFromData(imageData!)
            let gifManager = JWAnimationManager(memoryLimit: 10)
            self.bgImageView.SetGifImage(image, manager: gifManager)
        }
        UIView.animateWithDuration(0.8) {
            self.uberLoginButtonBottom.alpha = 0
            self.uberLoginButtonBottom.userInteractionEnabled = false
            self.signUpButton.center = self.uberLoginButtonBottom.center
            self.signUpButton.alpha = 1
            self.signUpButton.userInteractionEnabled = true
            self.wouldSignUpButton.alpha = 0
            self.wouldSignUpButton.userInteractionEnabled = false
            self.signUpPrompt.alpha = 0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        userNameField.delegate = self
        passwordField.delegate = self
        // fb login button setup
        loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        loginButton.frame.size.width = uberLoginButton.bounds.width
        loginButton.frame.size.height = uberLoginButton.bounds.height
        loginButton.center = fbLoginPlaceholder.center
        self.view.addSubview(loginButton)
        loginButton.delegate = self
        // uber buttons setup
        uberLoginButton.layer.cornerRadius = 5
        uberLoginButton.layer.borderWidth = 2
        uberLoginButton.layer.borderColor = UIColor.whiteColor().CGColor

        uberLoginButtonBottom.layer.cornerRadius = 5
        uberLoginButtonBottom.layer.borderWidth = 2
        uberLoginButtonBottom.layer.borderColor = UIColor.whiteColor().CGColor

        signUpButton.layer.cornerRadius = 5
        signUpButton.layer.borderWidth = 2
        signUpButton.layer.borderColor = UIColor.whiteColor().CGColor

        // Do any additional setup after loading the view.
    }

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if (error != nil) {
            print(error.localizedDescription)
            displayAlert("Error", message: error.localizedDescription)
        } else if (result.isCancelled) {
            // code for cancelled
            displayAlert("Error", message: "Sorry, we were unable to connect to Facebook right now. Please try again later.")
        } else {
            print("user logged in")
            let credentials = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
            FIRAuth.auth()?.signInWithCredential(credentials, completion: { (user, error) in
                if (error != nil) {
                    print(error?.localizedDescription)
                } else {
                    let currUserPath: FIRDatabaseReference = self.databaseRef.child("\((FIRAuth.auth()?.currentUser?.uid)!)")
                    currUserPath.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
                        if (snapshot.exists()) {
                            if let type = snapshot.value?.objectForKey("type") as? String {
                                if (type == "Driver") {
                                    // to driver view
                                    self.toDesginatedView()
                                } else {
                                    // to rider view
                                    self.toDesginatedView()
                                }
                            } else {
                                self.setDataWithFB(user!)
                            }
                        } else {
                            self.setDataWithFB(user!)
                        }
                    })

                }
            })
        }
    }

    func setDataWithFB(user: FIRUser) {
        let userPath = self.databaseRef.child("\((FIRAuth.auth()?.currentUser?.uid)!)")
        userPath.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
            if let type = snapshot.value?.objectForKey("type") as? String {
                self.toDesginatedView()
            }
        })
        let graphRequest = FBSDKGraphRequest.init(graphPath: "me", parameters: ["fields": "id"])
        graphRequest.startWithCompletionHandler { (connection, result, error) in
            if (error != nil) {
                print(error.localizedDescription)
                self.displayAlert("Error", message: error.localizedDescription)
            } else {
                if let FBID = result.valueForKey("id") as? String {

                    typeSelectuserImageURL = "https://graph.facebook.com/\(FBID)/picture?type=large"
                    typeSelectUserName = (user.displayName)!
                    let userData = [
                        "name": typeSelectUserName,
                        "email": user.email!,
                        "uid": user.uid,
                        "FBID": FBID,
                        "userProfilePicture": typeSelectuserImageURL
                    ]
                    self.databaseRef.child("\(user.uid)").setValue(userData)
                    self.performSegueWithIdentifier("toUserTypeSelect", sender: self)
                }
            }
        }
    }

    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("fb log out")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true

        if let user = FIRAuth.auth()?.currentUser {
//            do {
//                try FIRAuth.auth()?.signOut()
//            } catch { print("didnt signout") }
            toDesginatedView()
        }
    }

    override func viewWillAppear(animated: Bool) {
        UIView.animateWithDuration(0.8) {
            dispatch_async(dispatch_get_main_queue()) {
                let url = NSBundle.mainBundle().URLForResource("bg1", withExtension: "gif")!
                let imageData = NSData(contentsOfURL: url)
                let image = UIImage()
                image.AddGifFromData(imageData!)
                let gifManager = JWAnimationManager(memoryLimit: 10)
                self.bgImageView.SetGifImage(image, manager: gifManager)

            }
            self.orLabel.alpha = 1
            self.fbLoginPlaceholder.alpha = 0
            self.uberLoginButton.alpha = 1
            self.uberLoginButton.userInteractionEnabled = true
            self.loginButton.alpha = 1
            self.loginButton.userInteractionEnabled = true
            self.userNameField.alpha = 0
            self.userNameField.userInteractionEnabled = false
            self.passwordField.alpha = 0
            self.passwordField.userInteractionEnabled = false
            self.uberLoginButtonBottom.alpha = 0
            self.uberLoginButtonBottom.userInteractionEnabled = false
            self.signUpButton.alpha = 0
            self.signUpButton.userInteractionEnabled = false
            self.wouldSignUpButton.alpha = 0
            self.wouldSignUpButton.userInteractionEnabled = false
            self.signUpPrompt.alpha = 0
        }
    }

    func toDesginatedView() {
        startSpinner()
        let currUserPath: FIRDatabaseReference = self.databaseRef.child("\((FIRAuth.auth()?.currentUser?.uid)!)")
        currUserPath.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
            if let type = snapshot.value?.objectForKey("type") as? String {
                if (type == "Driver") {
                    // to driver view
                    self.performSegueWithIdentifier("toDriverViewFromLogin", sender: self)
                } else {
                    // to rider view

                    if let wantsRide = snapshot.value?.objectForKey("wantsRide") as? String {
                        if (wantsRide == "true") {
                            if let driverUID = snapshot.value?.objectForKey("driverUID") as? String {
                                self.riderWantsRide = true
                                if (driverUID.characters.count > 0) {
                                    self.riderHasRide = true
                                }
                            }
//                            let riderView = segue.destinationViewController as? RiderViewController
//                            riderView?.didReuqestRide = true
//                            riderView?.hasDriveApproaching = true
                        }
                    }
                    self.stopSpinner()
                    self.performSegueWithIdentifier("toRiderViewFromLogin", sender: self)
                }
            } else {
                self.stopSpinner()
                self.performSegueWithIdentifier("toUserTypeSelect", sender: self)
            }
        })

    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }

    func hasValidCredentials(userName: String, password: String) -> Bool {
        if (userName.characters.count == 0 && password.characters.count == 0) {
            // display alert for invlaid credentials
            displayAlert("Error", message: "Please enter a valid email address and password.")
            return false
        } else if (userName.characters.count == 0) {
            // display alert for invalid username
            displayAlert("Error", message: "Please enter a valid email address")
            return false
        } else if (password.characters.count == 0) {
            // display alert for invalid password
            displayAlert("Error", message: "Please enter a valid password")
            return false
        }
        return true
    }

    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func startSpinner() {
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "toRiderViewFromLogin") {
            if (riderWantsRide) {
                let riderView = segue.destinationViewController as? RiderViewController
                riderView?.didReuqestRide = riderWantsRide
                riderView?.hasDriverApproaching = riderHasRide
            }
        }
    }
}

