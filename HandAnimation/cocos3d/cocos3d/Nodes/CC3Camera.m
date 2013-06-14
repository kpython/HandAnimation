/*
 * CC3Camera.m
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
 * See header file CC3Camera.h for full API documentation.
 */

#import "CC3Camera.h"
#import "CC3Scene.h"
#import "CC3ProjectionMatrix.h"
#import "CC3Actions.h"
#import "CC3IOSExtensions.h"
#import "CC3CC2Extensions.h"
#import "CC3AffineMatrix.h"

/** The maximum allowed effective field of view. */
#define kMaxEffectiveFOV 179.9


#pragma mark CC3Camera implementation

@interface CC3Node (TemplateMethods)
-(void) transformMatrixChanged;
-(void) notifyTransformListeners;
-(void) updateGlobalScale;
@property(nonatomic, readonly) CC3Matrix* globalRotationMatrix;
@end

@interface CC3Camera (TemplateMethods)
@property(nonatomic, readonly) CC3ViewportManager* viewportManager;
-(void) buildModelViewMatrix;
-(void) openProjection;
-(void) closeProjection;
-(void) openView;
-(void) closeView;
-(void) loadProjectionMatrix;
-(void) loadViewMatrix;
-(void) ensureAtRootAncestor;
-(void) ensureSceneUpdated: (BOOL) checkScene;
-(void) moveToShowAllOf: (CC3Node*) aNode
		 whileLookingAt: (CC3Vector) targetLoc
		  fromDirection: (CC3Vector) aDirection
			withPadding: (GLfloat) padding
			 checkScene: (BOOL) checkScene;
-(void) moveWithDuration: (ccTime) t
			 toShowAllOf: (CC3Node*) aNode
		  whileLookingAt: (CC3Vector) targetLoc
		   fromDirection: (CC3Vector) aDirection
			 withPadding: (GLfloat) padding
			  checkScene: (BOOL) checkScene;
-(CC3Vector) calculateLocationToShowAllOf: (CC3Node*) aNode
						   whileLookingAt: (CC3Vector) targetLoc
							fromDirection: (CC3Vector) aDirection
							  withPadding: (GLfloat) padding
							   checkScene: (BOOL) checkScene;
@property(nonatomic, readonly) CGSize fovRatios;
@end


@implementation CC3Camera

@synthesize nearClippingDistance=_nearClippingDistance, farClippingDistance=_farClippingDistance;
@synthesize frustum=_frustum, fieldOfView=_fieldOfView, viewMatrix=_viewMatrix;
@synthesize hasInfiniteDepthOfField=_hasInfiniteDepthOfField, isOpen=_isOpen;

-(void) dealloc {
	[_viewMatrix release];
	[_frustum release];
	[super dealloc];
}

-(BOOL) isCamera { return YES; }

/** Overridden to return NO so that the forwardDirection aligns with the negative-Z-axis. */
-(BOOL) shouldReverseForwardDirection { return NO; }

-(CC3Matrix*) projectionMatrix {
	return _hasInfiniteDepthOfField
				? _frustum.infiniteProjectionMatrix
				: _frustum.finiteProjectionMatrix;
}

-(void) setFieldOfView:(GLfloat) anAngle {
	_fieldOfView = anAngle;
	[self markProjectionDirty];
}

-(void) setNearClippingDistance: (GLfloat) aDistance {
	_nearClippingDistance = aDistance;
	[self markProjectionDirty];
}

-(void) setFarClippingDistance: (GLfloat) aDistance {
	_farClippingDistance = aDistance;
	[self markProjectionDirty];
}

-(GLfloat) effectiveFieldOfView { return MIN(self.fieldOfView / self.uniformScale, kMaxEffectiveFOV); }

// Deprecated
-(GLfloat) nearClippingPlane { return self.nearClippingDistance; }
-(void) setNearClippingPlane: (GLfloat) aDistance { self.nearClippingDistance = aDistance; }
-(GLfloat) farClippingPlane { return self.farClippingDistance; }
-(void) setFarClippingPlane: (GLfloat) aDistance { self.farClippingDistance = aDistance; }

// Overridden to mark the frustum's projection matrix dirty instead of the
// transformMatrix. This is because for a camera, scale acts as a zoom to change
// the effective FOV, which is a projection quality, not a transformation quality.
-(void) setScale: (CC3Vector) aScale {
	scale = aScale;
	[self markProjectionDirty];
}

-(BOOL) isUsingParallelProjection { return _frustum.isUsingParallelProjection; }

-(void) setIsUsingParallelProjection: (BOOL) shouldUseParallelProjection {
	_frustum.isUsingParallelProjection = shouldUseParallelProjection;
	[self markProjectionDirty];
}

// The CC3Scene's viewport manager.
-(CC3ViewportManager*) viewportManager { return self.scene.viewportManager; }

// Keep the compiler happy with the additional declaration
// of this property on this class for documentation purposes
-(CC3Vector) forwardDirection { return super.forwardDirection; }
-(void) setForwardDirection: (CC3Vector) aDirection { super.forwardDirection = aDirection; }

// Deprecated
-(CC3Matrix*) modelviewMatrix { return self.viewMatrix; }


#pragma mark Allocation and initialization

-(id) initWithTag: (GLuint) aTag withName: (NSString*) aName {
	if ( (self = [super initWithTag: aTag withName: aName]) ) {
		_viewMatrix = [CC3AffineMatrix new];
		self.frustum = [CC3Frustum frustumOnViewMatrix: _viewMatrix];
		_isProjectionDirty = YES;
		_isViewMatrixInvertedDirty = YES;
		_fieldOfView = kCC3DefaultFieldOfView;
		_nearClippingDistance = kCC3DefaultNearClippingDistance;
		_farClippingDistance = kCC3DefaultFarClippingDistance;
		_hasInfiniteDepthOfField = NO;
		_isOpen = NO;
	}
	return self;
}

// Protected properties for copying
-(BOOL) isProjectionDirty { return _isProjectionDirty; }
-(BOOL) isViewMatrixInvertedDirty { return _isViewMatrixInvertedDirty; }

