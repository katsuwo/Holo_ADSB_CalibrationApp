//
//  ViewController.swift
//  Holo_ADSB_CalibrationApp
//
//  Created by katsuwo on 2019/02/24.
//  Copyright © 2019 katsuwo. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation

class ViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    //map marker
    var currentMarker :GMSMarker!
    var calibrateMarker :GMSMarker!
    
    var isFirstDetection:Bool!
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBAction func didChangedSelection(_ sender: Any) {
    }
    @IBAction func didChangedUpdate(_ sender: Any) {
    }
    @IBAction func didPushedUpdateNow(_ sender: Any) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        isFirstDetection = true
        setupMap()
        setupLocationManager()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupMap(){
        mapView.isMyLocationEnabled = false
        mapView.mapType = .satellite
        mapView.delegate? = self
        mapView.isMyLocationEnabled = true
        
        let markerImage = UIImage(named:"CalibratePoint")
        let markerView = UIImageView(image:markerImage)
        currentMarker = GMSMarker(position:CLLocationCoordinate2D(latitude:0, longitude:0))
        currentMarker.iconView = markerView
        currentMarker.map = mapView
        
        let markerImage2 = UIImage(named:"CurrentPoint")
        let markerView2 = UIImageView(image:markerImage2)
        calibrateMarker = GMSMarker(position:CLLocationCoordinate2D(latitude:0, longitude:0))
        calibrateMarker.iconView = markerView2
        calibrateMarker.map = mapView
    }
    
    func setupLocationManager(){
        self.locationManager = CLLocationManager()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.delegate = self
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            self.locationManager.requestAlwaysAuthorization()
            print("Location access was restricted.")
        case .denied:
            self.locationManager.requestAlwaysAuthorization()
            print("User denied access to location.")
            // Display the map using the default location.
        //            mapView.isHidden = false
        case .notDetermined:
            self.locationManager.requestAlwaysAuthorization()
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        if isFirstDetection {
            currentMarker.position = location.coordinate
        }
    }

}

