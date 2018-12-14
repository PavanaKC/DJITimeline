//
//  PreviewController.swift
//  DJITimeline
//
//  Created by Pavana KC on 06/12/18.
//  Copyright © 2018 Pavana KC. All rights reserved.
//

import UIKit
import DJISDK

class PreviewController: UIViewController {

    @IBOutlet weak var previewView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FlightManager.shared.setupVideoPreviewer(forView: previewView)
    }

    //MARK: UIButton Action methods
    @IBAction func onClose() {
        dismiss(animated: true, completion: nil)
    }
}