// Template method that populates this instance from the specified other instance.
// This method is invoked automatically during object copying via the copyWithZone: method.
-(void) populateFrom: (CC3Camera*) another {
	[super populateFrom: another];
	
	self.frustum = [another.frustum autoreleasedCopy];		// retained

	[_viewMatrix populateFrom: another.viewMatrix];

	_fieldOfView = another.fieldOfView;
	_nearClippingDistance = another.nearClippingDistance;
	_farClippingDistance = another.farClippingDistance;
	_isProjectionDirty = another.isProjectionDirty;
	_isViewMatrixInvertedDirty = another.isViewMatrixInvertedDirty;
	_isOpen = another.isOpen;
}

-(NSString*) fullDescription {
	return [NSString stringWithFormat: @"%@, FOV: %.2f, near: %.2f, far: %.2f",
			[super fullDescription], _fieldOfView, _nearClippingDistance, _farClippingDistance];
}


#pragma mark Transformations

-(void) markProjectionDirty { _isProjectionDirty = YES; }

-(void) markViewMatrixInvertedDirty { _isViewMatrixInvertedDirty = YES; }

/**
 * Scaling the camera is a null operation because it scales everything, including the size
 * of objects, but also the distance from the camera to those objects. The effects cancel
 * out, and visually, it appears that nothing has changed. Therefore, the scale property
 * is not applied to the transform matrix of the camera. Instead it is used to adjust the
 * field of view to create a zooming effect. See the notes for the fieldOfView property.
 *
 * This implementation sets the globalScale to that of the parent node, or to unit scaling
 * if no parent. The globalScale is then used to unwind all scaling from the camera, globally,
 * because any inherited scaling will scale the frustum, and cause undesirable clipping
 * artifacts, particularly at the near clipping plane.
 *
 * For example, if the camera is mounted on another node that is scaled to ten times, the
 * near clipping plane of the camera will be scaled away from the camera by ten times,
 * resulting in unwanted clipping around the fringes of the view. For this reason, an inverse
 * scale of 1/10 is applied to the transform to counteract this effect.
 */
-(void) applyScaling {
	[self updateGlobalScale];	// Make sure globalScale is current first.
	[transformMatrix scaleBy: CC3VectorInvert(globalScale)];
	LogTrace(@"%@ scaled back by global %@ to counter parent scaling %@",
			 self, NSStringFromCC3Vector(globalScale), transformMatrix);
}

/**
 * Scaling does not apply to cameras. Sets the globalScale to that of the parent node,
 * or to unit scaling if no parent.
 */
-(void) updateGlobalScale {
	globalScale = parent ? parent.globalScale : kCC3VectorUnitCube;
}

/** Overridden to also build the modelview matrix. */
-(void) transformMatrixChanged {
	[super transformMatrixChanged];
	[self buildModelViewMatrix];
}

/**
 * Template method to rebuild the viewMatrix from the deviceRotationMatrix, which
 * is managed by the CC3Scene's viewportManager, and the inverse of the transformMatrix.
 * Invoked automatically whenever the transformMatrix or device orientation are changed.
 */
-(void) buildModelViewMatrix {
	[_viewMatrix populateFrom: self.viewportManager.deviceRotationMatrix];
	LogTrace(@"%@ applied device rotation matrix %@", self, _viewMatrix);

	[_viewMatrix multiplyBy: self.transformMatrixInverted];
	LogTrace(@"%@ inverted transform applied to modelview matrix %@", self, _viewMatrix);

	// Mark the inverted view matrix as dirty, and let the frustum know that the contents
	// of the view matrix have changed.
	[self markViewMatrixInvertedDirty];
	[_frustum markDirty];
}

/**
 * Template method to rebuild the frustum's projection matrix if the
 * projection parameters have been changed since the last rebuild.
 */
-(void) buildProjection  {
	if(_isProjectionDirty) {
		CC3Viewport vp = self.viewportManager.viewport;
		CC3Assert(vp.h, @"Camera projection matrix cannot be updated before setting the viewport");

		[_frustum populateFrom: self.effectiveFieldOfView
					andAspect: ((GLfloat) vp.w / (GLfloat) vp.h)
				  andNearClip: _nearClippingDistance
				   andFarClip: _farClippingDistance];

		_isProjectionDirty = NO;
		
		// Notify the transform listeners that the projection has changed
		[self notifyTransformListeners];
	}
}

-(void) buildPerspective { [self buildProjection]; }	// Deprecated


#pragma mark Drawing

-(void) openWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	LogTrace(@"Opening %@", self);
	_isOpen = YES;
	[self openProjectionWithVisitor: (CC3NodeDrawingVisitor*) visitor];
	[self openViewWithVisitor: (CC3NodeDrawingVisitor*) visitor];
}

-(void) closeWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	LogTrace(@"Closing %@", self);
	_isOpen = NO;
	[self closeViewWithVisitor: visitor];
	[self closeProjectionWithVisitor: visitor];
}

/** Template method that pushes the GL projection matrix stack, and loads the projectionMatrix into it. */
-(void) openProjectionWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	LogTrace(@"Opening %@ 3D projection", self);
	[visitor.gl pushProjectionMatrixStack];
	[self loadProjectionMatrixWithVisitor: visitor];
}

/** Template method that pops the projectionMatrix from the GL projection matrix stack. */
-(void) closeProjectionWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	LogTrace(@"Closing %@ 3D projection", self);
	[visitor.gl popProjectionMatrixStack];
}

/** Template method that pushes the GL modelview matrix stack, and loads the viewMatrix into it. */
-(void) openViewWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	LogTrace(@"Opening %@ modelview", self);
	[visitor.gl pushModelviewMatrixStack];
	[self loadViewMatrixWithVisitor: visitor];
}

/** Template method that pops the viewMatrix from the GL modelview matrix stack. */
-(void) closeViewWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	LogTrace(@"Closing %@ modelview", self);
	[visitor.gl popModelviewMatrixStack];
}

/** Template method that loads the viewMatrix into the current GL modelview matrix. */
-(void) loadViewMatrixWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	LogTrace(@"%@ loading modelview matrix into GL: %@", self, _viewMatrix);
	CC3Matrix4x3 mtx;
	[self.viewMatrix populateCC3Matrix4x3: &mtx];
	[visitor.gl loadModelviewMatrix: &mtx];
}

/**
 * Template method that loads either the projectionMatrix or the
 * infiniteProjectionMatrix into the current GL projection matrix,
 * depending on the currents state of the hasInfiniteDepthOfField property.
 */
