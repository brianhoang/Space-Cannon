//
//  GameScene.m
//  Space Cannon
//
//  Created by Brian Hoang on 11/8/14.
//  Copyright (c) 2014 Brian Hoang. All rights reserved.
//

#import "GameScene.h"

@implementation GameScene

//adding a seperate layer, to keep background seperate
{
    //instance variable, want to access throughout class
    SKNode *_mainLayer;
    SKSpriteNode *_cannon; //displaying cannon
    SKSpriteNode *_ammoDisplay; // displaying ammo
    SKLabelNode *_scoreLabel; //keep track of score
    
    //variables for sound because there is a delay when loading sound
    //if we load sound into vairable beforehand we can
    //play sound without a delay
    SKAction *_bounceSound;
    SKAction *_deepExplosionSound;
    SKAction *_explosionSound;
    SKAction *_laserSound;
    SKAction *_zapSound;
    BOOL _didShoot;
}
static const CGFloat SHOOT_SPEED = 1000.0;
static const CGFloat LOW_HALO_ANGLE = 200.0 * M_PI / 180.0;  //in radian
static const CGFloat HIGH_HALO_ANGLE = 340.0 * M_PI / 180.0;  //in radian
static const CGFloat HALO_SPEED = 400.0 ; //in radian

//collision flag
static const uint32_t   HALO_CATEGORY       = 0x1 << 0;
static const uint32_t   BALL_CATEGORY       = 0x1 << 1;
static const uint32_t   EDGE_CATEGORY       = 0x1 << 2;
static const uint32_t   SHIELD_CATEGORY     = 0x1 << 3;
static const uint32_t   LIFEBAR_CATEGORY    = 0x1 << 4;



static inline CGVector radiansToVector(CGFloat radians)
{
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

//random number helper
static inline CGFloat randomInRange(CGFloat low, CGFloat high)
{
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
    return value * (high - low) + low;
}

-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    
    //turn off gravity
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    
    //which object should receive collision notification
    self.physicsWorld.contactDelegate = self;
    
    //add background
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"back"];
    background.position = CGPointMake(self.size.width/2, self.size.height/2);
   //background.anchorPoint = CGPointZero;
    //background.blendMode = SKBlendModeReplace;
    [self addChild:background];
    
    //add left edge
    SKNode *leftEdge = [[SKNode alloc] init];
    leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
    leftEdge.position = CGPointMake(300, 0.0);
    leftEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    [self addChild:leftEdge];
    
    //add right edge
    SKNode *rightEdge = [[SKNode alloc] init];
    rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
    rightEdge.position = CGPointMake(725, 0.0);
    rightEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    [self addChild:rightEdge];
    
    //add main layer, grouping nodes
    _mainLayer = [[SKNode alloc] init];
    [self addChild:_mainLayer];
    
    //add cannon
    _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
    _cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
    [self addChild:_cannon];

    //create cannon rotation actions
    //array of movement
    SKAction *rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                  [SKAction rotateByAngle:-M_PI duration:2]]];
    //repeating forever
    [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
    
    //create spawn halo action
    SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:1 withRange:1] , [SKAction performSelector:@selector(spawnHalo) onTarget:self ]]];
    [self runAction:[SKAction repeatActionForever:spawnHalo ]];
    
    //create ammo
    _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
    _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);  //centers in the middle of screen
    _ammoDisplay.position = _cannon.position;
    [self addChild:_ammoDisplay];
    
    SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1],
                                                   [SKAction runBlock:^{
        self.ammo++;
    }]]];
    [self runAction:[SKAction repeatActionForever:incrementAmmo]];
    
    
    //setup score display
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _scoreLabel.position = CGPointMake(310,10);
    _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _scoreLabel.fontSize = 15;
    [self addChild:_scoreLabel];
    
    //setup sound
   _bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
    _deepExplosionSound = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
    _explosionSound = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
    _laserSound = [SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO];
    _zapSound = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
    

    
    [self newGame];
  
}


-(void)newGame
{
    self.ammo = 5;
    self.score = 0;
    
    //cleat state
    [_mainLayer removeAllChildren];
    
    
    //set up shields
    for (int i = 0; i < 6; i++)
    {
        SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shield.name = @"Shield";
        shield.position = CGPointMake(350 + (65 *i), 90);   //( ) spaces inbetween shield
        [_mainLayer addChild:shield];
        //giving the shields a physical body, to detect collison
        shield.physicsBody = [ SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shield.physicsBody.categoryBitMask = SHIELD_CATEGORY;
        shield.physicsBody.collisionBitMask = 0; //move or interacts with anything
    }
    
    //set up life bar
    SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    //* 0.5 to center, 70 - for below shield
    lifeBar.position = CGPointMake(self.size.width * 0.5, 70);
                                                        //negative because centered bar in the middle
    lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width * 0.5, 0) toPoint:CGPointMake(lifeBar.size.width * 0.5, 0) ];
    lifeBar.physicsBody.categoryBitMask = LIFEBAR_CATEGORY;
    [_mainLayer addChild:lifeBar];
    
}



