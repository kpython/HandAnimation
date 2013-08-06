/**
 *  HandAnimationLayer.m
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 *  All rights reserved
 */

#import "HandAnimationLayer.h"
#import "HandAnimationScene.h"
#import "ClientSocketController.h"
#import "Player.h"


@implementation HandAnimationLayer{
    UIButton* connectButton;
    UIButton* recordButton;
    UIButton* playButton;
    UIButton* cameraOverlayButton;
}

-(void) dealloc {
    [super dealloc];
}

/**
 * Override to set up your 2D controls and other initial state, and to initialize update processing.
 *
 * For more info, read the notes of this method on CC3Layer.
 */
-(void) initializeControls {
    
    // Hide frame rates statistics on the bottom left
    [[CCDirector sharedDirector] setDisplayStats:NO];
    
	[self scheduleUpdate];
    [self addConnectButton];
    [self addRecordButton];
    [self addPlayButton];
    [self addCameraOverlayButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePlayButton:) name:@"playEnded" object:nil];
}

-(void) addConnectButton
{
    connectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [connectButton addTarget:self
                      action:@selector(connectButtonPressed:)
            forControlEvents:UIControlEventTouchDown];
    [connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    
    connectButton.frame = CGRectMake(870.0, 600.0, 110.0, 30.0);
    
    // get the cocos2d view (it's the CCGLView class which inherits from UIView)
    UIView* glView = [CCDirector sharedDirector].view;
    // add the text field view to the cocos2d CCGLView
    [glView addSubview:connectButton];
}


-(void) addCameraOverlayButton
{
    cameraOverlayButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [cameraOverlayButton addTarget:self
                     action:@selector(cameraOverlayButtonPressed:)
           forControlEvents:UIControlEventTouchDown];
    [cameraOverlayButton setTitle:@"Enable camera" forState:UIControlStateNormal];
    [cameraOverlayButton setTitle:@"Disable camera" forState:UIControlStateSelected];
    
    cameraOverlayButton.frame = CGRectMake(870.0, 640.0, 110.0, 30.0);
    
    // get the cocos2d view (it's the CCGLView class which inherits from UIView)
    UIView* glView = [CCDirector sharedDirector].view;
    // add the text field view to the cocos2d CCGLView
    [glView addSubview:cameraOverlayButton];
}

-(void) addPlayButton
{
    playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [playButton addTarget:self
                   action:@selector(playButtonPressed:)
         forControlEvents:UIControlEventTouchDown];
    [playButton setTitle:@"Play" forState:UIControlStateNormal];
    [playButton setTitle:@"Stop" forState:UIControlStateSelected];
    
    playButton.frame = CGRectMake(870.0, 680.0, 110.0, 30.0);
    
    // get the cocos2d view (it's the CCGLView class which inherits from UIView)
    UIView* glView = [CCDirector sharedDirector].view;
    // add the text field view to the cocos2d CCGLView
    [glView addSubview:playButton];
}

-(void) addRecordButton
{
    recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [recordButton addTarget:self
                     action:@selector(recordButtonPressed:)
           forControlEvents:UIControlEventTouchDown];
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [recordButton setTitle:@"Recording..." forState:UIControlStateSelected];
    
    recordButton.frame = CGRectMake(870.0, 720.0, 110.0, 30.0);
    
    // get the cocos2d view (it's the CCGLView class which inherits from UIView)
    UIView* glView = [CCDirector sharedDirector].view;
    // add the text field view to the cocos2d CCGLView
    [glView addSubview:recordButton];
    
}


-(void) connectButtonPressed:(id)sender{
    if ([sender isKindOfClass:[UIButton class]]) {
        NSLog(@"connectButtonPressed");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"connect" object:self];
    }
}

-(void) playButtonPressed:(id)sender{
    if ([sender isKindOfClass:[UIButton class]]) {
        NSLog(@"playButtonPressed");
        BOOL state = [playButton isSelected];
        if (state) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"stop" object:self];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"play" object:self];
        }
        // Toggle Play button
        [playButton setSelected:![playButton isSelected]];
    }
}

-(void) updatePlayButton:(NSNotification*)info{
    [playButton setSelected:[[Player sharedInstance] isPlaying]];
}

-(void) recordButtonPressed:(id)sender{
    if ([sender isKindOfClass:[UIButton class]]) {
        NSLog(@"recordButtonPressed");
        BOOL state = [recordButton isSelected];
        if (state) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"recordEnded" object:self];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"recordStarted" object:self];
        }
        // Toggle Record button
        [recordButton setSelected:![recordButton isSelected]];
    }
}

-(void) cameraOverlayButtonPressed:(id)sender{
    if ([sender isKindOfClass:[UIButton class]]) {
        NSLog(@"cameraOverlayButtonPressed");
        BOOL state = [cameraOverlayButton isSelected];
        if (state) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"disableCameraOverlay" object:self];
        }else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"enableCameraOverlay" object:self];
        }
        // Toggle Record button
        [cameraOverlayButton setSelected:![cameraOverlayButton isSelected]];
    }
}

@end