-(void) loadProjectionMatrixWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	LogTrace(@"%@ loading %@finite projection matrix into GL: %@",
			 self, (_hasInfiniteDepthOfField ? @"in" : @""), self.projectionMatrix);
	CC3Matrix4x4 mtx;
	[self.projectionMatrix populateCC3Matrix4x4: &mtx];
	[visitor.gl loadProjectionMatrix: &mtx];
}


#pragma mark Viewing nodes

-(void) moveToShowAllOf: (CC3Node*) aNode {
	[self moveToShowAllOf: aNode withPadding: kCC3DefaultFrustumFitPadding];
}

-(void) moveToShowAllOf: (CC3Node*) aNode withPadding: (GLfloat) padding {
	[self ensureSceneUpdated: YES];
	CC3Vector moveDir = CC3VectorDifference(self.globalLocation, aNode.globalLocation);
	[self moveToShowAllOf: aNode
		   whileLookingAt: kCC3VectorNull
			fromDirection: moveDir
			  withPadding: padding
			   checkScene: NO];
}

-(void) moveToShowAllOf: (CC3Node*) aNode fromDirection: (CC3Vector) aDirection {
	[self moveToShowAllOf: aNode fromDirection: aDirection withPadding: kCC3DefaultFrustumFitPadding];
}

-(void) moveToShowAllOf: (CC3Node*) aNode
		  fromDirection: (CC3Vector) aDirection
			withPadding: (GLfloat) padding {
	[self moveToShowAllOf: aNode
		   whileLookingAt: kCC3VectorNull
			fromDirection: aDirection
			  withPadding: padding
			   checkScene: YES];
}

-(void) moveToShowAllOf: (CC3Node*) aNode whileLookingAt: (CC3Vector) targetLoc {
	[self moveToShowAllOf: aNode
		   whileLookingAt: targetLoc
			  withPadding: kCC3DefaultFrustumFitPadding];
}

-(void) moveToShowAllOf: (CC3Node*) aNode
		 whileLookingAt: (CC3Vector) targetLoc
			withPadding: (GLfloat) padding {
	[self ensureSceneUpdated: YES];
	CC3Vector moveDir = CC3VectorDifference(self.globalLocation, aNode.globalLocation);
	[self moveToShowAllOf: aNode
		   whileLookingAt: targetLoc
			fromDirection: moveDir
			  withPadding: padding
			   checkScene: NO];
}

-(void) moveToShowAllOf: (CC3Node*) aNode
		 whileLookingAt: (CC3Vector) targetLoc
		  fromDirection: (CC3Vector) aDirection {
	[self moveToShowAllOf: aNode
		   whileLookingAt: targetLoc
			fromDirection: aDirection
			  withPadding: kCC3DefaultFrustumFitPadding];
}

-(void) moveToShowAllOf: (CC3Node*) aNode
		 whileLookingAt: (CC3Vector) targetLoc
		  fromDirection: (CC3Vector) aDirection
			withPadding: (GLfloat) padding {
	[self moveToShowAllOf: aNode
		   whileLookingAt: targetLoc
			fromDirection: aDirection
			  withPadding: padding
			   checkScene: YES];
}

-(void) moveToShowAllOf: (CC3Node*) aNode
		 whileLookingAt: (CC3Vector) targetLoc
		  fromDirection: (CC3Vector) aDirection
			withPadding: (GLfloat) padding
			 checkScene: (BOOL) checkScene {
	self.location = [self calculateLocationToShowAllOf: aNode
										whileLookingAt: targetLoc
										 fromDirection: aDirection
										   withPadding: padding
											checkScene: checkScene];
	self.forwardDirection = CC3VectorNegate(aDirection);
	[self ensureAtRootAncestor];
	[self updateTransformMatrices];
}

-(void) moveWithDuration: (ccTime) t toShowAllOf: (CC3Node*) aNode {
	[self moveWithDuration: t toShowAllOf: aNode withPadding: kCC3DefaultFrustumFitPadding];
}

-(void) moveWithDuration: (ccTime) t
			 toShowAllOf: (CC3Node*) aNode
			 withPadding: (GLfloat) padding {
	[self ensureSceneUpdated: YES];
	CC3Vector moveDir = CC3VectorDifference(self.globalLocation, aNode.globalLocation);
	[self moveWithDuration: t
			   toShowAllOf: aNode
			whileLookingAt: kCC3VectorNull
			 fromDirection: moveDir
			   withPadding: padding
				checkScene: NO];
}

-(void) moveWithDuration: (ccTime) t
			 toShowAllOf: (CC3Node*) aNode
		   fromDirection: (CC3Vector) aDirection {
	[self moveWithDuration: t
			   toShowAllOf: aNode
			 fromDirection: aDirection
			   withPadding: kCC3DefaultFrustumFitPadding];
}

-(void) moveWithDuration: (ccTime) t
			 toShowAllOf: (CC3Node*) aNode
		   fromDirection: (CC3Vector) aDirection
			 withPadding: (GLfloat) padding {
	[self moveWithDuration: t
			   toShowAllOf: aNode
			whileLookingAt: kCC3VectorNull
			 fromDirection: aDirection
			   withPadding: padding
				checkScene: YES ];
}

-(void) moveWithDuration: (ccTime) t
		  whileLookingAt: (CC3Vector) targetLoc
			 toShowAllOf: (CC3Node*) aNode {
	[self moveWithDuration: t
			   toShowAllOf: aNode
			whileLookingAt: targetLoc
			   withPadding: kCC3DefaultFrustumFitPadding];
}

-(void) moveWithDuration: (ccTime) t
			 toShowAllOf: (CC3Node*) aNode
		  whileLookingAt: (CC3Vector) targetLoc
			 withPadding: (GLfloat) padding {
	[self ensureSceneUpdated: YES];
	CC3Vector moveDir = CC3VectorDifference(self.globalLocation, aNode.globalLocation);
	[self moveWithDuration: t
			   toShowAllOf: aNode
			whileLookingAt: targetLoc
			 fromDirection: moveDir
			   withPadding: padding
				checkScene: NO];
}

-(void) moveWithDuration: (ccTime) t
			 toShowAllOf: (CC3Node*) aNode
		  whileLookingAt: (CC3Vector) targetLoc
		   fromDirection: (CC3Vector) aDirection {
	[self moveWithDuration: t
			   toShowAllOf: aNode
			whileLookingAt: targetLoc
			 fromDirection: aDirection
			   withPadding: kCC3DefaultFrustumFitPadding];
}

