//
//  AppDelegate.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 4/26/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var players = [Player]()
    var crystals = [Crystal]()
    var worldSize: Float!
    var mpcHandler:MPCHandler = MPCHandler()
    var backgroundTask: UIBackgroundTaskIdentifier!
    
    func getCreatedShips() -> [Spaceship] {
        return players.filter({$0.spaceship != nil}).map {$0.spaceship}
    }
    
    func getPlayerByPeerName(ID: String) -> Player? {
        return players.filter{$0.peerID == ID}.first
    }
    
    func getMyPlayer() -> Player? {
        let player = players.filter{$0.peerID == mpcHandler.peerID.displayName}.first
        if player?.spaceship != nil && player?.spacebase != nil {
            player?.spaceship.generateMessages = true
            player?.spacebase.generateMessages = true
        }
        return player
    }
    
    func allPlayersHaveStatus(status: Int) -> Bool {
        for player in players {
            if player.status != status {
                return false
            }
        }
        return true
    }
    
    func isSpaceshipMine(ship: Spaceship) -> Bool {
        return ship.ownerID == mpcHandler.peerID.displayName
    }
    
    func isSpacebaseMine(base: Spacebase) -> Bool {
        return base.ownerID == mpcHandler.peerID.displayName
    }
    
    func removePlayerByID(peerID: String) {
        let toBeRemoved = players.filter{ $0.peerID == peerID }
        players = players.filter{$0.peerID != peerID}
        for player in toBeRemoved {
            if player.spaceship != nil {
                player.spaceship.removeAllActions()
                player.spaceship.removeFromParent()
            }
            if player.spacebase != nil {
                player.spacebase.removeAllActions()
                player.spacebase.removeFromParent()
            }
        }
    }
    
    func removeMyPlayer() {
        removePlayerByID(mpcHandler.peerID.displayName)
    }
    
    func deleteCrystal(uid: Int) {
        let toBeRemoved = crystals.filter{ $0.uid == uid }
        crystals = crystals.filter { $0.uid != uid }
        for crystal in toBeRemoved {
            crystal.removeAllActions()
            crystal.removeFromParent()
        }
    }
    
    func deleteAllCrystals() {
        for crystal in crystals {
            crystal.removeAllActions()
            crystal.removeFromParent()
        }
    }
    
    func deleteAllPlayers() {
        for player in players {
            player.spaceship.removeAllActions()
            player.spaceship.removeFromParent()
            player.spacebase.removeAllActions()
            player.spacebase.removeFromParent()
        }
    }
    
    func updateCrystal(message: NSDictionary) {
        let uid = message.objectForKey("uid")?.integerValue
        deleteCrystal(uid!)
        let crystal = Crystal(
            location: CGPoint(
                x: CGFloat((message.objectForKey("x")?.doubleValue!)!),
                y: CGFloat((message.objectForKey("y")?.doubleValue!)!)
            ),
            uid: uid
        )
        crystals.append(crystal)
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        self.backgroundTask = application.beginBackgroundTaskWithExpirationHandler{
            application.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        self.backgroundTask = UIBackgroundTaskInvalid
    }

    func applicationWillTerminate(application: UIApplication) {
        mpcHandler.session.disconnect()
    }


}

