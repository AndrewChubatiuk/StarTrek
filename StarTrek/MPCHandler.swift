//
//  MPCHandler.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 4/27/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class MPCHandler: NSObject, MCSessionDelegate {
    
    let peerID = MCPeerID(displayName: UIDevice.current.name)
    fileprivate let serviceType = "star-trek"
    let maxConnections = 4
    let serviceBrowser:MCNearbyServiceBrowser
    let serviceAdvertiser:MCNearbyServiceAdvertiser
    
    override init () {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        super.init()
        self.serviceAdvertiser.delegate = self
    }
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.peerID)
        session.delegate = self
        return session
    }()
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let userInfo = [
            "peerID": peerID,
            "state": state.rawValue
        ] as [String : Any]
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: "MPC_DidChangeStateNotification"), object: nil, userInfo: userInfo)
        })
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let userInfo = [
            "data": data,
            "peerID": peerID
        ] as [String : Any]
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: "MPC_DidReceiveDataNotification"), object: nil, userInfo: userInfo)
        })
        
    }
    
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }

}

extension MPCHandler : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("ERROR CANNOT ADVERTISE")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if session.connectedPeers.count < maxConnections {
            invitationHandler(true, self.session)
        } else {
            invitationHandler(false, self.session)
        }
    }
}