-(void) moveWithDuration: (ccTime) t
			 toShowAllOf: (CC3Node*) aNode
		  whileLookingAt: (CC3Vector) targetLoc
		   fromDirection: (CC3Vector) aDirection
			 withPadding: (GLfloat) padding {
	[self moveWithDuration: t
			   toShowAllOf: aNode
			whileLookingAt: targetLoc
			 fromDirection: aDirection
			   withPadding: padding
				checkScene: YES ];
}

-(void) moveWithDuration: (ccTime) t
			 toShowAllOf: (CC3Node*) aNode
		  whileLookingAt: (CC3Vector) targetLoc
		   fromDirection: (CC3Vector) aDirection
			 withPadding: (GLfloat) padding
			  checkScene: (BOOL) checkScene {
	CC3Vector newLoc = [self calculateLocationToShowAllOf: aNode
										   whileLookingAt: targetLoc
											fromDirection: aDirection
											  withPadding: padding
											   checkScene: checkScene];
	CC3Vector newFwdDir = CC3VectorNegate(aDirection);
	[self ensureAtRootAncestor];
	[self runAction: [CC3MoveTo actionWithDuration: t moveTo: newLoc]];
	[self runAction: [CC3RotateToLookTowards actionWithDuration: t forwardDirection: newFwdDir]];
}

/**
 * Padding to add to the near & far clipping plane when it is adjusted as a result of showing
 * all of a node, to ensure that all of the node is within the far end of the frustum.
 */
#define kCC3FrustumFitPadding 0.01

-(CC3Vector) calculateLocationToShowAllOf: (CC3Node*) aNode
							fromDirection: (CC3Vector) aDirection
							  withPadding: (GLfloat) padding {
	return [self calculateLocationToShowAllOf: aNode
							   whileLookingAt: kCC3VectorNull
								fromDirection: aDirection
								  withPadding: padding];
}

-(CC3Vector) calculateLocationToShowAllOf: (CC3Node*) aNode
						   whileLookingAt: (CC3Vector) targetLoc
							fromDirection: (CC3Vector) aDirection
							  withPadding: (GLfloat) padding {
	return [self calculateLocationToShowAllOf: aNode
							   whileLookingAt: targetLoc
								fromDirection: aDirection
								  withPadding: padding
								   checkScene: YES];
}

-(CC3Vector) calculateLocationToShowAllOf: (CC3Node*) aNode
						   whileLookingAt: (CC3Vector) targLoc
							fromDirection: (CC3Vector) aDirection
							  withPadding: (GLfloat) padding
							   checkScene: (BOOL) checkScene {
	
	[self ensureSceneUpdated: checkScene];
	
	// Complementary unit vectors pointing towards camera from node, and vice versa
	CC3Vector camDir = CC3VectorNormalize(aDirection);
	CC3Vector viewDir = CC3VectorNegate(camDir);
	
	// The camera's new forward direction will be viewDir. Use a matrix to detrmine
	// the camera's new up and right directions assuming the same scene up direction.
	CC3Matrix3x3 rotMtx;
	CC3Matrix3x3PopulateToPointTowards(&rotMtx, viewDir, self.referenceUpDirection);
	CC3Vector upDir = CC3Matrix3x3ExtractUpDirection(&rotMtx);
	CC3Vector rtDir = CC3Matrix3x3ExtractRightDirection(&rotMtx);
	
	// Determine the eight vertices, of the node's bounding box, in the global coordinate system
	CC3BoundingBox gbb = aNode.globalBoundingBox;

	// If a target location has not been specified, use the center of the node's global bounding box
	if (CC3VectorIsNull(targLoc)) targLoc = CC3BoundingBoxCenter(gbb);

	CC3Vector bbMin = gbb.minimum;
	CC3Vector bbMax = gbb.maximum;
	CC3Vector bbVertices[8];
	bbVertices[0] = cc3v(bbMin.x, bbMin.y, bbMin.z);
	bbVertices[1] = cc3v(bbMin.x, bbMin.y, bbMax.z);
	bbVertices[2] = cc3v(bbMin.x, bbMax.y, bbMin.z);
	bbVertices[3] = cc3v(bbMin.x, bbMax.y, bbMax.z);
	bbVertices[4] = cc3v(bbMax.x, bbMin.y, bbMin.z);
	bbVertices[5] = cc3v(bbMax.x, bbMin.y, bbMax.z);
	bbVertices[6] = cc3v(bbMax.x, bbMax.y, bbMin.z);
	bbVertices[7] = cc3v(bbMax.x, bbMax.y, bbMax.z);
	
	// Express the camera's FOV in terms of ratios of the near clip bounds to
	// the near clip distance, so we can determine distances using similar triangles.
	CGSize fovRatios = self.fovRatios;
	
	// Iterate through all eight vertices of the node's bounding box, and calculate
	// the largest distance required to place the camera away from the center of the
	// node in order to fit all eight vertices within the camera's frustum.
	// Simultaneously, calculate the extra distance from the center of the node to
	// the vertex that will be farthest from the camera, so we can ensure that all
	// vertices will fall within the frustum's far end.
	GLfloat maxCtrDist = 0;
	GLfloat maxVtxDeltaDist = 0;
	GLfloat minVtxDeltaDist = 0;
	for (int i = 0; i < 8; i++) {
		
		// Get a vector from the target location to the vertex 
		CC3Vector relVtx = CC3VectorDifference(bbVertices[i], targLoc);
		
		// Project that vector onto each of the camera's new up and right directions,
		// and use similar triangles to determine the distance at which to place the
		// camera so that the vertex will fit in both the up and right directions.
		GLfloat vtxDistUp = ABS(CC3VectorDot(relVtx, upDir) / fovRatios.height);
		GLfloat vtxDistRt = ABS(CC3VectorDot(relVtx, rtDir) / fovRatios.width);
		GLfloat vtxDist = MAX(vtxDistUp, vtxDistRt);
		
		// Calculate how far along the view direction the vertex is from the center
		GLfloat vtxDeltaDist = CC3VectorDot(relVtx, viewDir);
		GLfloat ctrDist = vtxDist - vtxDeltaDist;
		
		// Accumulate the maximum distance from the node's center to the camera
		// required to fit all eight points, and the distance from the node's
		// center to the vertex that will be farthest away from the camera. 
		maxCtrDist = MAX(maxCtrDist, ctrDist);
		maxVtxDeltaDist = MAX(maxVtxDeltaDist, vtxDeltaDist);
		minVtxDeltaDist = MIN(minVtxDeltaDist, vtxDeltaDist);
	}
	
	// Add some padding so we will have a bit of space around the node when it fills the view.
	maxCtrDist *= (1 + padding);
	
	// Determine if we need to move the far end of the camera frustum farther away
	GLfloat farClip = CC3VectorLength(CC3VectorScaleUniform(viewDir, maxCtrDist + maxVtxDeltaDist));
	farClip *= (1 + kCC3FrustumFitPadding);		// Include a little bit of padding
	if (farClip > self.farClippingDistance) self.farClippingDistance = farClip;
	
	// Determine if we need to move the near end of the camera frustum closer
	GLfloat nearClip = CC3VectorLength(CC3VectorScaleUniform(viewDir, maxCtrDist + minVtxDeltaDist));
	nearClip *= (1 - kCC3FrustumFitPadding);		// Include a little bit of padding
	if (nearClip < self.nearClippingDistance) self.nearClippingDistance = nearClip;
	
	LogTrace(@"%@ moving to %@ to show %@ at %@ within %@ with new farClip: %.3f", self,
				  NSStringFromCC3Vector(CC3VectorAdd(targLoc, CC3VectorScaleUniform(camDir, maxCtrDist))),
				  aNode, NSStringFromCC3Vector(targLoc), frustum, self.farClippingDistance);
	
	// Return the new location of the camera,
	return CC3VectorAdd(targLoc, CC3VectorScaleUniform(camDir, maxCtrDist));
}

