/**
 *  HandAnimationScene.h
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright EIA-FR 2013. All rights reserved.
 */


#import "CC3Scene.h"
#import "HandLibrary.h"
#import "ServerUDPSocketController.h"

/** A sample application-specific CC3Scene subclass.*/
@interface HandAnimationScene : CC3Scene <UpdateHandModel>

@property (nonatomic,strong) CC3MeshNode *handNode;
@property (nonatomic) CC3Vector handLocation;
@property (nonatomic) CC3Vector handRotation;

-(void) setHandLocation:(CC3Vector)handLocation;
-(void) setHandRotation:(CC3Vector)handRotation;
-(void) setFingerFlexion:(HandFinger)finger withFactor:(float)factor;


@end
