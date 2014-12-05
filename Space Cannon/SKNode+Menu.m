//
//  SKNode+Menu.m
//  Space Cannon
//
//  Created by Brian Hoang on 12/4/14.
//  Copyright (c) 2014 Brian Hoang. All rights reserved.
//

#import "SKNode+Menu.h"

@implementation CCMenu

- (id)init
{
    self = [super init];
    if (self) {
        //add title screen
        SKSpriteNode *title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        title.position = CGPointMake(0, 140);
        [self addChild:title];
        
        //add score board
        SKSpriteNode *scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        scoreBoard.position = CGPointMake(0, 70);
        [self addChild:scoreBoard];
        
        //add play button
        SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        playButton.position = CGPointMake(0, 0);
        [self addChild:playButton];
    }
    return self;
}

@end
