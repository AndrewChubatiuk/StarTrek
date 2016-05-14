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
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.mpcHandler.serviceBrowser.delegate = self
        self.appDelegate.mpcHandler.serviceBrowser.startBrowsingForPeers()
        super.viewDidLoad()
        self.connectionsTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: "browserCell")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConnectionsListController.peerChangedStateWithNotification(_:)), name: "MPC_DidChangeStateNotification", object: nil)
        
    }
    
    @IBAction func previousView(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func peerChangedStateWithNotification(notification: NSNotification){
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.objectForKey("state") as! Int
        let peerID = userInfo.objectForKey("peerID") as! MCPeerID
        if state == MCSessionState.Connected.rawValue {
            if peerID.displayName == selectedPeer.displayName {
                let newGameController = self.storyboard?.instantiateViewControllerWithIdentifier("NewGameViewController") as? NewGameViewController
                self.appDelegate.getMyPlayer()!.server = false
                self.presentViewController(newGameController!, animated: true, completion: nil)
            }
        }
        connectionsTable.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.foundPeers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BrowserViewCell", forIndexPath: indexPath) as! BrowserViewCell
        let peerID = foundPeers[indexPath.row]
        cell.loadItem(peerID)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = connectionsTable.cellForRowAtIndexPath(indexPath) as! BrowserViewCell
        selectedPeer = cell.peerID
        self.appDelegate.mpcHandler.serviceBrowser.invitePeer(selectedPeer, toSession: self.appDelegate.mpcHandler.session, withContext: nil, timeout: 10)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        self.foundPeers.append(peerID)
        connectionsTable.reloadData()
    }
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("ERROR CANNOT BROWSE")
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        foundPeers = foundPeers.filter{$0.displayName != peerID.displayName}
        connectionsTable.reloadData()
    }
    
    deinit {
        self.appDelegate.mpcHandler.serviceBrowser.stopBrowsingForPeers()
    }
    
}