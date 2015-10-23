//
//  Obstacle.swift
//  HoppyBunny
//
//  Created by ChaoticDawgSoftware on 10/22/15.
//  Copyright © 2015 Apportable. All rights reserved.
//

import Foundation

class Obstacle: CCNode {
    
    weak var topCarrot: CCNode!
    weak var bottomCarrot: CCNode!
    
    let topCarrotMinimumPositionY: CGFloat = 128
    let bottomCarrotMinimumPositionY: CGFloat = 440
    let carrotDistance: CGFloat = 142
    
    func setupRandomPosition() {
        let randomPrecision: UInt32 = 100
        let random = CGFloat(arc4random_uniform(randomPrecision)) / CGFloat(randomPrecision)
        let range = bottomCarrotMinimumPositionY - carrotDistance - topCarrotMinimumPositionY
        topCarrot.position = ccp(topCarrot.position.x, topCarrotMinimumPositionY + (random * range))
        bottomCarrot.position = ccp(bottomCarrot.position.x, topCarrot.position.y + carrotDistance)
    }
    
    func didLoadFromCCB() {
        topCarrot.physicsBody.sensor = true
        bottomCarrot.physicsBody.sensor = true
    }
}