//
//  ClosestViewController.swift
//  BUBusTracker
//
//  Created by Alex Sikand on 10/10/19.
//  Copyright © 2019 AlexSikand. All rights reserved.
//

import UIKit
import SwiftSoup
import CoreLocation
import GoogleMaps
import SkeletonView
import NVActivityIndicatorView

class ClosestViewController: UIViewController {
    
    @IBOutlet weak var mapView1: GMSMapView!
    
    @IBOutlet weak var mapView2: GMSMapView!
    
    @IBOutlet weak var stop1Name: UILabel!
    
    @IBOutlet weak var stop2Name: UILabel!
    @IBOutlet weak var loading1: NVActivityIndicatorView!
    @IBOutlet weak var loading2: NVActivityIndicatorView!
    
    var busStops: [Stop] = []
    
    var toWestStops: [Stop] = []
    var toEastStops: [Stop] = []
    
    
    func BG(_ block: @escaping ()->Void) {
       DispatchQueue.global(qos: .default).async(execute: block)
   }

   func UI(_ block: @escaping ()->Void) {
       DispatchQueue.main.async(execute: block)
   }
    
    var timer = Timer()


    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }

    @objc func updateCounting(){
        getNearestStopEast()
        getNearestStopWest()
    }
    
    @IBOutlet weak var stop1: UILabel!
    @IBOutlet weak var stop2: UILabel!
    
    func getNearestStopWest() {
        var distances = [Double]()
        let currentPos = CLLocation(latitude: 42.350785, longitude: -71.105978)
        if self.toWestStops.isEmpty == false {
            for s in self.toWestStops {
                let busPos = CLLocation(latitude: Double(s.stopLat!)!, longitude: Double(s.stopLong!)!)
                let distance = abs(busPos.distance(from: currentPos))
                distances.append(distance)
            }
            let i = distances.indexOfMin!
            
            let nearestStop = self.toWestStops[i]
            //print(nearestStop)
            stop1Name.text = nearestStop.stopName
            stop1Name.isHidden = false
          
            
            UI() {
                let marker = GMSMarker()
                var pos = CLLocationCoordinate2D(latitude: Double(nearestStop.stopLat!) as! CLLocationDegrees, longitude: Double(nearestStop.stopLong!) as! CLLocationDegrees)
                marker.position = pos
                    marker.map = self.mapView1
                
                    
                self.mapView1.animate(toLocation: pos)
                
                self.getNextDeparture(stop: nearestStop, label: self.stop1, loadingView: self.loading1)
                
                
            }
            
        }
    }
    
    func getNearestStopEast() {
        var distances = [Double]()
        let currentPos = CLLocation(latitude: 42.350785, longitude: -71.105978)
        if self.toEastStops.isEmpty == false {
            for s in self.toEastStops {
                let busPos = CLLocation(latitude: Double(s.stopLat!)!, longitude: Double(s.stopLong!)!)
                let distance = abs(busPos.distance(from: currentPos))
                distances.append(distance)
            }
            let i = distances.indexOfMin!
            let nearestStop = self.toEastStops[i]
            stop2Name.text = nearestStop.stopName
            stop2Name.isHidden = false
            //stop2Name.hideSkeleton()
            
            
            
            //print(nearestStop)
           
            
            UI() {
                let marker = GMSMarker()
                var pos = CLLocationCoordinate2D(latitude: Double(nearestStop.stopLat!) as! CLLocationDegrees, longitude: Double(nearestStop.stopLong!) as! CLLocationDegrees)
                marker.position = pos
                    marker.map = self.mapView2
                    
                self.mapView2.animate(toLocation: pos)
                self.getNextDeparture(stop: nearestStop, label: self.stop2, loadingView: self.loading2)
                
                
                
                
            }
            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //UIApplication.shared.openURL(URL(string:"https://goo.gl/maps/2NZbz7T6CV4h2XZZ6")!)
        loading1.startAnimating()
        loading2.startAnimating()
        
        //stop1.showAnimatedGradientSkeleton()
        //stop1Name.showAnimatedGradientSkeleton()
        
        //stop2.showAnimatedGradientSkeleton()
        //stop2Name.showAnimatedGradientSkeleton()
        
        mapView1.isUserInteractionEnabled = false
        mapView2.isUserInteractionEnabled = false
        
        getStopMapping()
        //getNearestStopEast()
        //getNearestStopWest()
        scheduledTimerWithTimeInterval()
        
        do {
          // Set the map style by passing the URL of the local file.
          if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
            mapView1!.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            mapView2!.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
          } else {
            NSLog("Unable to find style.json")
          }
        } catch {
          NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        mapView1.layer.cornerRadius = 12
        mapView2.layer.cornerRadius = 12
        mapView1.layer.masksToBounds = true
        mapView2.layer.masksToBounds = true
        
        let cam = GMSCameraPosition.camera(withLatitude: 42.349634, longitude: -71.099688, zoom: 13.5)
        
        mapView1.camera = cam
        mapView1.animate(to: cam)
        
        mapView2.camera = cam
        mapView2.animate(to: cam)

        
        
        
        

        // Do any additional setup after loading the view.
    }
    
    
    
    func getStopMapping() {
        if let url = URL(string: "https://www.bu.edu/bumobile/rpc/bus/stops.json.php") {
           URLSession.shared.dataTask(with: url) { data, response, error in
              if let data = data {
                  do {
                    let res = try JSONDecoder().decode(StopData.self, from: data)
                    let stops = res.ResultSet?.Result
                    
                    for s in stops! {
                        if let id = s.stopId {
                            if s.directionId == "1" {
                                self.toEastStops.append(s)
                            }
                            else {
                                self.toWestStops.append(s)
                            }
                            
                            
                           
                            
                        }
                    }
                    
                  } catch let error {
                     print(error)
                  }
               }
           }.resume()
        }
    }
    
    func getNextDeparture(stop: Stop, label: UILabel, loadingView: NVActivityIndicatorView) {
        let times = stop.times
        for t in times {
            print(t)
            let currentDate = Calendar.current.date(byAdding: .hour, value: -4, to: Date())!
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "hh:mm a"
            df.timeZone = .current
            let dateMissing = df.date(from: t)
            //print(currentDate)
            
            
            let calendar = Calendar.current

            let chour = calendar.component(.hour, from: dateMissing!)
            let cminutes = calendar.component(.minute, from: dateMissing!)
            let cseconds = calendar.component(.second, from: dateMissing!)
            let d = calendar.component(.day, from: currentDate)
            let m = calendar.component(.month, from: currentDate)
            let y = calendar.component(.year, from: currentDate)
            
            var dateComponents: DateComponents? = calendar.dateComponents([.day, .month, .year, .hour, .minute], from: Date())
            
            dateComponents?.hour = chour
            dateComponents?.minute = cminutes
            dateComponents?.second = cseconds
            dateComponents?.day = d
            dateComponents?.month = m
            dateComponents?.year = y
            
            //print(y)
            
            let transformedDate: Date? = calendar.date(from: dateComponents!)
            
            //print(transformedDate! > currentDate)
            
            if transformedDate! > currentDate {
               // print("Found next departure")
               // print(currentDate)
               // print(transformedDate)
                label.text = String(Int(round(transformedDate!.timeIntervalSince(currentDate) / 60.0))) + " min"
                label.isHidden = false
                loadingView.stopAnimating()
                //label.hideSkeleton()
                break
            }
            
            
           
            
           // print("Current")
           // print(currentDate)
           // print("Time")
           // print(transformedDate)
        }
    }
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
