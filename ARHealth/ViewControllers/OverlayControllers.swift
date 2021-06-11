//
//  OverlayController.swift
//  ARHealth
//
//  Created by Daniel Won on 5/20/21.
//  Copyright © 2021 Daniel Won. All rights reserved.
//

import UIKit

class FirstTutorialViewController: UIViewController {
//    func showOverlay(from parentVC: UIViewController) {
//        let desc = UILabel()
//        let icon = UIImageView()
//        let closeBtn = UIButton()
//
//        let parentFrame = parentVC.view.bounds
//        let frameW = parentFrame.width
//        let frameH = parentFrame.height
//        let centerX = frameW / 2
//
//        // View
//        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.75)
//        overlay.frame = parentFrame
//        overlay.isUserInteractionEnabled = true
//
//        // Label
//        desc.frame = CGRect(x: centerX, y: frameH / 2, width: 317, height: 194)
//        desc.text = "Move your device to a find an AR surface"
//        desc.textAlignment = .center
//        desc.numberOfLines = 3
//        desc.font = UIFont(name: "Montserrat Bold", size: 26)
//
//        // Icon
//        let iconWidth = CGFloat(min(243, 0.5*frameW))
//        let iconHeight = iconWidth*142/243
//        let iconY = desc.frame.minY - iconHeight*0.1
//        icon.image = UIImage(named: "vr-20-512 1.png")
//        icon.frame = CGRect(x: centerX, y: iconY, width: iconWidth, height: iconHeight)
//        icon.contentMode = .scaleAspectFit
//
//        // Button
//        let btnY = (frameH + desc.frame.maxY) / 2
//        closeBtn.frame = CGRect(x: centerX, y: btnY, width: 80, height: 80)
//        closeBtn.setBackgroundImage(UIImage(named: "CheckButton.png"), for: .normal)
//        closeBtn.addTarget(self, action: #selector(closeOverlay(_:)), for: .touchUpInside)
//
//        overlay.addSubview(desc)
//        overlay.addSubview(icon)
//        overlay.addSubview(closeBtn)
//        view.addSubview(overlay)
//    }
    
    @IBAction func closeOverlay(_ sender: UIButton) {
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0.0
        })
        
        let parent = self.parent as? ViewController
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
        
        parent?.onboardNewUser()
    }
}
 
