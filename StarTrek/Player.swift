//
//  Player.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 5/14/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import MultipeerConnectivity
import SpriteKit
import Foundation

struct PlayerStatus {
    static let Ready: Int = 1
    static let Waiting: Int = 2
    static let Initialized: Int = 3
    static let Loaded: Int = 4
    static let Synchronize: Int = 5
    static let Load: Int = 6
    static let Initialize: Int = 7
    static let Loser: Int = 8
}

class Player : NSObject, Exchangable {
    
    var status: Int!
    var peerID: String!
    var loserCounter = 0
    var species: String!
    var spaceship: Spaceship!
    var spacebase: Spacebase!
    var server: Bool!
    
    init(peerID: String) {
        self.peerID = peerID
        self.status = PlayerStatus.Waiting
        self.server = true
    }
    
    func setupSpecies(species: String) {
        self.species = species
        self.status = PlayerStatus.Ready
    }
    
    func createSpaceship(location: CGPoint) {
        self.spaceship = Spaceship(location: location, species: species, ownerID: peerID)
        self.spacebase = Spacebase(location: location, species: species, ownerID: peerID)
    }
    
    func getInfo() -> NSDictionary {
        return [
            "status": status,
            "peerID": peerID,
            
        ]
    }
    
    func getStatusMap() -> NSDictionary {
        if species != nil {
            return [
                "status": status,
                "peerID": peerID,
                "species": species
            ]
        } else {
            return [
                "status": status,
                "peerID": peerID
            ]
        }
    }
    
    func objectUpdatesMessage(attribute: String) -> [String: AnyObject] {
        if attribute == "initial" {
            return [
                "peerID": peerID,
                "status": status,
                "species": species,
                "x": spaceship.position.x,
                "y": spaceship.position.y
            ]
        } else {
            return [
                "peerID": peerID,
                "status": status,
                "species": species,
                "x": spaceship.position.x,
                "y": spaceship.position.y
            ]
        }
    }
    
    static func createFromData(data: NSDictionary) -> Exchangable {
        let player = Player(peerID: data.objectForKey("peerID") as! String)
        player.setupSpecies(data.objectForKey("species") as! String)
        player.status = data.objectForKey("status")?.integerValue
        player.createSpaceship(
            CGPoint(
                x: CGFloat((data.objectForKey("x")?.doubleValue!)!),
                y: CGFloat((data.objectForKey("y")?.doubleValue!)!)
            )
        )
        return player
    }
    
}