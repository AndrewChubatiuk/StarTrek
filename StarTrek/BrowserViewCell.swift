//
//  BrowserViewCell.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 5/12/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import UIKit

class BrowserViewCell : UITableViewCell {
    
    @IBOutlet var playerName: UILabel!
    @IBOutlet var playerConnectionStatus: UIImageView!
    var peerID: MCPeerID!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func loadItem(_ peerID: MCPeerID) {
        self.peerID = peerID
        playerConnectionStatus.image = UIImage(named: "good.png")
        playerName.text = peerID.displayName
    }
}
