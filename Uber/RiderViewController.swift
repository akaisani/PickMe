//
//  RiderViewController.swift
//  PickMe
//
//  Created by Abid Amirali on 7/18/16.
//  Copyright © 2016 Abid Amirali. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase

class RiderViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    // rider settings intial code and rider view intitail code
    var locationManager: CLLocationManager!
    var userLocation: CLLocation!
    let databaseRef = FIRDatabase.database().reference().child("users")
    var didReuqestRide = false
    var hasDriverApproaching = false
    var driverName = ""
    var isFBLogin = false
    var riderImageString = ""
    var riderName = ""
    let currUID = (FIRAuth.auth()?.currentUser?.uid)!
    var tempLocationString = ""
    var driverUID = ""

    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var haulPickMeButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
//        navBar.barStyle = UIBarStyle.Black
//        navBar.tintColor = UIColor.whiteColor()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        // Do any additional setup after loading the view.
        haulPickMeButton.layer.cornerRadius = 5
        haulPickMeButton.layer.borderWidth = 2
        haulPickMeButton.layer.borderColor = UIColor.whiteColor().CGColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        let riderPath = databaseRef.child(currUID)
        print(riderPath)
        riderPath.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            if (snapshot.exists()) {
//                print(snapshot.value)
//                print(snapshot.hasChildren())
                if let driverUID = snapshot.value?.objectForKey("driverUID") as? String {
                    if let name = snapshot.value?.objectForKey("driverName") as? String {
                        self.driverName = name
                        if (driverUID.characters.count > 0) {
                            // perform segue to rider view
                            // add driver to map view
                            if let driverLocation = snapshot.value?.objectForKey("location") as? String {
                                self.haulPickMeButton.setTitle("Cancel", forState: UIControlState.Normal)
                                self.didReuqestRide = true
                                self.hasDriverApproaching = true
                                self.locationManager.startUpdatingLocation()
                                // getting driver's location
                                self.riderHasDriver()
                                self.addDriversLocation(self.driverName, locationString: driverLocation)

                            }
                        }
                    }
                }
                if let FBID = snapshot.value!["FBID"] as? String {
                    if (FBID != self.currUID) {
                        self.isFBLogin = true
                    }
                }
                if let imageString = snapshot.value!["userProfilePicture"] as? String {
                    self.riderImageString = imageString
                }
                if let name = snapshot.value! ["name"] as? String {
                    self.riderName = name
                }
                if let wantsRide = snapshot.value! ["wantsRide"] as? String {
                    if (wantsRide == "true") {
                        self.haulPickMeButton.setTitle("Cancel", forState: UIControlState.Normal)
                        self.didReuqestRide = true
                        self.locationManager.stopUpdatingLocation()
                    }
                }
            }
        })
        // fix issue when starting navigation

        // observer for driver Name

        // observer for driver UID
        databaseRef.observeEventType(FIRDataEventType.ChildChanged, withBlock: { (snapshot) in
            if (snapshot.exists()) {
                print(snapshot.key)
                if (snapshot.key == self.currUID) {

                    if let driverUID = snapshot.value?["driverUID"] as? String {
                        if let driverName = snapshot.value?["driverName"] as? String {
                            if (driverUID.characters.count > 0) {
                                self.hasDriverApproaching = true
                                self.driverUID = driverUID
                                self.driverName = driverName

                            }
                        }
                    }
                }
                if (snapshot.key == self.driverUID) {
                    if (self.driverUID.characters.count > 0) {
                        if (self.hasDriverApproaching) {
                            self.databaseRef.child("\(self.driverUID)").observeEventType(FIRDataEventType.ChildChanged, withBlock: { (snapshot) in
                                if (snapshot.exists()) {
                                    if (snapshot.key == "location") {
                                        if let returnedString = snapshot.value as? String {
                                            self.tempLocationString = returnedString
                                            if (self.driverName.characters.count > 0) {
                                                self.addDriversLocation(self.driverName, locationString: self.tempLocationString)
                                            }
                                        }
                                    }
                                    if (snapshot.key == "reachedRider") {
                                        if let returnedString = snapshot.value as? String {
                                            if (returnedString == "true") {
                                                self.reset()
                                            }
                                        }
                                    }
                                }

                            })
                        }

                    }
                }

            }
        })

        // alternate for getting rider deatils
        
        //                    if (snapshot.key == "driverName") {
        //                        if let returnedString = snapshot.value as? String {
        //                            self.driverName = returnedString
        //                            if (self.tempLocationString.characters.count > 0) {
        //                                self.hasDriverApproaching = true
        //                                self.didReuqestRide = true
        //                                self.addDriversLocation(self.driverName, locationString: self.tempLocationString)
        //                            }
        //                        }
        //                    }
        //
        //                    if (snapshot.key == "driverUID") {
        //                        if let returnedString = snapshot.value as? String {
        //                            self.driverUID = returnedString
        //                            if (self.tempLocationString.characters.count > 0 && self.driverName.characters.count > 0) {
        //                                self.hasDriverApproaching = true
        //                                self.didReuqestRide = true
        //                                self.addDriversLocation(self.driverName, locationString: self.tempLocationString)
        //                            }
        //                        }
        //                    }
        
        // alternate for getting rider details
        
