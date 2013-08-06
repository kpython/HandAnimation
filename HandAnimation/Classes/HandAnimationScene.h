/**
 *  HandAnimationScene.h
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 *  All rights reserved
 */


#import "CC3Scene.h"
#import "HandLibrary.h"
#import "FrameParser.h"

/** A application-specific CC3Scene subclass.*/
@interface HandAnimationScene : CC3Scene <UpdateHandModel>

@property (nonatomic,strong) CC3MeshNode *handNode;

-(void) setHandLocation:(CC3Vector)handLocation;
-(void) setHandRotation:(CC3Vector)handRotation;
-(void) setFingerFlexion:(HandFinger)finger withFactor:(float)factor;




@end
