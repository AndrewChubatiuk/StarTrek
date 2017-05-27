//
//  Bar.swift
//  StarTrek
//
//  Created by Andrii Chubatiuk on 5/4/16.
//  Copyright © 2016 Andrii Chubatiuk. All rights reserved.
//

import Foundation
import SpriteKit

class Bar: SKSpriteNode {
    
    var maxValue: Int!
    var progressNode: SKSpriteNode!
    var maxWidth: CGFloat!
    
    init(size: CGSize, color: UIColor, maxValue: Int) {
        self.maxWidth = size.width * 0.95
        self.maxValue = maxValue
        super.init(texture: nil, color: UIColor.black, size: size)
        progressNode = SKSpriteNode(color: color, size: CGSize(width: maxWidth, height: self.size.height / 2))
        progressNode.anchorPoint = CGPoint(x: 0, y: 0.5)
        anchorPoint = CGPoint(x: 0, y: 0.5)
        progressNode.position = CGPoint(x: (size.width-progressNode.size.width)/2, y: 0)
        addChild(progressNode)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setBar(_ value: Int) {
        progressNode.size.width = maxWidth*CGFloat(value)/CGFloat(maxValue)
    }
}