//        if (self.hasDriverApproaching) {
//            self.databaseRef.child("\(driverUID)").observeSingleEventOfType(FIRDataEventType.ChildChanged, withBlock: { (snapshot) in
//                if (snapshot.exists()) {
//                    if (snapshot.key == "location") {
//                        if let returnedString = snapshot.value as? String {
//                            self.tempLocationString = returnedString
//                            if (self.driverName.characters.count > 0) {
//                                self.addDriversLocation(self.driverName, locationString: self.tempLocationString)
//                            }
//                        }
//                    }
//                    if (snapshot.key == "reachedRider") {
//                        if let returnedString = snapshot.value as? String {
//                            if (returnedString == "true") {
//                                self.reset()
//                            }
//                        }
//                    }
//                }
//
//            })
//        }

    }

    func addDriversLocation(driverNameString: String, locationString: String) {
        let driverLocationCoordinates = locationString.componentsSeparatedByString(",")
        let driverLatitude: CLLocationDegrees = CLLocationDegrees(driverLocationCoordinates[0])!
        let driverLongitude: CLLocationDegrees = CLLocationDegrees(driverLocationCoordinates[1])!
        setMapReigon(CLLocation(latitude: driverLatitude, longitude: driverLongitude), title: "Your Driver", subtitle: "\(driverNameString)'s Location", hasAnnotations: true)
        let driverLocation = CLLocation(latitude: driverLatitude, longitude: driverLongitude)
        let distance = driverLocation.distanceFromLocation(driverLocation)
        if (distance < 10) {
            reset()
        }

    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // setting map reigon
        if (!hasDriverApproaching) {
            userLocation = locations[0]
            setMapReigon(userLocation, title: "", subtitle: "", hasAnnotations: false)
        }

    }

    func setMapReigon(location: CLLocation, title: String, subtitle: String, hasAnnotations: Bool) {
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let reigon = MKCoordinateRegionMake(location.coordinate, span)
        mapView.setRegion(reigon, animated: true)
        // adding annotion to represnt user location
        if (hasAnnotations) {
            mapView.removeAnnotations(mapView.annotations)
            var annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            if (title.characters.count > 0) {
                annotation.title = title
            }
            if (subtitle.characters.count > 0) {
                annotation.subtitle = subtitle
            }
            self.mapView.addAnnotation(annotation)
        }

    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
            pinAnnotationView.pinColor = .Purple
            pinAnnotationView.canShowCallout = false
            pinAnnotationView.animatesDrop = true
            return pinAnnotationView
        }
        return nil
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        // display alert
        displayAlert("Error", message: error.localizedDescription)
    }

    @IBAction func haulRide(sender: AnyObject) {
        let userPath = databaseRef.child(currUID)
        // getting current date
        let currentDate = NSDate()
        let dateFormater = NSDateFormatter()
        // formatting current date for later use
        dateFormater.dateFormat = "dd,MM,yyyy,HH,mm,ss"
        let formatedDate = dateFormater.stringFromDate(currentDate)
        // creating user data package with the user wanting a ride, the users location and date of request
        let rideData = [
            "wantsRide": "\(!didReuqestRide)",
            "location": "\(userLocation.coordinate.latitude),\(userLocation.coordinate.longitude)",
            "updated": formatedDate
        ]
        if (!didReuqestRide) {
            userPath.updateChildValues(rideData, withCompletionBlock: { (error, dataRef) in
                if (error != nil) {
                    self.displayAlert("Error", message: (error?.localizedDescription)!)
                } else {
                    self.haulPickMeButton.setTitle("Cancel", forState: UIControlState.Normal)
                    self.didReuqestRide = true
                    self.locationManager.stopUpdatingLocation()
                }
            })
        } else {
            userPath.updateChildValues(rideData, withCompletionBlock: { (error, dataRef) in
                if (error != nil) {
                    self.displayAlert("Error", message: (error?.localizedDescription)!)
                } else {
                    self.haulPickMeButton.setTitle("Haul A Ride", forState: UIControlState.Normal)
                    self.didReuqestRide = false
                    self.locationManager.startUpdatingLocation()
                }
            })
        }
    }

    func riderHasDriver() {
        if (hasDriverApproaching || didReuqestRide) {
            self.haulPickMeButton.setTitle("Cancel", forState: UIControlState.Normal)
            self.locationManager.startUpdatingLocation()
        }
    }

    func reset() {
        hasDriverApproaching = false
        didReuqestRide = false
//        displayAlert("Ride Arrived", message: "Your driver has arrived. Your drivers name is: \(driverName)")
        let alert = UIAlertController(title: "Ride Arrived", message: "Your driver has arrived. Your drivers name is: \(driverName)", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: {
            (action) in
            self.haulPickMeButton.setTitle("Haul An Ride", forState: UIControlState.Normal)
            }))
        self.presentViewController(alert, animated: true, completion: nil)
        let riderData = [
//            "reachedRider": "true",
            "driverUID": "",
            "driverName": "",
            "wantsRide": "\(didReuqestRide)"
        ]
        databaseRef.child(currUID).updateChildValues(riderData)
        locationManager.stopUpdatingLocation()
        mapView.removeAnnotations(mapView.annotations)
        locationManager.stopUpdatingLocation()
        driverName = ""
        driverUID = ""
        tempLocationString = ""
    }

    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

// MARK: - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "toSettingsFromRider") {
            if let settigsController = segue.destinationViewController as? SettingsViewController {

                // add to stting view
                settigsController.isRider = true
                settigsController.isFbLogin = isFBLogin
                settigsController.imageString = riderImageString
                settigsController.userName = riderName
            }
        }
    }

}
