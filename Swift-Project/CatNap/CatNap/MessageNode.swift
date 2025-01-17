//
//  MessageNode.swift
//  CatNap
//
//  Created by 谢乾坤 on 6/17/16.
//  Copyright © 2016 QiankunXie. All rights reserved.
//

import SpriteKit

class MessageNode: SKLabelNode {
    
    
    
    convenience init(message: String) {
        self.init(fontNamed: "AvenirNext-Regular")
        text = message
        fontSize = 256.0
        fontColor = SKColor.grayColor()
        zPosition = 100
        let front = SKLabelNode(fontNamed: "AvenirNext-Regular")
        front.text = message
        front.fontSize = 256.0
        front.fontColor = SKColor.whiteColor()
        front.position = CGPoint(x: -2, y: -2)
        addChild(front)
        
        physicsBody = SKPhysicsBody(circleOfRadius: 10)
        physicsBody!.collisionBitMask = PhysicsCategory.Edge
        physicsBody!.categoryBitMask = PhysicsCategory.Label
        physicsBody!.contactTestBitMask = PhysicsCategory.Edge

        physicsBody!.restitution = 0.7
    }
    
    private var bounceCount = 0
    
    func didBounce() {
        if bounceCount + 1 >= 4 {
            removeFromParent()
        }
        bounceCount += 1

    }
}










