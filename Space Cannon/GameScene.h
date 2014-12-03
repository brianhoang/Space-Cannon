//
//  GameScene.h
//  Space Cannon
//

//  Copyright (c) 2014 Brian Hoang. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameScene : SKScene <SKPhysicsContactDelegate>

@property (nonatomic) int ammo;  //used to track anount of ammo
@property (nonatomic) int score; //used to track score
@end
