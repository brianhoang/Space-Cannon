//
//  BHMenu.m
//  Space Cannon
//
//  Created by Brian Hoang on 12/5/14.
//  Copyright (c) 2014 Brian Hoang. All rights reserved.
//

#import "BHMenu.h"

@implementation BHMenu
{
    SKLabelNode *_gameScoreLabel;
    SKLabelNode *_topScoreLabel;
}

- (id)init
{
    self = [super init];
    if (self) {
        //add title screen
        SKSpriteNode *title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        //(0,_) 0 is center
        title.position = CGPointMake(0, 140);
        [self addChild:title];
        
        //add score board
        SKSpriteNode *scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        scoreBoard.position = CGPointMake(0, 70);
        [self addChild:scoreBoard];
        
        //add play button
        SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        playButton.position = CGPointMake(0, 0);
        playButton.name = @"Play";
        [self addChild:playButton];
        
        _gameScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _gameScoreLabel.fontSize = 30;
        // x = 0 is the center, y = 50 so that just under scoreboard
        _gameScoreLabel.position = CGPointMake(-52, 50);
        [self addChild:_gameScoreLabel];
        
        _topScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _topScoreLabel.fontSize = 30;
        // x = 0 is the center, y = 50 so that just under scoreboard
        _topScoreLabel.position = CGPointMake(48, 50);
        [self addChild:_topScoreLabel];
        
        self.score = 0;
        self.topScore = 0;
    }
    return self;
}

-(void)setScore:(int)score
{
    _score = score;
    _gameScoreLabel.text = [[NSNumber numberWithInt:score] stringValue];
}

-(void)setTopScore:(int)topScore
{
    _topScore = topScore;
    _topScoreLabel.text = [[NSNumber numberWithInt:topScore] stringValue];

}

@end
