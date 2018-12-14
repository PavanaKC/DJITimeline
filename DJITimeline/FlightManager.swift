//
//  FlightManager.swift
//  DJITimeline
//
//  Created by Pavana KC on 21/06/18.
//  Copyright © 2018 Pavana KC. All rights reserved.
//

import Foundation
import DJISDK
import VideoPreviewer

protocol FlightManagerDelegate: class {
    func updateFlightLocation(coordinates: CLLocationCoordinate2D, headingAngle: CGFloat)
}

class FlightManager: NSObject {
    
    static let shared = FlightManager()
    var missionCoordinate: CLLocationCoordinate2D? = nil
    private var timelineActions = [DJIMissionControlTimelineElement]()
    private var areMotorsOn = false
    private var isFlying = false
    
    weak var delegate: FlightManagerDelegate?
    
    enum DefaultCameraSettings {
        case none
        case normalMode
        
        var focus: DJICameraFocusMode {
            return .AFC
        }
        
        var aspectRatio: DJICameraPhotoAspectRatio {
            return .ratio16_9
        }
    }
    
    private var videoPreviewer: VideoPreviewer {
        return VideoPreviewer.instance()
    }
    
    func setUp() {
        DJISDKManager.appActivationManager().delegate = self
        DJISDKManager.registerApp(with: self)
    }
    
    private var product: DJIBaseProduct? {
        guard let product = DJISDKManager.product() else {
            logText += "\n Product is nil"
            return nil
        }
        logText += "\n Product is \(product)"
        return product
    }
    
    private var aircraft: DJIAircraft? {
        guard let product = self.product else { return nil }
        guard let aircraft = product as? DJIAircraft else { return nil }
        return aircraft
    }
    
    private var camera: DJICamera? {
        guard let aircraft = self.aircraft,
            let camera = aircraft.camera else {
                return nil
        }
        return camera
    }
    
    private var flightController: DJIFlightController? {
        guard let aircraft = self.aircraft else {
            return nil
        }
        
        if aircraft.flightController?.delegate == nil {
            aircraft.flightController?.delegate = self
        }
        
        return aircraft.flightController
    }
    
    private func checkForConnection() {
        // To enable flight controller delegate to get the flight status
        if flightController?.delegate == nil {
            flightController?.delegate = self
        }
        
        setCameraMode()
    }
    
    private func setCameraMode() {
        self.camera?.setPhotoAspectRatio(DefaultCameraSettings.normalMode.aspectRatio, withCompletion: { (error) in
            guard error == nil else {
                logText += "\n setPhotoAspectRatio: \(String(describing: error?.localizedDescription))"
                return
            }
            logText += "\n setPhotoAspectRatio"
        })
    }
    
    func createTimeline() {
        guard let coordinate = missionCoordinate else { return }
        let goToAction = DJIGoToAction(coordinate: coordinate, altitude: 30) // altitude is 100 mtrs
        
        let gimbalAction1 = DJIGimbalAttitudeAction(attitude: DJIGimbalAttitude(pitch: -90.0, roll: 0, yaw: 0))
        
        // DJIShootPhotoAction works if there is SD card available in the drone
        // The captured photo can be read from SD card
        let shootPhotoAction = DJIShootPhotoAction()
        
        let gimbalAction2 = DJIGimbalAttitudeAction(attitude: DJIGimbalAttitude(pitch: 0, roll: 0, yaw: 0))

        let returmHomeAction = DJIGoHomeAction()
        
        timelineActions = [goToAction, gimbalAction1, shootPhotoAction, gimbalAction2, returmHomeAction] as! [DJIMissionControlTimelineElement]
        
        checkForConnection()
        
        runMission(timelineElements: timelineActions)
    }
    
    private func runMission(timelineElements: [DJIMissionControlTimelineElement]) {
        
        // Validate parameters
        logText += "\n validate timeline elements"
        for element in timelineElements {
            let action: DJIMissionControlTimelineElement = element
            let missionError = action.checkValidity()
            if let error = missionError {
                logText += "error: \(error.localizedDescription) for element: \(element)"
                return
            }
        }
        
        logText += "\n validation success"
        
        if !isFlying {
            logText += "\n isFlying: \(isFlying)"
            //reset timeline before starting a new one
            logText += "\n stop timeline"
            DJISDKManager.missionControl()?.removeAllListeners()
            DJISDKManager.missionControl()?.stopTimeline()

            if areMotorsOn == false {
                logText += "\n areMotorsOn: \(areMotorsOn)"
                flightController?.turnOffMotors(completion: { (error) in
                    guard error == nil else { return }

                    logText += "\n Motors off"
                    self.addListenerForTimelineUpdates()

                    self.startTakeoff(completion: { (error) in
                        guard error == nil else { return }
                        logText += "\n start timeline"
                        DJISDKManager.missionControl()?.scheduleElements(timelineElements)
                        DJISDKManager.missionControl()?.startTimeline()
                    })
                })
            } else {
                startTakeoff(completion: { (error) in
                    guard error == nil else { return }
                    logText += "\n start timeline"
                    DJISDKManager.missionControl()?.scheduleElements(timelineElements)
                    DJISDKManager.missionControl()?.startTimeline()
                })
            }
        }
    }
    
