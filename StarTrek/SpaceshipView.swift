//
//  InstructionView.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 4/29/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import Foundation
import UIKit

class SpaceshipView: UIViewController
{
    
    var pageIndex : Int = 0
    var speciesShipImageText: String = ""
    var speciesInfoText: String = ""
    var speciesNameText: String = ""
    
    @IBOutlet var speciesShipImage: UIImageView!
    @IBOutlet var speciesInfo: UITextView!
    @IBOutlet var speciesName: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        speciesShipImage.image = UIImage(named: speciesShipImageText)
        speciesInfo.text = speciesInfoText
        speciesInfo.textColor = UIColor.yellow
        speciesInfo.font = UIFont(name: "Starjedi", size: 9)
        speciesInfo.textAlignment = NSTextAlignment.justified
        speciesName.text = speciesNameText
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
} 
