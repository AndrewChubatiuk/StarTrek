//
//  SpaceBase.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 5/1/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import Foundation
import SpriteKit

class Spacebase: SKSpriteNode, Exchangable {
    
    var ownerID: String!
    var species: String!
    let maxEnergy = 10000
    let maxShield = 500
    var alive: Bool!
    var shield: Int!
    var energy: Int!
    var image: SKSpriteNode!
    var generateMessages = false
    var shieldBar: Bar!
    var energyBar: Bar!
    var label: SKLabelNode!
    var shieldImage: SKSpriteNode!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(location: CGPoint, species: String, ownerID: String) {
        if energy == nil {
            energy = maxEnergy
        }
        if shield == nil {
            shield = maxShield
        }
        if alive == nil {
            alive = true
        }
        self.species = species
        let texture = SKTexture(imageNamed: species + "_base")
        self.ownerID = ownerID
        super.init(texture: nil, color: UIColor.clear, size: texture.size())
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        image = SKSpriteNode(texture: texture, color: UIColor.clear, size: size)
        self.addChild(image)
        self.physicsBody = SKPhysicsBody(
            circleOfRadius: size.width > size.height ? size.width / 2: size.height / 2
        ) 
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.categoryBitMask = CollisionGroups.Spacebase
        self.physicsBody?.contactTestBitMask = CollisionGroups.Bullet | CollisionGroups.Spaceship
        self.physicsBody?.isDynamic = true
        self.physicsBody?.usesPreciseCollisionDetection = false
        self.physicsBody?.collisionBitMask = 0
        self.position = location
        shieldBar = Bar(
            size: CGSize(
                width: 100,
                height: 12
            ),
            color: UIColor.blue,
            maxValue: maxShield
        )
        shieldBar.setBar(shield)
        shieldBar.position = CGPoint(
            x: -shieldBar.size.width/2,
            y: self.size.height/2
        )
        addChild(shieldBar)
        energyBar = Bar(
            size: CGSize(
                width: 100,
                height: 12
            ),
            color: UIColor.orange,
            maxValue: maxEnergy
        )
        energyBar.setBar(energy)
        energyBar.position = CGPoint(
            x: -shieldBar.size.width/2,
            y: self.size.height/2 + shieldBar.size.height
        )
        addChild(energyBar)
        label = SKLabelNode(text: ownerID)
        label.position = CGPoint(
            x: 0,
            y: self.size.height/2 + shieldBar.size.height + energyBar.size.height
        )
        label.fontName = "Starjedi"
        label.fontSize = 10
        addChild(label)
        shieldImage = SKSpriteNode(imageNamed: "shield")
        let radius = size.width > size.height ? size.width * 1.2 : size.height * 1.2
        shieldImage.size = CGSize(width: radius, height: radius)
        image.addChild(shieldImage)
        shieldImage.zPosition = image.zPosition + 1
    }
    
    func restoreShipShield(_ ship: Spaceship) {
        if energy >= ship.maxShield {
            ship.getShield(ship.maxShield)
            energy = energy - ship.maxShield
        } else {
            ship.getShield(energy)
            energy = 0
        }
        shieldImage.isHidden = false
        if generateMessages == true {
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SpacebaseData"), object: nil, userInfo: self.objectUpdatesMessage("energy"))
            })
        }
    }
    
    func getDamage(_ bullet: Bullet) {
        if shield > bullet.damage {
            shield = shield - bullet.damage
        } else {
            if shield > 0 {
                shield = 0
                shieldImage.isHidden = true
            } else {
                die()
            }
        }
        shieldBar.setBar(shield)
        if generateMessages == true {
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SpacebaseData"), object: nil, userInfo: self.objectUpdatesMessage("shield"))
            })
        }
    }
    
    func die() {
        if alive == true {
            self.alive = false
            if generateMessages == true {
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "SpacebaseData"), object: nil, userInfo: self.objectUpdatesMessage("alive"))
                })
            }
        }
    }
    
    func updateObject(_ data: NSDictionary) {
        if (data.object(forKey: "update") as AnyObject).isEqual(to: "shield") == true {
            self.shield = (data.object(forKey: "shield") as AnyObject).intValue
        } else if (data.object(forKey: "update") as AnyObject).isEqual(to: "energy") == true {
            self.energy = (data.object(forKey: "energy") as AnyObject).intValue
        } else if (data.object(forKey: "update") as AnyObject).isEqual(to: "alive") == true {
            self.alive = (data.object(forKey: "alive") as AnyObject).boolValue
        } 
    }
    
    func objectUpdatesMessage(_ attribute: String) -> [String : AnyObject] {
        if attribute == "initial" {
            return [
                "x": self.position.x as AnyObject,
                "y": self.position.y as AnyObject
            ]
        } else if attribute == "shield" {
            return [
                "update": "shield" as AnyObject,
                "object": "spacebase" as AnyObject,
                "shield": self.shield as AnyObject
            ]
        } else if attribute == "alive" {
            return [
                "update": "alive" as AnyObject,
                "object": "spacebase" as AnyObject,
                "alive": self.alive as AnyObject
            ]
        } else {
            return [
                "update": "energy" as AnyObject,
                "object": "spacebase" as AnyObject,
                "energy": self.energy as AnyObject,
            ]
        }
    }
    
    static func createFromData(_ data: NSDictionary) -> Exchangable {
        return Spacebase(
            location: CGPoint(
                x: CGFloat(((data.object(forKey: "x") as AnyObject).doubleValue!)),
                y: CGFloat(((data.object(forKey: "y") as AnyObject).doubleValue!))
            ),
            species: data.object(forKey: "species") as! String,
            ownerID: data.object(forKey: "ownerID") as! String
        )
    }
    
    deinit {
        self.removeFromParent()
    }
}
