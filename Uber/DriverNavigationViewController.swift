//
//  RiderLocationViewController.swift
//  PickMe
//
//  Created by Abid Amirali on 7/21/16.
//  Copyright © 2016 Abid Amirali. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase

class DriverNavigationViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var riderNameLabel: UILabel!
    @IBOutlet weak var navigateToRiderButton: UIButton!

    var riderLocation: CLLocation!
    var riderDistance: String!
    var riderNameString: String!
    var riderUID: String!
    var driverName: String!
    var driverUID: String!
    var locationManager: CLLocationManager!
    let databaseRef = FIRDatabase.database().reference().child("users")
    var count = 0
    var hasRider = false
    var isFBLogin = false
    var riderImage = UIImage()
    let currUID = (FIRAuth.auth()?.currentUser?.uid)!
    override func viewDidLoad() {
        super.viewDidLoad()
        // setting up location manager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

//        let userDefaults = NSUserDefaults.standardUserDefaults()
//
//        userDefaults.setBool(true, forKey: "ODLTrackingActive")

        navigateToRiderButton.layer.cornerRadius = 5
        navigateToRiderButton.layer.borderWidth = 2
        navigateToRiderButton.layer.borderColor = UIColor.whiteColor().CGColor

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(animated: Bool) {
        self.title = riderNameString
        riderNameLabel.text = riderNameString
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegionMake(riderLocation.coordinate, span)
        mapView.setRegion(region, animated: true)
        var annotation = MKPointAnnotation()
        annotation.title = "\(riderNameLabel.text!)'s Location"
        annotation.subtitle = "Distance: \(riderDistance)"
        annotation.coordinate = riderLocation.coordinate
        mapView.addAnnotation(annotation)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func navigateToRider(sender: AnyObject) {
        // add checks and nav
        if (!hasRider) {
            let riderPath = databaseRef.child("\(riderUID)")
            riderPath.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if (snapshot.exists()) {
                    if let wantsRide = snapshot.value?.objectForKey("wantsRide") as? String {
                        if let driverUID = snapshot.value?.objectForKey("driverUID") as? String {
                            if (wantsRide == "true" && driverUID.characters.count == 0) {
                                // code to navigate to rider

                                // viewin navigation options
                                let navgiationOptions = UIAlertController(title: "Navigate To Rider", message: "Navigate using:", preferredStyle: .ActionSheet)
                                navgiationOptions.addAction(UIAlertAction(title: "Maps", style: .Default, handler: { (action) -> Void in
                                    // code to navigate with maps
                                    self.navigateUsingAppleMaps()
                                    }))
                                navgiationOptions.addAction(UIAlertAction(title: "Google Maps", style: .Default, handler: { (action) -> Void in
                                    // code to navigate with google maps
                                    self.navigateUsingGoogleMaps()
                                    }))
                                navgiationOptions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                                self.presentViewController(navgiationOptions, animated: true, completion: nil)

                            } else {
                                self.displayAlert("Rider Not Available", message: "The selected rider no longer requires an Uber or managed to find a ride. Sorry")
                            }
                        }
                    }
                }
            })
        } else {
            displayAlert("Error", message: "You already have selected a rider")
        }

    }

    func navigateUsingAppleMaps() {
        navigationSetUp()
        CLGeocoder().reverseGeocodeLocation(riderLocation, completionHandler: { (placemarks, error) -> Void in
            if (error != nil) {
                self.displayAlert("Error", message: (error?.localizedDescription)!)
            } else {
                if (placemarks?.count > 0) {
                    let placemark = placemarks![0]
                    let mkPlacemark = MKPlacemark(placemark: placemark)
                    var mapitem = MKMapItem(placemark: mkPlacemark)
                    mapitem.name = self.riderNameString
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                    mapitem.openInMapsWithLaunchOptions(launchOptions)
                }
            }
        })

    }

    func navigateUsingGoogleMaps() {
        navigationSetUp()
        // "comgooglemaps://?center=%f,%f",rdOfficeLocation.latitude,rdOfficeLocation.longitude]
        // comgooglemaps://?saddr=2025+Garcia+Ave,+Mountain+View,+CA,+USA&daddr=Google,+1600+Amphitheatre+Parkway,+Mountain+View,+CA,+United+States&center=37.423725,-122.0877&directionsmode=walking&zoom=17
        let navURL = NSURL(string: "comgooglemaps://?center=\(riderLocation.coordinate.latitude),\(riderLocation.coordinate.longitude)")
//        let navURL = NSURL(string: "comgooglemaps://?center=37.423725,-122.0877&directionsmode=driving&zoom=17")
//        print(navURL)
        if (UIApplication.sharedApplication().canOpenURL(navURL!)) {
            UIApplication.sharedApplication().openURL(navURL!)
        } else {
            displayAlert("Navigation Error", message: "Google Maps was not found on your device. Please install Google Maps to navigate with Google Maps")
        }
    }

    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let driverPath = databaseRef.child("\((FIRAuth.auth()?.currentUser?.uid)!)")
        let driverLocation = locations[0]
        let currentDate = NSDate()
        let dateFormater = NSDateFormatter()
        // formatting current date for later use
        dateFormater.dateFormat = "dd,MM,yyyy,HH,mm,ss"
        let formatedDate = dateFormater.stringFromDate(currentDate)
        // creating user data package with the user wanting a ride, the users location and date of request
        let driverData = [
            "location": "\(driverLocation.coordinate.latitude),\(driverLocation.coordinate.longitude)",
            "updated": formatedDate
        ]
        driverPath.updateChildValues(driverData)
        driverPath.updateChildValues(driverData)