-(void)setAmmo:(int)ammo
{
    if (ammo >= 0 && ammo <= 5)
    {
        _ammo = ammo;
        //change ammo sprite depending on numbers of ammos
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d", ammo]];
    }
}


-(void)setScore:(int)score
{
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
}

-(void)shoot
{
    if(self.ammo > 0)
    {
        self.ammo --;
    
        //adding balls
        SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"Ball"];
        ball.name = @"Ball";
        CGVector rotationVector = radiansToVector(_cannon.zRotation);
        ball.position  = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx), _cannon.position.y +(_cannon.size.width * 0.5 * rotationVector.dy));
        [_mainLayer addChild:ball];
    
        //making the balls move
        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];  //image is 24 pix, retina makes it 12, and radius makes it 6, add gravity
        ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
        ball.physicsBody.restitution = 1.0; //bounciness
        ball.physicsBody.linearDamping = 0.0;
        ball.physicsBody.friction = 0.0;
        ball.physicsBody.categoryBitMask = BALL_CATEGORY;
    
        //ball not reacting to hitting halo, only interacts with edge
        ball.physicsBody.collisionBitMask = EDGE_CATEGORY;
        
        //detects when ball hits edge
        ball.physicsBody.contactTestBitMask = EDGE_CATEGORY;
        
        //add explosion sound
        [self runAction:_laserSound];
    }
}


-(void)spawnHalo
{
    //create halo node
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.name = @"Halo";
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)), self.size.height + (halo.size.height * 0.5));
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16.0];  //width 64 px, because of retina is 32, radius is 16
    CGVector direction = radiansToVector(randomInRange(LOW_HALO_ANGLE, HIGH_HALO_ANGLE));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * HALO_SPEED, direction.dy * HALO_SPEED);
    halo.physicsBody.restitution = 1.0; //bounciness
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    halo.physicsBody.categoryBitMask = HALO_CATEGORY;
    
    //halo ignores other halos, only react to edge
    halo.physicsBody.collisionBitMask = EDGE_CATEGORY ;
    
    //notifies when ball hits halo, or halo hits halo, or halo hits shield
    halo.physicsBody.contactTestBitMask = BALL_CATEGORY | SHIELD_CATEGORY | HALO_CATEGORY | LIFEBAR_CATEGORY |EDGE_CATEGORY;
    
    //added just cause, notifies when a halo hits another halo
   // halo.physicsBody.contactTestBitMask = HALO_CATEGORY;
    
    //within window to spawn
    if (halo.position.x > 300 && halo.position.x < 725){
    [_mainLayer addChild:halo];
    }
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        _didShoot = YES;
    }
}

//halo.physicsBody.contactTestBitMask = BALL_CATEGORY;, when true enter funtion
-(void)didBeginContact:(SKPhysicsContact *)contact
{
    //bodyA and bodyB dont know which is halo and which is ball
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask){
        //firstbody will always have the lowest category bit mask
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }

    
    //collison with ball and halo
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == BALL_CATEGORY)
    {
        //add explosion effect
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        
        //add explosion sound
        [self runAction:_explosionSound];
        
        //increment score
        self.score++;
     
        //delete from view
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    //collission with halo and shield
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == SHIELD_CATEGORY)
    {
        //add explosion effect
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        
        //add explosion sound
        [self runAction:_explosionSound];
        
        //delete from view
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    //collison with halo and halo
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask ==HALO_CATEGORY){
        
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        
        //add explosion sound
        [self runAction:_explosionSound];
        
        //delete from view
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    
    //collison with halo and lifebar also gane over
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask ==LIFEBAR_CATEGORY){

        [self addExplosion:secondBody.node.position withName:@"LifeExplosion"];
        
        //add explosion sound
        [self runAction:_deepExplosionSound];
        
        //delete from view
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        [self gameOver];
    }
    
    //collison with ball and edge
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == EDGE_CATEGORY){
        
        [self addExplosion:contact.contactPoint withName:@"HaloExplosion"];
        [self runAction:_zapSound];

    }
    
    //collison with ball and edge
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == EDGE_CATEGORY){
        
        [self addExplosion:contact.contactPoint withName:@"HaloExplosion"];
        [self runAction:_zapSound];
        
    }
    
}


//just because we no longer see the nodes, does not mean it is gone
//deletes node from tree once it is out of view

-(void)didSimulatePhysics
{
    if(_didShoot)
    {
        [self shoot];
        _didShoot = NO;
    }
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if (!CGRectContainsPoint(self.frame, node.position))
        {
            [node removeFromParent];
        }
    }];
    
}

//adding explosion particles and loading SKS file
-(void)addExplosion:(CGPoint) position withName:(NSString*) name
{
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
    explosion.position = position;
    [_mainLayer addChild:explosion];
    
    //remove otherwise framerate will drop
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5], [SKAction removeFromParent]]];
    
    [explosion runAction:removeExplosion];
}


-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

-(void) gameOver
{   //blow up all halos
    [_mainLayer enumerateChildNodesWithName:@"Halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"Shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];

    
    [_mainLayer enumerateChildNodesWithName:@"Ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];

    [self performSelector: @selector(newGame) withObject:nil afterDelay:1.5];

}

@end
