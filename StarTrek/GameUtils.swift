//
//  GameUtils.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 5/14/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import Foundation
import SpriteKit

class GameUtils {
    
    static func generateRandomPointInWorld(_ worldSize: CGFloat) -> CGPoint {
        return CGPoint(
            x: CGFloat(Float(arc4random())).truncatingRemainder(dividingBy: worldSize) * 0.80 - worldSize * 0.4,
            y: CGFloat(Float(arc4random())).truncatingRemainder(dividingBy: worldSize) * 0.80 - worldSize * 0.4
        )
    }
    
    static func getCreatedShips(_ players: [Player]) -> [Spaceship] {
        return players.filter({$0.spaceship != nil}).map { player in
            return player.spaceship
        }
    }
    
    static func generateGameMap(_ worldSize: CGFloat, players: [Player]) -> [Crystal] {
        var crystals = [Crystal]()
        let minBaseDistance = Float(0.4 * worldSize)
        for player in players {
            while true {
                let location = generateRandomPointInWorld(worldSize)
                for spaceship in getCreatedShips(players) {
                    if hypotf(Float(location.x - spaceship.position.x), Float(location.y - spaceship.position.y)) < minBaseDistance {
                        continue
                    }
                }
                player.createSpaceship(location)
                break
            }
        }
        for _ in 0 ... players.count * 10 {
            let location = generateRandomPointInWorld(worldSize)
            crystals.append(Crystal(location: location, uid: nil))
        }
        return crystals
    }
}
