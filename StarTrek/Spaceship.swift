//
//  Starship.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 5/1/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import Foundation
import SpriteKit


class Spaceship: SKSpriteNode, Exchangable {
    
    var ownerID: String!
    var species: String!
    var reloading = false
    var sending = false
    var shield: Int!
    var alive: Bool!
    var energy: Int!
    var generateMessages = false
    let shotEnergyConsumption = 2
    let maxEnergy = 100
    let maxShield = 100
    let shotDamage = 10
    var shieldBar: Bar!
    var energyBar: Bar!
    var shieldImage: SKSpriteNode!
    var spaceshipImage: SKSpriteNode!
    var label: SKLabelNode!
    var rocket: SKEmitterNode!
    
    func updateObject(data: NSDictionary) {
        if data.objectForKey("update")?.isEqualToString("shield") == true {
            self.shield = data.objectForKey("shield")?.integerValue
        } else if data.objectForKey("update")?.isEqualToString("energy") == true {
            self.energy = data.objectForKey("energy")?.integerValue
        } else if data.objectForKey("update")?.isEqualToString("alive") == true {
            self.alive = data.objectForKey("alive")?.boolValue
            self.position = CGPoint(
                x: CGFloat((data.objectForKey("x")?.doubleValue!)!),
                y: CGFloat((data.objectForKey("y")?.doubleValue!)!)
            )
        } else if data.objectForKey("update")?.isEqualToString("movement") == true {
            let pos = CGPoint(
                x: CGFloat((data.objectForKey("x")?.doubleValue!)!),
                y: CGFloat((data.objectForKey("y")?.doubleValue!)!)
            )
            let angle = CGFloat((data.objectForKey("angle")?.doubleValue!)!)
            rocket.targetNode = self.scene
            self.spaceshipImage.zRotation = angle
            rocket.emissionAngle = angle + 3 * 3.14 / 2
            rocket.particleSpeed = 50
            self.runAction(SKAction.moveTo(
                pos,
                duration: 0.1
            ))
        }
    }
    
