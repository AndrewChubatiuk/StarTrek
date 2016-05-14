//
//  ConnectionsListController.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 4/30/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

class ConnectionsListController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var startButton: UIButton!
    var appDelegate:AppDelegate!
    @IBOutlet var connectionsTable: UITableView!
    
    @IBAction func sendGeneratedMap(sender: UIButton) {
        appDelegate.worldSize = Float(self.appDelegate.players.count * 1000)
        appDelegate.crystals = GameUtils.generateGameMap(
            CGFloat(appDelegate.worldSize),
            players: self.appDelegate.players
        )
        self.appDelegate.getMyPlayer()?.status = PlayerStatus.Initialized
        let messageDict = [
            "type": "data",
            "status": PlayerStatus.Initialize,
            "worldSize": appDelegate.worldSize,
            "players": Message.createMessageArray(appDelegate.players),
            "crystals": Message.createMessageArray(appDelegate.crystals)
        ]
        sendReliableData(messageDict)
    }
    
    override func viewDidLoad()
    {
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        super.viewDidLoad()
        if self.appDelegate.getMyPlayer()!.server == false {
            self.startButton.enabled = false
            self.startButton.hidden = true
        }
        if self.appDelegate.players.count <= 1 && self.appDelegate.getMyPlayer()!.server == true {
            self.startButton.enabled = false
            self.startButton.hidden = true
            appDelegate.mpcHandler.serviceAdvertiser.startAdvertisingPeer()
        }
        if self.appDelegate.getMyPlayer()!.server == false {
            sendReady()
        }
        self.connectionsTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: "connectionCell")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConnectionsListController.peerChangedStateWithNotification(_:)), name: "MPC_DidChangeStateNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConnectionsListController.handleReceivedDataWithNotification(_:)), name: "MPC_DidReceiveDataNotification", object: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destViewController: GameplayController = segue.destinationViewController as! GameplayController
    }
    
    @IBAction func previousView(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.appDelegate.players.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ConnectionTableViewCell", forIndexPath: indexPath) as! ConnectionTableViewCell
        let player = self.appDelegate.players[indexPath.row]
        cell.loadItem(player.peerID, status: player.status)
        return cell
    }
    
    func peerChangedStateWithNotification(notification: NSNotification){
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.objectForKey("state") as! Int
        let peerID = userInfo.objectForKey("peerID") as! MCPeerID
        if state == MCSessionState.Connected.rawValue {
            self.appDelegate.players.append(
                Player(peerID: peerID.displayName)
            )
        } else if state == MCSessionState.NotConnected.rawValue {
            self.appDelegate.removePlayerByID(peerID.displayName)
            if self.appDelegate.players.count == 1 && self.appDelegate.getMyPlayer()!.server == true {
                self.startButton.enabled = false
                self.startButton.hidden = true
            }
        }
        connectionsTable.reloadData()
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
        
        if message.objectForKey("type")?.isEqualToString("connection") == true {
            if message.objectForKey("status")?.isEqualToNumber(PlayerStatus.Ready) == true {
                var player = self.appDelegate.getPlayerByPeerName(senderDisplayName)
                if player == nil {
                    player = Player(peerID: senderDisplayName)
                    player!.setupSpecies(message.objectForKey("species") as! String)
                    self.appDelegate.players.append(player!)
                } else {
                    player!.setupSpecies(message.objectForKey("species") as! String)
                }
                if appDelegate.allPlayersHaveStatus(PlayerStatus.Ready) && self.appDelegate.getMyPlayer()!.server == true {
                    self.startButton.enabled = true
                    self.startButton.hidden = false
                } else {
                    self.startButton.enabled = false
                    self.startButton.hidden = true
                }
            } else if message.objectForKey("status")?.isEqualToNumber(PlayerStatus.Load) == true {
                let gameplayController = self.storyboard?.instantiateViewControllerWithIdentifier("GameplayController") as? GameplayController
                NSNotificationCenter.defaultCenter().removeObserver(self)
                self.presentViewController(gameplayController!, animated: true, completion: nil)
            }
        } else if message.objectForKey("type")?.isEqualToString("data") == true {
            if message.objectForKey("status")?.isEqualToNumber(PlayerStatus.Initialize) == true && self.appDelegate.getMyPlayer()!.server == false {
                self.appDelegate.players = Message.unpackMessageArray(self.appDelegate.players, data: message.objectForKey("players") as! NSArray)
                self.appDelegate.crystals = Message.unpackMessageArray(self.appDelegate.crystals, data: message.objectForKey("crystals") as! NSArray)
                self.appDelegate.worldSize = message.objectForKey("worldSize")?.floatValue
                let messageDict = [
                    "type": "data",
                    "status": PlayerStatus.Initialized,
                ]
                sendReliableData(messageDict)
            } else if message.objectForKey("status")?.isEqualToNumber(PlayerStatus.Initialized) == true && self.appDelegate.getMyPlayer()!.server == true {
                self.appDelegate.getPlayerByPeerName(senderDisplayName)!.status = PlayerStatus.Initialized
                if self.appDelegate.allPlayersHaveStatus(PlayerStatus.Initialized) {
                    sendLoad()
                    let gameplayController = self.storyboard?.instantiateViewControllerWithIdentifier("GameplayController") as? GameplayController
                    NSNotificationCenter.defaultCenter().removeObserver(self)
                    self.presentViewController(gameplayController!, animated: true, completion: nil)
                }
            }
        }
        connectionsTable.reloadData()
        
    }
    
    func sendLoad() {
        let messageDict = [
            "type": "connection",
            "status": PlayerStatus.Load,
        ]
        sendReliableData(messageDict)
    }
    
    func sendReady() {
        
        let messageDict = [
            "type": "connection",
            "status": PlayerStatus.Ready,
            "species": (self.appDelegate.getMyPlayer()?.species)!
        ]
        sendReliableData(messageDict)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    deinit {
        appDelegate.mpcHandler.serviceAdvertiser.stopAdvertisingPeer()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}