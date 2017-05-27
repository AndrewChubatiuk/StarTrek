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
    
    func updateObject(_ data: NSDictionary) {
        if (data.object(forKey: "update") as AnyObject).isEqual(to: "shield") == true {
            self.shield = (data.object(forKey: "shield") as AnyObject).intValue
        } else if (data.object(forKey: "update") as AnyObject).isEqual(to: "energy") == true {
            self.energy = (data.object(forKey: "energy") as AnyObject).intValue
        } else if (data.object(forKey: "update") as AnyObject).isEqual(to: "alive") == true {
            self.alive = (data.object(forKey: "alive") as AnyObject).boolValue
            self.position = CGPoint(
                x: CGFloat(((data.object(forKey: "x") as AnyObject).doubleValue!)),
                y: CGFloat(((data.object(forKey: "y") as AnyObject).doubleValue!))
            )
        } else if (data.object(forKey: "update") as AnyObject).isEqual(to: "movement") == true {
            let pos = CGPoint(
                x: CGFloat(((data.object(forKey: "x") as AnyObject).doubleValue!)),
                y: CGFloat(((data.object(forKey: "y") as AnyObject).doubleValue!))
            )
            let angle = CGFloat(((data.object(forKey: "angle") as AnyObject).doubleValue!))
            self.spaceshipImage.zRotation = angle
            self.rocket.targetNode = self.scene
            rocket.emissionAngle = angle + 3 * 3.14 / 2
            self.run(SKAction.move(
                to: pos,
                duration: 0.1
            ))
        }
    }
    
    func move(_ angle: CGFloat, velocity: CGPoint) {
        self.spaceshipImage.zRotation = angle
        rocket.emissionAngle = angle + 3 * 3.14 / 2
        let shipAction = SKAction.move(
            by: CGVector(dx: velocity.x, dy: velocity.y),
            duration: 0.2
        )
        self.rocket.targetNode = self.scene
        self.run(shipAction)
        rocket.particleSpeed = 100 * CGFloat(hypotf(Float(velocity.x), Float(velocity.y)))
        if generateMessages == true {
            if self.sending == false {
                self.sending = true
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "SpaceshipData"), object: nil, userInfo: self.objectUpdatesMessage("movement"))
                })
                Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(Spaceship.enableSending), userInfo: nil, repeats: false)
            }
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
                "object": "spaceship" as AnyObject,
                "shield": self.shield as AnyObject
            ]
        } else if attribute == "energy" {
            return [
                "update": "energy" as AnyObject,
                "object": "spaceship" as AnyObject,
                "energy": self.energy as AnyObject,
            ]
        } else if attribute == "alive" {
            if generateMessages == true {
                return [
                    "update": "alive" as AnyObject,
                    "x": self.position.x as AnyObject,
                    "y": self.position.y as AnyObject,
                    "object": "spaceship" as AnyObject,
                    "alive": self.alive as AnyObject
                ]
            } else {
                return [
                    "update": "alive" as AnyObject,
                    "x": self.position.x as AnyObject,
                    "y": self.position.y as AnyObject,
                    "object": "spaceship" as AnyObject,
                    "ownerID": self.ownerID as AnyObject,
                    "alive": self.alive as AnyObject
                ]
            }
        } else {
            return [
                "update": "movement" as AnyObject,
                "object": "spaceship" as AnyObject,
                "angle": self.spaceshipImage.zRotation as AnyObject,
                "x": self.position.x as AnyObject,
                "y": self.position.y as AnyObject
            ]
        }
    }
    
    static func createFromData(_ data: NSDictionary) -> Exchangable {
        return Spaceship(
            location: CGPoint(
                x: CGFloat(((data.object(forKey: "x") as AnyObject).doubleValue!)),
                y: CGFloat(((data.object(forKey: "y") as AnyObject).doubleValue!))
            ),
            species: data.object(forKey: "species") as! String,
            ownerID: data.object(forKey: "ownerID") as! String
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
        super.init(texture: nil, color: UIColor.clear, size: texture.size())
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        spaceshipImage = SKSpriteNode(texture: texture, color: UIColor.clear, size: texture.size())
        self.addChild(spaceshipImage)
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width > size.height ? size.width / 2 : size.height / 2)   //  y(texture: texture, size: size)
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.categoryBitMask = CollisionGroups.Spaceship
        self.physicsBody?.contactTestBitMask = CollisionGroups.Spacebase | CollisionGroups.Crystal | CollisionGroups.Bullet | CollisionGroups.Spaceship
        self.physicsBody?.collisionBitMask = CollisionGroups.Border
        self.physicsBody?.isDynamic = true
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.position = location
        shieldBar = Bar(size: CGSize(width: 100, height: 12), color: UIColor.blue, maxValue: maxShield)
        shieldBar.setBar(shield)
        shieldBar.position = CGPoint(x: -shieldBar.size.width/2, y: self.size.height/2)
        addChild(shieldBar)
        energyBar = Bar(size: CGSize(width: 100, height: 12), color: UIColor.orange, maxValue: maxEnergy)
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
        rocket.targetNode = self.scene
        rocket.particleSpeed = 500
        rocket.emissionAngleRange = 3.14 / 8
        spaceshipImage.addChild(rocket!)
        shieldImage = SKSpriteNode(imageNamed: "shield")
        let radius = size.width > size.height ? size.width * 1.2 : size.height * 1.2
        shieldImage.size = CGSize(width: radius, height: radius)
        self.addChild(shieldImage)
        shieldImage.zPosition = spaceshipImage.zPosition + 1
    }
    
    func pickCrystal(_ crystal: Crystal) {
        if energy < maxEnergy {
            if (maxEnergy > (crystal.energy + energy)) {
                self.energy = self.energy + crystal.energy
        
            } else {
                self.energy = maxEnergy
            }
            if generateMessages == true {
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "SpaceshipData"), object: nil, userInfo: self.objectUpdatesMessage("energy"))
                })
            }
        }
        energyBar.setBar(energy)
    }
    
    func getShield(_ shield: Int) {
        if self.shield < maxShield {
            if (maxShield > (shield + self.shield)) {
                self.shield = self.shield + shield
            } else {
                self.shield = maxShield
            }
            shieldBar.setBar(energy)
            if generateMessages == true {
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "SpaceshipData"), object: nil, userInfo: self.objectUpdatesMessage("shield"))
                })
            }
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
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SpaceshipData"), object: nil, userInfo: self.objectUpdatesMessage("shield"))
            })
        }
    }
    
    func die() {
        if alive == true {
            self.alive = false
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: "SpaceshipData"), object: nil, userInfo: self.objectUpdatesMessage("alive"))
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
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "SpaceshipData"), object: nil, userInfo: self.objectUpdatesMessage("energy"))
                })
                Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(Spaceship.enableFire), userInfo: nil, repeats: false)
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
