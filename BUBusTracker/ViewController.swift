//
//  ViewController.swift
//  BUBusTracker
//
//  Created by Alex Sikand on 10/9/19.
//  Copyright © 2019 AlexSikand. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation

struct SnappedPointsData: Codable {
    let snappedPoints: [Point]
}

struct Point: Codable {
    let location: Location?
}

struct Location: Codable {
    let longitude: Double
    let latitude: Double
}

struct BusData: Codable { // or Decodable
    let service: String?
    let ResultSet: BusResultSet?
    let totalResultsAvailable: Int?
}

//Main response from https://www.bu.edu/bumobile/rpc/bus/livebus.json.php
struct StopData: Codable { // or Decodable
    let ResultSet: StopResultSet?
}


//Contains info on all the running buses
struct BusResultSet: Codable {
    let Result: [Bus]?
}

struct StopResultSet: Codable {
    let Result: [Stop]?
}

struct Stop: Codable {
    let stopId: String?
    let stopCode: String?
    let stopName: String?
    let stopDesc: String?
    let stopLong: String?
    let stopLat: String?
    let directionId: String?
    let times: [String]
    
    enum CodingKeys: String, CodingKey {
        case stopCode = "stop_id"
        case stopId = "transloc_stop_id"
        case stopName = "stop_name"
        case stopDesc = "stop_desc"
        case stopLong = "stop_lon"
        case stopLat = "stop_lat"
        case directionId = "direction_id"
        case times
    }
    
}

//Represents an arrival estimate for a particular bus
struct Estimate: Codable {
    let routeId: String?
    let stopId: String?
    let arrivalTime: String?
    
    enum CodingKeys: String, CodingKey {
        case routeId = "route_id"
        case stopId = "stop_id"
        case arrivalTime = "arrival_at"
    }
    
}

