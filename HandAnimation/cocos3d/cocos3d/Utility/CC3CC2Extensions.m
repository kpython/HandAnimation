/*
 * CC3CC2Extensions.m
 *
 * cocos3d 2.0.0
 * Author: Bill Hollings
 * Copyright (c) 2010-2013 The Brenwill Workshop Ltd. All rights reserved.
 * http://www.brenwill.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * http://en.wikipedia.org/wiki/MIT_License
 * 
 * See header file CC3CC2Extensions.h for full API documentation.
 */

#import "CC3CC2Extensions.h"
#import "CC3IOSExtensions.h"
#import "CC3Logging.h"
#import "uthash.h"

#if ((CC3_CC2_1) && (CC3_OSX))
@implementation CCGLView
@end
#endif	// CC3_CC2_1 && CC3_OSX


#if !CC3_IOS

#pragma mark -
#pragma mark Extensions for non-IOS environments

@implementation CCTouchDispatcher
-(void) addTargetedDelegate: (id) delegate priority: (NSInteger) priority swallowsTouches: (BOOL) swallowsTouches {}
+(id) sharedDispatcher { return nil; }
@end

@implementation CCDirector (NonIOS)
-(CCTouchDispatcher*) touchDispatcher { return nil; }
@end

@implementation CCNode (NonIOS)
-(CGPoint) convertTouchToNodeSpace: (UITouch*) touch { return CGPointZero; }
@end

#endif		// !CC3_IOS


#if COCOS2D_VERSION < 0x020100
#	define CC2_DT dt
#	define CC2_FRAME_RATE frameRate_
#	define CC2_RUNNING_SCENE runningScene_
#	define CC2_NEXT_SCENE nextScene_
#	define CC2_LAST_DISPLAY_TIME lastDisplayTime_
#else
#	define CC2_DT _dt
#	define CC2_FRAME_RATE _frameRate
#	define CC2_RUNNING_SCENE _runningScene
#	define CC2_NEXT_SCENE _nextScene
#	define CC2_LAST_DISPLAY_TIME _lastDisplayTime
#endif

#if !CC3_IOS
#	undef CC2_LAST_DISPLAY_TIME
#	define CC2_LAST_DISPLAY_TIME 0
#endif

#pragma mark -
#pragma mark CC3CCSizeTo action

@implementation CC3CCSizeTo

-(id) initWithDuration: (ccTime) dur sizeTo: (CGSize) endSize {
	if( (self = [super initWithDuration: dur]) ) {
		endSize_ = endSize;
	}
	return self;
}

+(id) actionWithDuration: (ccTime) dur sizeTo: (CGSize) endSize {
	return [[[self alloc] initWithDuration: dur sizeTo: endSize] autorelease];
}

-(id) copyWithZone: (NSZone*) zone {
	return [[[self class] allocWithZone: zone] initWithDuration: [self duration]
														 sizeTo: endSize_];
}

-(id) reverse { return [[self class] actionWithDuration: self.duration  sizeTo: endSize_]; }

-(void) startWithTarget: (CCNode*) aTarget {
	[super startWithTarget: aTarget];
	startSize_ = aTarget.contentSize;
	sizeChange_ = CGSizeMake(endSize_.width - startSize_.width, endSize_.height - startSize_.height);
}

-(void) update: (ccTime) t {
	CCNode* tNode = (CCNode*)self.target;
	tNode.contentSize = CGSizeMake(startSize_.width + (sizeChange_.width * t),
								   startSize_.height + (sizeChange_.height * t));
}

-(NSString*) description {
	return [NSString stringWithFormat: @"%@ start: %@, end: %@, time change: %@", [self class],
			NSStringFromCGSize(startSize_), NSStringFromCGSize(endSize_), NSStringFromCGSize(sizeChange_)];
}

@end


#pragma mark -
#pragma mark CCNode extension

@implementation CCNode (CC3)

#if CC3_CC2_2
-(CGSize) contentSizeInPixels { return CC_SIZE_POINTS_TO_PIXELS(self.contentSize); }

-(CGRect) boundingBoxInPixels { return CC_RECT_POINTS_TO_PIXELS(self.boundingBox); }
#endif

-(BOOL) isTouchEnabled { return NO; }

-(CGRect) globalBoundingBoxInPixels {
	CGSize csp = self.contentSizeInPixels;
	CGRect rect = CGRectMake(0, 0, csp.width, csp.height);
	return CGRectApplyAffineTransform(rect, [self nodeToWorldTransform]);
}

