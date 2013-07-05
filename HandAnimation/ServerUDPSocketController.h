//
//  ServerUDPSocketController.h
//  HandAnimation
//
//  Created by Kevin Python on 01.07.13.
//
//

#import <Foundation/Foundation.h>
#import "HandLibrary.h"
#import "CC3Scene.h"

@protocol UpdateHandModel;

@interface ServerUDPSocketController : NSObject
    @property (nonatomic, assign) id<UpdateHandModel> delegate;

    -(id) initWithDelegate:(id<UpdateHandModel>)delegate;
@end



@protocol UpdateHandModel <NSObject>

@required
-(void) setHandLocation:(CC3Vector)handLocation;
-(void) setHandRotation:(CC3Vector)handRotation;
-(void) setFingerFlexion:(HandFinger)finger withFactor:(float)factor;

@end
