/**
 *  FrameParser.m
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 *  All rights reserved
 */

#import "FrameParser.h"

@implementation FrameParser

static FrameParser *sharedInstance = nil;

+(id)sharedInstance{
	@synchronized(self) {
		if (!sharedInstance) {
			sharedInstance=[[self alloc] init];
		}
	}
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self) {
		if (sharedInstance == nil) {
			sharedInstance = [super allocWithZone:zone];
			return sharedInstance;
		}
	}
    
	return nil;
}

-(id) initWithDelegate:(id<UpdateHandModel>)delegate
{
    self = [super init];
    if (self != nil)
    {
        self.delegate = delegate;
    }
    return self;
}


-(void) parseFrame:(NSData*)data{
    // Parse received frame
    NSError* error = nil;
    if (data) {
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                             options:kNilOptions
                                                               error:&error];
        
        [self readJSONFrame:json];
        
    }
    else {
        NSLog(@"Error parsing received frame: %@", [error userInfo]);
    }
}

-(void) readJSONFrame: (NSDictionary*)json{
    if (json) {
        NSArray* hands = [json objectForKey:@"hands"];
        
        NSDictionary* palmInfo = [hands objectAtIndex:0];
        
        NSArray* palmPosition = [palmInfo objectForKey:@"palmPosition"];
        NSArray* palmRotation = [palmInfo objectForKey:@"palmRotation"];
        NSArray* fingersFlexion = [palmInfo objectForKey:@"fingersFlexion"];
        
        if (palmPosition)
            [self udpateHandPosition:palmPosition];
        
        if (palmRotation)
            [self udpateHandRotation:palmRotation];
        
        if (fingersFlexion) 
            [self updateFingersFlexion:fingersFlexion];
        
    }
}


// The correspondance between the real position of the hand and the position of the hand
// on the screen is scalled according a decreasing factor.
#define SCREEN_REALITY_FACTOR   25.0
-(void)udpateHandPosition:(NSArray*)palmPosition
{
    if ([self.delegate respondsToSelector:@selector(setHandLocation:)]){
        float xLoc = [[palmPosition objectAtIndex:0] floatValue] / SCREEN_REALITY_FACTOR;
        float yLoc = [[palmPosition objectAtIndex:1] floatValue] / SCREEN_REALITY_FACTOR;
        float zLoc = [[palmPosition objectAtIndex:2] floatValue] / SCREEN_REALITY_FACTOR;
        CC3Vector handLocation = cc3v(xLoc,yLoc,zLoc);
        [self.delegate setHandLocation:handLocation];
    }
}

-(void)udpateHandRotation:(NSArray*)palmRotation
{
    if ([self.delegate respondsToSelector:@selector(setHandRotation:)]){
        float xRot = [[palmRotation objectAtIndex:0] floatValue];
        float yRot = [[palmRotation objectAtIndex:1] floatValue];
        float zRot = [[palmRotation objectAtIndex:2] floatValue];
        // Y axis is modified due to different convention of axis rotation
        CC3Vector handRotation = cc3v(xRot,-yRot,zRot);
        [self.delegate setHandRotation:handRotation];
    }
}

-(void)updateFingersFlexion:(NSArray*)fingersFlexion{
    if ([self.delegate respondsToSelector:@selector(setFingerFlexion:withFactor:)]){
        float thumbFlexion = [[fingersFlexion objectAtIndex:0] floatValue];
        float indexFlexion = [[fingersFlexion objectAtIndex:1] floatValue];
        float middleFlexion = [[fingersFlexion objectAtIndex:2] floatValue];
        float ringFlexion = [[fingersFlexion objectAtIndex:3] floatValue];
        float pinkyFlexion = [[fingersFlexion objectAtIndex:4] floatValue];
        
        [self.delegate setFingerFlexion:FINGER_THUMB withFactor:thumbFlexion];
        [self.delegate setFingerFlexion:FINGER_INDEX withFactor:indexFlexion];
        [self.delegate setFingerFlexion:FINGER_MIDDLE withFactor:middleFlexion];
        [self.delegate setFingerFlexion:FINGER_RING withFactor:ringFlexion];
        [self.delegate setFingerFlexion:FINGER_PINKY withFactor:pinkyFlexion];
    }
}


@end
