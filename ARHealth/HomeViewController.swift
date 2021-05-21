//
//  HomeViewController.swift
//  ARHealth
//
//  Created by Daniel Won on 5/20/21.
//  Copyright © 2021 Daniel Won. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signInButton.layer.cornerRadius = 25
    }
    
    @IBAction func signIn(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(identifier: "mainVC") as? ViewController else {
            return
        }
//        present(vc, animated: true)
//        show(vc, sender:self)
    self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
