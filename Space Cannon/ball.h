//
//  ball.h
//  Space Cannon
//
//  Created by Brian Hoang on 12/24/14.
//  Copyright (c) 2014 Brian Hoang. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface ball : SKSpriteNode

@property (nonatomic) SKEmitterNode *trail;

@property (nonatomic) int bounces;

-(void)updateTrail;

@end
