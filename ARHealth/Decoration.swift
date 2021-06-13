//
//  Decoration.swift
//  ARHealth
//
//  Created by Daniel Won on 4/14/21.
//  Copyright © 2021 Daniel Won. All rights reserved.
//

import Foundation
import ARKit
import RealityKit

class Decoration: Entity, HasModel, HasAnchoring, HasCollision {
    static let DECORATION_COLLISION_GROUP = CollisionGroup(rawValue: 1)
    var decorationName:String = ""
    
    
    required init() {
        super.init()
        self.collision?.filter.group = Decoration.DECORATION_COLLISION_GROUP
        
        self.components[CollisionComponent] = CollisionComponent(
            shapes: [.generateBox(size: [0.25,0.75,0.25])],
          mode: .trigger,
          filter: .sensor
        )
        
        self.components[ModelComponent] = ModelComponent(
            mesh: .generatePlane(width: 0.1, depth: 0.1), materials: [SimpleMaterial(color: .clear, isMetallic: false)]
        )
        
    }
    
    convenience init (modelName: String, position: SIMD3<Float>) {
        self.init()
        
        decorationName = modelName
        
        let model = try! Entity.loadModel(named: modelName)
        self.addChild(model)
        model.setPosition(SIMD3<Float>(0,0.05,0), relativeTo: self)
        self.setScale(SIMD3<Float>(0.25,0.25,0.25), relativeTo: self)
        
        self.generateCollisionShapes(recursive: true)
    }
    
    convenience init(color: UIColor) {
        self.init()
        self.components[ModelComponent] = ModelComponent(
            mesh: .generatePlane(width: 0.1, depth: 0.1), materials: [SimpleMaterial(color: color, isMetallic: false)]
        )
    }
    
    convenience init(color: UIColor, position: SIMD3<Float>) {
        self.init(color: color)
        self.position = position
    }
}
