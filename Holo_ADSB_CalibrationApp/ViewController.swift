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
    var alt = 0.0;
    var gainValue:String = "MAX"
    var agcValue:Bool = true
    var fov:Float = 17.82
    
    @IBOutlet weak var FOVLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    var isFirstDetection:Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isFirstDetection = true
        setupLocationManager()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupMap()
        FOVLabel.text = NSString(format: "%.2f", fov) as String
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupMap(){
        mapView.isMyLocationEnabled = false
        mapView.mapType = .satellite
        mapView.isMyLocationEnabled = true
        
        let markerImage = UIImage(named:"CalibratePoint")
        let markerView = UIImageView(image:markerImage)
        currentMarker = GMSMarker(position:CLLocationCoordinate2D(latitude:0, longitude:0))
        currentMarker.iconView = markerView
        currentMarker.isDraggable = true;
        currentMarker.userData = "CUR";
        currentMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        currentMarker.map = mapView
        
        let markerImage2 = UIImage(named:"CurrentPoint")
        let markerView2 = UIImageView(image:markerImage2)
        calibrateMarker = GMSMarker(position:CLLocationCoordinate2D(latitude:0, longitude:0))
        calibrateMarker.iconView = markerView2
        calibrateMarker.isDraggable = false;
        calibrateMarker.userData = "CAL"
        calibrateMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        calibrateMarker.map = mapView
        self.mapView.delegate? = self
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
        print("location update")
        let loc: CLLocation = locations.last!
        if isFirstDetection {
            currentMarker.position = loc.coordinate
            calibrateMarker.position = loc.coordinate
            let camera = GMSCameraPosition.camera(withLatitude: loc.coordinate.latitude,
                                                  longitude: loc.coordinate.longitude,
                                                  zoom: 17)
            mapView.animate(to: camera)
            isFirstDetection = false
        }
        alt = loc.altitude
    }
    
    @IBAction func didChangedMapType(_ sender: Any) {
        let seg:UISegmentedControl = sender as! UISegmentedControl
        switch seg.selectedSegmentIndex {
        case 0:
            print("SATELLITE")
            mapView.mapType = .satellite
            break
        case 1:
            print("NORMAL")
            mapView.mapType = .normal
            break
        default:
            break
        }
    }
    
    @IBAction func didChangedSelection(_ sender: Any) {
        let seg:UISegmentedControl = sender as! UISegmentedControl
        switch seg.selectedSegmentIndex {
        case 0:
            print("CURRENT")
            calibrateMarker.isDraggable = false;
            currentMarker.isDraggable = true;
            break
        case 1:
            print("CALIBRATE")
            calibrateMarker.isDraggable = true;
            currentMarker.isDraggable = false;
            break
        default:
            break
        }
    }
    
    @IBAction func didChangedUpdate(_ sender: Any) {
    }
    
    @IBAction func didPushedUpdateNow(_ sender: Any) {
        let currentPosDic:NSMutableDictionary = NSMutableDictionary()
        currentPosDic.setValue(currentMarker.position.latitude, forKey: "latitude")
        currentPosDic.setValue(currentMarker.position.longitude, forKey: "longitude")
        currentPosDic.setValue(self.alt, forKey: "altitude")
        
        let calibratePosDic:NSMutableDictionary = NSMutableDictionary()
        calibratePosDic.setValue(calibrateMarker.position.latitude, forKey: "latitude")
        calibratePosDic.setValue(calibrateMarker.position.longitude, forKey: "longitude")
        
        let receiverSettingDic:NSMutableDictionary = NSMutableDictionary()
        receiverSettingDic.setValue(agcValue, forKey: "AGC")
        receiverSettingDic.setValue(gainValue, forKey: "GAIN")

        let FOVSettingDic:NSMutableDictionary = NSMutableDictionary()
        FOVSettingDic.setValue(fov, forKey: "FOV")
        
        let body:NSMutableDictionary = NSMutableDictionary()
        body.setValue(calibratePosDic, forKey: "calibratePosition")
        body.setValue(currentPosDic, forKey: "currentPosition")
        body.setValue(receiverSettingDic, forKey: "receiverSetting")
        body.setValue(FOVSettingDic, forKey: "fovSetting")
        postPosition(body: body)
    }
    
    func postPosition(body:NSDictionary){
        let urlString = "http://192.168.10.88:5000/calibration"
        do {
            try post(urlString:urlString, body: body as NSDictionary, completionHandler: { data, response, error in
                if data != nil{
                    self.dataPrint(data: data!)
                    let resp_dict = self.dataToJson(d: data!)
                    let resp_code:Int = resp_dict["statusCode"] as! Int
                    
                    if resp_code == 200 {
                        print("SEND SUCESS")
                        DispatchQueue.main.async {
                            self.showAlert(msg: "Success", title: "Calibration data sent.")
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            self.showAlert(msg: "Failed", title: "Calibration data send failed.")
                        }
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.showAlert(msg: "Failed", title: "Server is not responeded.")
                    }
                }
            })
        }
        catch {
            DispatchQueue.main.async {
                self.showAlert(msg: "Failed", title: "error.")
            }
        }
    }
    
    @IBAction func didChangedGain(_ sender: Any) {
        let seg:UISegmentedControl = sender as! UISegmentedControl
        switch seg.selectedSegmentIndex {
        case 0:
            print("AUTO")
            gainValue = "-10"
            break
        case 1:
            print("GAIN MAX")
            gainValue = "MAX"
            break
        case 2:
            print("40db")
            gainValue = "40"
            break
        case 3:
            print("30db")
            gainValue = "30"
           break
        case 4:
            print("20db")
            gainValue = "20"
            break
        default:
            break
        }
    }
    
    @IBAction func didChangedFOV(_ sender: Any) {
        let slider:UISlider = sender as! UISlider
        fov = slider.value
        FOVLabel.text = NSString(format: "%.2f", fov) as String
    }
    
    @IBAction func didChangedAGC(_ sender: Any) {
        let seg:UISegmentedControl = sender as! UISegmentedControl
        switch seg.selectedSegmentIndex {
        case 0:
            print("AGC ON")
            agcValue = true
            break
        case 1:
            print("AGC OFF")
            agcValue = false
            break
        default:
            break
        }
    }
    
    
    func post(urlString: String, body: NSDictionary, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        let url = URL(string: urlString)
        var request: URLRequest = URLRequest(url: url!)
        let session : URLSession = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions.prettyPrinted)
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }

    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        print("DRAG");
    }

    func dataToJson(d:Data) -> Dictionary<String, Any> {
        do {
            dataPrint(data: d)
            let ret = try JSONSerialization.jsonObject(with: d, options: []) as? [String: Any]
            return ret!
        }
        catch{
        }
        return[:]
    }
    
    func showAlert(msg:String, title:String){
        let alertBox: UIAlertController = UIAlertController(title:title, message: msg, preferredStyle:  UIAlertController.Style.alert)
        let okButton: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            print("OK")
        })
        alertBox.addAction(okButton)
        present(alertBox, animated: true, completion: nil)
    }
    
    func dataPrint(data:Data){
        let s: String? = String(data:data, encoding:.utf8)
        print(s)
    }
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        print(marker.userData!)
    }
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        print("START")
    }
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("TAP")
    }
}

