//
//  Goal.swift
//  HoppyBunny
//
//  Created by ChaoticDawgSoftware on 10/23/15.
//  Copyright © 2015 Apportable. All rights reserved.
//

import Foundation

class Goal: CCNode {
    func didLoadFromCCB() {
        physicsBody.sensor = true
    }
}