/**
 * If the checkScene arg is YES, and the scene is not running, force an update
 * to ensure that all nodes are transformed to their global coordinates.
 */
-(void) ensureSceneUpdated: (BOOL) checkScene {
	if (checkScene) {
		CC3Scene* myScene = self.scene;
		if ( !myScene.isRunning ) [myScene updateScene];
	}
}

/**
 * Returns the camera's FOV in terms of ratios of the near clip bounds
 * (width & height) to the near clip distance.
 */
-(CGSize) fovRatios {
	switch(CCDirector.sharedDirector.deviceOrientation) {
		case UIDeviceOrientationLandscapeLeft:
		case UIDeviceOrientationLandscapeRight:
			return CGSizeMake(_frustum.top / _frustum.near, _frustum.right / _frustum.near);
		case UIDeviceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
		default:
			return CGSizeMake(_frustum.right / _frustum.near, _frustum.top / _frustum.near);
	}
}


/**
 * Ensures that this camera is a direct child of its root ancestor, which in almost all
 * cases will be your CC3Scene. This is done by simply adding this camera to the root ancestor.
 * The request will be ignored if this camera is already a direct child of the root ancestor.
 */
-(void) ensureAtRootAncestor { [self.rootAncestor addChild: self]; }


#pragma mark 3D <-> 2D mapping functionality

-(CC3Vector) projectLocation: (CC3Vector) a3DLocation {
	
	// Convert specified location to a 4D homogeneous location vector
	// and transform it using the modelview and projection matrices.
	CC3Vector4 hLoc = CC3Vector4FromLocation(a3DLocation);
	hLoc = [_viewMatrix transformHomogeneousVector: hLoc];
	hLoc = [self.projectionMatrix transformHomogeneousVector: hLoc];
	
	// Convert projected 4D vector back to 3D.
	CC3Vector projectedLoc = CC3VectorFromHomogenizedCC3Vector4(hLoc);

	// The projected vector is in a projection coordinate space between -1 and +1 on all axes.
	// Normalize the vector so that each component is between 0 and 1 by calculating ( v = (v + 1) / 2 ).
	projectedLoc = CC3VectorAverage(projectedLoc, kCC3VectorUnitCube);
	
	// Map the X & Y components of the projected location (now between 0 and 1) to viewport coordinates.
	CC3Viewport vp = self.viewportManager.viewport;
	projectedLoc.x = vp.x + (vp.w * projectedLoc.x);
	projectedLoc.y = vp.y + (vp.h * projectedLoc.y);
	
	// Using the vector from the camera to the 3D location, determine whether or not the
	// 3D location is in front of the camera by using the dot-product of that vector and
	// the direction the camera is pointing. Set the Z-component of the projected location
	// to be the signed distance from the camera to the 3D location, with a positive sign
	// indicating the location is in front of the camera, and a negative sign indicating
	// the location is behind the camera.
	CC3Vector camToLocVector = CC3VectorDifference(a3DLocation, self.globalLocation);
	GLfloat camToLocDist = CC3VectorLength(camToLocVector);
	GLfloat frontOrBack = SIGN(CC3VectorDot(camToLocVector, self.globalForwardDirection));
	projectedLoc.z = frontOrBack * camToLocDist;
	
	// Map the projected point to the device orientation then return it
	CGPoint ppt = [self.viewportManager cc2PointFromGLPoint: ccp(projectedLoc.x, projectedLoc.y)];
	CC3Vector orientedLoc = cc3v(ppt.x, ppt.y, projectedLoc.z);
	
	LogTrace(@"%@ projecting location %@ to %@ and orienting with device to %@ using viewport %@",
				  self, NSStringFromCC3Vector(a3DLocation), NSStringFromCC3Vector(projectedLoc),
				  NSStringFromCC3Vector(orientedLoc), NSStringFromCC3Viewport(self.viewportManager.viewport));
	return orientedLoc;
}

-(CC3Vector) projectLocation: (CC3Vector) aLocal3DLocation onNode: (CC3Node*) aNode {
	return [self projectLocation: [aNode.transformMatrix transformLocation: aLocal3DLocation]];
}

-(CC3Vector) projectNode: (CC3Node*) aNode {
	CC3Assert(aNode, @"Camera cannot project a nil node.");
	CC3Vector pLoc = [self projectLocation: aNode.globalLocation];
	aNode.projectedLocation = pLoc;
	return pLoc;
}

