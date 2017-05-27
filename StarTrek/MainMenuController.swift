//
//  GameViewController.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 4/26/16.
//  Copyright (c) 2016 Andrii Chubatiuk. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class MainMenuController: UIViewController {
    
    @IBAction func exitGame(_ sender: AnyObject) {
        exit(0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let player = Player(
            peerID: appDelegate.mpcHandler.peerID.displayName
        )
        appDelegate.players = [Player]()
        appDelegate.crystals = [Crystal]()
        if appDelegate.getMyPlayer() == nil {
            appDelegate.players.append(player)
        }
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
}
