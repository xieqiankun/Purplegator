//
//  HookNode.swift
//  CatNap
//
//  Created by 谢乾坤 on 6/17/16.
//  Copyright © 2016 QiankunXie. All rights reserved.
//

import SpriteKit

class HookNode: SKSpriteNode, CustomNodeEvents {

    private var hookNode = SKSpriteNode(imageNamed: "hook")
    private var ropeNode = SKSpriteNode(imageNamed: "rope")
    private var hookJoint: SKPhysicsJointFixed!
    
    var isHooked: Bool {
        return hookJoint != nil
    }
    
    func didMoveToScene() {
        guard let scene = scene else {
            return
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HookNode.catTapped), name: kCatTappedNotification, object: nil)
        
        let ceilingFix = SKPhysicsJointFixed.jointWithBodyA(scene.physicsBody!, bodyB: physicsBody!, anchor: CGPoint.zero)
        scene.physicsWorld.addJoint(ceilingFix)
        ropeNode.anchorPoint = CGPoint(x: 0, y: 0.5)
        ropeNode.zRotation = CGFloat(270).degreesToRadians()
        ropeNode.position = position
//        print(position)
//        print(scene.position)
//        print(scene.anchorPoint)
        scene.addChild(ropeNode)
        
        hookNode.position = CGPoint(
            x: position.x,
            y: position.y - ropeNode.size.width )
        hookNode.physicsBody =
            SKPhysicsBody(circleOfRadius: hookNode.size.width/2)
        hookNode.physicsBody!.categoryBitMask = PhysicsCategory.Hook
        hookNode.physicsBody!.contactTestBitMask = PhysicsCategory.Cat
        hookNode.physicsBody!.collisionBitMask = PhysicsCategory.None
        scene.addChild(hookNode)
        
        let hookPosition = CGPoint(x: hookNode.position.x,
                                   y: hookNode.position.y+hookNode.size.height/2)
        //let test = SKPhysicsJointLimit.jointWithBodyA(physicsBody!, bodyB: hookNode.physicsBody!, anchorA: position, anchorB: hookPosition)
        let ropeJoint = SKPhysicsJointSpring.jointWithBodyA(physicsBody!,
                                                bodyB: hookNode.physicsBody!,
                                                anchorA: position,
                                                anchorB: hookPosition)
        scene.physicsWorld.addJoint(ropeJoint)
        
        // add contraint
        let range = SKRange(lowerLimit: 0.0, upperLimit: 0.0)
        let orientConstraint = SKConstraint.orientToNode(hookNode, offset: range)
        ropeNode.constraints = [orientConstraint]
        hookNode.physicsBody!.applyImpulse(CGVector(dx: 50, dy: 0))
        
    }
    
    func hookCat(catNode: SKNode) {
        catNode.parent!.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
        catNode.parent!.physicsBody!.angularVelocity = 0
        let pinPoint = CGPoint(
            x: hookNode.position.x,
            y: hookNode.position.y + hookNode.size.height/2)
        hookJoint = SKPhysicsJointFixed.jointWithBodyA(hookNode.physicsBody!,
                                                       bodyB: catNode.parent!.physicsBody!, anchor: pinPoint)
        scene!.physicsWorld.addJoint(hookJoint)
        hookNode.physicsBody!.contactTestBitMask = PhysicsCategory.None
    }
    
    func releaseCat() {
        hookNode.physicsBody!.categoryBitMask = PhysicsCategory.None
        hookNode.physicsBody!.contactTestBitMask = PhysicsCategory.None
        hookJoint.bodyA.node!.zRotation = 0
        hookJoint.bodyB.node!.zRotation = 0
        scene!.physicsWorld.removeJoint(hookJoint)
        hookJoint = nil
    }
    
    func catTapped() {
        if isHooked {
            releaseCat()
        }
    }
    
}












