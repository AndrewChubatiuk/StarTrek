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
    @IBAction func exitGame(_ sender: AnyObject) {
        exit(0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.gameOverLabel.text = gameOverText
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
        var destViewController: MainMenuController = segue.destination as! MainMenuController
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
