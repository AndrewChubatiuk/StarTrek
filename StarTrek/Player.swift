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
    
    func setupSpecies(_ species: String) {
        self.species = species
        self.status = PlayerStatus.Ready
    }
    
    func createSpaceship(_ location: CGPoint) {
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
    
    func objectUpdatesMessage(_ attribute: String) -> [String: AnyObject] {
        if attribute == "initial" {
            return [
                "peerID": peerID as AnyObject,
                "status": status as AnyObject,
                "species": species as AnyObject,
                "x": spaceship.position.x as AnyObject,
                "y": spaceship.position.y as AnyObject
            ]
        } else {
            return [
                "peerID": peerID as AnyObject,
                "status": status as AnyObject,
                "species": species as AnyObject,
                "x": spaceship.position.x as AnyObject,
                "y": spaceship.position.y as AnyObject
            ]
        }
    }
    
    static func createFromData(_ data: NSDictionary) -> Exchangable {
        let player = Player(peerID: data.object(forKey: "peerID") as! String)
        player.setupSpecies(data.object(forKey: "species") as! String)
        player.status = (data.object(forKey: "status") as AnyObject).intValue
        player.createSpaceship(
            CGPoint(
                x: CGFloat(((data.object(forKey: "x") as AnyObject).doubleValue!)),
                y: CGFloat(((data.object(forKey: "y") as AnyObject).doubleValue!))
            )
        )
        return player
    }
    
}
