//
//  DriverTableViewController.swift
//  PickMe
//
//  Created by Abid Amirali on 7/18/16.
//  Copyright © 2016 Abid Amirali. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

class DriverTableViewController: UITableViewController, CLLocationManagerDelegate {

    var currUID = (FIRAuth.auth()?.currentUser?.uid)!
    let databaseRef = FIRDatabase.database().reference().child("users")
    var riderUIDs = [String]()
    var riderNames = [String]()
    var riderEmails = [String]()
    var requestDates = [String]()
    var riderLocations = [String]()
    var riderDistances = [String]()
    var selectedRiderIndex = -1
    var driverName: String!
    var driverUID: String!
    var locationManager: CLLocationManager!
    var driverLocation = CLLocation()
    var driverHasRider = false
    var isFbLogin = false
    var driverImage = UIImage()
    var driverImageString = ""
    var currRiderUID = ""
    var riderImageURLS = [String]()
    var riderImages = [UIImage]()
    var riderLoginTypes = [Bool]()
    var activityIndicator = UIActivityIndicatorView()
    @IBOutlet var tasktable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // setting up location manager
        self.navigationController?.navigationBar.backgroundColor = self.view.backgroundColor
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        // getting data from firebase
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        // get data from firebase
//        getDataFromFirebase()

    }

    override func viewDidAppear(animated: Bool) {
        stopSpinner()
        startSpinner()
        self.navigationController?.navigationBarHidden = false
        var count = 0
        self.riderUIDs = []
        self.riderNames = []
        self.riderEmails = []
        self.requestDates = []
        self.riderLocations = []
        self.riderImages = []
        self.riderImageURLS = []
        self.riderLoginTypes = []
        databaseRef.observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) in
            if (snapshot.exists()) {
                print(snapshot)
                if (snapshot.key != FIRAuth.auth()?.currentUser?.uid) {
                    print(snapshot)
                    if let type = snapshot.value?.objectForKey("type") as? String {
                        if (type == "Rider") {
                            if let request = snapshot.value?.objectForKey("wantsRide") as? String {
                                if (request == "true") {
                                    if let uid = snapshot.value?.objectForKey("uid") as? String {
                                        if let driverUID = snapshot.value?.objectForKey("driverUID") as? String {
                                            if (driverUID.characters.count == 0) {
                                                if let name = snapshot.value?.objectForKey("name") as? String {
                                                    if let email = snapshot.value?.objectForKey("email") as? String {
                                                        if let riderRequestDate = snapshot.value?.objectForKey("updated") as? String {
                                                            if let riderLocationString = snapshot.value?.objectForKey("location") as? String {
                                                                if let imageString = snapshot.value?.objectForKey("userProfilePicture") as? String {
                                                                    if (imageString.characters.count > 0) {
                                                                        if let FBID = snapshot.value?.objectForKey("FBID") as? String {
                                                                            var loginType = false
                                                                            if (uid != FBID) {
                                                                                loginType = true
                                                                            }
                                                                            self.addRider(uid, name: name, email: email, riderRequestDate: riderRequestDate, riderLocationString: riderLocationString, riderLoginType: loginType, imageURL: imageString)
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            } else {
                                                count += 1
                                            }
                                        }
                                    }
                                } else {
                                    count += 1
                                }
                            }
                        } else {
                            count += 1
                        }
                    } else {
                        count += 1
                    }
                } else {
                    if let name = snapshot.value?.objectForKey("name") as? String {
                        if let uid = snapshot.value?.objectForKey("uid") as? String {
                            self.driverUID = uid
                            self.driverName = name
                            if let riderUID = snapshot.value?.objectForKey("riderUID") as? String {
                                if (riderUID.characters.count > 0) {
                                    self.driverHasRider = true
                                    self.currUID = riderUID
                                }
                                if let FBID = snapshot.value?.objectForKey("FBID") as? String {
                                    if let imageURLString = snapshot.value?.objectForKey("userProfilePicture") as? String {
                                        if (FBID != self.driverUID) {
                                            self.isFbLogin = true
                                            self.driverImageString = imageURLString
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                print(self.riderEmails.count)
                print("count", count)
                print(snapshot.childrenCount)
                let totalCount: Int = Int(snapshot.childrenCount / 2) - count - 1
                print("total count", totalCount)
                if (self.riderEmails.count == totalCount) {
                    // indicated that all valuable data has been colleected now the data will be sorted according to the drivers location and time elapsed between when the rider calls for a ride and a driver checks for a ride
                    self.filterRiders()
                }
            }

        })

        databaseRef.observeEventType(FIRDataEventType.ChildChanged, withBlock: { (snapshot) in
//            print("in child changed")
//            print(snapshot)
            // fix child changed¬
            if (snapshot.exists()) {
                if let wantsRide = snapshot.value?.objectForKey("wantsRide") as? String {
                    if (wantsRide == "true") {
                        if let uid = snapshot.value?.objectForKey("uid") as? String {
                            if let name = snapshot.value?.objectForKey("name") as? String {
                                if let email = snapshot.value?.objectForKey("email") as? String {
                                    if let riderRequestDate = snapshot.value?.objectForKey("updated") as? String {
                                        if let riderLocationString = snapshot.value?.objectForKey("location") as? String {
                                            if let driverUID = snapshot.value?.objectForKey("driverUID") as? String {
                                                if (driverUID.characters.count == 0) {
                                                    print(driverUID)
                                                    print(self.riderUIDs)
                                                    print(self.riderUIDs.contains(driverUID))
                                                    if let imageString = snapshot.value?.objectForKey("userProfilePicture") as? String {
                                                        if (imageString.characters.count > 0) {
                                                            if let FBID = snapshot.value?.objectForKey("FBID") as? String {
                                                                var loginType = false
                                                                if (uid != FBID) {
                                                                    loginType = true
                                                                }
                                                                self.addRider(uid, name: name, email: email, riderRequestDate: riderRequestDate, riderLocationString: riderLocationString, riderLoginType: loginType, imageURL: imageString)
                                                                self.filterRiders()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if let uid = snapshot.value?.objectForKey("uid") as? String {
                            let removalIndex = self.riderUIDs.indexOf(uid)
                            if (removalIndex != nil) {
                                self.removeRider(removalIndex as Int!)
                                self.filterRiders()
                            } else {
                                self.tasktable.reloadData()
                            }
                        } // driver location === rider then rest and if not then error
                    }
                }
            }
        })

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return riderUIDs.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("driverCell", forIndexPath: indexPath)
        // Configure the cell...
        cell.textLabel?.text = "\(riderNames[indexPath.row])\tDist: \(riderDistances[indexPath.row])"
        cell.imageView?.image = riderImages[indexPath.row]
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var error = false
        selectedRiderIndex = indexPath.row
        if (currRiderUID.characters.count > 0) {
            if (riderUIDs[indexPath.row] != currRiderUID) {
                displayAlert("You already Have a Rider", message: "You can only navigate to one rider at a time")
                error = true
            }
        }
        if (!error) {
            self.performSegueWithIdentifier("toRiderNav", sender: self)
        }
    }

    // MARK: - CLLocation Manger Methods

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let driverPath = databaseRef.child("\(currUID)")
        driverLocation = locations[0]
//        print(driverLocation.coordinate)
        let currentDate = NSDate()
        let dateFormater = NSDateFormatter()
        // formatting current date for later use
        dateFormater.dateFormat = "dd,MM,yyyy,HH,mm,ss"
        let formatedDate = dateFormater.stringFromDate(currentDate)
        // creating user data package with the user wanting a ride, the users location and date of request
        let driverLocationString = "\(driverLocation.coordinate.latitude),\(driverLocation.coordinate.longitude)"
        let driverData = [
            "location": driverLocationString,
            "updated": formatedDate
        ]
        driverPath.updateChildValues(driverData)
        if let riderIndex = riderUIDs.indexOf(currUID) {
            let riderLocationString = riderLocations[riderIndex]
            // splitting coordinate into latitude and longitude
            let riderLocationCoordinates = riderLocationString.componentsSeparatedByString(",")
            let riderLatitude: CLLocationDegrees = CLLocationDegrees(riderLocationCoordinates[0])!
            let riderLongitude: CLLocationDegrees = CLLocationDegrees(riderLocationCoordinates[1])!
            let riderLocation: CLLocation = CLLocation(latitude: riderLatitude, longitude: riderLongitude)
            let distance = driverLocation.distanceFromLocation(riderLocation)
            if (distance < 10) {
                reset()
            }
        }
    }

    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
        displayAlert("Error", message: (error?.localizedDescription)!)
    }

//    func setUpNavigation() {
//        locationManager.startUpdatingLocation()
//
//    }

    // MARK: - Uber data filtering methods

    func filterRiders() {
        // get drivers coordinates
        var removeNum = 0
        let driverLatitude = driverLocation.coordinate.latitude
        let driverLongitude = driverLocation.coordinate.longitude
//        print("printing driver lat and long\n", driverLatitude,driverLongitude )
        locationManager.stopUpdatingLocation()
        // getting the current date
        let driverCurrDate = NSDate()
        let dateFormater = NSDateFormatter()
        // formatting current date for later use
        dateFormater.dateFormat = "dd,MM,yyyy,HH,mm,ss"
        let formatedDate = dateFormater.stringFromDate(driverCurrDate)
        let driverDateComponents = formatedDate.componentsSeparatedByString(",")
        for i in 0 ..< riderUIDs.count {
            // filtering rider by current date

            let riderDateString = requestDates[i]
            let riderDateComponents = riderDateString.componentsSeparatedByString(",")
            var doRemoveRider = false
            // filtering riders by year of request
            let driversDay: Int = Int(driverDateComponents[0])!
            let driversMonth: Int = Int(driverDateComponents[1])!
            let driversYear: Int = Int(driverDateComponents[2])!
            let driverHour: Int = Int(driverDateComponents[3])!
            let driverMinute: Int = Int(driverDateComponents[4])!

            let ridersDay: Int = Int(riderDateComponents[0])!
            let ridersMonth: Int = Int(riderDateComponents[1])!
            let riderYear: Int = Int(riderDateComponents[2])!
            let riderHour: Int = Int(riderDateComponents[3])!
            let riderMinute: Int = Int(riderDateComponents[4])!
            print(riderHour, driverHour)
            if (driversYear != riderYear) {
                doRemoveRider = true
                // filtering riders by month of request
            } else if (driversMonth != ridersMonth) {
                doRemoveRider = true
                // filtering riders by day of request
            } else if (driversDay != ridersDay) {
                doRemoveRider = true
                // filtering riders by year of request
            } else if (driverHour != riderHour) {
                doRemoveRider = true
            }
            if (riderDateComponents[3] == "00" && driverDateComponents[3] == "23" || riderDateComponents[3] == "23" && driverDateComponents[3] == "00") {
                doRemoveRider = false
            }
            if ((riderMinute < 20 && driverMinute > 50) || (riderMinute > 50 && driverMinute < 20)) {
                if (driverHour != riderHour + 1 && driverHour != riderHour - 1) {
                    doRemoveRider = false
                }
            }
            // filtering riders by minute of request
            var timeDiff = riderMinute - driverMinute
            if (timeDiff < 0) {
                timeDiff = -timeDiff
            }

            if (timeDiff > 30) {
                doRemoveRider = true
            }

            // done filtering riders by date and time

            // filtering rider by location if not yet filtered by time
            // getting riders location
            if (!doRemoveRider) {
                let riderLocationString = riderLocations[i]
                // splitting coordinate into latitude and longitude
                let riderLocationCoordinates = riderLocationString.componentsSeparatedByString(",")
                let riderLatitude: CLLocationDegrees = CLLocationDegrees(riderLocationCoordinates[0])!
                let riderLongitude: CLLocationDegrees = CLLocationDegrees(riderLocationCoordinates[1])!
                // finding differnce between user and rider longitude and lattitude and sorting accordingly
                print(riderLatitude, driverLatitude)
                var latDiffernce = riderLatitude - driverLatitude

                if (latDiffernce < 0) {
                    latDiffernce = -latDiffernce
                }

                var longDiffernce = riderLongitude - driverLongitude

                if (longDiffernce < 0) {
                    longDiffernce = -longDiffernce
                }
                print(latDiffernce, longDiffernce)
                if (latDiffernce > 10 || longDiffernce > 10) {
                    doRemoveRider = true
                } else {
                    let riderLocation = CLLocation(latitude: riderLatitude, longitude: riderLongitude)
                    let distance = self.driverLocation.distanceFromLocation(riderLocation)
                    print (distance)
                    let doubleDistance = Double(round((distance * 10)) / 10)
//                    let roundedDistance = Double
                    riderDistances.append(String.init(format: "%.2f KM", doubleDistance))
                }
            }

            if (doRemoveRider) {
                removeRider(i - removeNum)
                removeNum += 1
            }

        }

        getRiderImages()

    }

    func removeRider(index: Int) {
        print(index)
        self.riderUIDs.removeAtIndex(index)
        self.riderNames.removeAtIndex(index)
        self.riderEmails.removeAtIndex(index)
        self.requestDates.removeAtIndex(index)
        self.riderLocations.removeAtIndex(index)
        self.riderLoginTypes.removeAtIndex(index)
        self.riderImageURLS.removeAtIndex(index)
        if (self.riderImages.count > index) {
            self.riderImages.removeAtIndex(index)
        }
    }

    func addRider(uid: String, name: String, email: String, riderRequestDate: String, riderLocationString: String, riderLoginType: Bool, imageURL: String) {
        self.riderUIDs.append(uid)
        self.riderNames.append(name)
        self.riderEmails.append(email)
        self.requestDates.append(riderRequestDate)
        self.riderLocations.append(riderLocationString)
        self.riderLoginTypes.append(riderLoginType)
        self.riderImageURLS.append(imageURL)
    }

    // MARK: -  UIAlertActionController Methods

    func reset() {
        let driverData = [
            "reachedRider": "true",
            "riderUID": "",
            "riderName": ""
        ]
        databaseRef.child(driverUID).updateChildValues(driverData)
        locationManager.stopUpdatingLocation()
        displayAlert("You Have Arrived", message: "Your rider should be near you. Your riders name is: \(riderNames[riderUIDs.indexOf(currUID)!])")

    }

    func getRiderImages() {
        riderImages = []
        for i in 0 ..< riderImageURLS.count {
            if (!(riderLoginTypes[i])) {
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
                        self.riderImages.append(image!)

                    }
                })
            } else {
                // getting UserImage
                let url = NSURL(string: riderImageURLS[i])
                let data = NSData(contentsOfURL: url!)
                let image = UIImage(data: data!)
                riderImages.append(image!)
            }
        }
        stopSpinner()
        tasktable.reloadData()

    }

    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func startSpinner() {
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0,0,50,50))
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
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

    // MARK: - FIRDatabase data retrival methods

//    func getDataFromFirebase() {
//        var count: Int = 0
//        riderUIDs = []
//        riderNames = []
//        riderEmails = []
//        requestDates = []
//        riderLocations = []
//        databaseRef.observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) in
//            if (snapshot.exists()) {
//                for user in snapshot.children {
//                    if (user.key! != FIRAuth.auth()?.currentUser?.uid) {
//                        if let type = user.value.objectForKey("type") as? String {
//                            if (type == "Rider") {
//                                if let request = user.value.objectForKey("wantsRide") as? String {
//                                    if (request == "true") {
//                                        if let uid = user.value.objectForKey("uid") as? String {
//                                            if let name = user.value.objectForKey("name") as? String {
//                                                if let email = user.value.objectForKey("email") as? String {
//                                                    if let riderRequestDate = user.value.objectForKey("updated") as? String {
//                                                        if let riderLocationString = user.value.objectForKey("location") as? String {
//                                                            self.riderUIDs.append(uid)
//                                                            self.riderNames.append(name)
//                                                            self.riderEmails.append(email)
//                                                            self.requestDates.append(riderRequestDate)
//                                                            self.riderLocations.append(riderLocationString)
//                                                        }
//                                                    }
//                                                }
//                                            }
//                                        }
//                                    } else {
//                                        count += 1
//                                    }
//                                }
//                            } else {
//                                count += 1
//                            }
//                        } else {
//                            count += 1
//                        }
//                    }
//                }
//            }
//            print(self.riderEmails.count)
//            print("count", count)
//            let totalCount: Int = Int(snapshot.childrenCount) - count - 1
//            print("total count", totalCount)
//            if (self.riderEmails.count == totalCount) {
//                // indicated that all valuable data has been colleected now the data will be sorted according to the drivers location and time elapsed between when the rider calls for a ride and a driver checks for a ride
//                self.filterRiders()
//            }
//
//        })
//    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */

    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */

    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

     }
     */

    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "toRiderNav") {
            if let navController = segue.destinationViewController as? DriverNavigationViewController {
                navController.riderNameString = riderNames[selectedRiderIndex]
                navController.riderDistance = riderDistances[selectedRiderIndex]
                navController.riderUID = riderUIDs[selectedRiderIndex]
                navController.driverName = driverName
                navController.driverUID = driverUID
                let selectedRiderLocationString = riderLocations[selectedRiderIndex]
                let locationComponents = selectedRiderLocationString.componentsSeparatedByString(",")
                let riderLatitude: CLLocationDegrees = CLLocationDegrees(locationComponents[0])!
                let riderLongitude: CLLocationDegrees = CLLocationDegrees(locationComponents[1])!
                let riderLocation = CLLocation(latitude: riderLatitude, longitude: riderLongitude)
                navController.riderLocation = riderLocation
                navController.isFBLogin = isFbLogin

            }
        }
        if (segue.identifier == "toSettingsFromDriver") {
            if let settigsController = segue.destinationViewController as? SettingsViewController {

                // add to stting view
                settigsController.isRider = false
                settigsController.isFbLogin = isFbLogin
                settigsController.imageString = driverImageString
                settigsController.userName = driverName
            }
        }

    }
}