-(void) updateViewport { [self.children makeObjectsPerformSelector:@selector(updateViewport)]; }

-(CGPoint) cc3ConvertUIPointToNodeSpace: (CGPoint) viewPoint {
	CGPoint glPoint = [[CCDirector sharedDirector] convertToGL: viewPoint];
	return [self convertToNodeSpace: glPoint];
}

-(CGPoint) cc3ConvertNodePointToUISpace: (CGPoint) glPoint {
	CGPoint gblPoint = [self convertToWorldSpace: glPoint];
	return [[CCDirector sharedDirector] convertToUI: gblPoint];
}

-(CGPoint) cc3ConvertUIMovementToNodeSpace: (CGPoint) uiMovement {
	switch ( CCDirector.sharedDirector.deviceOrientation ) {
		case UIDeviceOrientationLandscapeLeft:
			return ccp( uiMovement.y, uiMovement.x );
		case UIDeviceOrientationLandscapeRight:
			return ccp( -uiMovement.y, -uiMovement.x );
		case UIDeviceOrientationPortraitUpsideDown:
			return ccp( -uiMovement.x, uiMovement.y );
		case UIDeviceOrientationPortrait:
		default:
			return ccp( uiMovement.x, -uiMovement.y );
	}
}

-(CGPoint) cc3NormalizeUIMovement: (CGPoint) uiMovement {
	CGSize cs = self.contentSize;
	CGPoint glMovement = [self cc3ConvertUIMovementToNodeSpace: uiMovement];
	return ccp(glMovement.x / cs.width, glMovement.y / cs.height);
}

/**
 * Based on cocos2d Gesture Recognizer ideas by Krzysztof Zabłocki at:
 * http://www.merowing.info/2012/03/using-gesturerecognizers-in-cocos2d/
 */
-(BOOL) cc3WillConsumeTouchEventAt: (CGPoint) viewPoint {
	
	if (self.isTouchEnabled &&
		self.visible &&
		self.isRunning &&
		[self cc3ContainsTouchPoint: viewPoint] ) return YES;
	
	CCArray* myKids = self.children;
	for (CCNode* child in myKids) {
		if ( [child cc3WillConsumeTouchEventAt: viewPoint] ) return YES;
	}

	LogTrace(@"%@ will NOT consume event at %@", [self class], NSStringFromCGPoint(viewPoint));

	return NO;
}

-(BOOL) cc3ContainsTouchPoint: (CGPoint) viewPoint {
	CGPoint nodePoint = [self cc3ConvertUIPointToNodeSpace: viewPoint];
	CGSize cs = self.contentSize;
	CGRect nodeBounds = CGRectMake(0, 0, cs.width, cs.height);
	if (CGRectContainsPoint(nodeBounds, nodePoint)) {
		LogTrace(@"%@ will consume event at %@ in bounds %@",
					  [self class],
					  NSStringFromCGPoint(nodePoint),
					  NSStringFromCGRect(nodeBounds));
		return YES;
	}
	return NO;
}

#if CC3_IOS
-(BOOL) cc3ValidateGesture: (UIGestureRecognizer*) gesture {
	if ( [self cc3WillConsumeTouchEventAt: gesture.location] ) {
		[gesture cancel];
		return NO;
	} else {
		return YES;
	}
}
#endif	// CC3_IOS

-(CGPoint) cc3ConvertNSEventToNodeSpace: (NSEvent*) event {
#if CC3_OSX
	return [self convertToNodeSpace: [CCDirector.sharedDirector convertEventToGL: event]];
#else
	return CGPointZero;
#endif	// CC3_OSX
}

-(void) reshapeProjection: (CGSize) newWindowSize {
	for (CCNode* child in self.children) [child reshapeProjection: newWindowSize];
}

@end


#pragma mark -
#pragma mark CCLayer extension

@implementation CCLayer (CC3)

#if COCOS2D_VERSION < 0x020100
-(void) setTouchEnabled: (BOOL) isTouchEnabled { self.isTouchEnabled = isTouchEnabled; }
#endif

#if CC3_IOS
-(BOOL) isMouseEnabled { return NO; }
-(void) setMouseEnabled: (BOOL) isMouseEnabled {}
-(NSInteger) mousePriority { return 0; }
-(void) setMousePriority: (NSInteger) priority {}
#endif	// CC3_IOS

