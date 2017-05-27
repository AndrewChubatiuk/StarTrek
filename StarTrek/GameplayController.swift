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
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mpcHandler.serviceBrowser.delegate = self
        self.appDelegate.mpcHandler.serviceAdvertiser.startAdvertisingPeer()
        self.appDelegate.mpcHandler.serviceBrowser.startBrowsingForPeers()
        NotificationCenter.default.addObserver(self, selector: #selector(GameplayController.peerChangedStateWithNotification(_:)), name: NSNotification.Name(rawValue: "MPC_DidChangeStateNotification"), object: nil)
            
        NotificationCenter.default.addObserver(self, selector: #selector(GameplayController.handleReceivedDataWithNotification(_:)), name: NSNotification.Name(rawValue: "MPC_DidReceiveDataNotification"), object: nil)
            
        NotificationCenter.default.addObserver(self, selector: #selector(GameplayController.handleGameData(_:)), name: NSNotification.Name(rawValue: "SpaceshipData"), object: nil)
            
        NotificationCenter.default.addObserver(self, selector: #selector(GameplayController.handleGameData(_:)), name: NSNotification.Name(rawValue: "SpacebaseData"), object: nil)
            
        NotificationCenter.default.addObserver(self, selector: #selector(GameplayController.handleGameData(_:)), name: NSNotification.Name(rawValue: "CrystalData"), object: nil)
            
        NotificationCenter.default.addObserver(self, selector: #selector(GameplayController.handleGameData(_:)), name: NSNotification.Name(rawValue: "BulletData"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(GameplayController.handleGameData(_:)), name: NSNotification.Name(rawValue: "GameExit"), object: nil)
        let skView = self.view as! SKView
        skView.showsFPS = false
        skView.isMultipleTouchEnabled = true
        skView.showsNodeCount = false
        skView.ignoresSiblingOrder = false
        print(skView.bounds.size)
        print(scene.size)
        originalOrientation = UIDevice.current.orientation
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
        scene.scaleMode = .aspectFill
        print(skView.bounds.size)
        print(scene.size)
        skView.presentScene(scene)

    }
    
   override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil){context in
            if (UIDevice.current.orientation.isPortrait && self.originalOrientation.isLandscape) || (UIDevice.current.orientation.isLandscape && self.originalOrientation.isPortrait) {
                self.scene.size = CGSize(width: self.normalSize.height, height: self.normalSize.width)
            } else {
                self.scene.size = self.normalSize
            }
            if self.scene.initialized == true {
                let joystickView = self.scene.camera!.childNode(withName: "joystickView")! as! SKSpriteNode
                let screenSize = self.scene.size
                let x = (joystickView.size.width - (screenSize.width))/2
                let y = (joystickView.size.height - (screenSize.height))/2
                joystickView.position = CGPoint(x: x, y: y)
            }
            
            self.scene.scaleMode = .aspectFill
            print ((self.view as! SKView).bounds.size)
            print (self.scene.size)
        }
    }
    
    func handleGameData(_ notification: Notification) {
        sendUnreliableData(notification.userInfo! as NSDictionary)
        if notification.userInfo!["update"] != nil && notification.userInfo!["update"] as! String == "alive" {
            if notification.userInfo!["object"] as! String == "spacebase" {
                self.appDelegate.getMyPlayer()?.spacebase.removeFromParent()
            } else if notification.userInfo!["object"] as! String == "spaceship" {
                if notification.userInfo!["ownerID"] == nil {
                    Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(GameplayController.endGameLoser), userInfo: nil, repeats: false)
                } else {
                    let id = notification.userInfo!["ownerID"] as! String
                    appDelegate.getPlayerByPeerName(id)?.loserCounter = (appDelegate.getPlayerByPeerName(id)?.loserCounter)! + 1
                    for player in appDelegate.players {
                        if 2 * player.loserCounter >= self.appDelegate.players.count {
                            appDelegate.removePlayerByID(player.peerID)
                            let message = ["status": PlayerStatus.Loser, "ownerID": player.peerID] as [String : Any]
                            sendReliableData(message as NSDictionary)
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
        let gameplayController = self.storyboard?.instantiateViewController(withIdentifier: "ExitGameController") as? ExitGameController
        gameplayController?.gameOverText = "loser"
        close()
        appDelegate.mpcHandler.session.disconnect()
        self.appDelegate.removeMyPlayer()
        self.present(gameplayController!, animated: true, completion: nil)
    }
    
    func peerChangedStateWithNotification(_ notification: Notification){
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.object(forKey: "state") as! Int
        let peerID = userInfo.object(forKey: "peerID") as! MCPeerID
        if state == MCSessionState.connected.rawValue {
            for player in appDelegate.players {
                if player.peerID == peerID.displayName {
                    player.status = PlayerStatus.Initialized
                }
            }
        } else if state == MCSessionState.notConnected.rawValue {
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(GameplayController.checkPeer), userInfo: ["peerID": peerID.displayName], repeats: false)
        }
    }
    
    func checkPeer(_ timer: Timer) {
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
    
    func handleReceivedDataWithNotification(_ notification: Notification){
        let userInfo = notification.userInfo! as Dictionary
        let receivedData:Data = userInfo["data"] as! Data
        var message:NSDictionary!
        do{
            try message = JSONSerialization.jsonObject(with: receivedData, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
        } catch {
            
        }
        let senderPeerId:MCPeerID = userInfo["peerID"] as! MCPeerID
        let senderDisplayName = senderPeerId.displayName
        if (message.object(forKey: "status") as! Int) ==  PlayerStatus.Loser {
            self.appDelegate.getMyPlayer()?.loserCounter = (self.appDelegate.getMyPlayer()?.loserCounter)! + 1
        } else if (message.object(forKey: "object") as AnyObject).isEqual(to: "bullet") == true {
            if self.appDelegate.getPlayerByPeerName(senderDisplayName)?.spaceship != nil {
                self.appDelegate.getPlayerByPeerName(senderDisplayName)!.spaceship.fire()
            }
        } else {
            let objectName = message.object(forKey: "object") as! String
            let update = message.object(forKey: "update") as! String
            if objectName == "spacebase" {
                if update == "alive" {
                    self.appDelegate.getPlayerByPeerName(senderDisplayName)?.spacebase.removeFromParent()
                }
            } else if objectName == "spaceship" {
                if update == "alive" {
                    if message.object(forKey: "ownerID") != nil {
                        let ownerName = message.object(forKey: "ownerID") as! String
                        self.appDelegate.getPlayerByPeerName(ownerName)?.spaceship.updateObject(message)
                        self.appDelegate.getPlayerByPeerName(ownerName)?.loserCounter = (self.appDelegate.getPlayerByPeerName(ownerName)?.loserCounter)! + 1
                        for player in self.appDelegate.players {
                            if 2 * player.loserCounter >= self.appDelegate.players.count {
                                self.appDelegate.removePlayerByID(player.peerID)
                                let message = ["status": PlayerStatus.Loser, "ownerID": player.peerID] as [String : Any]
                                sendReliableData(message as NSDictionary)
                            }
                        }
                    } else {
                        self.appDelegate.getPlayerByPeerName(senderDisplayName)?.spaceship.updateObject(message)
                        self.appDelegate.removePlayerByID(senderDisplayName)
                    }
                    if self.appDelegate.players.count == 1 {
                        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(GameplayController.endGame), userInfo: nil, repeats: false)
                    }
                } else {
                    if self.appDelegate.getPlayerByPeerName(senderDisplayName)?.spaceship != nil {
                        self.appDelegate.getPlayerByPeerName(senderDisplayName)!.spaceship.updateObject(message)
                    }
                }
            } else if objectName == "spacebase" {
                if update == "alive" {
                    self.appDelegate.getPlayerByPeerName(senderDisplayName)!.spacebase.removeFromParent()
                } else {
                    self.appDelegate.getPlayerByPeerName(senderDisplayName)!.spacebase.updateObject(message)
                }
            } else if objectName == "crystal" {
                self.appDelegate.updateCrystal(message)
            }
        }
    }
    
    func endGame() {
        let gameplayController = self.storyboard?.instantiateViewController(withIdentifier: "ExitGameController") as? ExitGameController
        if self.appDelegate.getMyPlayer() != nil && self.appDelegate.getMyPlayer()?.spaceship.alive == true {
            if 2 * self.appDelegate.getMyPlayer()!.loserCounter >= appDelegate.players.count {
                gameplayController?.gameOverText = "loser"
            } else {
                gameplayController?.gameOverText = "you win"
            }
        } else {
            gameplayController?.gameOverText = "loser"
        }
        close()
        appDelegate.mpcHandler.session.disconnect()
        self.appDelegate.removeMyPlayer()
        self.present(gameplayController!, animated: true, completion: nil)
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if self.appDelegate.getPlayerByPeerName(peerID.displayName) != nil && self.appDelegate.mpcHandler.session.connectedPeers.filter({$0.displayName == peerID.displayName }).count == 0 {
            self.appDelegate.mpcHandler.serviceBrowser.invitePeer(peerID, to: self.appDelegate.mpcHandler.session, withContext: nil, timeout: 10)
            
        }
        print(self.appDelegate.mpcHandler.session.connectedPeers)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
    }
    
    func sendReliableData(_ message: NSDictionary) {
        var messageData:Data!
        do {
            try messageData = JSONSerialization.data(withJSONObject: message, options: JSONSerialization.WritingOptions.prettyPrinted)
            try appDelegate.mpcHandler.session.send(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: MCSessionSendDataMode.reliable)
        } catch {
            print("error: Failed to create a session")
        }
    }
    
    func sendUnreliableData(_ message: NSDictionary) {
        var messageData:Data!
        do {
            try messageData = JSONSerialization.data(withJSONObject: message, options: JSONSerialization.WritingOptions.prettyPrinted)
            try appDelegate.mpcHandler.session.send(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: MCSessionSendDataMode.unreliable)
        } catch {
            print("error: Failed to create a session")
        }
    }
    
    func close() {
        self.appDelegate.mpcHandler.serviceBrowser.stopBrowsingForPeers()
        self.appDelegate.mpcHandler.serviceAdvertiser.stopAdvertisingPeer()
        NotificationCenter.default.removeObserver(self)
    }
}
