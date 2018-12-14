//
//  AircraftAnnotationView.swift
//  Drone
//
//  Created by Pavana KC on 10/3/17.
//  Copyright © 2017 Pavana KC. All rights reserved.
//

import Foundation
import Mapbox

class AircraftAnnotationView: DraggableAnnotationView {
    
    private var annotationImageView: UIImageView = UIImageView()
    
    init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier, size: 30, title: "")
        let image = #imageLiteral(resourceName: "icn_drone")
        frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        
        scalesWithViewingDistance = false
        isDraggable = false

        annotationImageView.image = image
        annotationImageView.frame.size = image.size
        annotationImageView.center = self.center
        self.addSubview(annotationImageView)
    }
    
    // These two initializers are forced upon us by Swift.
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateHeading(_ heading: CGFloat) {
        annotationImageView.transform = CGAffineTransform.identity
        annotationImageView.transform = CGAffineTransform(rotationAngle: heading)
    }
}

class AircraftAnnotation: MGLPointAnnotation {
    
    var annotationView: AircraftAnnotationView?
    
    func updateHeading(_ heading: CGFloat) {
        annotationView?.updateHeading(heading)
    }
}