#if CC3_OSX
#if COCOS2D_VERSION < 0x020100
-(void) setMouseEnabled: (BOOL) isMouseEnabled { self.isMouseEnabled = isMouseEnabled; }
-(NSInteger) mousePriority { return 0; }
-(void) setMousePriority: (NSInteger) priority {}
#endif
#endif	// CC3_OSX

@end


#pragma mark -
#pragma mark CCMenu extension

@implementation CCMenu (CC3)

-(BOOL) cc3ContainsTouchPoint: (CGPoint) viewPoint {
	CCArray* myKids = self.children;
	for (CCNode* child in myKids) {
		if ( [child cc3ContainsTouchPoint: viewPoint] ) return YES;
	}
	return NO;
}

@end


#pragma mark -
#pragma mark CCMenu extension

@implementation CCMenuItemImage (CC3)
#if CC3_CC2_1
+(id) itemWithNormalImage: (NSString*)value selectedImage:(NSString*) value2 {
	return [self itemFromNormalImage:value selectedImage:value2];
}
+(id) itemWithNormalImage: (NSString*)value selectedImage:(NSString*) value2 target:(id) r selector:(SEL) s {
	return [self itemFromNormalImage:value selectedImage:value2 target:r selector:s];
}
#endif
@end


#pragma mark -
#pragma mark CCDirector extension

@implementation CCDirector (CC3)

-(CCGLView*) ccGLView { return (CCGLView*)self.view; }

-(void) setCcGLView: (CCGLView*) ccGLView { self.view = ccGLView; }

-(ccTime) frameInterval { return CC2_DT; }

-(ccTime) frameRate { return CC2_FRAME_RATE; }

-(BOOL) hasScene { return !((CC2_RUNNING_SCENE == nil) && (CC2_NEXT_SCENE == nil)); }

-(NSTimeInterval) displayLinkTime { return [NSDate timeIntervalSinceReferenceDate]; }

#if CC3_CC2_1
-(void) setDisplayStats: (BOOL) displayFPS { [self setDisplayFPS: displayFPS]; }

-(CCGLView*) view { return (CCGLView*)self.openGLView; }

-(void) setView: (CCGLView*) view { self.openGLView = (CCGLView*)view; }

-(CCActionManager*) actionManager { return CCActionManager.sharedManager; }

#if CC3_IOS
-(CCTouchDispatcher*) touchDispatcher { return CCTouchDispatcher.sharedDispatcher; }
#endif	// CC3_IOS

-(CCScheduler*) scheduler { return CCScheduler.sharedScheduler; }

#if COCOS2D_VERSION < 0x010100
-(void) setRunLoopCommon: (BOOL) common {}
#endif

#endif	// CC3_CC2_1

#if CC3_CC2_2 || CC3_OSX
-(UIDeviceOrientation) deviceOrientation { return UIDeviceOrientationPortrait; }
#endif

@end


#if CC3_IOS

#pragma mark -
#pragma mark CCDirectorIOS extension

@implementation CCDirectorIOS (CC3)

/**
 * Overridden to use a different font file (fps_images_1.png) when using cocos2d 1.x.
 *
 * Both cocos2d 1.x & 2.x use a font file named fps_images.png, which are different and
 * incompatible with each other. This allows a project to include both versions of the file,
 * and use the font file version that is appropriate for the cocos2d version.
 */
-(void) setGLDefaultValues {

#if CC_DIRECTOR_FAST_FPS
    if (!FPSLabel_) {
		CCTexture2DPixelFormat currentFormat = [CCTexture2D defaultAlphaPixelFormat];
		[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA4444];
		FPSLabel_ = [[CCLabelAtlas labelWithString:@"00.0" charMapFile:@"fps_images_1.png" itemWidth:16 itemHeight:24 startCharMap:'.'] retain];
		[CCTexture2D setDefaultAlphaPixelFormat:currentFormat];
	}
#endif	// CC_DIRECTOR_FAST_FPS

	[super setGLDefaultValues];
}

@end

#endif		// CC3_IOS


#if CC3_OSX

#pragma mark -
#pragma mark CCDirectorMac extension

@implementation CCDirectorMac (CC3)

-(void) reshapeProjection: (CGSize) newWindowSize {
	[super reshapeProjection: newWindowSize];
	if (self.resizeMode == kCCDirectorResize_NoScale)
		[self.runningScene reshapeProjection: newWindowSize];
}

@end

#endif		// CC3_OSX


#pragma mark -
#pragma mark CCDirectorDisplayLink extension

