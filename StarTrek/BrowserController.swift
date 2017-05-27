//
//  BrowserController.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 5/12/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

class BrowserController: UIViewController, UITableViewDelegate, UITableViewDataSource, MCNearbyServiceBrowserDelegate {
    var appDelegate:AppDelegate!
    var foundPeers = [MCPeerID]()
    var selectedPeer: MCPeerID!
    @IBOutlet var connectionsTable: UITableView!
    
    override func viewDidLoad()
    {
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mpcHandler.serviceBrowser.delegate = self
        self.appDelegate.mpcHandler.serviceBrowser.startBrowsingForPeers()
        super.viewDidLoad()
        self.connectionsTable.register(UITableViewCell.self, forCellReuseIdentifier: "browserCell")
        NotificationCenter.default.addObserver(self, selector: #selector(ConnectionsListController.peerChangedStateWithNotification(_:)), name: NSNotification.Name(rawValue: "MPC_DidChangeStateNotification"), object: nil)
        
    }
    
    @IBAction func previousView(_ sender: UIButton) {
        self.appDelegate.mpcHandler.serviceBrowser.stopBrowsingForPeers()
        self.dismiss(animated: true, completion: nil)
    }
    
    func peerChangedStateWithNotification(_ notification: Notification){
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.object(forKey: "state") as! Int
        let peerID = userInfo.object(forKey: "peerID") as! MCPeerID
        if state == MCSessionState.connected.rawValue {
            if peerID.displayName == selectedPeer.displayName {
                let newGameController = self.storyboard?.instantiateViewController(withIdentifier: "NewGameViewController") as? NewGameViewController
                self.appDelegate.getMyPlayer()!.server = false
                self.appDelegate.mpcHandler.serviceBrowser.stopBrowsingForPeers()
                self.present(newGameController!, animated: true, completion: nil)
            }
        }
        connectionsTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.foundPeers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BrowserViewCell", for: indexPath) as! BrowserViewCell
        let peerID = foundPeers[indexPath.row]
        cell.loadItem(peerID)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = connectionsTable.cellForRow(at: indexPath) as! BrowserViewCell
        selectedPeer = cell.peerID
        self.appDelegate.mpcHandler.serviceBrowser.invitePeer(selectedPeer, to: self.appDelegate.mpcHandler.session, withContext: nil, timeout: 10)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        self.foundPeers.append(peerID)
        connectionsTable.reloadData()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("ERROR CANNOT BROWSE")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        foundPeers = foundPeers.filter{$0.displayName != peerID.displayName}
        connectionsTable.reloadData()
    }
    
}
