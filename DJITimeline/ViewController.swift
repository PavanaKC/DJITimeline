//
//  ViewController.swift
//  DJITimeline
//
//  Created by Pavana KC on 21/06/18.
//  Copyright © 2018 Pavana KC. All rights reserved.
//

import UIKit
import Mapbox

var logText = ""

class ViewController: UIViewController {

    @IBOutlet weak var mapViewContainer: UIView!
    @IBOutlet weak var startMissionBtn: UIButton!
    
    private let locationManager = CLLocationManager()
    private var aircraftAnnotation = AircraftAnnotation()
    private var mapView = MGLMapView()
    var selectedLocationCoordinates: CLLocationCoordinate2D? = nil
    let flightManager = FlightManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flightManager.setUp()
        flightManager.delegate = self
        enableStartMission(shouldEnable: false)
        setupMapView()
    }
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        selectedLocationCoordinates = coordinate
        addAnnotationOnMap(coordinate: coordinate)
    }
    
    //MARK: Private functions
    private func setupMapView() {
        mapView = MGLMapView(frame: mapViewContainer.frame)
        mapView.delegate = self
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.styleURL = MGLStyle.streetsStyleURL()
        mapViewContainer.addSubview(mapView)
        addGesture()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    private func addGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    private func addAnnotationOnMap(coordinate: CLLocationCoordinate2D) {
        //reset previous annotation if any
        if let annotations = mapView.annotations, !annotations.isEmpty {
            for eachAnnotation in annotations {
                if eachAnnotation.title != "aircraft" {
                    mapView.removeAnnotation(eachAnnotation)
                }
            }
        }
        
        let myAnnotation = MGLPointAnnotation()
        myAnnotation.coordinate = coordinate
        myAnnotation.title = "Downshot"
        mapView.addAnnotation(myAnnotation)
        enableStartMission(shouldEnable: true)
    }
    
    private func enableStartMission(shouldEnable: Bool) {
        if shouldEnable {
            startMissionBtn.isEnabled = true
            startMissionBtn.alpha = 1.0
        } else {
            startMissionBtn.isEnabled = false
            startMissionBtn.alpha = 0.5
        }
    }
    
    //MARK: UIButton Action methods
    @IBAction func onStartTimeline() {
        flightManager.missionCoordinate = selectedLocationCoordinates
        flightManager.createTimeline()
    }
    
    @IBAction func onViewLog() {
        if let logController = storyboard?.instantiateViewController(withIdentifier: "LogController") {
            present(logController, animated: true, completion: nil)
        }
    }
    
    @IBAction func onPreview() {
        if let previewController = storyboard?.instantiateViewController(withIdentifier: "PreviewController") {
            present(previewController, animated: true, completion: nil)
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        mapView.setCenter(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), zoomLevel: 15, animated: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

extension ViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if (annotation is MGLUserLocation) { return nil }
        
        guard annotation is MGLPointAnnotation else {  return nil }
        
        return nil
    }
}

extension ViewController: FlightManagerDelegate {
    func updateFlightLocation(coordinates: CLLocationCoordinate2D, headingAngle: CGFloat) {
        aircraftAnnotation.coordinate = coordinates
        aircraftAnnotation.title = "aircraft"
        mapView.addAnnotation(aircraftAnnotation)
        aircraftAnnotation.updateHeading(headingAngle)
    }
}
