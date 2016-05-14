//
//  GameplayController.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 4/30/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import SpriteKit

class GameplayController: UIViewController, MCNearbyServiceBrowserDelegate {
    
    var appDelegate: AppDelegate!
    
    var scene: GameplayScene!
    var normalSize: CGSize!
    var originalOrientation: UIDeviceOrientation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scene = GameplayScene(fileNamed:"GameplayScene")
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.mpcHandler.serviceBrowser.delegate = self
        self.appDelegate.mpcHandler.serviceAdvertiser.startAdvertisingPeer()
        self.appDelegate.mpcHandler.serviceBrowser.startBrowsingForPeers()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameplayController.peerChangedStateWithNotification(_:)), name: "MPC_DidChangeStateNotification", object: nil)
            
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameplayController.handleReceivedDataWithNotification(_:)), name: "MPC_DidReceiveDataNotification", object: nil)
            
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameplayController.handleGameData(_:)), name: "SpaceshipData", object: nil)
            
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameplayController.handleGameData(_:)), name: "SpacebaseData", object: nil)
            
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameplayController.handleGameData(_:)), name: "CrystalData", object: nil)
            
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameplayController.handleGameData(_:)), name: "BulletData", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameplayController.handleGameData(_:)), name: "GameExit", object: nil)
        let skView = self.view as! SKView
        skView.showsFPS = false
        skView.multipleTouchEnabled = true
        skView.showsNodeCount = false
        skView.ignoresSiblingOrder = false
        print(skView.bounds.size)
        print(scene.size)
        originalOrientation = UIDevice.currentDevice().orientation
        var coef: CGFloat = 0
        if (skView.bounds.size.width > skView.bounds.height && scene.size.width > scene.size.height) || (skView.bounds.size.width < skView.bounds.height && scene.size.width < scene.size.height){
            if scene.size.width >= skView.bounds.size.width {
                coef = scene.size.height / skView.bounds.size.height > scene.size.width / skView.bounds.size.width ? scene.size.height / skView.bounds.size.height : scene.size.width / skView.bounds.size.width
            } else {
                coef = scene.size.height / skView.bounds.size.height > scene.size.width / skView.bounds.size.width ? scene.size.height / skView.bounds.size.height : scene.size.width / skView.bounds.size.width
            }
        } else {
            coef = scene.size.height / skView.bounds.size.width > scene.size.width / skView.bounds.size.height ? scene.size.height / skView.bounds.size.width : scene.size.width / skView.bounds.size.height
        }
        normalSize = CGSize(width: coef * skView.bounds.size.width , height: coef * skView.bounds.size.height)
        skView.bounds.size = normalSize
        scene.size = normalSize
        scene.scaleMode = .AspectFill
        print(skView.bounds.size)
        print(scene.size)
        skView.presentScene(scene)

    }
    
   override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition(nil){context in
            if (UIDevice.currentDevice().orientation.isPortrait && self.originalOrientation.isLandscape) || (UIDevice.currentDevice().orientation.isLandscape && self.originalOrientation.isPortrait) {
                self.scene.size = CGSize(width: self.normalSize.height, height: self.normalSize.width)
            } else {
                self.scene.size = self.normalSize
            }
            if self.scene.initialized == true {
                let joystickView = self.scene.camera!.childNodeWithName("joystickView")! as! SKSpriteNode
                let screenSize = self.scene.size
                let x = (joystickView.size.width - (screenSize.width))/2
                let y = (joystickView.size.height - (screenSize.height))/2
                joystickView.position = CGPoint(x: x, y: y)
            }
            
            self.scene.scaleMode = .AspectFill
            print ((self.view as! SKView).bounds.size)
            print (self.scene.size)
        }
    }
    
    func handleGameData(notification: NSNotification) {
        sendUnreliableData(notification.userInfo!)
        if notification.userInfo!["update"] as! String == "alive" {
            if notification.userInfo!["object"] as! String == "spacebase" {
                self.appDelegate.getMyPlayer()?.spacebase.removeFromParent()
            } else if notification.userInfo!["object"] as! String == "spaceship" {
                if notification.userInfo!["ownerID"] == nil {
                    NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(GameplayController.endGameLoser), userInfo: nil, repeats: false)
                } else {
                    let id = notification.userInfo!["ownerID"] as! String
                    appDelegate.getPlayerByPeerName(id)?.loserCounter = (appDelegate.getPlayerByPeerName(id)?.loserCounter)! + 1
                    for player in appDelegate.players {
                        if 2 * player.loserCounter >= self.appDelegate.players.count {
                            appDelegate.removePlayerByID(player.peerID)
                            let message = ["type": "connection", "status": "loser", "ownerID": player.peerID]
                            sendReliableData(message)
                        }
                    }
                    if self.appDelegate.players.count == 1 {
                        endGame()
                    }
                }
            }
        }
    }
    
    
    func endGameLoser() {
        let gameplayController = self.storyboard?.instantiateViewControllerWithIdentifier("ExitGameController") as? ExitGameController
        gameplayController?.gameOverText = "loser"
        self.appDelegate.mpcHandler.serviceBrowser.stopBrowsingForPeers()
        self.appDelegate.mpcHandler.serviceAdvertiser.stopAdvertisingPeer()
        appDelegate.mpcHandler.session.disconnect()
        self.appDelegate.removeMyPlayer()
        self.presentViewController(gameplayController!, animated: true, completion: nil)
    }
    
    func peerChangedStateWithNotification(notification: NSNotification){
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.objectForKey("state") as! Int
        let peerID = userInfo.objectForKey("peerID") as! MCPeerID
        if state == MCSessionState.Connected.rawValue {
            for player in appDelegate.players {
                if player.peerID == peerID.displayName {
                    player.status = PlayerStatus.Initialized
                }
            }
        } else if state == MCSessionState.NotConnected.rawValue {
            NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(GameplayController.checkPeer), userInfo: ["peerID": peerID.displayName], repeats: false)
        }
    }
    
    func checkPeer(timer: NSTimer) {
        let peerID = (timer.userInfo as! [String : String])["peerID"]
        if appDelegate.getPlayerByPeerName(peerID!) != nil {
            if appDelegate.getPlayerByPeerName(peerID!)!.status == PlayerStatus.Initialized {
                if self.appDelegate.mpcHandler.session.connectedPeers.count == 0 && self.appDelegate.players.count > 2 {
                    appDelegate.removePlayerByID(peerID!)
                    endGameLoser()
                } else {
                    appDelegate.removePlayerByID(peerID!)
                    endGame()
                }
            }
        }
    }
    
    func handleReceivedDataWithNotification(notification: NSNotification){
        let userInfo = notification.userInfo! as Dictionary
        let receivedData:NSData = userInfo["data"] as! NSData
        var message:NSDictionary!
        do{
            try message = NSJSONSerialization.JSONObjectWithData(receivedData, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
        } catch {
            
        }
        let senderPeerId:MCPeerID = userInfo["peerID"] as! MCPeerID
        let senderDisplayName = senderPeerId.displayName
        print(senderPeerId.displayName)
        if message.objectForKey("status")?.isEqualToString("loser") == true {
            self.appDelegate.getMyPlayer()?.loserCounter = (self.appDelegate.getMyPlayer()?.loserCounter)! + 1
        } else if message.objectForKey("type")?.isEqualToString("data") == true {
            if message.objectForKey("object")?.isEqualToString("spacebase") == true {
                if message.objectForKey("update")?.isEqualToString("alive") == true {
                    self.appDelegate.getPlayerByPeerName(senderDisplayName)?.spacebase.removeFromParent()
                }
            } else if message.objectForKey("object")?.isEqualToString("spaceship") == true {
                if message.objectForKey("update")?.isEqualToString("alive") == true {
                    if message.objectForKey("ownerID") != nil {
                        let ownerName = message.objectForKey("ownerID") as! String
                        self.appDelegate.getPlayerByPeerName(ownerName)?.spaceship.updateObject(message)
                        self.appDelegate.getPlayerByPeerName(ownerName)?.loserCounter = (self.appDelegate.getPlayerByPeerName(ownerName)?.loserCounter)! + 1
                        for player in self.appDelegate.players {
                            if 2 * player.loserCounter >= self.appDelegate.players.count {
                                self.appDelegate.removePlayerByID(player.peerID)
                                let message = ["type": "connection", "status": "loser", "ownerID": player.peerID]
                                sendReliableData(message)
                            }
                        }
                    } else {
                        self.appDelegate.getPlayerByPeerName(senderDisplayName)?.spaceship.updateObject(message)
                        self.appDelegate.removePlayerByID(senderDisplayName)
                    }
                    if self.appDelegate.players.count == 1 {
                        NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(GameplayController.endGame), userInfo: nil, repeats: false)
                    }
                } else {
                    if self.appDelegate.getPlayerByPeerName(senderDisplayName)?.spaceship != nil {
                        self.appDelegate.getPlayerByPeerName(senderDisplayName)!.spaceship.updateObject(message)
                    }
                }
            } else if message.objectForKey("object")?.isEqualToString("spacebase") == true {
                if message.objectForKey("update")?.isEqualToString("alive") == true {
                    self.appDelegate.getPlayerByPeerName(senderDisplayName)!.spacebase.removeFromParent()
                } else {
                    self.appDelegate.getPlayerByPeerName(senderDisplayName)!.spacebase.updateObject(message)
                }
            } else if message.objectForKey("object")?.isEqualToString("crystal") == true {
                self.appDelegate.updateCrystal(message)
            } else if message.objectForKey("object")?.isEqualToString("bullet") == true {
                if self.appDelegate.getPlayerByPeerName(senderDisplayName)?.spaceship != nil {
                    self.appDelegate.getPlayerByPeerName(senderDisplayName)!.spaceship.fire()
                }
            }
        }
    }
    
    func endGame() {
        let gameplayController = self.storyboard?.instantiateViewControllerWithIdentifier("ExitGameController") as? ExitGameController
        if self.appDelegate.getMyPlayer() != nil && self.appDelegate.getMyPlayer()?.spaceship.alive == true {
            if 2 * self.appDelegate.getMyPlayer()!.loserCounter >= appDelegate.players.count {
                gameplayController?.gameOverText = "loser"
            } else {
                gameplayController?.gameOverText = "you win"
            }
        } else {
            gameplayController?.gameOverText = "loser"
        }
        self.appDelegate.mpcHandler.serviceBrowser.stopBrowsingForPeers()
        self.appDelegate.mpcHandler.serviceAdvertiser.stopAdvertisingPeer()
        appDelegate.mpcHandler.session.disconnect()
        self.appDelegate.removeMyPlayer()
        self.presentViewController(gameplayController!, animated: true, completion: nil)
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if self.appDelegate.getPlayerByPeerName(peerID.displayName) != nil && self.appDelegate.mpcHandler.session.connectedPeers.filter({$0.displayName == peerID.displayName }).count == 0 {
            self.appDelegate.mpcHandler.serviceBrowser.invitePeer(peerID, toSession: self.appDelegate.mpcHandler.session, withContext: nil, timeout: 10)
            
        }
        print(self.appDelegate.mpcHandler.session.connectedPeers)
    }
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
    }
    
    func sendReliableData(message: NSDictionary) {
        var messageData:NSData!
        do {
            try messageData = NSJSONSerialization.dataWithJSONObject(message, options: NSJSONWritingOptions.PrettyPrinted)
            try appDelegate.mpcHandler.session.sendData(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
        } catch {
            print("error: Failed to create a session")
        }
    }
    
    func sendUnreliableData(message: NSDictionary) {
        var messageData:NSData!
        do {
            try messageData = NSJSONSerialization.dataWithJSONObject(message, options: NSJSONWritingOptions.PrettyPrinted)
            try appDelegate.mpcHandler.session.sendData(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Unreliable)
        } catch {
            print("error: Failed to create a session")
        }
    }
    
    deinit {
        self.appDelegate.mpcHandler.serviceBrowser.stopBrowsingForPeers()
        self.appDelegate.mpcHandler.serviceAdvertiser.stopAdvertisingPeer()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}