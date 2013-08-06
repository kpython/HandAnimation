/**
 *  FrameParser.h
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 *  All rights reserved
 */

#import <Foundation/Foundation.h>
#import "HandLibrary.h"
#import "CC3Foundation.h"

@protocol UpdateHandModel;

@interface FrameParser : NSObject
@property (nonatomic, assign) id<UpdateHandModel> delegate;

+(FrameParser *) sharedInstance;

-(id) initWithDelegate:(id<UpdateHandModel>)delegate;
-(void) parseFrame:(NSData*)data;
-(void) readJSONFrame:(NSDictionary*)json;
@end



@protocol UpdateHandModel <NSObject>

@required
-(void) setHandLocation:(CC3Vector)handLocation;
-(void) setHandRotation:(CC3Vector)handRotation;
-(void) setFingerFlexion:(HandFinger)finger withFactor:(float)factor;

@end
