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
    
    static var nextUid = Int(1)
    static func generateUid() -> Int {
        nextUid = nextUid + 1
        return nextUid
    }
    
    let energy = 50
    var uid: Int!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(location: CGPoint, uid: Int?) {
        let texture = SKTexture(imageNamed: "crystal")
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        if uid == nil {
            self.uid = Crystal.generateUid()
        } else {
            self.uid = uid
        }
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width > size.height ? size.width / 2 : size.height / 2)
        self.physicsBody?.isDynamic = true
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.categoryBitMask = CollisionGroups.Crystal
        self.physicsBody?.contactTestBitMask = CollisionGroups.Spaceship
        self.position = location
    }
    
    func objectUpdatesMessage(_ attribute: String) -> [String : AnyObject] {
        if attribute == "initial" {
            return [
                "uid": self.uid as AnyObject,
                "x": self.position.x as AnyObject,
                "y": self.position.y as AnyObject
            ]
        } else {
            return [
                "update": "location" as AnyObject,
                "object": "crystal" as AnyObject,
                "uid": self.uid as AnyObject,
                "x": self.position.x as AnyObject,
                "y": self.position.y as AnyObject
            ]
        }
    }
    
    static func createFromData(_ data: NSDictionary) -> Exchangable {
        return Crystal(location: CGPoint(
                x: CGFloat(((data.object(forKey: "x") as AnyObject).doubleValue)!),
                y: CGFloat(((data.object(forKey: "y") as AnyObject).doubleValue)!)
            ),
            uid: nil
        )
    }
    
    static func regenerate(_ x: CGFloat, y: CGFloat, uid: Int) -> Crystal {
        let pos = CGPoint(x: x, y: y)
        let crystal = Crystal(location: pos, uid: uid)
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: "CrystalData"), object: nil, userInfo: crystal.objectUpdatesMessage("position"))
        })
        return crystal
    }
    
    deinit {
        self.removeFromParent()
    }
    
}
