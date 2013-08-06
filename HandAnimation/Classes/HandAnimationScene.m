/**
 *  HandAnimationScene.m
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 *  All rights reserved
 */

#import "HandAnimationScene.h"
#import "CC3PODResourceNode.h"
#import "CC3ActionInterval.h"
#import "CC3MeshNode.h"
#import "CC3Camera.h"
#import "CC3Light.h"
#import "CC3NodePODExtensions.h"
#import "ClientSocketController.h"
#import "Recorder.h"
#import "Player.h"


@implementation HandAnimationScene
{
    FrameParser *frameParser;
    ClientSocketController *socketController;
}

-(void) dealloc {
	[super dealloc];
}

/**
 * Constructs the 3D scene.
 *
 * Adds 3D objects to the scene, loading the hand model from 
 * the POD file, and creating the camera and light programatically.
 *
 */
-(void) initializeScene {

	// Create the camera, place it on top of the hand face down, and add it to the scene
	CC3Camera* cam = [CC3Camera nodeWithName: @"Camera"];
	cam.location = cc3v(0.0, 15.0, 0.0);
    cam.rotation = cc3v(-90.0, 0.0, 0.0);
	[self addChild: cam];

	// Create a light, place it back, and add it to the scene
	CC3Light* lamp = [CC3Light nodeWithName: @"Lamp"];
	lamp.location = cc3v( -2.0, 0.0, 0.0 );
	lamp.isDirectionalOnly = NO;
	[cam addChild: lamp];

    // Load the POD ressource file and add it to the scene. This file contain the hand model without any animation. Animation will be added from other POD ressources later.
	[self addContentFromPODFile: @"Hand_withoutAnim.pod"];
    
    
    // --- Cocos3D code --- 
	[self createGLBuffers];
	[self releaseRedundantContent];
	[self selectShaderPrograms];
		
	// If you encounter issues creating and adding nodes, or loading models from
	// files, the following line is used to log the full structure of the scene.
	LogInfo(@"The structure of this scene is: %@", [self structureDescription]);
	// ---- Cocos3D code ---
    
    
    // Retrieve the reference of the Hand mesh
    self.handNode = (CC3MeshNode*)[self getNodeNamed:@"Hand_withoutAnim.pod-SoftBody"];
    
    // POD files can contain one single animation. The easiest way to have multiple animation on the same model, is to
    // export a POD file from the 3D editor for each animation. Each animation of each POD file is then added to the
    // first hand model we loaded before as a different track. Each track can be played independently. 
    [self.handNode addAnimationFromPODFile:@"Hand_thumb.pod" asTrack:FINGER_THUMB];
    [self.handNode addAnimationFromPODFile:@"Hand_index.pod" asTrack:FINGER_INDEX];
    [self.handNode addAnimationFromPODFile:@"Hand_middle.pod" asTrack:FINGER_MIDDLE];
    [self.handNode addAnimationFromPODFile:@"Hand_ring.pod" asTrack:FINGER_RING];
    [self.handNode addAnimationFromPODFile:@"Hand_pinky.pod" asTrack:FINGER_PINKY];
    
    // Start thread to simulate the animation of the hand. This is only for testing purpose comment this line when using leap motion
    //[NSThread detachNewThreadSelector:@selector(startRandomPositionThread) toTarget:self withObject:nil];
    
    // Initialize socket, recorder player and the frame parser
    socketController = [[ClientSocketController alloc] init];
    [[Recorder alloc] init];
    [[Player alloc] init];
    
    frameParser = [FrameParser sharedInstance];
    frameParser.delegate = self;
}


#pragma mark Thread for hand animation simulation

#define FORWARD TRUE
#define BACKWARD FALSE
#define FINGER_STEP 1
#define X_MOVE_STEP 0.01
#define Y_MOVE_STEP 0.01
#define Z_MOVE_STEP 0.01
#define REFRESH_TIME 0.01
/*
    This thread permit to test the animation of the hand. This thread will:
        - move the hand in each axis x,y,z
        - rotate the hand in each axis x,y,z
        - flex every finger
 */
-(void)startAnimationSimulationThread{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Location
    CC3Vector currentLocation;
    BOOL xDirection = FORWARD;
    BOOL yDirection = FORWARD;
    BOOL zDirection = FORWARD;
    
    // Finger Flexion
    float fingerFlexion = 0.0;
    BOOL flexionDirection = FORWARD;
    int  fingerFlexionCount = 1;
    
    while (true) {
        /* Location
         This part will simulate the movement of the hand in each 3 axis
         */
        currentLocation = self.handNode.location;
        
        currentLocation.x += (xDirection == FORWARD) ? +X_MOVE_STEP : -X_MOVE_STEP;
        if (currentLocation.x > 2.5)
            xDirection = BACKWARD;
        if (currentLocation.x < -2.5)
            xDirection = FORWARD;
        
        currentLocation.y += (yDirection == FORWARD) ? +Y_MOVE_STEP : -Y_MOVE_STEP;
        if (currentLocation.y > 1.0)
            yDirection = BACKWARD;
        if (currentLocation.y < -1.0)
            yDirection = FORWARD;
        
        currentLocation.z += (zDirection == FORWARD) ? +Z_MOVE_STEP : -Z_MOVE_STEP;
        if (currentLocation.z > 2.0)
            zDirection = BACKWARD;
        if (currentLocation.z < -2.0)
            zDirection = FORWARD;
        
        [self setHandLocation:currentLocation];

    
        /* Rotation
         This part will simulate the rotation of the hand on different axis. 
         */
        CC3Vector currentRotation = self.handNode.rotation;
        currentRotation.x += 0.2;
        currentRotation.y += 0.2;
        //currentRotation.z += 0.2;
        [self setHandRotation:currentRotation];
    
        
        /* Finger flexion
        This part will simulate the flexion of a finger in the forward.
        The variable fingerFlexionCount is a counter counting from 0 to 100 and decreasing from 100 to 0 indefinitely
        This value is scaled to float value from 0.0 to 1.0. This permits to avoid error additioning floating number.
        */
        fingerFlexionCount += (flexionDirection == FORWARD) ? +FINGER_STEP : -FINGER_STEP;
        fingerFlexion = (float)fingerFlexionCount/100;
        
        if (fingerFlexionCount == 100)
            flexionDirection = BACKWARD;
        if (fingerFlexionCount == 0)
            flexionDirection = FORWARD;
        
        [self setFingerFlexion:FINGER_THUMB withFactor:fingerFlexion];
        [self setFingerFlexion:FINGER_INDEX withFactor:fingerFlexion];
        [self setFingerFlexion:FINGER_MIDDLE withFactor:fingerFlexion];
        [self setFingerFlexion:FINGER_RING withFactor:fingerFlexion];
        [self setFingerFlexion:FINGER_PINKY withFactor:fingerFlexion];

        [NSThread sleepForTimeInterval:REFRESH_TIME];
    }
    [pool release];
}