    func move(angle: CGFloat, velocity: CGPoint) {
        rocket.targetNode = self.scene
        self.spaceshipImage.zRotation = angle
        rocket.emissionAngle = angle + 3 * 3.14 / 2
        rocket.particleSpeed = 50
        let shipAction = SKAction.moveBy(
            CGVector(dx: velocity.x, dy: velocity.y),
            duration: 0.2
        )
        self.runAction(shipAction)
        if generateMessages == true {
            if self.sending == false {
                self.sending = true
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("SpaceshipData", object: nil, userInfo: self.objectUpdatesMessage("movement"))
                })
                NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(Spaceship.enableSending), userInfo: nil, repeats: false)
            }
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
                "object": "spaceship",
                "shield": self.shield
            ]
        } else if attribute == "energy" {
            return [
                "type": "data",
                "update": "energy",
                "object": "spaceship",
                "energy": self.energy,
            ]
        } else if attribute == "alive" {
            if generateMessages == true {
                return [
                    "type": "data",
                    "update": "alive",
                    "x": self.position.x,
                    "y": self.position.y,
                    "object": "spaceship",
                    "alive": self.alive
                ]
            } else {
                return [
                    "type": "data",
                    "update": "alive",
                    "x": self.position.x,
                    "y": self.position.y,
                    "object": "spaceship",
                    "ownerID": self.ownerID,
                    "alive": self.alive
                ]
            }
        } else {
            return [
                "type": "data",
                "update": "movement",
                "object": "spaceship",
                "angle": self.spaceshipImage.zRotation,
                "x": self.position.x,
                "y": self.position.y
            ]
        }
    }
    
    static func createFromData(data: NSDictionary) -> Exchangable {
        return Spaceship(
            location: CGPoint(
                x: CGFloat((data.objectForKey("x")?.doubleValue!)!),
                y: CGFloat((data.objectForKey("y")?.doubleValue!)!)
            ),
            species: data.objectForKey("species") as! String,
            ownerID: data.objectForKey("ownerID") as! String
        )
    }
    
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
        let texture = SKTexture(imageNamed: species + "_ship")
        self.ownerID = ownerID
        super.init(texture: nil, color: UIColor.clearColor(), size: texture.size())
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        spaceshipImage = SKSpriteNode(texture: texture, color: UIColor.clearColor(), size: texture.size())
        self.addChild(spaceshipImage)
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width > size.height ? size.width / 2 : size.height / 2)   //  y(texture: texture, size: size)
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.categoryBitMask = CollisionGroups.Spaceship
        self.physicsBody?.contactTestBitMask = CollisionGroups.Spacebase | CollisionGroups.Crystal | CollisionGroups.Bullet | CollisionGroups.Spaceship
        self.physicsBody?.collisionBitMask = CollisionGroups.Border
        self.physicsBody?.dynamic = true
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.position = location
        shieldBar = Bar(size: CGSize(width: 100, height: 12), color: UIColor.blueColor(), maxValue: maxShield)
        shieldBar.setBar(shield)
        shieldBar.position = CGPoint(x: -shieldBar.size.width/2, y: self.size.height/2)
        addChild(shieldBar)
        energyBar = Bar(size: CGSize(width: 100, height: 12), color: UIColor.orangeColor(), maxValue: maxEnergy)
        energyBar.setBar(energy)
        energyBar.position = CGPoint(x: -shieldBar.size.width/2, y: self.size.height/2 + shieldBar.size.height)
        addChild(energyBar)
        label = SKLabelNode(text: ownerID)
        label.position = CGPoint(x: 0, y: self.size.height/2 + shieldBar.size.height + energyBar.size.height)
        label.fontName = "Starjedi"
        label.fontSize = 10
        addChild(label)
        rocket = SKEmitterNode(fileNamed: "Turbine.sks")
        rocket!.particlePosition = CGPoint(x: 0, y: self.spaceshipImage.frame.minY)
        spaceshipImage.addChild(rocket!)
        shieldImage = SKSpriteNode(imageNamed: "shield")
        let radius = size.width > size.height ? size.width * 1.2 : size.height * 1.2
        shieldImage.size = CGSize(width: radius, height: radius)
        self.addChild(shieldImage)
        shieldImage.zPosition = spaceshipImage.zPosition + 1
    }
    
    func pickCrystal(crystal: Crystal) {
        if energy < maxEnergy {
            if (maxEnergy > (crystal.energy + energy)) {
                self.energy = self.energy + crystal.energy
        
            } else {
                self.energy = maxEnergy
            }
            if generateMessages == true {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("SpaceshipData", object: nil, userInfo: self.objectUpdatesMessage("energy"))
                })
            }
        }
        energyBar.setBar(energy)
    }
    
    func getShield(shield: Int) {
        if self.shield < maxShield {
            if (maxShield > (shield + self.shield)) {
                self.shield = self.shield + shield
            } else {
                self.shield = maxShield
            }
            shieldBar.setBar(energy)
            if generateMessages == true {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("SpaceshipData", object: nil, userInfo: self.objectUpdatesMessage("shield"))
                })
            }
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
                NSNotificationCenter.defaultCenter().postNotificationName("SpaceshipData", object: nil, userInfo: self.objectUpdatesMessage("shield"))
            })
        }
    }
    
    func die() {
        if alive == true {
            self.alive = false
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("SpaceshipData", object: nil, userInfo: self.objectUpdatesMessage("alive"))
            })
        }
    }
    
    func fire() {
        if reloading == false && energy >= shotEnergyConsumption {
            let destinationVector = CGVector(
                dx: -1000 * sin(self.spaceshipImage.zRotation),
                dy: 1000 * cos(self.spaceshipImage.zRotation)
            )
            let bullet = Bullet(
                ownerID: ownerID,
                start: self.position,
                destinationVector: destinationVector,
                angle: self.spaceshipImage.zRotation
            )
            self.parent!.addChild(bullet)
            bullet.generateMessages = generateMessages
            bullet.move()
            energy = energy - shotEnergyConsumption
            if generateMessages == true {
                self.reloading = true
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("SpaceshipData", object: nil, userInfo: self.objectUpdatesMessage("energy"))
                })
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(Spaceship.enableFire), userInfo: nil, repeats: false)
            }
        }
        energyBar.setBar(energy)
    }
    
    func enableFire() {
        self.reloading = false
    }
    
    func enableSending() {
        self.sending = false
    }
    
    deinit {
        self.removeFromParent()
    }
    
    
}
