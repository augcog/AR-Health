//
//  OverlayController.swift
//  ARHealth
//
//  Created by Daniel Won on 5/20/21.
//  Copyright © 2021 Daniel Won. All rights reserved.
//

import UIKit

class FirstTutorialViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func closeFirstTutorialOverlay(_ sender: Any) {
        self.view.isHidden = true
        self.view.layer.zPosition = -1
        self.removeFromParent()
    }
}
