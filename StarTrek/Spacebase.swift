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
        super.init(texture: nil, color: UIColor.clearColor(), size: texture.size())
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        image = SKSpriteNode(texture: texture, color: UIColor.clearColor(), size: size)
        self.addChild(image)
        self.physicsBody = SKPhysicsBody(
            circleOfRadius: size.width > size.height ? size.width / 2: size.height / 2
        ) 
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.categoryBitMask = CollisionGroups.Spacebase
        self.physicsBody?.contactTestBitMask = CollisionGroups.Bullet | CollisionGroups.Spaceship
        self.physicsBody?.dynamic = true
        self.physicsBody?.usesPreciseCollisionDetection = false
        self.physicsBody?.collisionBitMask = 0
        self.position = location
        shieldBar = Bar(
            size: CGSize(
                width: 100,
                height: 12
            ),
            color: UIColor.blueColor(),
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
            color: UIColor.orangeColor(),
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
    
    func restoreShipShield(ship: Spaceship) {
        if energy >= ship.maxShield {
            ship.getShield(ship.maxShield)
            energy = energy - ship.maxShield
        } else {
            ship.getShield(energy)
            energy = 0
        }
        shieldImage.hidden = false
        if generateMessages == true {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("SpacebaseData", object: nil, userInfo: self.objectUpdatesMessage("energy"))
            })
        }
    }
    
    func getDamage(bullet: Bullet) {
        if shield > bullet.damage {
            shield = shield - bullet.damage
        } else {
            if shield > 0 {
                shield = 0
                shieldImage.hidden = true
            } else {
                die()
            }
        }
        shieldBar.setBar(shield)
        if generateMessages == true {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("SpacebaseData", object: nil, userInfo: self.objectUpdatesMessage("shield"))
            })
        }
    }
    
    func die() {
        if alive == true {
            self.alive = false
            if generateMessages == true {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("SpacebaseData", object: nil, userInfo: self.objectUpdatesMessage("alive"))
                })
            }
        }
    }
    
    func updateObject(data: NSDictionary) {
        if data.objectForKey("update")?.isEqualToString("shield") == true {
            self.shield = data.objectForKey("shield")?.integerValue
        } else if data.objectForKey("update")?.isEqualToString("energy") == true {
            self.energy = data.objectForKey("energy")?.integerValue
        } else if data.objectForKey("update")?.isEqualToString("alive") == true {
            self.alive = data.objectForKey("alive")?.boolValue
        } 
    }
    
    func objectUpdatesMessage(attribute: String) -> [String : AnyObject] {
        if attribute == "initial" {
            return [
                "ownerID": self.ownerID,
                "species": self.species,
                "x": self.position.x,
                "y": self.position.y
            ]
        } else if attribute == "shield" {
            return [
                "type": "data",
                "update": "shield",
                "object": "spacebase",
                "shield": self.shield
            ]
        } else if attribute == "alive" {
            return [
                "type": "data",
                "update": "alive",
                "object": "spacebase",
                "alive": self.alive
            ]
        } else {
            return [
                "type": "data",
                "update": "energy",
                "object": "spacebase",
                "energy": self.energy,
            ]
        }
    }
    
    static func createFromData(data: NSDictionary) -> Exchangable {
        return Spacebase(
            location: CGPoint(
                x: CGFloat((data.objectForKey("x")?.doubleValue!)!),
                y: CGFloat((data.objectForKey("y")?.doubleValue!)!)
            ),
            species: data.objectForKey("species") as! String,
            ownerID: data.objectForKey("ownerID") as! String
        )
    }
    
    deinit {
        self.removeFromParent()
    }
}