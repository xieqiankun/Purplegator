//
//  GameOverScene.swift
//  ZombieConge
//
//  Created by 谢乾坤 on 6/16/16.
//  Copyright © 2016 QiankunXie. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    let won:Bool
    init(size: CGSize, won: Bool) {
        self.won = won
        super.init(size: size)
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didMoveToView(view: SKView) {
        var background: SKSpriteNode
        if (won) {
            background = SKSpriteNode(imageNamed: "YouWin")
            runAction(SKAction.sequence([
                SKAction.waitForDuration(0.1),
                SKAction.playSoundFileNamed("win.wav",
                    waitForCompletion: false)
                ]))
        } else {
            background = SKSpriteNode(imageNamed: "YouLose")
            runAction(SKAction.sequence([
                SKAction.waitForDuration(0.1),
                SKAction.playSoundFileNamed("lose.wav",
                    waitForCompletion: false)
                ]))
        }
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        self.addChild(background)
        // More here...
        let wait = SKAction.waitForDuration(3.0)
        let block = SKAction.runBlock {
            let myScene = GameScene(size: self.size)
            myScene.scaleMode = self.scaleMode
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            self.view?.presentScene(myScene, transition: reveal)
        }
        self.runAction(SKAction.sequence([wait, block]))
    }
}








