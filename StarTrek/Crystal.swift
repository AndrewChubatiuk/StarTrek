//
//  Crystal.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 5/1/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import Foundation
import SpriteKit

class Crystal: SKSpriteNode, Exchangable {
    
    static var nextUid = 1
    static func generateUid() -> Int {
        return nextUid++
    }
    
    let energy = 50
    var uid: Int!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(location: CGPoint, uid: Int?) {
        let texture = SKTexture(imageNamed: "crystal")
        super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        if uid == nil {
            self.uid = Crystal.generateUid()
        } else {
            self.uid = uid
        }
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width > size.height ? size.width / 2 : size.height / 2)
        self.physicsBody?.dynamic = true
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.categoryBitMask = CollisionGroups.Crystal
        self.physicsBody?.contactTestBitMask = CollisionGroups.Spaceship
        self.position = location
    }
    
    func objectUpdatesMessage(attribute: String) -> [String : AnyObject] {
        if attribute == "initial" {
            return [
                "uid": self.uid,
                "x": self.position.x,
                "y": self.position.y
            ]
        } else {
            return [
                "update": "location",
                "object": "crystal",
                "uid": self.uid,
                "x": self.position.x,
                "y": self.position.y
            ]
        }
    }
    
    static func createFromData(data: NSDictionary) -> Exchangable {
        return Crystal(location: CGPoint(
                x: CGFloat((data.objectForKey("x")?.doubleValue)!),
                y: CGFloat((data.objectForKey("y")?.doubleValue)!)
            ),
            uid: nil
        )
    }
    
    static func regenerate(x: CGFloat, y: CGFloat, uid: Int) -> Crystal {
        let pos = CGPoint(x: x, y: y)
        let crystal = Crystal(location: pos, uid: uid)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("CrystalData", object: nil, userInfo: crystal.objectUpdatesMessage("position"))
        })
        return crystal
    }
    
    deinit {
        self.removeFromParent()
    }
    
}