@implementation CCDirectorDisplayLink (CC3)

#if CC3_CC2_2
-(NSTimeInterval) displayLinkTime { return CC2_LAST_DISPLAY_TIME; }
#endif

@end


#pragma mark -
#pragma mark CCFileUtils extension

/** Extension category to support cocos3d functionality. */
@implementation CCFileUtils (CC3)

#if CC3_CC2_1
+(Class) sharedFileUtils { return self; }
#endif

@end


#pragma mark -
#pragma mark CCArray extension

@implementation CCArray (CC3)

-(NSUInteger) indexOfObjectIdenticalTo: (id) anObject {
	return [self indexOfObject: anObject];
}

-(void) removeObjectIdenticalTo: (id) anObject {
	[self removeObject: anObject];
}

-(void) fastReplaceObjectAtIndex: (NSUInteger) index withObject: (id) anObject {
	CC3Assert(index < data->num, @"Invalid index. Out of bounds");

	id oldObj = data->arr[index];
	data->arr[index] = [anObject retain];
	[oldObj release];						// Release after in case new is same as old
}

-(BOOL) setCapacity: (NSUInteger) newCapacity {
	if (data->max == newCapacity) return NO;

	// Release any current elements that are beyond the new capacity.
	if (self.count > 0) {	// Reqd so count - 1 can't be done on NSUInteger of zero
		for (NSUInteger i = self.count - 1; i >= newCapacity; i--) {
			[self removeObjectAtIndex: i];
		}
	}

	// Returned newArrs will be non-zero on successful allocation,
	// but will be zero on either successful deallocation or on failed allocation
	id* newArr = realloc( data->arr, (newCapacity * sizeof(id)) );

	// If we wanted to allocate, but it failed, log an error and return without changing anything.
	if ( (newCapacity != 0) && !newArr ) {
		LogError(@"Could not change %@ to a capacity of %lu elements", self, (unsigned long)newCapacity);
		return NO;
	}
	
	// Otherwise, set the new array pointer and size.
	data->arr = newArr;
	data->max = newCapacity;
	LogTrace(@"Changed %@ to a capcity of %u elements", [self class], newCapacity);
	return YES;
}


#pragma mark Allocation and initialization

- (id) initWithZeroCapacity {
	if ( (self = [super init]) ) {
		data = (ccArray*)malloc( sizeof(ccArray) );
		data->num = 0;
		data->max = 0;
		data->arr = NULL;
	}
	return self;
}

+(id) arrayWithZeroCapacity { return [[[self alloc] initWithZeroCapacity] autorelease]; }


#pragma mark Support for unretained objects

- (void) addUnretainedObject: (id) anObject {
	ccCArrayAppendValueWithResize(data, anObject);
}

- (void) insertUnretainedObject: (id) anObject atIndex: (NSUInteger) index {
	ccCArrayEnsureExtraCapacity(data, 1);
	ccCArrayInsertValueAtIndex(data, anObject, index);
}

- (void) removeUnretainedObjectIdenticalTo: (id) anObject {
	ccCArrayRemoveValue(data, anObject);
}

- (void) removeUnretainedObjectAtIndex: (NSUInteger) index {
	ccCArrayRemoveValueAtIndex(data, index);
}

- (void) removeAllObjectsAsUnretained {
	ccCArrayRemoveAllValues(data);
}

-(void) releaseAsUnretained {
	[self removeAllObjectsAsUnretained];
	[self release];
}

- (NSString*) fullDescription {
	NSMutableString *desc = [NSMutableString stringWithFormat:@"%@ (", [self class]];
	if (data->num > 0) {
		[desc appendFormat:@"\n\t%@", data->arr[0]];
	}
	for (NSUInteger i = 1; i < data->num; i++) {
		[desc appendFormat:@",\n\t%@", data->arr[i]];
	}
	[desc appendString:@")"];
	return desc;
}

@end


#pragma mark -
#pragma mark Miscellaneous extensions and functions

NSString* NSStringFromTouchType(uint tType) {
	switch (tType) {
		case kCCTouchBegan:
			return @"kCCTouchBegan";
		case kCCTouchMoved:
			return @"kCCTouchMoved";
		case kCCTouchEnded:
			return @"kCCTouchEnded";
		case kCCTouchCancelled:
			return @"kCCTouchCancelled";
		default:
			return [NSString stringWithFormat: @"unknown touch type (%u)", tType];
	}
}

