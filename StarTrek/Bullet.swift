//
//  Bullet.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 5/1/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//


import Foundation
import SpriteKit


struct CollisionGroups {
    static let Bullet: UInt32 = 0x1 << 0
    static let Crystal: UInt32 = 0x1 << 1
    static let Spaceship: UInt32 = 0x1 << 2
    static let Spacebase: UInt32 = 0x1 << 3
    static let Border: UInt32 = 0x1 << 4
}

class Bullet: SKSpriteNode, Exchangable {
    
    var active: Bool = true
    var destinationVector: CGVector!
    var ownerID: String!
    let damage = 10
    var generateMessages = false
    var track: SKEmitterNode!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(ownerID: String, start: CGPoint, destinationVector: CGVector, angle: CGFloat) {
        self.ownerID = ownerID
        let texture = SKTexture(imageNamed: "bullet")
        super.init(texture: texture, color: UIColor.blackColor(), size: texture.size())
        self.position = start
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.physicsBody = SKPhysicsBody(texture: texture, size: size)
        self.physicsBody?.dynamic = false
        self.physicsBody?.usesPreciseCollisionDetection = false
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.categoryBitMask = CollisionGroups.Bullet
        self.physicsBody?.contactTestBitMask = CollisionGroups.Spacebase | CollisionGroups.Spaceship
        self.destinationVector = destinationVector
        track = SKEmitterNode(fileNamed: "Turbine.sks")
        track.particleColorSequence = nil;
        track.particleColorBlendFactor = 1.0;
        track.particleSpeed = 1000
        track.particleSpeedRange = 500
        track.particleScaleRange = 6
        track.particleBirthRate = 600
        track.particleLifetime = 0.1
        track.emissionAngleRange = 3.14 / 4
        track.particleColor = SKColor.orangeColor()
        track!.particlePosition = CGPoint(x: 0, y: 0)
        self.addChild(track)
        track.emissionAngle = angle + 3 * 3.14 / 2
    }
    
    func move() {
        let bulletAction = SKAction.sequence([SKAction.moveBy(destinationVector, duration: 2), SKAction.removeFromParent()])
        self.runAction(bulletAction)
        track.targetNode = self.scene
        if generateMessages == true {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("BulletData", object: nil, userInfo: self.objectUpdatesMessage("direction"))
            })
        }
    }
    
    func objectUpdatesMessage(attribute: String) -> [String : AnyObject] {
        return [
            "object": "bullet"
        ]
    }
    
    static func createFromData(data: NSDictionary) -> Exchangable {
        return Bullet(
            ownerID: data.objectForKey("ownerID") as! String,
            start: CGPoint(
                x: CGFloat((data.objectForKey("x")?.doubleValue)!),
                y: CGFloat((data.objectForKey("y")?.doubleValue)!)
            ),
            destinationVector: CGVector(
                dx: CGFloat((data.objectForKey("dx")?.doubleValue)!),
                dy: CGFloat((data.objectForKey("dy")?.doubleValue)!)
            ),
            angle: CGFloat((data.objectForKey("angle")?.doubleValue)!)
        )
    }
    
    deinit {
        self.removeFromParent()
    }
}
