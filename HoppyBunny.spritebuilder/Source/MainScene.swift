import Foundation

class MainScene: CCNode, CCPhysicsCollisionDelegate {
    
    weak var hero: CCSprite!
    weak var gamePhysicsNode: CCPhysicsNode!
    weak var ground1: CCSprite!
    weak var ground2: CCSprite!
    weak var obstaclesLayer: CCNode!
    weak var restartButton: CCButton!
    weak var scoreLabel: CCLabelTTF!
    weak var clouds1: CCSprite!
    weak var clouds2: CCSprite!
    weak var crystals1: CCSprite!
    weak var crystals2: CCSprite!
    
    var parallaxItems: [CCSprite : CCSprite] = [:]
    var parallaxSpeed: CGFloat = 25
    var points: NSInteger = 0
    var grounds = [CCSprite]()
    var sinceTouch: CCTime = 0
    var scrollSpeed: CGFloat = 80
    var obstacles: [CCNode] = []
    let firstObstaclePosition: CGFloat = 280
    let distanceBetweenObstacles: CGFloat = 160
    var gameOver = false
    
    func didLoadFromCCB() {
        userInteractionEnabled = true
        grounds.append(ground1)
        grounds.append(ground2)
        parallaxItems[clouds1] = crystals1
        parallaxItems[clouds2] = crystals2
        
        for _ in 0...2 {
            spawnNewObstacle()
        }
        
        gamePhysicsNode.collisionDelegate = self
    }
    
    override func touchBegan(touch: CCTouch!, withEvent event: CCTouchEvent!) {
        if !gameOver {
            hero.physicsBody.applyImpulse(ccp(0, 400))
            hero.physicsBody.applyAngularImpulse(10000)
            sinceTouch = 0
        }
    }
    
    override func update(delta: CCTime) {
        
        let velocityY = clampf(Float(hero.physicsBody.velocity.y), -Float(CGFloat.max), 200)
        hero.physicsBody.velocity = ccp(0, CGFloat(velocityY))
        
        sinceTouch += delta
        hero.rotation = clampf(hero.rotation, -25, 90)
        
        if hero.physicsBody.allowsRotation {
            let angularVelocity = clampf(Float(hero.physicsBody.angularVelocity), -2, 1)
            hero.physicsBody.angularVelocity = CGFloat(angularVelocity)
        }
        
        if sinceTouch > 0.3 {
            let impulse = -18000.0 * delta
            hero.physicsBody.applyAngularImpulse(CGFloat(impulse))
        }
        
        hero.position = ccp(hero.position.x + scrollSpeed * CGFloat(delta), hero.position.y)
        gamePhysicsNode.position = ccp(gamePhysicsNode.position.x - scrollSpeed * CGFloat(delta), gamePhysicsNode.position.y)
        // Fix black lines where ground1 and ground2 intersect
        //gamePhysicsNode.position = ccp(round(gamePhysicsNode.position.x), round(gamePhysicsNode.position.y))
        let scale = CCDirector.sharedDirector().contentScaleFactor
        gamePhysicsNode.position = ccp(round(gamePhysicsNode.position.x * scale) / scale, round(gamePhysicsNode.position.y * scale) / scale)
        hero.position = ccp(round(hero.position.x * scale) / scale, round(hero.position.y * scale) / scale)
        
        for ground in grounds {
            let groundWorldPosition = gamePhysicsNode.convertToWorldSpace(ground.position)
            let groundScreenPosition = convertToNodeSpace(groundWorldPosition)
            
            if groundScreenPosition.x <= (-ground.contentSize.width) {
                ground.position = ccp(ground.position.x + ground.contentSize.width * 2, ground.position.y)
            }
        }
        
        // parallax clouds and crystals
        
        for (cloud, crystal) in parallaxItems {
            
            cloud.position = ccp(round((cloud.position.x - parallaxSpeed * CGFloat(delta)) * scale) / scale, round(cloud.position.y * scale) / scale)
            
            crystal.position = ccp(round((crystal.position.x - parallaxSpeed * CGFloat(delta)) * scale) / scale, round(crystal.position.y * scale) / scale)
            
            let cloudWorldPosition = self.convertToWorldSpace(cloud.position)
            let cloudScreenPosition = convertToNodeSpace(cloudWorldPosition)
            
            let crystalWorldPosition = self.convertToWorldSpace(crystal.position)
            let crystalScreenPosition = convertToNodeSpace(crystalWorldPosition)

            
            if cloudScreenPosition.x <= (-cloud.contentSize.width) {
                var cloudXPos = cloud.position.x + cloud.contentSize.width * 2
                cloudXPos = round(cloudXPos * scale) / scale
                cloud.position = ccp(cloudXPos, cloud.position.y)
            }
            
            if crystalScreenPosition.x <= (-crystal.contentSize.width) {
                var crystalXPos = (crystal.position.x + crystal.contentSize.width * 2) - 2 // - 2 pixel shift to fix intersect line
                crystalXPos = round(crystalXPos * scale) / scale
                crystal.position = ccp(crystalXPos, crystal.position.y)
            }
        }
        
        for obstacle in Array(obstacles.reverse()) {
            let obstacleWorldPosition = gamePhysicsNode.convertToWorldSpace(obstacle.position)
            let obstacleScreenPosition = convertToNodeSpace(obstacleWorldPosition)
            
            // obstacle moved past the left of the screen?
            if obstacleScreenPosition.x < (-obstacle.contentSize.width) {
                obstacle.removeFromParent()
                obstacles.removeAtIndex(obstacles.indexOf(obstacle)!)
                
                // for each removed obstacle, add a new one
                spawnNewObstacle()
            }
        }
    }
    
    func spawnNewObstacle() {
        
        var prevObstaclePos = firstObstaclePosition
        if obstacles.count > 0 {
            prevObstaclePos = obstacles.last!.position.x
        }
        
        // Create and add a new obstacle
        let obstacle = CCBReader.load("Obstacle") as! Obstacle
        obstacle.position = ccp(prevObstaclePos + distanceBetweenObstacles, 0)
        obstacle.setupRandomPosition()
        //gamePhysicsNode.addChild(obstacle)
        obstaclesLayer.addChild(obstacle)
        obstacles.append(obstacle)
    }
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, level: CCNode!) -> Bool {
        //print("TODO: handle Game Over!")
        //restartButton.visible = true
        triggerGameOver()
        return true
    }
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, goal: CCNode!) -> Bool {
        goal.removeFromParent()
        points++
        scoreLabel.string = String(points)
        return true
    }
    
    func restart() {
        let scene = CCBReader.loadAsScene("MainScene")
        CCDirector.sharedDirector().replaceScene(scene)
    }
    
    func triggerGameOver() {
        if !gameOver {
            gameOver = true
            restartButton.visible = true
            scrollSpeed = 0
            parallaxSpeed = 0
            hero.rotation = 90
            hero.physicsBody.allowsRotation = false
            
            // Just in case
            hero.stopAllActions()
            
            let move = CCActionEaseBounceOut(action: CCActionMoveBy(duration: 0.2, position: ccp(0, 4)))
            let moveBack = CCActionEaseBounceOut(action: move.reverse())
            let shakeSequence = CCActionSequence(array: [move, moveBack])
            runAction(shakeSequence)
        }
    }

}
