//
//  ExitGameController.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 5/11/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import Foundation
import UIKit

class ExitGameController: UIViewController {

    var gameOverText: String!
    
    @IBOutlet var gameOverLabel: UILabel!
    @IBAction func exitGame(sender: AnyObject) {
        exit(0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.gameOverLabel.text = gameOverText
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        self.view.window!.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
        var destViewController: MainMenuController = segue.destinationViewController as! MainMenuController
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