-(CC3Ray) unprojectPoint: (CGPoint) cc2Point {

	// CC_CONTENT_SCALE_FACTOR = 2.0 if Retina display active, or 1.0 otherwise.
	CGPoint glPoint = ccpMult(cc2Point, CC_CONTENT_SCALE_FACTOR());
	
	// Express the glPoint X & Y as proportion of the layer dimensions, based
	// on an origin in the center of the layer (the center of the camera's view).
	CGSize lb = self.viewportManager.layerBounds.size;
	GLfloat xp = ((2.0 * glPoint.x) / lb.width) - 1;
	GLfloat yp = ((2.0 * glPoint.y) / lb.height) - 1;
	
	// Now that we have the location of the glPoint proportional to the layer dimensions,
	// we need to map the layer dimensions onto the frustum near clipping plane.
	// The layer dimensions change as device orientation changes, but the viewport
	// dimensions remain the same. The field of view is always measured relative to the
	// viewport height, independent of device orientation. We can find the top-right
	// corner of the view on the near clipping plane (top-right is positive X & Y from
	// the center of the camera's view) by multiplying by an orientation aspect in each
	// direction. This orientation aspect depends on the device orientation, which can
	// be expressed in terms of the relationship between the layer width and height and
	// the constant viewport height. The Z-coordinate at the near clipping plane is
	// negative since the camera points down the negative Z axis in its local coordinates.
	CGFloat vph = self.viewportManager.viewport.h;
	GLfloat xNearTopRight = _frustum.top * (lb.width / vph);
	GLfloat yNearTopRight = _frustum.top * (lb.height / vph);
	GLfloat zNearTopRight = -_frustum.near;
	
	LogTrace(@"%@ view point %@ mapped to proportion (%.3f, %.3f) of top-right corner: (%.3f, %.3f) of view bounds %@ and viewport %@",
				  [self class], NSStringFromCGPoint(glPoint), xp, yp, xNearTopRight, yNearTopRight,
				  NSStringFromCGSize(lb), NSStringFromCC3Viewport(self.viewportManager.viewport));
	
	// We now have the location of the the top-right corner of the view, at the near
	// clipping plane, taking into account device orientation. We can now map the glPoint
	// onto the near clipping plane by multiplying by the glPoint's proportional X & Y
	// location, relative to the top-right corner of the view, which was calculated above.
	CC3Vector pointLocNear = cc3v(xNearTopRight * xp,
								  yNearTopRight * yp,
								  zNearTopRight);
	CC3Ray ray;
	if (self.isUsingParallelProjection) {
		// The location on the near clipping plane is relative to the camera's
		// local coordinates. Convert it to global coordinates before returning.
		// The ray direction is straight out from that global location in the 
		// camera's globalForwardDirection.
		ray.startLocation =  [transformMatrix transformLocation: pointLocNear];
		ray.direction = self.globalForwardDirection;
	} else {
		// The location on the near clipping plane is relative to the camera's local
		// coordinates. Since the camera's origin is zero in its local coordinates,
		// this point on the near clipping plane forms a directional vector from the
		// camera's origin. Rotate this directional vector with the camera's rotation
		// matrix to convert it to a global direction vector in global coordinates.
		// Thanks to cocos3d forum user Rogs for suggesting the use of the globalRotationMatrix.
		ray.startLocation = self.globalLocation;
		ray.direction = [self.globalRotationMatrix transformDirection: pointLocNear];
	}
	
	// Ensure the direction component is normalized before returning.
	ray.direction = CC3VectorNormalize(ray.direction);
	
	LogTrace(@"%@ unprojecting point %@ to near plane location %@ and to ray starting at %@ and pointing towards %@",
				  [self class], NSStringFromCGPoint(glPoint), NSStringFromCC3Vector(pointLocNear),
				  NSStringFromCC3Vector(ray.startLocation), NSStringFromCC3Vector(ray.direction));

	return ray;
}

-(CC3Vector4) unprojectPoint:(CGPoint) cc2Point ontoPlane: (CC3Plane) plane {
	return CC3RayIntersectionWithPlane([self unprojectPoint: cc2Point], plane);
}

@end


#pragma mark -
#pragma mark CC3Frustum

// Indices of the six boundary planes
#define kCC3TopIdx		0
#define kCC3BotmIdx		1
#define kCC3LeftIdx		2
#define kCC3RgtIdx		3
#define kCC3NearIdx		4
#define kCC3FarIdx		5

// Indices of the eight boundary vertices
#define kCC3NearTopLeftIdx	0
#define kCC3NearTopRgtIdx	1
#define kCC3NearBtmLeftIdx	2
#define kCC3NearBtmRgtIdx	3
#define kCC3FarTopLeftIdx	4
#define kCC3FarTopRgtIdx	5
#define kCC3FarBtmLeftIdx	6
#define kCC3FarBtmRgtIdx	7

@interface CC3BoundingVolume (TemplateMethods)
-(void) updateIfNeeded;
@end

@interface CC3Frustum (TemplateMethods)
-(void) populateProjectionMatrix;
-(void) buildVertices;
@end

@implementation CC3Frustum

@synthesize top=_top, bottom=_bottom, left=_left, right=_right, near=_near, far=_far;
@synthesize viewMatrix=_viewMatrix, isUsingParallelProjection=_isUsingParallelProjection;

-(void) dealloc {
	[_viewMatrix release];
	[_finiteProjectionMatrix release];
	[_infiniteProjectionMatrix release];
	[super dealloc];
}

-(void) setTop: (GLfloat) aValue {
	_top = aValue;
	[self markDirty];
}

-(void) setBottom: (GLfloat) aValue {
	_bottom = aValue;
	[self markDirty];
}

-(void) setLeft: (GLfloat) aValue {
	_left = aValue;
	[self markDirty];
}

-(void) setRight: (GLfloat) aValue {
	_right = aValue;
	[self markDirty];
}

-(void) setNear: (GLfloat) aValue {
	_near = aValue;
	[self markDirty];
}

-(void) setFar: (GLfloat) aValue {
	_far = aValue;
	[self markDirty];
}

-(CC3Plane*) planes {
	[self updateIfNeeded];
	return _planes;
}

-(GLuint) planeCount { return 6; }

-(CC3Vector*) vertices {
	[self updateIfNeeded];
	return _vertices;
}

-(GLuint) vertexCount { return 8; }

