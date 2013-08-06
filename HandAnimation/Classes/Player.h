/**
 *  Player.h
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 *  All rights reserved
 */

#import <Foundation/Foundation.h>

@interface Player : NSObject

+(Player *) sharedInstance;

- (void)startPlaying;
- (void)stopPlaying;

@property (nonatomic) BOOL isPlaying;

@end
