//
//  LogController.swift
//  DJITimeline
//
//  Created by Pavana KC on 17/08/18.
//  Copyright © 2018 Pavana KC. All rights reserved.
//

import UIKit

class LogController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textView.text = logText
    }

    @IBAction func onBack() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onClear() {
       logText = ""
        textView.text = logText
    }
    
    @IBAction func onScrollToBottom() {
        let bottom = NSMakeRange(textView.text.count - 1, 1)
        textView.scrollRangeToVisible(bottom)
    }
}