-(void)setHandLocation:(CC3Vector)handLocation{
    [self.handNode setLocation:handLocation];
}

-(void)setHandRotation:(CC3Vector)handRotation{
    [self.handNode setRotation:handRotation];
}

-(void)setFingerFlexion:(HandFinger)finger withFactor:(float)factor{
    if (factor) {
        if (factor < 0.0) {
            factor = 0.0;
        }else if (factor > 1.0){
            factor = 1.0;
        }
        [self.handNode establishAnimationFrameAt:factor onTrack:finger];
    }
}

-(void)printCurrentLocation{
    CC3Vector currentLocation = self.handNode.location;
    NSLog(@"Location X position: %1.2f", currentLocation.x);
    NSLog(@"Location Y position: %1.2f", currentLocation.y);
    NSLog(@"Location Z position: %1.2f", currentLocation.z);
}

-(void)printCurrentRotation{
    CC3Vector currentRotation = self.handNode.rotation;
    NSLog(@"Rotation X rotation: %1.2f", currentRotation.x);
    NSLog(@"Rotation Y rotation: %1.2f", currentRotation.y);
    NSLog(@"Rotation Z rotation: %1.2f", currentRotation.z);
}


#pragma mark Updating custom activity

/**
 * This template method is invoked periodically whenever the 3D nodes are to be updated.
 *
 * This method provides your app with an opportunity to perform update activities before
 * any changes are applied to the transformMatrix of the 3D nodes in the scene.
 *
 * For more info, read the notes of this method on CC3Node.
 */
-(void) updateBeforeTransform: (CC3NodeUpdatingVisitor*) visitor {}

/**
 * This template method is invoked periodically whenever the 3D nodes are to be updated.
 *
 * This method provides your app with an opportunity to perform update activities after
 * the transformMatrix of the 3D nodes in the scen have been recalculated.
 *
 * For more info, read the notes of this method on CC3Node.
 */
-(void) updateAfterTransform: (CC3NodeUpdatingVisitor*) visitor {
	// If you have uncommented the moveWithDuration: invocation in the onOpen: method, you
	// can uncomment the following to track how the camera moves, where it ends up, and what
	// the camera's clipping distances are, in order to determine how to position and configure
	// the camera to view the entire scene.
//	LogDebug(@"Camera: %@", activeCamera.fullDescription);
}


#pragma mark Scene opening and closing

/**
 * Callback template method that is invoked automatically when the CC3Layer that
 * holds this scene is first displayed.
 *
 * This method is a good place to invoke one of CC3Camera moveToShowAllOf:... family
 * of methods, used to cause the camera to automatically focus on and frame a particular
 * node, or the entire scene.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) onOpen {

	// Move the camera to frame the scene. You can uncomment the LogDebug line in the
	// updateAfterTransform: method to track how the camera moves, where it ends up, and
	// what the camera's clipping distances are, in order to determine how to position
	// and configure the camera to view your entire scene. Then you can remove this code.
	//[self.activeCamera moveWithDuration: 3.0 toShowAllOf: self withPadding: 0.5f];

	// Uncomment this line to draw the bounding box of the scene.
//	self.shouldDrawWireframeBox = YES;
}

/**
 * Callback template method that is invoked automatically when the CC3Layer that
 * holds this scene has been removed from display.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) onClose {}


#pragma mark Handling touch events 

/**
 * This method is invoked from the CC3Layer whenever a touch event occurs, if that layer
 * has indicated that it is interested in receiving touch events, and is handling them.
 *
 * Override this method to handle touch events, or remove this method to make use of
 * the superclass behaviour of selecting 3D nodes on each touch-down event.
 *
 * This method is not invoked when gestures are used for user interaction. Your custom
 * CC3Layer processes gestures and invokes higher-level application-defined behaviour
 * on this customized CC3Scene subclass.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) touchEvent: (uint) touchType at: (CGPoint) touchPoint {}

/**
 * This callback template method is invoked automatically when a node has been picked
 * by the invocation of the pickNodeFromTapAt: or pickNodeFromTouchEvent:at: methods,
 * as a result of a touch event or tap gesture.
 *
 * Override this method to perform activities on 3D nodes that have been picked by the user.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) nodeSelected: (CC3Node*) aNode byTouchEvent: (uint) touchType at: (CGPoint) touchPoint {}

@end

