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
    
    @IBAction func sendGeneratedMap(_ sender: UIButton) {
        appDelegate.worldSize = Float(self.appDelegate.players.count * 1000)
        appDelegate.crystals = GameUtils.generateGameMap(
            CGFloat(appDelegate.worldSize),
            players: self.appDelegate.players
        )
        self.appDelegate.getMyPlayer()?.status = PlayerStatus.Initialized
        let messageDict = [
            "status": PlayerStatus.Initialize,
            "worldSize": appDelegate.worldSize,
            "players": Message.createMessageArray(appDelegate.players),
            "crystals": Message.createMessageArray(appDelegate.crystals)
        ] as [String : Any]
        sendReliableData(messageDict as NSDictionary)
    }
    
    override func viewDidLoad()
    {
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        super.viewDidLoad()
        if self.appDelegate.getMyPlayer()!.server == false {
            self.startButton.isEnabled = false
            self.startButton.isHidden = true
        }
        if self.appDelegate.players.count <= 1 && self.appDelegate.getMyPlayer()!.server == true {
            self.startButton.isEnabled = false
            self.startButton.isHidden = true
            appDelegate.mpcHandler.serviceAdvertiser.startAdvertisingPeer()
        }
        if self.appDelegate.getMyPlayer()!.server == false {
            sendReady()
        }
        self.connectionsTable.register(UITableViewCell.self, forCellReuseIdentifier: "connectionCell")
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectionsListController.peerChangedStateWithNotification(_:)), name: NSNotification.Name(rawValue: "MPC_DidChangeStateNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectionsListController.handleReceivedDataWithNotification(_:)), name: NSNotification.Name(rawValue: "MPC_DidReceiveDataNotification"), object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destViewController: GameplayController = segue.destination as! GameplayController
    }
    
    @IBAction func previousView(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.appDelegate.players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConnectionTableViewCell", for: indexPath) as! ConnectionTableViewCell
        let player = self.appDelegate.players[indexPath.row]
        cell.loadItem(player.peerID, status: player.status)
        return cell
    }
    
    func peerChangedStateWithNotification(_ notification: Notification){
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.object(forKey: "state") as! Int
        let peerID = userInfo.object(forKey: "peerID") as! MCPeerID
        if state == MCSessionState.connected.rawValue {
            self.appDelegate.players.append(
                Player(peerID: peerID.displayName)
            )
        } else if state == MCSessionState.notConnected.rawValue {
            self.appDelegate.removePlayerByID(peerID.displayName)
            if self.appDelegate.players.count == 1 && self.appDelegate.getMyPlayer()!.server == true {
                self.startButton.isEnabled = false
                self.startButton.isHidden = true
            }
        }
        connectionsTable.reloadData()
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
        if (message.object(forKey: "status") as! Int) == PlayerStatus.Ready {
            var player = self.appDelegate.getPlayerByPeerName(senderDisplayName)
            if player == nil {
                player = Player(peerID: senderDisplayName)
                player!.setupSpecies(message.object(forKey: "species") as! String)
                self.appDelegate.players.append(player!)
            } else {
                player!.setupSpecies(message.object(forKey: "species") as! String)
            }
            if appDelegate.allPlayersHaveStatus(PlayerStatus.Ready) && self.appDelegate.getMyPlayer()!.server == true {
                self.startButton.isEnabled = true
                self.startButton.isHidden = false
            } else {
                self.startButton.isEnabled = false
                self.startButton.isHidden = true
            }
        } else if (message.object(forKey: "status") as! Int) == PlayerStatus.Load {
            let gameplayController = self.storyboard?.instantiateViewController(withIdentifier: "GameplayController") as? GameplayController
            appDelegate.mpcHandler.serviceAdvertiser.stopAdvertisingPeer()
            NotificationCenter.default.removeObserver(self)
            self.present(gameplayController!, animated: true, completion: nil)
        } else if (message.object(forKey: "status") as! Int) == PlayerStatus.Initialize && self.appDelegate.getMyPlayer()!.server == false {
            self.appDelegate.players = Message.unpackMessageArray(self.appDelegate.players, data: message.object(forKey: "players") as! NSArray)
            self.appDelegate.crystals = Message.unpackMessageArray(self.appDelegate.crystals, data: message.object(forKey: "crystals") as! NSArray)
            self.appDelegate.worldSize = (message.object(forKey: "worldSize") as AnyObject).floatValue
            let messageDict = [
                "status": PlayerStatus.Initialized,
            ]
            sendReliableData(messageDict as NSDictionary)
        } else if (message.object(forKey: "status") as! Int) == PlayerStatus.Initialized && self.appDelegate.getMyPlayer()!.server == true {
            self.appDelegate.getPlayerByPeerName(senderDisplayName)!.status = PlayerStatus.Initialized
            if self.appDelegate.allPlayersHaveStatus(PlayerStatus.Initialized) {
                sendLoad()
                let gameplayController = self.storyboard?.instantiateViewController(withIdentifier: "GameplayController") as? GameplayController
                appDelegate.mpcHandler.serviceAdvertiser.stopAdvertisingPeer()
                NotificationCenter.default.removeObserver(self)
                self.present(gameplayController!, animated: true, completion: nil)
            }
        }
        connectionsTable.reloadData()
    }
    
    func sendLoad() {
        let messageDict = [
            "status": PlayerStatus.Load,
        ]
        sendReliableData(messageDict as NSDictionary)
    }
    
    func sendReady() {
        
        let messageDict = [
            "status": PlayerStatus.Ready,
            "species": (self.appDelegate.getMyPlayer()?.species)!
        ] as [String : Any]
        sendReliableData(messageDict as NSDictionary)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
}