-(CC3Plane) topPlane { return self.planes[kCC3TopIdx]; }
-(CC3Plane) bottomPlane { return self.planes[kCC3BotmIdx]; }
-(CC3Plane) leftPlane { return self.planes[kCC3LeftIdx]; }
-(CC3Plane) rightPlane { return self.planes[kCC3RgtIdx]; }
-(CC3Plane) nearPlane { return self.planes[kCC3NearIdx]; }
-(CC3Plane) farPlane { return self.planes[kCC3FarIdx]; }

-(CC3Vector) nearTopLeft { return self.vertices[kCC3NearTopLeftIdx]; }
-(CC3Vector) nearTopRight { return self.vertices[kCC3NearTopRgtIdx]; }
-(CC3Vector) nearBottomLeft { return self.vertices[kCC3NearBtmLeftIdx]; }
-(CC3Vector) nearBottomRight { return self.vertices[kCC3NearBtmRgtIdx]; }
-(CC3Vector) farTopLeft { return self.vertices[kCC3FarTopLeftIdx]; }
-(CC3Vector) farTopRight { return self.vertices[kCC3FarTopRgtIdx]; }
-(CC3Vector) farBottomLeft { return self.vertices[kCC3FarBtmLeftIdx]; }
-(CC3Vector) farBottomRight { return self.vertices[kCC3FarBtmRgtIdx]; }

// Deprecated
-(CC3Matrix*) modelviewMatrix { return self.viewMatrix; }

-(CC3Matrix*) finiteProjectionMatrix {
	[self updateIfNeeded];
	return _finiteProjectionMatrix;
}


#pragma mark Allocation and initialization

-(id) init { return [self initOnViewMatrix: [CC3AffineMatrix matrix]]; }

-(id) initOnViewMatrix: (CC3Matrix*) aMtx {
	if ( (self = [super init]) ) {
		_top = _bottom = _left = _right = _near = _far = 0.0f;
		_viewMatrix = [aMtx retain];
		_finiteProjectionMatrix = [CC3ProjectionMatrix new];
		_infiniteProjectionMatrix = nil;
		_isUsingParallelProjection = NO;
		_isInfiniteProjectionDirty = YES;
	}
	return self;
}

+(id) frustumOnViewMatrix: (CC3Matrix*) aMtx {
	return [[[self alloc] initOnViewMatrix: aMtx] autorelease];
}

// Protected properties for copying
-(BOOL) isInfiniteProjectionDirty { return _isInfiniteProjectionDirty; }

-(void) populateFrom: (CC3Frustum*) another {
	[super populateFrom: another];
	
	_top = another.top;
	_bottom = another.bottom;
	_left = another.left;
	_right = another.right;
	_near = another.near;
	_far = another.far;
	
	[_finiteProjectionMatrix release];
	_finiteProjectionMatrix = [another.finiteProjectionMatrix copy];		// retained
	
	[_infiniteProjectionMatrix release];
	_infiniteProjectionMatrix = [another.infiniteProjectionMatrix copy];	// retained
	_isInfiniteProjectionDirty = another.isInfiniteProjectionDirty;
	
	_isUsingParallelProjection = another.isUsingParallelProjection;
}

-(void) populateFrom: (GLfloat) fieldOfView
		   andAspect: (GLfloat) aspect
		 andNearClip: (GLfloat) nearClip
		  andFarClip: (GLfloat) farClip {
	
	GLfloat halfFOV = fieldOfView / 2.0f;
	_near = nearClip;
	_far = farClip;

	// Apply the field of view angle to the narrower aspect.
	if (aspect >= 1.0f) {			// Landscape
		_top = _near * tanf(DegreesToRadians(halfFOV));
		_right = _top * aspect;
	} else {						// Portrait
		_right = _near * tanf(DegreesToRadians(halfFOV));
		_top = _right / aspect;
	}
	
	_bottom = -_top;
	_left = -_right;
	
	[self markDirty];
	
	LogTrace(@"%@ updated from FOV: %.3f, Aspect: %.3f, Near: %.3f, Far: %.3f",
			 self, fieldOfView, nearClip, nearClip, farClip);
}

-(NSString*) fullDescription {
	NSMutableString* desc = [NSMutableString stringWithCapacity: 500];
	[desc appendFormat: @"%@", self.description];
	[desc appendFormat: @"left: %.3f, right: %.3f, ", _left, _right];
	[desc appendFormat: @"top: %.3f, bottom: %.3f, ", _top, _bottom];
	[desc appendFormat: @"near: %.3f, far: %.3f", _near, _far];
	[desc appendFormat: @"\n\tleftPlane: %@", NSStringFromCC3Plane(self.leftPlane)];
	[desc appendFormat: @"\n\trightPlane: %@", NSStringFromCC3Plane(self.rightPlane)];
	[desc appendFormat: @"\n\ttopPlane: %@", NSStringFromCC3Plane(self.topPlane)];
	[desc appendFormat: @"\n\tbottomPlane: %@", NSStringFromCC3Plane(self.bottomPlane)];
	[desc appendFormat: @"\n\tnearPlane: %@", NSStringFromCC3Plane(self.nearPlane)];
	[desc appendFormat: @"\n\tfarPlane: %@", NSStringFromCC3Plane(self.farPlane)];
	[desc appendFormat: @"\n\tnearTopLeft: %@", NSStringFromCC3Vector(self.nearTopLeft)];
	[desc appendFormat: @"\n\tnearTopRight: %@", NSStringFromCC3Vector(self.nearTopRight)];
	[desc appendFormat: @"\n\tnearBottomLeft: %@", NSStringFromCC3Vector(self.nearBottomLeft)];
	[desc appendFormat: @"\n\tnearBottomRight: %@", NSStringFromCC3Vector(self.nearBottomRight)];
	[desc appendFormat: @"\n\tfarTopLeft: %@", NSStringFromCC3Vector(self.farTopLeft)];
	[desc appendFormat: @"\n\tfarTopRight: %@", NSStringFromCC3Vector(self.farTopRight)];
	[desc appendFormat: @"\n\tfarBottomLeft: %@", NSStringFromCC3Vector(self.farBottomLeft)];
	[desc appendFormat: @"\n\tfarBottomRight: %@", NSStringFromCC3Vector(self.farBottomRight)];
	return desc;
}


#pragma mark Projection matrices

/**
 * Template method that populates the projection matrix from the frustum.
 * Uses either orthographic or perspective projection, depending on the value
 * of the isUsingParallelProjection property.
 */
