//
//  ViewController.swift
//  PracticeDragonPlacement
//
//  Created by Daniel Won on 2/23/21.
//  Copyright © 2021 Daniel Won. All rights reserved.
//

import UIKit
import ARKit
import RealityKit
import AVFoundation
import Foundation

class ViewController: UIViewController, ARSessionDelegate, UITextFieldDelegate {
    // MARK: - UI Elements
    @IBOutlet var arView: ARView!
    
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var decorationModeButton: UIButton!
    @IBOutlet weak var placeButton: UIButton!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var placeBoundaryButton: UIButton!
    
    @IBOutlet weak var scanningView: UIView!
    @IBOutlet weak var loadingView: UIStackView!
    
    @IBOutlet weak var gardenCreatorView: UIView!
    @IBOutlet weak var gardenCreatorIcon: UIImageView!
    @IBOutlet weak var gardenCreatorButton: UIButton!
    @IBOutlet weak var gardenCreatorInput: UITextField!
    @IBOutlet weak var gardenCreatorButton2: UIButton!
    @IBOutlet weak var nextDecorButton: UIButton!
    
    var onboardIndex: Int = 0
    
    
    var virtualPetAnchors: [AnchorEntity] = []
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    // MARK: - Save & Load Variables
    var worldName: String = ""
    var gameName: String = "dragon-game"
    var saveFileExtension: String = ".arexperience"
    var initLock = NSLock()
    
    var currentObjectIndex: Int = 0
    
    // MARK: - State Variables
    var isInDecorationMode: Bool = false
    var isInitializingDragon: Bool = false
    var isInMovementMode: Bool = false
    var worldHasBeenSaved: Bool = false
    var isCreatingNewWorld: Bool = false
    var isRelocalizing: Bool = false
    var worldHasLoaded: Bool = false
    var useRaycast: Bool = false
    var canPlaceDragon: Bool = false
    
    var isFirstOverlayClosed: Bool = false
    var isScanningWorld: Bool = false
    var scanningIndex: Int = 0
    
    // MARK: - Camera Variables
    var cameraTransform: simd_float4x4 = simd_float4x4.init()
    var cameraAnchor: AnchorEntity = AnchorEntity(plane: .horizontal)
    
    // MARK: - Garden Variables
    var gardenBoundaryPoints: [SIMD3<Float>] = []
    var gardenAnchor: Entity = AnchorEntity(world: SIMD3<Float>(0,0,0))
    var groundPoint: SIMD3<Float> = SIMD3<Float>(0,0,0)
    var placementStep = 0
    var boundaryTimer = Timer()
    var originEntity: Entity = AnchorEntity(world: SIMD3<Float>(0,0,0))
    
    // MARK: - View Life Cycle
    
    // Allows user to auto-rotate phone
    override var shouldAutorotate: Bool {
        return false
    }
    
    // View is loaded into memory
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareMainScene()
        arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        placeBoundaryButton.setTitle("Set Ground", for: .normal)
        debugLabel.text = "\(self.children.count)"
//        self.runSession()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @IBOutlet weak var gardenCreatorViewConstraint: NSLayoutConstraint!
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           // if keyboard size is not available for some reason, dont do anything
           return
        }
      
      // move the root view up by the distance of keyboard height
//        self.gardenCreatorView.bottomAnchor. -= keyboardSize.height
        
        UIView.animate(withDuration: 1, animations: {
            self.gardenCreatorView.frame.origin.y = self.view.frame.height - self.gardenCreatorView.frame.height - keyboardSize.height
        })
        
        gardenCreatorViewConstraint.constant = keyboardSize.height
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
      // move back the root view origin to zero
      UIView.animate(withDuration: 1, animations: {
          self.gardenCreatorView.frame.origin.y = self.view.frame.height - self.gardenCreatorView.frame.height - 36
      })
        
        self.gardenCreatorViewConstraint.constant = 36
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.isUserInteractionEnabled = true
//        let tapGesture = UITapGestureRecognizer(target: self, action: Selector(("handleTap")))
//        self.view.addGestureRecognizer(tapGesture)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
//        self.decorationModeButton.isHidden = true
        
//        let isOverlayClosed = firstTutorialOverlay.isHidden
//        placeButton.isHidden = !isOverlayClosed
//        placeBoundaryButton.isHidden = !isOverlayClosed
//        debugLabel.isHidden = !isOverlayClosed
//        sessionInfoView.isHidden = !isOverlayClosed
//        statusLabel.isHidden = !isOverlayClosed
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }

// MARK: - Delegate functions
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if isScanningWorld {
            isFirstOverlayClosed = true
            scanningView.isHidden = false
            
            if (frame.worldMappingStatus == .mapped && frame.camera.trackingState.description == "Normal") {
                isScanningWorld = false
                onboardUser()
            } else {
                for index in 0...2 {
                    let delay = 0.25*Double(index)
                    UIView.animate(withDuration: 1, delay: delay, options: [UIView.AnimationOptions.repeat, UIView.AnimationOptions.autoreverse, UIView.AnimationOptions.curveEaseInOut], animations: {
                        self.loadingView.arrangedSubviews[index].alpha = 1.0
                    }, completion: nil)
                }
            }
        }
        
        statusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        Tracking: \(frame.camera.trackingState.description)
        """
        
        let transform = frame.camera.transform.columns.3
        self.cameraTransform = float4x4(SIMD4<Float>(1, 0, 0, 0), SIMD4<Float>(0, 1, 0, 0), SIMD4<Float>(0, 0, 1, 0), SIMD4<Float>(transform.x, transform.y, transform.z, 1))
        
        let position = Transform(matrix: frame.camera.transform)
        self.cameraAnchor.transform = position
        
        debugLabel.text="""
            y: \(round(self.cameraAnchor.transform.translation.y*100)/100.0)
            z: \(round(self.cameraAnchor.transform.translation.z*100)/100.0)
            """
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState.description {
        case "Relocalizing":
            self.isRelocalizing = true
        default:
            if self.isRelocalizing && !self.worldHasLoaded {
                self.worldHasLoaded = true
//                enterMainScene()
            }
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        sessionInfoLabel.text = "Session interrupted."
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        sessionInfoLabel.text = "Session interruption ended."
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        guard error is ARError else { return }

        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]

        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")

        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.arView.session.run(self.defaultConfiguration, options: [.resetTracking, .removeExistingAnchors])
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Saving and Loading
    
    func getSaveURL(name: String) -> URL {
        return {
            do {
                return try FileManager.default
                    .url(for: .documentDirectory,
                         in: .userDomainMask,
                         appropriateFor: nil,
                         create: true)
                    .appendingPathComponent(name + saveFileExtension)
            } catch {
                fatalError("Can't get file save URL: \(error.localizedDescription)")
            }
        }()
    }
    
    func readSavedWorldNames() -> Array<String> {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let savedWorldFiles = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil).filter{ $0.pathExtension == "arexperience" }
            return savedWorldFiles.map{ $0.deletingPathExtension().lastPathComponent }
        } catch {
            fatalError("Can't load saved worlds")
        }
    }
    
    // MARK: - Decoration
    
    @IBAction func placeDecoration(_ sender: Any) {
//        let mesh = MeshResource.generateBox(size: 0.2)
//        let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
//        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
//        modelEntity.scale = SIMD3<Float>(0.03, 0.03, 0.1)
//        modelEntity.generateCollisionShapes(recursive: true)
//
//        modelEntity.transform = Transform(matrix: self.cameraTransform)
        
//        let box = CustomBox(color: .yellow, position: Transform(matrix: cameraTransform).translation)
//        arView.installGestures(.all, for: box)
//        box.generateCollisionShapes(recursive: true)
        let box = Decoration(color: .yellow, position: Transform(matrix: self.cameraTransform).translation)
        let model = try! Entity.self.loadModel(named: "fly")
        for anim in model.availableAnimations {
            model.playAnimation(anim.repeat(duration: .infinity))
        }
        
        box.setPosition(SIMD3<Float>(0,0,0), relativeTo: cameraAnchor)
        
        box.addChild(model)
        model.setPosition(SIMD3<Float>(0, 0.05, 0), relativeTo: box)
        arView.installGestures(.all, for:box)
        box.generateCollisionShapes(recursive: true)
        
//        let anchor = AnchorEntity(plane: .horizontal)
//        anchor.addChild(modelEntity)
        arView.scene.anchors.append(box)
    }

    @IBAction func placeBoundaryPoints(_ sender: Any) {
        switch (placementStep) {
        case 0:
            groundPoint = cameraAnchor.transform.translation
            placeBoundaryButton.setTitle("Start setting boundary", for: .normal)
            placementStep += 1
            break;
        case 1:
            placeBoundaryButton.setTitle("Stop setting boundary", for: .normal)
            placementStep += 1
            boundaryTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.putBoundaryPoints), userInfo: nil, repeats: true)
            break;
        default:
            boundaryTimer.invalidate()
            placeBoundaryButton.setTitle("Reset boundary", for: .normal)
            placementStep = 0
            break;
        }
    }
    
    @objc func putBoundaryPoints() {
        gardenBoundaryPoints.append(cameraAnchor.transform.translation)
        let box = Decoration(color: .blue, position: Transform(matrix: self.cameraTransform).translation)
//    box.setPosition(SIMD3<Float>(cameraAnchor.transform.translation.x,cameraAnchor.transform.translation.z,groundPoint.y), relativeTo: originEntity)
        box.setPosition(SIMD3<Float>(0,-0.8,0), relativeTo: cameraAnchor)
    box.position.y=groundPoint.y
//        box.position = SIMD3<Float>(cameraAnchor.transform.translation.x,cameraAnchor.transform.translation.z,-groundPoint.y)
        box.generateCollisionShapes(recursive: true)
//        box.scale = SIMD3<Float>(0.03, 0.03, 0.03)
        
        gardenAnchor = box
        arView.scene.anchors.append(box)
    }

// MARK: - Start of Lifecycle
    func prepareMainScene() {
        self.worldHasBeenSaved = true
        self.arView.debugOptions = []
        self.sessionInfoLabel.text = "Welcome to \(self.worldName)! Decorate your space or play a minigame."
        self.decorationModeButton.isHidden = true
        
        placeButton.isHidden = true
        placeBoundaryButton.isHidden = true
        debugLabel.isHidden = false
        sessionInfoView.isHidden = true
        
        scanningView.isHidden = true
        for icon in loadingView.arrangedSubviews {
            icon.alpha = 0.0
        }
        
        guard let vc = storyboard?.instantiateViewController(identifier: "firstTutorialVC") as? FirstTutorialViewController else {
            return
        }
        self.view.addSubview(vc.view)
        self.view.didAddSubview(vc.view)
        self.addChild(vc)
        vc.didMove(toParent:self)
        
        
        gardenCreatorView.layer.cornerRadius = 25
        gardenCreatorView.layer.shadowColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        gardenCreatorView.layer.shadowRadius = 25
        gardenCreatorView.layer.shadowOpacity = 0.5
        gardenCreatorView.layer.shadowOffset = CGSize(width: 0, height: 0)
        gardenCreatorButton.layer.cornerRadius = 15
        gardenCreatorButton2.layer.cornerRadius = 15
        gardenCreatorButton2.isHidden = true
        gardenCreatorInput.layer.cornerRadius = 15
        gardenCreatorInput.delegate = self
        gardenCreatorView.isHidden = true
        nextDecorButton.isHidden = true
    }
    
    func enterMainScene() {
        canPlaceDragon = true
        self.worldHasBeenSaved = true
        self.arView.debugOptions = []
        self.sessionInfoLabel.text = "Welcome to \(self.worldName)! Decorate your space or play a minigame."
        self.decorationModeButton.isHidden = true
        
        scanningView.isHidden = true
        
        placeButton.isHidden = false
        placeBoundaryButton.isHidden = false
        debugLabel.isHidden = false
        sessionInfoView.isHidden = false
    }
    
//    func onboardNewUser() {
//        let alert = UIAlertController(title: "Welcome to \(gameName)! Please name your world.", message:"", preferredStyle: .alert)
//        let defaultName = "DK's Forest"
//        alert.addTextField{ (textField) in textField.placeholder = defaultName}
//        alert.addAction(UIAlertAction(title:"Confirm", style: .default, handler: {[weak alert] (_) in
//            guard let textField = alert?.textFields?[0], let userText = textField.text else { return }
//            self.worldName = userText.count > 0 ? userText : defaultName
//            self.worldHasBeenSaved = false
//            self.sessionInfoLabel.text = "The world has not been saved. Move your camera around."
//
//            self.decorationModeButton.isHidden = true
//
//            self.runSession()
//        }))
//    }
    
    @IBAction func enterDecorationMode(_ sender: UIButton) {
        isInDecorationMode = true
    }
    
    func runSession() {
        arView.session.delegate = self
        arView.session.run(defaultConfiguration)
        
        isScanningWorld = true
        
        UIApplication.shared.isIdleTimerDisabled = true
    }

// MARK: - Dragon Movement
    
    //Initializes the dragon placement on a horizontal plane
    private func initializeDragon() {
        let anchor = AnchorEntity(plane: .horizontal)
            
        let dragon = try! Entity.loadModel(named: "fly")
        
        anchor.addChild(dragon)
        arView.scene.addAnchor(anchor)
        self.virtualPetAnchors.append(anchor)
        
        for anim in dragon.availableAnimations {
            dragon.playAnimation(anim.repeat(duration: .infinity))
        }
        
        let camera = arView.cameraTransform.translation
        let currPos = anchor.transform.translation
        anchor.look(at: camera, from: currPos, relativeTo: nil)
        
        dragon.generateCollisionShapes(recursive: true)
    }
    
    //Adds and moves dragon
    func handleTap(_ sender: UIView) {
//        if isInDecorationMode {
//            let tapLocation = sender.location(in: arView)
//
//           placeDecor(point: tapLocation)
//        }
//
//
//        let transform = cameraAnchor.transform
//        let planeMesh = MeshResource.generatePlane(width: 0.5, depth: 0.5)
//        let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
//        let planeEntity = ModelEntity(mesh:planeMesh, materials:[material])
//        planeEntity.generateCollisionShapes(recursive: true)
//        let planeAnchor = AnchorEntity(world: transform.translation)
//        planeAnchor.addChild(planeEntity)
//
//        arView.scene.anchors.append(planeAnchor)
//
//
//
//            guard let query = arView.makeRaycastQuery(from: tapLocation, allowing: .existingPlaneGeometry, alignment: .horizontal) else { return }
//            guard let raycast = arView.session.raycast(query).first else { return }
//
//            let transform = Transform(matrix: raycast.worldTransform)
//
//
//            let raycastAnchor = AnchorEntity(raycastResult: raycast)
//            arView.scene.addAnchor(raycastAnchor)
//            movePet(transform: transform)
    }

    /** Place decoration */
    private func placeDecor(point: CGPoint) {
        guard let query = arView.makeRaycastQuery(from: point, allowing: .existingPlaneInfinite, alignment: .horizontal) else {
            return
        }
        
        guard let result = arView.session.raycast(query).first else {
            return
        }
        
        let transform = Transform(matrix: result.worldTransform)
        
        let mesh = MeshResource.generateBox(size: 0.2)
        let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        modelEntity.scale = SIMD3<Float>(0.03, 0.03, 0.1)
        modelEntity.generateCollisionShapes(recursive: true)
        
        modelEntity.transform = transform
        
        let raycastAnchor = AnchorEntity(raycastResult: result)
        raycastAnchor.addChild(modelEntity)
        arView.scene.addAnchor(raycastAnchor)
    }
    
    /**
     Moves pet to the 3d location specified by the raycast created by the tap and gets dragon to look at user once it stops moving
    */
    private func movePet(transform: Transform) {
//            if virtualPetAnchors.count > 0 {
        let anchor = virtualPetAnchors[0]
        let camera = arView.cameraTransform.translation
        
        guard let dragon = anchor.children.first else { return }
        
        let currPos = dragon.transform.translation
        
        dragon.look(at: transform.translation, from: currPos, relativeTo: nil)
        dragon.move(to: transform, relativeTo: anchor, duration: 3, timingFunction: .easeInOut)
        dragon.look(at: camera, from: transform.translation, relativeTo: nil)
        
        anchor.transform.translation = transform.translation
//            }
    }


// MARK: - Garden Decoration
    @IBOutlet weak var gardenCreatorSubhead: UILabel!
    @IBOutlet weak var gardenCreatorHeadline: UILabel!
    
    var currDecorIndex:Int = 0
    var availableObjects:[String] = ["wateringcan", "guitar", "chair", "tulip"]
    
    func onboardUser() {
        gardenCreatorView.isHidden = false
    }
    
    @IBAction func toggleGardenCreatorButton(_ sender: UIButton) {
        switch onboardIndex {
        case 0:
            if gardenCreatorInput.text != "" {
                self.worldName = gardenCreatorInput.text ?? ""
                onboardIndex += 1
                
                gardenCreatorIcon.image = UIImage(named: "GardenFenceIcon.png")
                gardenCreatorIcon.layer.opacity = 1.0
                gardenCreatorHeadline.text = "Create Garden Fence"
                gardenCreatorSubhead.text = "Let's create a boundary for your garden! First, find a spot to plant the fences and place your device there!"
                gardenCreatorInput.isHidden = true
                gardenCreatorButton.setTitle("Set Ground", for: .normal)
            }
            break
        case 1:
            onboardIndex += 1
            
            groundPoint = cameraAnchor.transform.translation
            
            gardenAnchor = AnchorEntity(plane: .horizontal)
            let fence = try! Entity.loadModel(named: "fencepost")
            gardenAnchor.setPosition(SIMD3<Float>(0,0,0), relativeTo: cameraAnchor)
            
            gardenAnchor.addChild(fence)
            
            gardenAnchor.generateCollisionShapes(recursive: true)
            
            arView.scene.addAnchor(gardenAnchor.anchor!)
            
            
            gardenCreatorIcon.image = UIImage(named: "GardenFenceIcon")
            gardenCreatorHeadline.text = "Are you satisfied with your garden?"
            gardenCreatorSubhead.text = ""
            gardenCreatorInput.isHidden = true
            gardenCreatorButton2.isHidden = false
            
            gardenCreatorButton2.setTitle("Yes", for: .normal)
            gardenCreatorButton.setTitle("No", for: .normal)
            break
        case 2:
            onboardIndex -= 1
            
            gardenCreatorInput.isHidden = false
            gardenCreatorButton2.isHidden = true
            
            arView.scene.removeAnchor(gardenAnchor.anchor!)
            gardenAnchor.anchor!.removeFromParent()
            
            gardenCreatorIcon.image = UIImage(named: "GardenFenceIcon")
            gardenCreatorHeadline.text = "Create Garden Fence"
            gardenCreatorSubhead.text = "Let's create a boundary for your garden! First, find a spot to plant the fences and place your device there!"
            gardenCreatorInput.isHidden = true
            gardenCreatorButton.setTitle("Set Garden Ground", for: .normal)
            break
        case 3, 4:
            onboardIndex+=1
            
            UIView.animate(withDuration: 1, animations: {
                self.gardenCreatorView.alpha = 0.0
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.gardenCreatorView.isHidden = true
                self.enterMainScene()
            }
            break
        default:
            break
        }
    }
    
    @IBAction func toggleGardenButton2(_ sender: Any) {
        switch onboardIndex {
        case 2:
            onboardIndex+=1
            
            gardenCreatorIcon.image = UIImage(named: "DecorationIcon.png")
            gardenCreatorHeadline.text = "Add Decorations"
            gardenCreatorSubhead.text = "Next, make your garden pretty! Add some decorations! (Note: You can edit them later.)"
            gardenCreatorInput.isHidden = true
            
            gardenCreatorButton2.isHidden = false
            gardenCreatorButton2.setTitle("Add Decorations", for: .normal)
            gardenCreatorButton.setTitle("Skip", for: .normal)
            
            break
        case 3:
            onboardIndex+=1
            
            gardenCreatorIcon.image = UIImage(named: "DecorationIcon.png")
            gardenCreatorHeadline.text = "Add Decorations"
            gardenCreatorSubhead.text = "Place your phone where you want to set your decoration!"
            gardenCreatorInput.isHidden = true
            
            gardenCreatorButton2.isHidden = false
            gardenCreatorButton2.setTitle("Add", for: .normal)
            gardenCreatorButton.setTitle("Done", for: .normal)
            
            nextDecorButton.isHidden = false
            break
        case 4:
            let plane = Decoration(color: .clear, position: Transform(matrix: self.cameraTransform).translation)
            
            let decor = try! Entity.loadModel(named: availableObjects[currentObjectIndex])
                    
            plane.setPosition(SIMD3<Float>(0,0,0), relativeTo: cameraAnchor)
                    
            plane.addChild(decor)
            decor.setPosition(SIMD3<Float>(0, 0.05, 0), relativeTo: plane)
            
            plane.setScale(SIMD3<Float>(0.25,0.25,0.25), relativeTo: plane)
            plane.generateCollisionShapes(recursive: true)
            arView.scene.anchors.append(plane)
            break
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    @IBAction func nextObject(_ sender: Any) {
        currentObjectIndex+=1
        
        if currentObjectIndex >= availableObjects.count {
            currentObjectIndex = 0
        }
    nextDecorButton.setTitle(availableObjects[currentObjectIndex], for: .normal)
    }
}