//Represents a BU Bus
struct Bus: Codable {
    let id: String?
    let busNumber: String?
    let heading: String?
    let generalHeading: Int?
    let speed: String?
    let timestamp: String?
    let route: String?
    let longitude: String?
    let latitude: String?
    let arrivalEstimates: [Estimate]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case busNumber = "call_name"
        case longitude = "lng"
        case latitude = "lat"
        case heading
        case generalHeading = "general_heading"
        case speed
        case timestamp
        case route
        case arrivalEstimates = "arrival_estimates"
    }
}

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var labelView: UILabel!
    
    var busStops: [Stop] = []
    
    let locationManager = CLLocationManager()
    
    var mapView : GMSMapView?
    @IBOutlet weak var mapViewAlt: GMSMapView!
    
    var commLoopStops = ["E1", "E2", "E3", "E4", "E5", "E6", "E7"]
    var crcMedStops = ["M7", "C1", "C2", "M6", "M5", "C4", "C3", "M3", "M4", "C5", "C6", "M2", "C7", "C8"]
    
    func BG(_ block: @escaping ()->Void) {
        DispatchQueue.global(qos: .default).async(execute: block)
    }

    func UI(_ block: @escaping ()->Void) {
        DispatchQueue.main.async(execute: block)
    }
    
    @IBAction func resetView(_ sender: Any) {
         let commLoop = GMSCameraPosition.camera(withLatitude: 42.350313, longitude: -71.106534, zoom: 15.8, bearing: 278 as CLLocationDirection, viewingAngle: 50)
        mapViewAlt.animate(to: commLoop)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!,
        longitude: (location?.coordinate.longitude)!,
        zoom: 15.0)
        //mapViewAlt.camera = camera
        //mapViewAlt.animate(to: camera)
        
        let currentLong = location?.coordinate.longitude
        let currentLat = location?.coordinate.latitude
        //let currentPos = CLLocation(latitude: currentLat!, longitude: currentLong!)
        
        

        
    }


    func formatBusData(busList: [Bus]) {
        for b in busList {
            print("\n")
            print("ID: " + (b.id ?? ""))
            print("Bus Number: " + (b.busNumber ?? ""))
            print("Route: " + (b.route ?? ""))
            print("Longitude: " + (b.longitude ?? ""))
            print("Latitude: " + (b.latitude ?? ""))
            print("Last Updated: " + b.timestamp!)
            print("")
            
           // if b.route != "fen" {
                UI() {
                    
                    
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: Double(b.latitude!) as! CLLocationDegrees, longitude: Double(b.longitude!) as! CLLocationDegrees)
                    marker.title = "Bus " + b.busNumber!
                    if let nextStop = b.arrivalEstimates?[0] {
                        let df = DateFormatter()
                        df.locale = Locale(identifier: "en_US_POSIX")
                        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                        df.timeZone = .current
                        let date = df.date(from: nextStop.arrivalTime!)
                        let minutesUntilArrival = String(Int(round(date!.timeIntervalSinceNow / 60.0)))
                        //var formatRoute = "\n" + b.route!
                        //print(self.stopMapping)
                        marker.snippet = "Next Stop: " + self.stopMapping[nextStop.stopId!]! + " in " + minutesUntilArrival + " min"
                        marker.icon = UIImage(named: "busicon")
                        //marker.rotation = Double(278) as! CLLocationDegrees
                        marker.map = self.mapViewAlt
                    }
                    
                }
           // }
    }
    }
    


    func getBusData() {
        if let url = URL(string: "https://www.bu.edu/bumobile/rpc/bus/livebus.json.php") {
           URLSession.shared.dataTask(with: url) { data, response, error in
              if let data = data {
                  do {
                    let res = try JSONDecoder().decode(BusData.self, from: data)
                    self.formatBusData(busList: (res.ResultSet?.Result)!)
                  } catch let error {
                     print(error)
                  }
               }
           }.resume()
        }
    }

    var stopMapping: [String: String] = [:]

    func getStopMapping() {
        if let url = URL(string: "https://www.bu.edu/bumobile/rpc/bus/stops.json.php") {
           URLSession.shared.dataTask(with: url) { data, response, error in
              if let data = data {
                  do {
                    let res = try JSONDecoder().decode(StopData.self, from: data)
                    let stops = res.ResultSet?.Result
                    
                    for s in stops! {
                        if let id = s.stopId {
                            self.busStops.append(s)
                            self.stopMapping[s.stopId!] = s.stopName
                            
                        }
                    }
                    self.plotStops(stops: stops!)
                  } catch let error {
                     print(error)
                  }
               }
           }.resume()
        }
    }
    
    func plotStops(stops: [Stop]) {
        for s in stops {
            if crcMedStops.contains(s.stopCode!) {
                UI() {
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: Double(s.stopLat!) as! CLLocationDegrees, longitude: Double(s.stopLong!) as! CLLocationDegrees)
                    marker.title = s.stopName
                    marker.icon = UIImage(named: "stop")
                    marker.snippet = s.stopDesc
                    marker.map = self.mapViewAlt
                }
            }
        }
    }


    //Generate the mapping between stopIds and stopNames

    
    
    
    

    
    func getPoints() {
        /*
        let url : NSString = "https://roads.googleapis.com/v1/snapToRoads?path=42.353155,-71.118162|42.352259,-71.115550|42.351005,-71.115716|42.348928, -71.098420|42.348815, -71.092865|42.346927, -71.092389|42.344988, -71.090746|42.344000, -71.090245|42.343323, -71.085838|42.334017, -71.074109|42.340750, -71.082091|42.335884, -71.070119|42.333614, -71.073590|42.334034, -71.072689|42.335886, -71.070114|42.337476, -71.071906|42.338789, -71.073462|42.338638, -71.074020|42.337984, -71.075002|42.336596, -71.076901|42.337341, -71.077888|42.339244, -71.080189|42.340770, -71.081869|42.343323, -71.085705|42.345198, -71.086660|42.347248, -71.087669|42.348854, -71.088474|42.350801, -71.089407|42.350309, -71.091580|42.349857, -71.093238|42.349076, -71.096140|42.349104, -71.097985|42.349606, -71.102113|42.349980, -71.105055|42.350487, -71.109239|42.351018, -71.113831|42.351565, -71.118477|42.353155,-71.118162&interpolate=true&key=AIzaSyBzptVTFLqRLulLKI3Yycfunl0ggBNjMg0"*/
        let url: NSString = "https://roads.googleapis.com/v1/snapToRoads?path=42.352649, -71.118285|42.353599, -71.118075|42.353179, -71.116766|42.3513977, -71.1157539|42.3509757, -71.1155695|42.3506796, -71.1131444|42.3504566, -71.1112789|42.3501340, -71.1085387|42.3497782, -71.1056681|42.3493413, -71.1021490|42.3489897, -71.0989988|42.3488844, -71.0981931|42.348970, -71.098035|42.349089, -71.098185|42.349480, -71.101021|42.350169, -71.106826|42.350795, -71.112029|42.351160, -71.115097|42.351541, -71.118498|42.352649, -71.118285&interpolate=true&key=AIzaSyBzptVTFLqRLulLKI3Yycfunl0ggBNjMg0"
        let urlStr : NSString = url.addingPercentEscapes(using: String.Encoding.utf8.rawValue)! as NSString
        //let searchURL : NSURL = NSURL(string: urlStr as String)!
        
        if let url = URL(string: urlStr as String) {
           URLSession.shared.dataTask(with: url) { data, response, error in
              if let data = data {
                  do {
                    let res = try JSONDecoder().decode(SnappedPointsData.self, from: data)
                    self.renderPath(points: res.snappedPoints)
                  } catch let error {
                     print(error)
                  }
               }
           }.resume()
        }
    }
    
    
    
    func renderPath(points: [Point]) {
        UI() {
        let path = GMSMutablePath()
        for p in points {
            path.add(CLLocationCoordinate2D(latitude: p.location!.latitude, longitude: p.location!.longitude))
        }
        let polyline = GMSPolyline(path: path)
            polyline.strokeWidth = 4
            polyline.strokeColor = .red
        polyline.map = self.mapViewAlt
            
        }
    }

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        
        do {
          // Set the map style by passing the URL of the local file.
          if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
            mapViewAlt!.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
          } else {
            NSLog("Unable to find style.json")
          }
        } catch {
          NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        //view = mapView
        
        let cam = GMSCameraPosition.camera(withLatitude: 42.350313, longitude: -71.106534, zoom: 15.8, bearing: 278 as CLLocationDirection, viewingAngle: 50)
        
        
       
        
        getStopMapping()

        getBusData()
        
        getPoints()
        
        mapViewAlt.camera = cam
        mapViewAlt.animate(to: cam)

        //mapViewAlt.settings.compassButton = true
        //mapViewAlt.settings.myLocationButton = true
    }
    
    
        
        
        
    }



extension Array where Element: Comparable {
   var indexOfMin: Index? {
      guard var minValue = self.first else { return nil }
      var minIndex = 0

      for (index, value) in self.enumerated() {
         if value < minValue {
            minValue = value
            minIndex = index
         }
     }

     return minIndex
   }
}

