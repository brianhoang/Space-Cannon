//
//  ball.m
//  Space Cannon
//
//  Created by Brian Hoang on 12/24/14.
//  Copyright (c) 2014 Brian Hoang. All rights reserved.
//

#import "ball.h"

@implementation ball

-(void) updateTrail
{
    if(self.trail){
        self.trail.position = self.position;
    }
}

//overrride
-(void) removeFromParent
{
    if(self.trail){
        self.trail.particleBirthRate = 0.0;
        
        SKAction *removeTrail = [SKAction sequence :@[[SKAction waitForDuration:self.trail.particleLifetime+ self.trail.particleLifetimeRange], [SKAction removeFromParent]]];
        
        [self runAction:removeTrail];
    }
    
    
    [super removeFromParent];
    
}

@end
