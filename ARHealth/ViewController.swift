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

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var decorationModeButton: UIButton!
    @IBOutlet weak var placeButton: UIButton!
    @IBOutlet weak var debugLabel: UILabel!
    
    var virtualPetAnchors: [AnchorEntity] = []
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    var worldName: String = ""
    var gameName: String = "dragon-game"
    var saveFileExtension: String = ".arexperience"
    
    var canPlaceDragon: Bool = false
    
    var currentObjectIndex: Int = 0
    
    var isInDecorationMode: Bool = false
    var isInitializingDragon: Bool = false
    
    var isInMovementMode: Bool = false
    
    
    var worldHasBeenSaved: Bool = false
    var isCreatingNewWorld: Bool = false
    var isRelocalizing: Bool = false
    var worldHasLoaded: Bool = false
    var useRaycast: Bool = false
    var initLock = NSLock()
    
    var cameraTransform: simd_float4x4 = simd_float4x4.init()
    
    var cameraAnchor: AnchorEntity = AnchorEntity(world: SIMD3<Float>(0,0,0))
    
    var gardenBoundaryPoints: [SIMD3<Float>] = []
    var gardenAnchor: Entity = AnchorEntity(world: SIMD3<Float>(0,0,0))
    
    
    // MARK: - View Life Cycle
    
    // Allows user to auto-rotate phone
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        self.runSession()
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
        
        self.decorationModeButton.isHidden = true
//        self.placeButton.isHidden = true
        
//        onboardNewUser()
//
//        let virtualPetAnchor = ARAnchor(name: "PetAnchor", transform: float4x4(SIMD4<Float>(1, 0, 0, 0), SIMD4<Float>(0, 1, 0, 0), SIMD4<Float>(0, 0, 1, 0), SIMD4<Float>(0, -0.2, 0, 1)))
//        arView.session.add(anchor: virtualPetAnchor)
        
//        initializeDragon()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }

// MARK: - Delegate functions
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        initLock.lock()
//
//        if isInDecorationMode {
//            switch frame.worldMappingStatus {
//            case .mapped:
//                self.enterMainScene()
//            default:
//                break
//            }
//        }
//
//        initLock.unlock()
        
        statusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        Tracking: \(frame.camera.trackingState.description)
        """
        
        let transform = frame.camera.transform.columns.3
        self.cameraTransform = float4x4(SIMD4<Float>(1, 0, 0, 0), SIMD4<Float>(0, 1, 0, 0), SIMD4<Float>(0, 0, 1, 0), SIMD4<Float>(transform.x, transform.y, transform.z, 1))
        
        let position = Transform(matrix: frame.camera.transform)
        cameraAnchor.transform = position
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState.description {
        case "Relocalizing":
            self.isRelocalizing = true
        default:
            if self.isRelocalizing && !self.worldHasLoaded {
                self.worldHasLoaded = true
                enterMainScene()
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
    
    // MARK: - Start of Lifecycle
    
    func prepareMainScene() {
        self.worldHasBeenSaved = true
        self.arView.debugOptions = []
        self.sessionInfoLabel.text = "Welcome to \(self.worldName)! Decorate your space or play a minigame."
        self.decorationModeButton.isHidden = false
    }
    
    func enterMainScene() {
        canPlaceDragon = true
        self.worldHasBeenSaved = true
        self.arView.debugOptions = []
        self.sessionInfoLabel.text = "Welcome to \(self.worldName)! Decorate your space or play a minigame."
        self.decorationModeButton.isHidden = false
//        initializeDragon()
    }
    
    func onboardNewUser() {
        let alert = UIAlertController(title: "Welcome to \(gameName)! Please name your world.", message:"", preferredStyle: .alert)
        let defaultName = "DK's Forest"
        alert.addTextField{ (textField) in textField.placeholder = defaultName}
        alert.addAction(UIAlertAction(title:"Confirm", style: .default, handler: {[weak alert] (_) in
            guard let textField = alert?.textFields?[0], let userText = textField.text else { return }
            self.worldName = userText.count > 0 ? userText : defaultName
            self.worldHasBeenSaved = false
            self.sessionInfoLabel.text = "The world has not been saved. Move your camera around."
            
            self.decorationModeButton.isHidden = true
            
            self.runSession()
        }))
    }
    
    @IBAction func enterDecorationMode(_ sender: UIButton) {
        isInDecorationMode = true
    }
    
    func runSession() {
        arView.session.delegate = self
        arView.session.run(defaultConfiguration)
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    // MARK: - Dragon Placement
        
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
        if gardenBoundaryPoints.count < 3 {
            gardenBoundaryPoints.append(cameraAnchor.transform.translation)
            let box = Decoration(color: .blue, position: Transform(matrix: self.cameraTransform).translation)
            box.setPosition(SIMD3<Float>(0,0,0), relativeTo: cameraAnchor)
            box.generateCollisionShapes(recursive: true)
//            box.scale = SIMD3<Float>(0.03, 0.03, 0.03)
            
            if gardenBoundaryPoints.count == 0 {
                gardenAnchor = box
            }
            
            arView.scene.anchors.append(box)
        } else {
            let center = gardenBoundaryPoints[0]
            let width = 2 * abs(gardenBoundaryPoints[1].x - center.x)
            let depth = 2 * abs(gardenBoundaryPoints[2].z - center.z)
            
            let plane = Plane(color:.green, position:center, width: width, depth: depth)
            plane.generateCollisionShapes(recursive: true)
            
            debugLabel.text = "Width: \(width), Depth: \(depth)"
            
            arView.scene.anchors.append(plane)
        }
    }
    
    //Adds and moves dragon
    func handleTap(_ sender: UIView) {
//        if isInDecorationMode {
//            let tapLocation = sender.location(in: arView)
//
//           placeDecor(point: tapLocation)
//        }
        
        
//        let transform = cameraAnchor.transform
//        let planeMesh = MeshResource.generatePlane(width: 0.5, depth: 0.5)
//        let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
//        let planeEntity = ModelEntity(mesh:planeMesh, materials:[material])
//        planeEntity.generateCollisionShapes(recursive: true)
//        let planeAnchor = AnchorEntity(world: transform.translation)
//        planeAnchor.addChild(planeEntity)
//
//        arView.scene.anchors.append(planeAnchor)
        
        
        
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

    // Place decoration
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
    
    // Moves pet to the 3d location specified by the raycast created by the tap and gets dragon to look at user once it stops moving
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
}
