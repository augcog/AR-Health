//
//  Plane.swift
//  ARHealth
//
//  Created by Daniel Won on 4/21/21.
//  Copyright © 2021 Daniel Won. All rights reserved.
//

import Foundation
import ARKit
import RealityKit

class Plane: Entity, HasModel, HasAnchoring, HasCollision {
    
    required init(color: UIColor) {
        super.init()
        self.components[ModelComponent] = ModelComponent(
            mesh: .generatePlane(width: 0.1, depth: 0.1),
            materials: [SimpleMaterial(
                color: color,
                isMetallic: false)
            ]
        )
    }
    
    required init(color: UIColor, position: SIMD3<Float>, width:Float, depth:Float) {
        super.init()
        self.components[ModelComponent] = ModelComponent(
            mesh: .generatePlane(width: width, depth: depth),
            materials: [SimpleMaterial(
                color: color,
                isMetallic: false)
            ]
        )
        self.position = position
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}

