/**
 *  HandAnimationAppDelegate.m
 *  HandAnimation
 *
 * @author Kevin Python
 * @version 1.0
 * @since 14.06.13
 *
 * Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 * All rights reserved
 */

#import "HandAnimationAppDelegate.h"
#import "HandAnimationLayer.h"
#import "HandAnimationScene.h"
#import "CC3CC2Extensions.h"

#define kAnimationFrameRate		60		// Animation frame rate

@implementation HandAnimationAppDelegate {
	UIWindow* _window;
	CC3DeviceCameraOverlayUIViewController* _viewController;
}

-(void) dealloc {
	[_window release];
	[_viewController release];
	[super dealloc];
}

#if CC3_CC2_1
/**
 * In cocos2d 1.x, the view controller and CCDirector are different objects.
 *
 * NOTE: As of iOS6, supported device orientations are an intersection of the mask established for the
 * UIViewController (as set in this method here), and the values specified in the project 'Info.plist'
 * file, under the 'Supported interface orientations' and 'Supported interface orientations (iPad)'
 * keys. Specifically, although the mask here is set to UIInterfaceOrientationMaskAll, to ensure that
 * all orienatations are enabled under iOS6, be sure that those settings in the 'Info.plist' file also
 * reflect all four orientation values. By default, the 'Info.plist' settings only enable the two
 * landscape orientations. These settings can also be set on the Summary page of your project.
 *
 * Multisampling and stencil buffers cannot be used together. Setting the viewShouldUseStencilBuffer
 * property to YES will force the viewPixelSamples property to be 1.
 */
-(void) establishDirectorController {
	
	// Establish the type of CCDirector to use.
	// Try to use CADisplayLink director and if it fails (SDK < 3.1) use the default director.
	// This must be the first thing we do and must be done before establishing view controller.
	if( ! [CCDirector setDirectorType: kCCDirectorTypeDisplayLink] )
		[CCDirector setDirectorType: kCCDirectorTypeDefault];
	
	// Create the view controller for the 3D view.
	_viewController = [CC3DeviceCameraOverlayUIViewController new];
	_viewController.supportedInterfaceOrientations = UIInterfaceOrientationMaskAll;
	_viewController.viewShouldUseStencilBuffer = NO;		// Set to YES if using shadow volumes
	_viewController.viewPixelSamples = 1;					// Set to 4 for antialiasing multisampling
	
	// Create the CCDirector, set the frame rate, and attach the view.
	CCDirector *director = CCDirector.sharedDirector;
	director.runLoopCommon = YES;		// Improves display link integration with UIKit
	director.animationInterval = (1.0f / kAnimationFrameRate);
    // Set displayFPS to YES to display information about the frame rate on the bottom left
	director.displayFPS = NO;
	director.openGLView = _viewController.view;
	
	// Enables High Res mode on Retina Displays and maintains low res on all other devices
	// This must be done after the GL view is assigned to the director!
	[director enableRetinaDisplay: YES];
}
#endif

#if CC3_CC2_2
/**
 * In cocos2d 2.x, the view controller and CCDirector are one and the same, and we create the
 * controller using the singleton mechanism. To establish the correct CCDirector/UIViewController
 * class, this MUST be performed before any other references to the CCDirector singleton!!
 *
 * NOTE: As of iOS6, supported device orientations are an intersection of the mask established for the
 * UIViewController (as set in this method here), and the values specified in the project 'Info.plist'
 * file, under the 'Supported interface orientations' and 'Supported interface orientations (iPad)'
 * keys. Specifically, although the mask here is set to UIInterfaceOrientationMaskAll, to ensure that
 * all orienatations are enabled under iOS6, be sure that those settings in the 'Info.plist' file also
 * reflect all four orientation values. By default, the 'Info.plist' settings only enable the two
 * landscape orientations. These settings can also be set on the Summary page of your project.
 *
 * Multisampling and stencil buffers cannot be used together. Setting the viewShouldUseStencilBuffer
 * property to YES will force the viewPixelSamples property to be 1.
 */
-(void) establishDirectorController {
	_viewController = CC3DeviceCameraOverlayUIViewController.sharedDirector;
	_viewController.supportedInterfaceOrientations = UIInterfaceOrientationMaskAll;
	_viewController.viewShouldUseStencilBuffer = NO;		// Set to YES if using shadow volumes
	_viewController.viewPixelSamples = 1;					// Set to 4 for antialiasing multisampling
	_viewController.animationInterval = (1.0f / kAnimationFrameRate);
	_viewController.displayStats = YES;
	[_viewController enableRetinaDisplay: YES];
}
#endif

-(void) applicationDidFinishLaunching: (UIApplication*) application {
    // Increase launch screen time
    sleep(2);
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images.
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565. You can change anytime.
	CCTexture2D.defaultAlphaPixelFormat = kCCTexture2DPixelFormat_RGBA8888;
	
	// Establish the view controller and CCDirector (in cocos2d 2.x, these are one and the same)
	[self establishDirectorController];
	
	// Create the window, make the controller (and its view) the root of the window, and present the window
	_window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
	[_window addSubview: _viewController.view];
	_window.rootViewController = _viewController;
	[_window makeKeyAndVisible];
	
	// ******** START OF COCOS3D SETUP CODE... ********
	
	// Create the customized CC3Layer that supports 3D rendering.
	CC3Layer* cc3Layer = [HandAnimationLayer node];
	
	// Create the customized 3D scene and attach it to the layer.
	// Could also just create this inside the customer layer.
    HandAnimationScene *currentScene = [HandAnimationScene scene];
	cc3Layer.cc3Scene = currentScene;
    
	// Assign to a generic variable so we can uncomment options below to play with the capabilities
	CC3ControllableLayer* mainLayer = cc3Layer;
	
	// Attach the layer to the controller and run a scene with it.
	[_viewController runSceneOnNode: mainLayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableCameraOverlay:) name:@"enableCameraOverlay" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableCameraOverlay:) name:@"disableCameraOverlay" object:nil];
}

/** Pause the cocos3d/cocos2d action. */
-(void) applicationWillResignActive: (UIApplication*) application {
	[CCDirector.sharedDirector pause];
}

/** Resume the cocos3d/cocos2d action. */
-(void) resumeApp { [CCDirector.sharedDirector resume]; }

-(void) applicationDidBecomeActive: (UIApplication*) application {
}

-(void) applicationDidReceiveMemoryWarning: (UIApplication*) application {
	[CCDirector.sharedDirector purgeCachedData];
}

-(void) applicationDidEnterBackground: (UIApplication*) application {
	[CCDirector.sharedDirector stopAnimation];
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"closeConnection" object:self];
}

-(void) applicationWillEnterForeground: (UIApplication*) application {
	[CCDirector.sharedDirector startAnimation];
}

-(void)applicationWillTerminate: (UIApplication*) application {
	[CCDirector.sharedDirector.view removeFromSuperview];
	[CCDirector.sharedDirector end];
}

-(void) applicationSignificantTimeChange: (UIApplication*) application {
	[CCDirector.sharedDirector setNextDeltaTimeZero: YES];
}

- (void)enableCameraOverlay:(NSNotification*)notification
{
    _viewController.isOverlayingDeviceCamera = YES;
}

- (void)disableCameraOverlay:(NSNotification*)notification
{
    _viewController.isOverlayingDeviceCamera = NO;
}

@end
