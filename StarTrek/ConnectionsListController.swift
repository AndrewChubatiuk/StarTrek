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
    var server: Bool!
    
    @IBAction func sendGeneratedMap(sender: UIButton) {
        let mapObjects = generateGameMap()
        appDelegate.spacebases = mapObjects.spacebases
        appDelegate.spaceships = mapObjects.spaceships
        appDelegate.crystals = mapObjects.crystals
        self.appDelegate.peersList[self.appDelegate.mpcHandler.peerID.displayName] = "initialized"
        let messageDict = [
            "type":"data",
            "status": "initialize",
            "spacebases": Message.createMessageArray(mapObjects.spacebases),
            "spaceships": Message.createMessageArray(mapObjects.spaceships),
            "crystals": Message.createMessageArray(mapObjects.crystals)
        ]
        self.appDelegate.getMySpacebase()?.generateMessages = true
        self.appDelegate.getMySpaceship()?.generateMessages = true
        var messageData:NSData!
        do {
            try messageData = NSJSONSerialization.dataWithJSONObject(messageDict, options: NSJSONWritingOptions.PrettyPrinted)
        } catch {
        }
        do {
            try appDelegate.mpcHandler.session.sendData(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
        } catch {
            print("error: Failed to create a session")
        }
        
    }
    
    override func viewDidLoad()
    {
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        super.viewDidLoad()
        if server == false {
            self.startButton.enabled = false
            self.startButton.hidden = true
        }
        if self.appDelegate.peersList.count <= 1 && server == true {
            self.startButton.enabled = false
            self.startButton.hidden = true
            appDelegate.mpcHandler.serviceAdvertiser.startAdvertisingPeer()
        }
        if server == false {
            sendReady()
        }
        self.appDelegate.peersList[self.appDelegate.mpcHandler.peerID.displayName] = PlayerStatus.Ready
        self.appDelegate.users_species[self.appDelegate.mpcHandler.peerID.displayName] = self.appDelegate.species
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
        return self.appDelegate.peersList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ConnectionTableViewCell", forIndexPath: indexPath) as! ConnectionTableViewCell
        let peerID = Array(self.appDelegate.peersList.keys)[indexPath.row]
        cell.loadItem(peerID, status: self.appDelegate.peersList[peerID]!)
        return cell
    }
    
    func peerChangedStateWithNotification(notification: NSNotification){
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.objectForKey("state") as! Int
        let peerID = userInfo.objectForKey("peerID") as! MCPeerID
        if state == MCSessionState.Connected.rawValue {
            self.appDelegate.peersList[peerID.displayName] = PlayerStatus.Waiting
        } else if state == MCSessionState.NotConnected.rawValue {
            self.appDelegate.peersList.removeValueForKey(peerID.displayName)
            if self.appDelegate.peersList.count == 1 && server == true {
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
            if message.objectForKey("status")?.isEqualToString(PlayerStatus.Ready) == true && server == true {
                self.appDelegate.peersList[senderDisplayName] = PlayerStatus.Ready
                self.startButton.enabled = true
                self.startButton.hidden = false
                self.appDelegate.users_species[senderDisplayName] = message.objectForKey("species") as! String
                sendNeighbourTable()
                
            } else if message.objectForKey("status")?.isEqualToString("synchronize") == true && server == false {
                self.appDelegate.peersList = message.objectForKey("neighbours") as! [String:String]
            } else if message.objectForKey("status")?.isEqualToString("load") == true && server == false {
                let gameplayController = self.storyboard?.instantiateViewControllerWithIdentifier("GameplayController") as? GameplayController
                self.presentViewController(gameplayController!, animated: true, completion: nil)
            }
        } else if message.objectForKey("type")?.isEqualToString("data") == true {
            if message.objectForKey("status")?.isEqualToString("initialize") == true && server == false {
                self.appDelegate.spacebases = Message.unpackMessageArray(self.appDelegate.spacebases, data: message.objectForKey("spacebases") as! NSArray)
                self.appDelegate.spaceships = Message.unpackMessageArray(self.appDelegate.spaceships, data: message.objectForKey("spaceships") as! NSArray)
                self.appDelegate.crystals = Message.unpackMessageArray(self.appDelegate.crystals, data: message.objectForKey("crystals") as! NSArray)
                self.appDelegate.getMySpacebase()?.generateMessages = true
                self.appDelegate.getMySpaceship()?.generateMessages = true
                let messageDict = [
                    "type": "data",
                    "status": "initialized",
                ]
                var messageData:NSData!
                do {
                    try messageData = NSJSONSerialization.dataWithJSONObject(messageDict, options: NSJSONWritingOptions.PrettyPrinted)
                } catch {
                }
                do {
                    try appDelegate.mpcHandler.session.sendData(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
                } catch {
                    print("error: Failed to create a session")
                }
            } else if message.objectForKey("status")?.isEqualToString("initialized") == true && server == true {
                self.appDelegate.peersList[senderDisplayName] = "initialized"
                if self.appDelegate.allClientsInitialized() {
                    sendLoad()
                    let gameplayController = self.storyboard?.instantiateViewControllerWithIdentifier("GameplayController") as? GameplayController
                    self.presentViewController(gameplayController!, animated: true, completion: nil)
                }
            }
        }
        connectionsTable.reloadData()
        
    }
    
    func sendLoad() {
        let messageDict = [
            "type": "connection",
            "status": "load",
        ]
        var messageData:NSData!
        do {
            try messageData = NSJSONSerialization.dataWithJSONObject(messageDict, options: NSJSONWritingOptions.PrettyPrinted)
        } catch {
        }
        do {
            try appDelegate.mpcHandler.session.sendData(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
        } catch {
            print("error: Failed to create a session")
        }
    }
    
    func generateGameMap() -> (spaceships: [Spaceship], spacebases: [Spacebase], crystals: [Crystal]){
        var spaceships = [Spaceship]()
        var spacebases = [Spacebase]()
        var crystals = [Crystal]()
        //let xPos = CGFloat(Float(arc4random())) % 15000 - 5000
        //let yPos = CGFloat(Float(arc4random())) % 15000 - 5000
        for (player, _) in self.appDelegate.peersList {
            let xPos = CGFloat(Float(arc4random())) % 1500 - 500
            let yPos = CGFloat(Float(arc4random())) % 1500 - 500
            let location = CGPoint(x: xPos, y: yPos )
            spacebases.append(Spacebase(location: location, species: self.appDelegate.users_species[player]!, ownerID: player))
            spaceships.append(Spaceship(location: location, species: self.appDelegate.users_species[player]!, ownerID: player))
        }
        for _ in 0 ... (self.appDelegate.peersList.count) * 10 {
            let xPos = CGFloat(Float(arc4random())) % 1500 - 500
            let yPos = CGFloat(Float(arc4random())) % 1500 - 500
            let location = CGPoint(x: xPos, y: yPos)
            crystals.append(Crystal(location: location, uid: nil))
        }
        return (spaceships, spacebases, crystals)
    }
    
    func sendNeighbourTable() {
        let messageDict = [
            "type": "connection",
            "status": "synchronize",
            "neighbours": self.appDelegate.peersList
        ]
        var messageData:NSData!
        do {
            try messageData = NSJSONSerialization.dataWithJSONObject(messageDict, options: NSJSONWritingOptions.PrettyPrinted)
        } catch {
        }
        do {
            try appDelegate.mpcHandler.session.sendData(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
        } catch {
            print("error: Failed to create a session")
        }
    }
    
    func sendReady() {
        
        let messageDict = [
            "type":"connection",
            "status": PlayerStatus.Ready,
            "species": self.appDelegate.species
        ]
        var messageData:NSData!
        do {
            try messageData = NSJSONSerialization.dataWithJSONObject(messageDict, options: NSJSONWritingOptions.PrettyPrinted)
        } catch {
        }
        do {
            try appDelegate.mpcHandler.session.sendData(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
        } catch {
            print("error: Failed to create a session")
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        appDelegate.mpcHandler.serviceAdvertiser.stopAdvertisingPeer()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}