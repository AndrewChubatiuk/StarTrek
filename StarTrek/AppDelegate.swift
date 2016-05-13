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
    var species: String!
    var users_species = [String : String]()
    var spaceships = [Spaceship]()
    var spacebases = [Spacebase]()
    var crystals = [Crystal]()
    var peersList = [String : String]()
    var mpcHandler:MPCHandler = MPCHandler()
    
    func getSpaceshipByPeerName(ID: String) -> Spaceship? {
        return spaceships.filter{$0.ownerID == ID}.first
    }
    
    func isSpaceshipMine(ship: Spaceship) -> Bool {
        return ship.ownerID == mpcHandler.peerID.displayName
    }
    
    func isSpacebaseMine(base: Spacebase) -> Bool {
        return base.ownerID == mpcHandler.peerID.displayName
    }
    
    func getMySpaceship() -> Spaceship? {
        return spaceships.filter{$0.ownerID == mpcHandler.peerID.displayName}.first
    }
    
    func getMySpacebase() -> Spacebase? {
        return spacebases.filter{$0.ownerID == mpcHandler.peerID.displayName}.first
    }
    
    func deleteSpaceshipByUserID(ID: String) {
        let toBeRemoved = spaceships.filter{ $0.ownerID == ID }
        spaceships = spaceships.filter { $0.ownerID != ID }
        for ship in toBeRemoved {
            ship.removeAllActions()
            ship.removeFromParent()
        }
    }
    
    func deleteSpacebaseByUserID(ID: String) {
        let toBeRemoved = spacebases.filter{ $0.ownerID == ID }
        spacebases = spacebases.filter { $0.ownerID != ID }
        for base in toBeRemoved {
            base.removeAllActions()
            base.removeFromParent()
        }
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
    
    func deleteAllSpaceships() {
        for ship in spaceships {
            ship.removeAllActions()
            ship.removeFromParent()
        }
    }
    
    func deleteAllSpacebases() {
        for base in spacebases {
            base.removeAllActions()
            base.removeFromParent()
        }
    }
    
    func deleteMySpaceship() {
        deleteSpaceshipByUserID(mpcHandler.peerID.displayName)
    }
    
    func deleteMySpacebase() {
        deleteSpacebaseByUserID(mpcHandler.peerID.displayName)
    }
    
    func getSpacebaseByPeerName(ID: String) -> Spacebase? {
        return spacebases.filter{$0.ownerID == ID}.first
    }
    
    func allClientsInitialized() -> Bool {
        return peersList.values.contains("initialized") || peersList.values.contains("initialized")
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
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

