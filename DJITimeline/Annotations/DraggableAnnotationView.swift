//
//  DraggableAnnotationView.swift
//  Drone
//
//  Created by Pavana KC on 9/29/17.
//  Copyright © 2017 Pavana KC. All rights reserved.
//

import UIKit
import Mapbox

protocol DraggableAnnotationViewDelegate: class {
    func draggableAnnotationViewDidBeginDragging(annotationView: DraggableAnnotationView)
    func draggableAnnotationViewDidEndDragging(annotationView: DraggableAnnotationView)
    func draggableAnnotationViewIsBeingDragged(annotationView: DraggableAnnotationView, to location : CGPoint) -> Bool
    func willSelectAnnotation()
}

extension DraggableAnnotationViewDelegate {
    func draggableAnnotationViewDidBeginDragging(annotationView: DraggableAnnotationView) {}
    func draggableAnnotationViewDidEndDragging(annotationView: DraggableAnnotationView) {}
    func draggableAnnotationViewIsBeingDragged(annotationView: DraggableAnnotationView, to location : CGPoint) -> Bool { return false }
    func willSelectAnnotation() {}
}

class DraggableAnnotationView: MGLAnnotationView {
    
    weak var delegate: DraggableAnnotationViewDelegate?
    
    init(reuseIdentifier: String?, size: CGFloat, title: String) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        // `isDraggable` is a property of MGLAnnotationView, disabled by default.
        isDraggable = true
        
        // This property prevents the annotation from changing size when the map is tilted.
        scalesWithViewingDistance = false
    }
    
    // These two initializers are forced upon us by Swift.
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Custom handler for changes in the annotation’s drag state.
    override func setDragState(_ dragState: MGLAnnotationViewDragState, animated: Bool) {
        super.setDragState(dragState, animated: animated)
        
        switch dragState {
        case .starting:
            startDragging()
            delegate?.draggableAnnotationViewDidBeginDragging(annotationView: self)
        case .dragging:
            break
        case .ending, .canceling:
            endDragging()
            delegate?.draggableAnnotationViewDidEndDragging(annotationView: self)
        case .none:
            return
        }
    }
    
    // When the user interacts with an annotation, animate opacity and scale changes.
    func startDragging() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 0.8
            self.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        }, completion: nil)
    }
    
    func endDragging() {
        transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 1
            self.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
        }, completion: nil)
    }
}