    private func startTakeoff(completion: @escaping (Error?) -> ()) {
        flightController?.startTakeoff(completion: { (error) in
            guard error == nil else {
                completion(error)
                return
            }
            
            logText += "\n start take off"
            
            // NOTE: Take off completion is returned in mid of execution as per the documentation
            // For now adding extra delay so that takeoff can complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                completion(error)
            })
        })
    }
}

extension FlightManager: DJISDKManagerDelegate {
    func appRegisteredWithError(_ error: Error?) {
        guard error == nil else {
            logText += "App registration failed: \(String(describing: error))"
            return
        }
        establishConnection()
        logText += "\n app registered"
    }
    
    @objc public func establishConnection() {
        logText += "\n connection initiated"
        DJISDKManager.appActivationManager().delegate = self
        DJISDKManager.startConnectionToProduct()
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        logText += "\n Product connected"
        self.checkForConnection()
    }
    
    func productDisconnected() {
        logText += "\n Product disconnected"
    }
}

extension FlightManager: DJIFlightControllerDelegate {
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        areMotorsOn = state.areMotorsOn
        isFlying = state.isFlying
        let headingAngle = CGFloat(state.attitude.yaw * .pi / 180.0)
        
        if let location = state.aircraftLocation {
            delegate?.updateFlightLocation(coordinates: location.coordinate, headingAngle: headingAngle)
        }
    }
}

extension FlightManager: DJIAppActivationManagerDelegate {
    
    func manager(_ manager: DJIAppActivationManager!, didUpdate appActivationState: DJIAppActivationState) {
        logText += "\n appActivationState \(appActivationState.rawValue)"
    }
    
    func manager(_ manager: DJIAppActivationManager!, didUpdate aircraftBindingState: DJIAppActivationAircraftBindingState) {
        logText += "\n aircraftBindingState \(aircraftBindingState.rawValue)"
    }
}

extension FlightManager {
    func addListenerForTimelineUpdates() {
        
        DJISDKManager.missionControl()?.addListener(self, toTimelineProgressWith: { (event, element, error, info) in
            guard error == nil else { return }
            
            logText += "### \n\n Event: \(event.rawValue) \n Element:\(String(describing: element)) \n Error: \(String(describing: error)) \n Info: \(String(describing: info)) \n\n "
            
            //once event is finished, stop the timeline and initiate return home
            if event.rawValue == DJIMissionControlTimelineEvent.finished.rawValue && element == nil {
                logText += "DJIMissionControlTimelineEvent.finished, stop timeline and remove listeners"
                DJISDKManager.missionControl()?.removeAllListeners()
                DJISDKManager.missionControl()?.stopTimeline()
            }
            
            
        })
    }
}

extension FlightManager: DJIVideoFeedListener {
    func setupVideoPreviewer(forView view: UIView) {
        // Reset previous previewer
        resetVideoPreviewer()
        
        videoPreviewer.setView(view)
        videoPreviewer.enableHardwareDecode = true
        currentVideoFeed()?.add(self as DJIVideoFeedListener, with: nil)
        videoPreviewer.start()
    }
    
    func resetVideoPreviewer() {
        currentVideoFeed()?.remove(self as DJIVideoFeedListener)
        DJISDKManager.videoFeeder()?.removeAllListeners()
        videoPreviewer.reset()
        videoPreviewer.unSetView()
        videoPreviewer.close()
        videoPreviewer.clearVideoData()
    }
    
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        videoData.withUnsafeBytes {  (pointer: UnsafePointer<UInt8>) in
            VideoPreviewer.instance().push( UnsafeMutablePointer(mutating: pointer), length: Int32(videoData.count))
        }
    }
    
    private func currentVideoFeed() -> DJIVideoFeed? {
        let model = DJISDKManager.product()?.model
        if (model  == DJIAircraftModelNameA3 ||
            model == DJIAircraftModelNameN3 ||
            model == DJIAircraftModelNameMatrice600 ||
            model == DJIAircraftModelNameMatrice600Pro) {
            return DJISDKManager.videoFeeder()?.secondaryVideoFeed
        }
        
        return DJISDKManager.videoFeeder()?.primaryVideoFeed
    }
}