-(void) populateProjectionMatrix {
	if (_isUsingParallelProjection) {
		[_finiteProjectionMatrix populateOrthoFromFrustumLeft: _left andRight: _right andTop: _top
											  andBottom: _bottom andNear: _near andFar: _far];
	} else {
		[_finiteProjectionMatrix populateFromFrustumLeft: _left andRight: _right andTop: _top
										andBottom: _bottom andNear: _near andFar: _far];
	}
	_isInfiniteProjectionDirty = YES;
}

/**
 * Returns the projection matrix modified to have an infinite depth of view,
 * by assuming a farClippingDistance set at infinity.
 *
 * Since this matrix is not commonly used, it is only calculated when the
 * finiateProjectionMatrix has changed, and then only on demand.
 *
 * When the finiteProjectionMatrix is recalculated, the infiniteProjectionMatrix
 * is marked as dirty. It is then recalculated the next time this property
 * is accessed, and is cached until it is marked dirty again.
 */
-(CC3Matrix*) infiniteProjectionMatrix {
	[self updateIfNeeded];		// Make sure properties are up to date
	if (!_infiniteProjectionMatrix) {
		_infiniteProjectionMatrix = [CC3ProjectionMatrix new];
		_isInfiniteProjectionDirty = YES;
	}
	if (_isInfiniteProjectionDirty) {
		if (_isUsingParallelProjection) {
			[_infiniteProjectionMatrix populateOrthoFromFrustumLeft: _left andRight: _right
															andTop: _top andBottom: _bottom
														   andNear: _near];
		} else {
			[_infiniteProjectionMatrix populateFromFrustumLeft: _left andRight: _right
													   andTop: _top andBottom: _bottom
													  andNear: _near];
		}
		_isInfiniteProjectionDirty = NO;
	}
	return _infiniteProjectionMatrix;
}


#pragma mark Updating

/** Make sure projection matrix is current. */
-(void) buildVolume { [self populateProjectionMatrix]; }

/**
 * Builds the six planes that define the frustum volume,
 * using the modelview matrix and the finite projection matrix.
 */
-(void) buildPlanes{
	CC3Matrix4x4 projMtx, viewMtx, m;
	[_finiteProjectionMatrix populateCC3Matrix4x4: &projMtx];
	[_viewMatrix populateCC3Matrix4x4: &viewMtx];
	CC3Matrix4x4Multiply(&m, &projMtx, &viewMtx);
	
	_planes[kCC3BotmIdx] = CC3PlaneNegate(CC3PlaneNormalize(CC3PlaneMake((m.c1r4 + m.c1r2), (m.c2r4 + m.c2r2),
																		 (m.c3r4 + m.c3r2), (m.c4r4 + m.c4r2))));
	_planes[kCC3TopIdx]  = CC3PlaneNegate(CC3PlaneNormalize(CC3PlaneMake((m.c1r4 - m.c1r2), (m.c2r4 - m.c2r2),
																		 (m.c3r4 - m.c3r2), (m.c4r4 - m.c4r2))));
	
	_planes[kCC3LeftIdx] = CC3PlaneNegate(CC3PlaneNormalize(CC3PlaneMake((m.c1r4 + m.c1r1), (m.c2r4 + m.c2r1),
																		 (m.c3r4 + m.c3r1), (m.c4r4 + m.c4r1))));
	_planes[kCC3RgtIdx]  = CC3PlaneNegate(CC3PlaneNormalize(CC3PlaneMake((m.c1r4 - m.c1r1), (m.c2r4 - m.c2r1),
																		 (m.c3r4 - m.c3r1), (m.c4r4 - m.c4r1))));
	
	_planes[kCC3NearIdx] = CC3PlaneNegate(CC3PlaneNormalize(CC3PlaneMake((m.c1r4 + m.c1r3), (m.c2r4 + m.c2r3),
																		 (m.c3r4 + m.c3r3), (m.c4r4 + m.c4r3))));
	_planes[kCC3FarIdx]  = CC3PlaneNegate(CC3PlaneNormalize(CC3PlaneMake((m.c1r4 - m.c1r3), (m.c2r4 - m.c2r3),
																		 (m.c3r4 - m.c3r3), (m.c4r4 - m.c4r3))));
	[self buildVertices];
	
	LogTrace(@"Built planes for %@ from projection: %@ and view: %@",
				  self.fullDescription, _finiteProjectionMatrix, _viewMatrix);
}

-(void) buildVertices {
	CC3Plane tp = _planes[kCC3TopIdx];
	CC3Plane bp = _planes[kCC3BotmIdx];
	CC3Plane lp = _planes[kCC3LeftIdx];
	CC3Plane rp = _planes[kCC3RgtIdx];
	CC3Plane np = _planes[kCC3NearIdx];
	CC3Plane fp = _planes[kCC3FarIdx];
	
	_vertices[kCC3NearTopLeftIdx] = CC3TriplePlaneIntersection(np, tp, lp);
	_vertices[kCC3NearTopRgtIdx] = CC3TriplePlaneIntersection(np, tp, rp);
	
	_vertices[kCC3NearBtmLeftIdx] = CC3TriplePlaneIntersection(np, bp, lp);
	_vertices[kCC3NearBtmRgtIdx] = CC3TriplePlaneIntersection(np, bp, rp);
	
	_vertices[kCC3FarTopLeftIdx] = CC3TriplePlaneIntersection(fp, tp, lp);
	_vertices[kCC3FarTopRgtIdx] = CC3TriplePlaneIntersection(fp, tp, rp);
	
	_vertices[kCC3FarBtmLeftIdx] = CC3TriplePlaneIntersection(fp, bp, lp);
	_vertices[kCC3FarBtmRgtIdx] = CC3TriplePlaneIntersection(fp, bp, rp);
}

// Deprecated method
-(void) markPlanesDirty { [self markDirty]; }

// Deprecated method
-(BOOL) doesIntersectPointAt: (CC3Vector) aLocation {
	return [self doesIntersectLocation: aLocation];
}

// Deprecated method
-(BOOL) doesIntersectSphereAt: (CC3Vector) aLocation withRadius: (GLfloat) radius {
	return [self doesIntersectSphere: CC3SphereMake(aLocation, radius)];
}

@end


#pragma mark -
#pragma mark CC3Node extension for cameras

@implementation CC3Node (Camera)

-(BOOL) isCamera { return NO; }

@end

