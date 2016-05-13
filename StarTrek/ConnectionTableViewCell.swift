//
//  ConnectionTableViewCell.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 4/30/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import Foundation
import UIKit

struct PlayerStatus {
    static let Ready: String = "ready"
    static let Waiting: String = "waiting"
}

class ConnectionTableViewCell : UITableViewCell {
    
    @IBOutlet var playerName: UILabel!
    @IBOutlet var playerConnectionStatus: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func loadItem(name: String, status: String) {
        if status == PlayerStatus.Ready {
            playerConnectionStatus.image = UIImage(named: "good.png")
        } else {
            playerConnectionStatus.image = UIImage(named: "bad.png")
        }
        playerName.text = name
    }
}