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
    
    @IBAction func exitGame(sender: AnyObject) {
        exit(0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let player = Player(
            peerID: appDelegate.mpcHandler.peerID.displayName
        )
        appDelegate.players = [Player]()
        appDelegate.crystals = [Crystal]()
        if appDelegate.getMyPlayer() == nil {
            appDelegate.players.append(player)
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
