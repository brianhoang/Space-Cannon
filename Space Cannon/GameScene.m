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
    SKSpriteNode *_cannon;
    BOOL _didShoot;
}
static const CGFloat SHOOT_SPEED = 1000.00;
static const CGFloat LOW_HALO_ANGLE = 200.0 * M_PI / 180.0;  //in radian
static const CGFloat HIGH_HALO_ANGLE = 340.0 * M_PI / 180.0;  //in radian
static const CGFloat HALO_SPEED = 300.0 ; //in radian

//collision flag
static const uint32_t   HALO_CATEGORY = 0x1 << 0;
static const uint32_t   BALL_CATEGORY = 0x1 << 1;
static const uint32_t   EDGE_CATEGORY = 0x1 << 2;



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
    [_mainLayer addChild:_cannon];

    //create cannon rotation actions
    //array of movement
    SKAction *rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                  [SKAction rotateByAngle:-M_PI duration:2]]];
    //repeating forever
    [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
    
    //create spawn halo action
    SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:1 withRange:1] , [SKAction performSelector:@selector(spawnHalo) onTarget:self ]]];
    [self runAction:[SKAction repeatActionForever:spawnHalo ]];
}

-(void)shoot
{
    //adding balls
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"Ball"];
    ball.name = @"ball";
    CGVector rotationVector = radiansToVector(_cannon.zRotation);
    ball.position  = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx)
                                 , _cannon.position.y +(_cannon.size.width * 0.5 * rotationVector.dy));
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
}


-(void)spawnHalo
{
    //create halo node
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)), self.size.height + (halo.size.height * 0.5));
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16.0];  //width 64 px, because of retina is 32, radius is 16
    CGVector direction = radiansToVector(randomInRange(LOW_HALO_ANGLE, HIGH_HALO_ANGLE));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * HALO_SPEED, direction.dy * HALO_SPEED);
    halo.physicsBody.restitution = 1.0; //bounciness
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    halo.physicsBody.categoryBitMask = HALO_CATEGORY;
    
    //halo ignores other halos, only react to edge
    halo.physicsBody.collisionBitMask = EDGE_CATEGORY;
    
    //notifies when ball hits halo
    halo.physicsBody.contactTestBitMask = BALL_CATEGORY;
    
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
    
    if(contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        //firstbody will always have the lowest category bit mask
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }else{
        firstBody   = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    //collison with ball and halo
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == BALL_CATEGORY)
    {
        [self addExplosion:firstBody.node.position];
        
        //delete from view
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
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
-(void)addExplosion:(CGPoint) position
{
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:@"HaloExplosion" ofType:@"sks"];
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

@end
