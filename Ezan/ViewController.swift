//
//  ViewController.swift
//  Ezan
//
//  Created by M. Akif Petek on 07/12/14.
//  Copyright (c) 2014 M. Akif Petek. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, CLLocationManagerDelegate
{

    @IBOutlet weak var timeLabel: UILabel!
    var prayTimes: Array<String> = Array()
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        //Location
        // For use in foreground
        locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.significantLocationChangeMonitoringAvailable() {

            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.activityType = CLActivityType.otherNavigation
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.startMonitoringSignificantLocationChanges()
        }

        let colors = Colors()

        self.view.backgroundColor = UIColor.clear
        let backgroundLayer = colors.gl
        backgroundLayer.frame = view.frame
        view.layer.insertSublayer(backgroundLayer, at: 0)

        //====
        let touchGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.onTouch(_:)))
        view.addGestureRecognizer(touchGestureRecognizer)
        
    }
    
    // Present the ad only after it has loaded and is ready
    /*func interstitialDidLoadAd(interstitial: MPInterstitialAdController) {
        if (interstitial.ready) {
            interstitial.showFromViewController(self)
        }
    }*/


    @objc func onTouch(_ gesture: UITapGestureRecognizer) -> Void {

        //print(gesture.state.hashValue)
        //"http://maps.googleapis.com/maps/api/geocode/json?latlng=" + g.latitude + "," + g.longitude + "&sensor=true"
        
        Alamofire.request("http://yapps.co/ezanapp/words.php?lang=tr").responseJSON { response in

            switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    print("JSON: \(json["words"][1])")
                    self.timeLabel.text = json["words"][1]["source"].string
                    break
                case .failure(let error):
                    print(error)
                    break
            }
            
            
//            if let json = response.result.value {
//                print(json)
//
//            }
            
//            if(response.result.isSuccess) {
//
//            }
            
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let locValue: CLLocationCoordinate2D = manager.location!.coordinate
//        print("locations = \(locValue.latitude) \(locValue.longitude)")

        let pt: PrayTimes = PrayTimes()

        let date = Date()
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.hour, .minute, .month, .year, .day], from: date)
        let timeZone: Double = Double(calendar.timeZone.secondsFromGMT() / 3600)

//        print(timeZone)
//        print("tz \(calendar.timeZone.secondsFromGMT) \(components.timeZone?.description)")
//
//        print(pt.getPrayerTimes(components, latitude: locValue.latitude as Double, longitude: locValue.longitude as Double, timeZone: timeZone))
        
        
        let location = locations[locations.count - 1]
        
        if(location.horizontalAccuracy > 0) {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            
            prayTimes = pt.getPrayerTimes(components, latitude: location.coordinate.latitude as Double, longitude: location.coordinate.longitude as Double, timeZone: timeZone) as! Array<String>
            
            print(prayTimes)
            
        Alamofire.request("https://maps.googleapis.com/maps/api/geocode/json?latlng=\(location.coordinate.latitude),\(location.coordinate.longitude)&sensor=true&key=AIzaSyDY6iFTopd-otn_r-GLX08h0gBPavPjTcU").responseJSON { response in
                
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    //print("JSON: \(json)")
                case .failure(let error):
                    print(error)
                }
            }
        }

    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("cannot get location - warn user")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var shouldIAllow = false


        switch status {
        case CLAuthorizationStatus.restricted:
            print("Restricted Access to location")
        case CLAuthorizationStatus.denied:
            print("User denied access to location")
        case CLAuthorizationStatus.notDetermined:
            print("Status not determined")
        default:
            //                locationStatus = "Allowed to location Access"
            shouldIAllow = true
        }

        NotificationCenter.default.post(name: Notification.Name(rawValue: "LabelHasbeenUpdated"), object: nil)
        if (shouldIAllow == true) {
            NSLog("Location to Allowed")
            // Start location services
            self.locationManager.startUpdatingLocation()
        } else {
            NSLog("Denied access:")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

class Colors {
    var colorTop = UIColor(red: 17.0 / 255.0, green: 22.0 / 255.0, blue: 25.0 / 255.0, alpha: 1.0).cgColor
    var colorBottom = UIColor(red: 12.0 / 255.0, green: 54.0 / 255.0, blue: 82.0 / 255.0, alpha: 1.0).cgColor

    let gl: CAGradientLayer

    init() {
        gl = CAGradientLayer()
        gl.colors = [colorTop, colorBottom]
        gl.locations = [0.0, 1.0]
    }
}

