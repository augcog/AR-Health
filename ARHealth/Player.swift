//
//  Player.swift
//  ARrehab
//
//  Created by Eric Wang on 2/24/20.
//  Copyright © 2020 Eric Wang. All rights reserved.
//

import Foundation
import RealityKit
import Combine

class Player : PlayerCollider, HasModel, HasAnchoring {
    
    static let PLAYER_COLLISION_GROUP = CollisionGroup(rawValue: 2)
        
    required init(target: AnchoringComponent.Target) {
        super.init()
        self.collision?.filter.group = Player.PLAYER_COLLISION_GROUP
        self.components[AnchoringComponent] = AnchoringComponent(target)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    override func onCollisionBegan(decor: Decoration, vc: ViewController) {
        //super.onCollisionBegan(tile: tile)
        if vc.isInDecorationMode {
            vc.showDecorOverlay(decor: decor)
        }
    }
    
    override func onCollisionEnded(decor: Decoration, vc: ViewController) {
        if vc.isInDecorationMode {
            vc.hideDecorOverlay()
        }
        //print("CURRENTLY ON:",onTile?.tileName)
        //super.onCollisionEnded(tile: tile)
    }
}

class PlayerCollider : Entity, HasCollision {
    
    static let defaultCollisionComp = CollisionComponent(shapes: [ShapeResource.generateBox(width: 0.0, height: 0.0, depth: 0.0)], mode: .trigger, filter: CollisionFilter(group: .default, mask: Decoration.DECORATION_COLLISION_GROUP))
    
    var subscriptions: [Cancellable] = []

    required init() {
        super.init()
        self.components[CollisionComponent] = PlayerCollider.defaultCollisionComp
    }
    
    func addCollision(vc: ViewController) {
        guard let scene = self.scene else {return}
        self.subscriptions.append(scene.subscribe(to: CollisionEvents.Began.self, on: self) { event in
            print("Collision Tile Began with", event.entityB)
            guard let decor = event.entityB as? Decoration else {
                return
            }
            self.onCollisionBegan(decor: decor, vc: vc)
            print("Collsion Tile Began Ending")
        })
        self.subscriptions.append(scene.subscribe(to: CollisionEvents.Ended.self, on: self) { event in
            print("Collision Tile Ended Start")
            guard let decor = event.entityB as? Decoration else {
                return
            }
            self.onCollisionEnded(decor: decor, vc: vc)
            print("Collision Tile Ended Finish")
        })
    }
    
    func onCollisionBegan(decor: Decoration, vc: ViewController) {
        print("Collision Started")
        print("On Tile: \(decor.decorationName)")
    }
    
    func onCollisionEnded(decor: Decoration, vc: ViewController) {
        print("Collision Ended")
        print("On Tile: \(decor.decorationName)")
    }
    
}