//        if let riderIndex = riderUIDs.indexOf(currUID) {
//        let riderLocationString = riderLocations[riderIndex]
        // splitting coordinate into latitude and longitude
//        let riderLocationCoordinates = riderLocationString.componentsSeparatedByString(",")
//        let riderLatitude: CLLocationDegrees = CLLocationDegrees(riderLocationCoordinates[0])!
//        let riderLongitude: CLLocationDegrees = CLLocationDegrees(riderLocationCoordinates[1])!
//        let riderLocation: CLLocation = CLLocation(latitude: riderLatitude, longitude: riderLongitude)
        print(driverLocation.coordinate)
        print()
        print(riderLocation.coordinate)
        let distance = driverLocation.distanceFromLocation(riderLocation)
        if (distance < 10) {
            reset()
        }
//        }

    }

    func navigationSetUp() {
        locationManager.stopUpdatingLocation()
        let systemVersion = UIDevice.currentDevice().systemVersion
        let osVersion = "\(systemVersion[systemVersion.characters.startIndex])"
        print(osVersion)
        if (Float(osVersion) <= 8.0) {
            print(UIDevice.currentDevice().systemVersion)
            print(Double(UIDevice.currentDevice().systemVersion))
            locationManager.requestAlwaysAuthorization()
        }
        if (Float(osVersion) >= 9.0) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        locationManager.startUpdatingLocation()
        // add code to add driver to riders data
        let riderData = [
            "driverName": driverName,
            "driverUID": driverUID
        ]
        let driverData = [
            "riderName": riderNameString,
            "riderUID": riderUID
        ]
        databaseRef.child("\(riderUID)").updateChildValues(riderData)
        databaseRef.child("\((FIRAuth.auth()?.currentUser?.uid)!)").updateChildValues(driverData)
    }

    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
        displayAlert("Error", message: (error?.localizedDescription)!)
    }

    func reset() {
        let driverData = [
            "reachedRider": "true",
            "riderUID": "",
            "riderName": ""
        ]
        databaseRef.child(driverUID).updateChildValues(driverData)
        locationManager.stopUpdatingLocation()
        displayAlert("You Have Arrived", message: "Your rider should be near you. Your riders name is: \(riderNameString)")

    }


    
//    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//        if annotation is MKPointAnnotation {
//            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
//            pinAnnotationView.pinColor = .Purple
//            pinAnnotationView.canShowCallout = true
//            pinAnnotationView.animatesDrop = true
//            return pinAnnotationView
//        }
//        return nil
//    }
//    
    

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}
