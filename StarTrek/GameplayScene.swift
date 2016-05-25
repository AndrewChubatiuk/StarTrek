//
//  GameScene.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 4/26/16.
//  Copyright (c) 2016 Andrii Chubatiuk. All rights reserved.
//

import SceneKit
import SpriteKit

class GameplayScene: SKScene, SKPhysicsContactDelegate {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var world: SKSpriteNode!
    var controller: GameplayController!
    var initialized = false
    
    override func didChangeSize(oldSize: CGSize) {
        if initialized == true {
            let joystickView = self.camera!.childNodeWithName("joystickView")! as! SKSpriteNode
            let screenSize = self.view?.frame.size
            let x = (joystickView.size.width - (screenSize?.width)!)/2
            let y = (joystickView.size.height - (screenSize?.height)!)/2
            joystickView.position = CGPoint(x: x, y: y)
        }
    }
    
    override func didMoveToView(view: SKView) {
        world = childNodeWithName("world") as! SKSpriteNode
        world.size = CGSize(width: CGFloat(4 * appDelegate.worldSize), height: CGFloat(4 * appDelegate.worldSize))
        world.color = UIColor.clearColor()
        world.physicsBody = SKPhysicsBody(edgeLoopFromRect: world.frame)
        physicsWorld.contactDelegate = self
        let screenSize = self.view?.frame.size
        let joystickView = self.camera!.childNodeWithName("joystickView")! as! SKSpriteNode
        let joystickDimension = CGFloat(200)
        let joystick = AnalogJoystick(diameter: joystickDimension / 10, colors: (UIColor.grayColor(), UIColor.blackColor()))
        joystick.trackingHandler = handlerTracking
        joystickView.size = CGSize(width: joystickDimension, height: joystickDimension)
        joystickView.color = UIColor.clearColor()
        joystickView.position = CGPoint(
           x: (joystickView.size.width - (screenSize?.width)!)/2,
           y: (joystickView.size.width - (screenSize?.height)!)/2
        )
        joystickView.addChild(joystick)
        for player in appDelegate.players {
            if player.spaceship.parent == nil {
                self.world.addChild(player.spaceship)
                player.spaceship.rocket.targetNode = self.scene
            }
            if player.spacebase.parent == nil {
                self.world.addChild(player.spacebase)
            }
        }
        for crystal in appDelegate.crystals {
            if crystal.parent == nil {
                self.world.addChild(crystal)
            }
        }
        self.starEmitter()
        initialized = true

    }

    
    func handlerTracking(data: AnalogJoystickData) {
        if self.appDelegate.getMyPlayer() != nil && self.appDelegate.getMyPlayer()?.spaceship != nil {
            self.appDelegate.getMyPlayer()?.spaceship!.move(data.angular, velocity: data.velocity)
            self.camera!.runAction(SKAction.moveTo((self.appDelegate.getMyPlayer()?.spaceship!.position)!, duration: 0.1))
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.appDelegate.getMyPlayer()?.spaceship!.fire()
    }
   
    override func update(currentTime: CFTimeInterval) {
    }
    
    override func didSimulatePhysics() {
        self.centerOnNode(self.camera!)
    }
    
    func centerOnNode(node: SKNode) {
        let cameraPositionInScene: CGPoint = node.scene!.convertPoint(node.position, fromNode: node.parent!)
        node.parent!.position = CGPoint(x:node.parent!.position.x - cameraPositionInScene.x, y:node.parent!.position.y - cameraPositionInScene.y)
    }
    
    func starEmitter() {
        let starField = SKEmitterNode(fileNamed: "StarField")
        starField!.position = CGPointMake(0, 0)
        starField?.particlePositionRange = CGVector(dx: self.frame.width, dy: self.frame.height)
        starField?.particleBirthRate = 150
        starField!.zPosition = -2
        self.camera!.addChild(starField!)
    }
    
    func explosion(pos: CGPoint) {
        let emitterNode = SKEmitterNode(fileNamed: "Explosion.sks")
        emitterNode?.particleColor = UIColor.blueColor()
        emitterNode!.particlePosition = pos
        self.world.addChild(emitterNode!)
        self.runAction(SKAction.waitForDuration(2), completion: { emitterNode!.removeFromParent() })
    }
    
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        if (contact.bodyA.node == nil || contact.bodyB.node == nil) {
            return
        }
        
        if (contact.bodyA.categoryBitMask == CollisionGroups.Spaceship && contact.bodyB.categoryBitMask == CollisionGroups.Spaceship) {
            
            //Ship collision
            let ship1 = contact.bodyA.node as! Spaceship
            let ship2 = contact.bodyB.node as! Spaceship
            explosion(ship1.position)
            explosion(ship2.position)
            ship1.die()
            ship2.die()
            
        } else if (contact.bodyA.categoryBitMask == CollisionGroups.Spaceship && contact.bodyB.categoryBitMask == CollisionGroups.Bullet || contact.bodyA.categoryBitMask == CollisionGroups.Bullet && contact.bodyB.categoryBitMask == CollisionGroups.Spaceship){
            
            //Ship got bullet
        
            let bullet = (contact.bodyA.categoryBitMask == CollisionGroups.Bullet ? contact.bodyA.node : contact.bodyB.node) as! Bullet
            let ship = (contact.bodyA.categoryBitMask == CollisionGroups.Spaceship ? contact.bodyA.node : contact.bodyB.node) as! Spaceship
            if ship.ownerID != bullet.ownerID {
                let ship_position = ship.position
                explosion(bullet.position)
                ship.getDamage(bullet)
                if ship.alive == true {
                    explosion(ship_position)
                }
                bullet.removeAllActions()
                bullet.removeFromParent()
                
            }
        } else if (contact.bodyA.categoryBitMask == CollisionGroups.Spaceship && contact.bodyB.categoryBitMask == CollisionGroups.Spacebase || contact.bodyA.categoryBitMask == CollisionGroups.Spacebase && contact.bodyB.categoryBitMask == CollisionGroups.Spaceship) {
            
            //Ship setted on Base
            
            let ship = (contact.bodyA.categoryBitMask == CollisionGroups.Spaceship ? contact.bodyA.node : contact.bodyB.node) as! Spaceship
            let base = (contact.bodyA.categoryBitMask == CollisionGroups.Spacebase ? contact.bodyA.node : contact.bodyB.node) as! Spacebase
            if ship.shield < ship.maxShield {
                base.restoreShipShield(ship)
            }
            
        } else if (contact.bodyA.categoryBitMask == CollisionGroups.Spacebase && contact.bodyB.categoryBitMask == CollisionGroups.Bullet || contact.bodyA.categoryBitMask == CollisionGroups.Bullet && contact.bodyB.categoryBitMask == CollisionGroups.Spacebase){
            
            //Base got bullet
            
            let bullet = (contact.bodyA.categoryBitMask == CollisionGroups.Bullet ? contact.bodyA.node : contact.bodyB.node) as! Bullet
            let base = (contact.bodyA.categoryBitMask == CollisionGroups.Spacebase ? contact.bodyA.node : contact.bodyB.node) as! Spacebase
            if base.ownerID != bullet.ownerID {
                let base_position = base.position
                explosion(bullet.position)
                base.getDamage(bullet)
                if base.alive == true {
                    explosion(base_position)
                }
                bullet.removeAllActions()
                bullet.removeFromParent()
            }
            
        } else if (contact.bodyA.categoryBitMask == CollisionGroups.Spaceship && contact.bodyB.categoryBitMask == CollisionGroups.Crystal || contact.bodyA.categoryBitMask == CollisionGroups.Crystal && contact.bodyB.categoryBitMask == CollisionGroups.Spaceship) {
            
            //Ship got a crystal
            
            let crystal = (contact.bodyA.categoryBitMask == CollisionGroups.Crystal ? contact.bodyA.node : contact.bodyB.node) as! Crystal
            let ship = (contact.bodyA.categoryBitMask == CollisionGroups.Spaceship ? contact.bodyA.node : contact.bodyB.node) as! Spaceship
            if ship.energy < ship.maxEnergy {
                ship.pickCrystal(crystal)
                let xPos = CGFloat(Float(arc4random())) % 1500 - 500
                let yPos = CGFloat(Float(arc4random())) % 1500 - 500
                let cryst = Crystal.regenerate(xPos, y: yPos, uid: crystal.uid)
                self.appDelegate.deleteCrystal(crystal.uid)
                self.appDelegate.crystals.append(cryst)
            }

        } 
    }
}
