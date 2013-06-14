/*
 * CC3Mesh.m
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
 * See header file CC3Mesh.h for full API documentation.
 */

#import "CC3Mesh.h"
#import "CC3IOSExtensions.h"

NSString* NSStringFromCC3VertexContent(CC3VertexContent vtxContent) {
	NSMutableString* desc = [NSMutableString stringWithCapacity: 100];
	BOOL first = YES;
	if (vtxContent & kCC3VertexContentLocation) {
		[desc appendFormat: @"%@", first ? @" (" : @" + "];
		[desc appendFormat: @"Location"];
		first = NO;
	}
	if (vtxContent & kCC3VertexContentNormal) {
		[desc appendFormat: @"%@", first ? @" (" : @" + "];
		[desc appendFormat: @"Normal"];
		first = NO;
	}
	if (vtxContent & kCC3VertexContentTangent) {
		[desc appendFormat: @"%@", first ? @" (" : @" + "];
		[desc appendFormat: @"Tangent"];
		first = NO;
	}
	if (vtxContent >= kCC3VertexContentBitangent) {
		[desc appendFormat: @"%@", first ? @" (" : @" + "];
		[desc appendFormat: @"Bitangent"];
		first = NO;
	}
	if (vtxContent & kCC3VertexContentColor) {
		[desc appendFormat: @"%@", first ? @" (" : @" + "];
		[desc appendFormat: @"Color"];
		first = NO;
	}
	if (vtxContent & kCC3VertexContentTextureCoordinates) {
		[desc appendFormat: @"%@", first ? @" (" : @" + "];
		[desc appendFormat: @"TexCoords"];
		first = NO;
	}
	if (vtxContent & kCC3VertexContentPointSize) {
		[desc appendFormat: @"%@", first ? @" (" : @" + "];
		[desc appendFormat: @"PointSize"];
		first = NO;
	}
	if (vtxContent & kCC3VertexContentWeights) {
		[desc appendFormat: @"%@", first ? @" (" : @" + "];
		[desc appendFormat: @"Weights"];
		first = NO;
	}
	if (vtxContent & kCC3VertexContentMatrixIndices) {
		[desc appendFormat: @"%@", first ? @" (" : @" + "];
		[desc appendFormat: @"MatrixIndices"];
		first = NO;
	}
	[desc appendFormat: @"%@", first ? @"(None)" : @")"];
	return desc;
}


#pragma mark CC3Mesh

@implementation CC3Mesh

@synthesize faces=_faces, capacityExpansionFactor=_capacityExpansionFactor;

-(void) dealloc {
	[_faces release];
	[_vertexLocations release];
	[_vertexNormals release];
	[_vertexTangents release];
	[_vertexBitangents release];
	[_vertexColors release];
	[_vertexTextureCoordinates release];
	[_vertexMatrixIndices release];
	[_vertexWeights release];
	[_vertexPointSizes release];
	[_vertexIndices release];
	[_overlayTextureCoordinates release];
	[super dealloc];
}

-(void) setName: (NSString*) aName {
	super.name = aName;
	[_vertexLocations deriveNameFrom: self];
	[_vertexNormals deriveNameFrom: self];
	[_vertexTangents deriveNameFrom: self];
	[_vertexBitangents deriveNameFrom: self];
	[_vertexColors deriveNameFrom: self];
	[_vertexTextureCoordinates deriveNameFrom: self];
	[_vertexMatrixIndices deriveNameFrom: self];
	[_vertexWeights deriveNameFrom: self];
	[_vertexPointSizes deriveNameFrom: self];
	[_vertexIndices deriveNameFrom: self];
	for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) {
		[otc deriveNameFrom: self];
	}
}

-(NSString*) nameSuffix { return @"Mesh"; }


#pragma mark Vertex arrays

-(CC3VertexLocations*) vertexLocations { return _vertexLocations; }

-(void) setVertexLocations: (CC3VertexLocations*) vtxLocs {
	[_vertexLocations autorelease];
	_vertexLocations = [vtxLocs retain];
	[_vertexLocations deriveNameFrom: self];
}

-(BOOL) hasVertexLocations { return (_vertexLocations != nil); }

-(CC3VertexNormals*) vertexNormals { return _vertexNormals; }

-(void) setVertexNormals: (CC3VertexNormals*) vtxNorms {
	[_vertexNormals autorelease];
	_vertexNormals = [vtxNorms retain];
	[_vertexNormals deriveNameFrom: self];
}

-(BOOL) hasVertexNormals { return (_vertexNormals != nil); }

-(CC3VertexTangents*) vertexTangents { return _vertexTangents; }

-(void) setVertexTangents: (CC3VertexTangents*) vtxTans {
	[_vertexTangents autorelease];
	_vertexTangents = [vtxTans retain];
	[_vertexTangents deriveNameFrom: self];
}

-(BOOL) hasVertexTangents { return (_vertexTangents != nil); }

-(CC3VertexTangents*) vertexBitangents { return _vertexBitangents; }

-(void) setVertexBitangents: (CC3VertexTangents*) vtxBitans {
	[_vertexBitangents autorelease];
	_vertexBitangents = [vtxBitans retain];
	[_vertexBitangents deriveNameFrom: self usingSuffix: @"Bitangents"];
	_vertexBitangents.semantic = kCC3SemanticVertexBitangent;
}

-(BOOL) hasVertexBitangents { return (_vertexBitangents != nil); }

-(CC3VertexColors*) vertexColors { return _vertexColors; }

-(void) setVertexColors: (CC3VertexColors*) vtxCols {
	[_vertexColors autorelease];
	_vertexColors = [vtxCols retain];
	[_vertexColors deriveNameFrom: self];
}

-(BOOL) hasVertexColors { return (_vertexColors != nil); }

-(GLenum) vertexColorType { return _vertexColors ? _vertexColors.elementType : GL_FALSE; }

-(CC3VertexMatrixIndices*) vertexMatrixIndices { return _vertexMatrixIndices; }

-(void) setVertexMatrixIndices: (CC3VertexMatrixIndices*) vtxMtxInd {
	[_vertexMatrixIndices autorelease];
	_vertexMatrixIndices = [vtxMtxInd retain];
	[_vertexMatrixIndices deriveNameFrom: self];
}

-(BOOL) hasVertexMatrixIndices { return (_vertexMatrixIndices != nil); }

-(CC3VertexWeights*) vertexWeights { return _vertexWeights; }

-(void) setVertexWeights: (CC3VertexWeights*) vtxWgts {
	[_vertexWeights autorelease];
	_vertexWeights = [vtxWgts retain];
	[_vertexWeights deriveNameFrom: self];
}

-(BOOL) hasVertexWeights { return (_vertexWeights != nil); }

-(CC3VertexPointSizes*) vertexPointSizes { return _vertexPointSizes; }

-(void) setVertexPointSizes: (CC3VertexPointSizes*) vtxSizes {
	[_vertexPointSizes autorelease];
	_vertexPointSizes = [vtxSizes retain];
	[_vertexPointSizes deriveNameFrom: self];
}

-(BOOL) hasVertexPointSizes { return (_vertexPointSizes != nil); }

-(CC3VertexIndices*) vertexIndices { return _vertexIndices; }

-(void) setVertexIndices: (CC3VertexIndices*) vtxInd {
	[_vertexIndices autorelease];
	_vertexIndices = [vtxInd retain];
	[_vertexIndices deriveNameFrom: self];
}

-(BOOL) hasVertexIndices { return (_vertexIndices != nil); }

-(CC3VertexTextureCoordinates*) vertexTextureCoordinates { return _vertexTextureCoordinates; }

-(void) setVertexTextureCoordinates: (CC3VertexTextureCoordinates*) vtxTexCoords {
	[_vertexTextureCoordinates autorelease];
	_vertexTextureCoordinates = [vtxTexCoords retain];
	[_vertexTextureCoordinates deriveNameFrom: self];
}

-(BOOL) hasVertexTextureCoordinates { return (_vertexTextureCoordinates != nil); }

-(GLuint) textureCoordinatesArrayCount {
	return (_overlayTextureCoordinates ? (GLuint)_overlayTextureCoordinates.count : 0) + (_vertexTextureCoordinates ? 1 : 0);
}

-(void) addTextureCoordinates: (CC3VertexTextureCoordinates*) vtxTexCoords {
	CC3Assert(vtxTexCoords, @"Overlay texture cannot be nil");
	CC3Assert(!_overlayTextureCoordinates || ((_overlayTextureCoordinates.count + 1) <
											  CC3OpenGL.sharedGL.maxNumberOfTextureUnits),
			  @"Too many overlaid textures. This platform only supports %i texture units.",
			  CC3OpenGL.sharedGL.maxNumberOfTextureUnits);
	LogTrace(@"Adding %@ to %@", vtxTexCoords, self);
	
	// Set the first texture coordinates into vertexTextureCoordinates
	if (!_vertexTextureCoordinates) {
		self.vertexTextureCoordinates = vtxTexCoords;
	} else {
		// Add subsequent texture coordinate arrays to the array of overlayTextureCoordinates,
		// creating it first if necessary
		if(!_overlayTextureCoordinates) {
			_overlayTextureCoordinates = [[CCArray array] retain];
		}
		[_overlayTextureCoordinates addObject: vtxTexCoords];
		[vtxTexCoords deriveNameFrom: self];
	}
}

-(void) removeTextureCoordinates: (CC3VertexTextureCoordinates*) aTexCoord {
	LogTrace(@"Removing %@ from %@", aTexCoord, self);
	
	// If the array to be removed is actually the vertexTextureCoordinates, remove it
	if (_vertexTextureCoordinates == aTexCoord) {
		self.vertexTextureCoordinates = nil;
	} else {
		// Otherwise, find it in the array of overlays and remove it,
		// and remove the overlay array if it is now empty
		if (_overlayTextureCoordinates && aTexCoord) {
			[_overlayTextureCoordinates removeObjectIdenticalTo: aTexCoord];
			if (_overlayTextureCoordinates.count == 0) {
				[_overlayTextureCoordinates release];
				_overlayTextureCoordinates = nil;
			}
		}
	}
}

-(void) removeAllTextureCoordinates {
	// Remove the first texture coordinates
	self.vertexTextureCoordinates = nil;
	
	// Remove the overlay texture coordinates
	CCArray* myOTCs = [_overlayTextureCoordinates copy];
	for (CC3VertexTextureCoordinates* otc in myOTCs) {
		[self removeTextureCoordinates: otc];
	}
	[myOTCs release];
}

-(CC3VertexTextureCoordinates*) getTextureCoordinatesNamed: (NSString*) aName {
	NSString* tcName;
	
	// First check if the first texture coordinates is the one
	if (_vertexTextureCoordinates) {
		tcName = _vertexTextureCoordinates.name;
		if ([tcName isEqual: aName] || (!tcName && !aName)) {		// Name equal or both nil.
			return _vertexTextureCoordinates;
		}
	}
	// Then look for it in the overlays array
	for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) {
		tcName = otc.name;
		if ([tcName isEqual: aName] || (!tcName && !aName)) {		// Name equal or both nil.
			return otc;
		}
	}
	return nil;
}

// If first texture unit, return vertexTextureCoordinates property.
// Otherwise, if texUnit within bounds of overlays, get overlay.
// Otherwise, look up the texture coordinates for the previous texture unit
// recursively until one is found, or we reach first texture unit.
-(CC3VertexTextureCoordinates*) textureCoordinatesForTextureUnit: (GLuint) texUnit {
	if (texUnit == 0) {
		return _vertexTextureCoordinates;
	} else if (texUnit < self.textureCoordinatesArrayCount) {
		return [_overlayTextureCoordinates objectAtIndex: (texUnit - 1)];
	} else {
		return [self textureCoordinatesForTextureUnit: (texUnit - 1)];
	}
}

-(void) setTextureCoordinates: (CC3VertexTextureCoordinates *) aTexCoords
			   forTextureUnit: (GLuint) texUnit {
	CC3Assert(aTexCoords, @"Overlay texture coordinates cannot be nil");
	if (texUnit == 0) {
		self.vertexTextureCoordinates = aTexCoords;
	} else if (texUnit < self.textureCoordinatesArrayCount) {
		[_overlayTextureCoordinates fastReplaceObjectAtIndex: (texUnit - 1) withObject: aTexCoords];
	} else {
		[self addTextureCoordinates: aTexCoords];
	}
}

-(CC3VertexArray*) vertexArrayForSemantic: (GLenum) semantic at: (GLuint) semanticIndex {
	switch (semantic) {
		case kCC3SemanticVertexLocation: return self.vertexLocations;
		case kCC3SemanticVertexNormal: return self.vertexNormals;
		case kCC3SemanticVertexTangent: return self.vertexTangents;
		case kCC3SemanticVertexBitangent: return self.vertexBitangents;
		case kCC3SemanticVertexColor: return self.vertexColors;
		case kCC3SemanticVertexWeights: return self.vertexWeights;
		case kCC3SemanticVertexMatrixIndices: return self.vertexMatrixIndices;
		case kCC3SemanticVertexPointSize: return self.vertexPointSizes;
		case kCC3SemanticVertexTexture: return [self textureCoordinatesForTextureUnit: semanticIndex];
		default: return nil;
	}
}


#pragma mark Vertex management

-(BOOL) shouldInterleaveVertices { return _shouldInterleaveVertices; }

-(void) setShouldInterleaveVertices: (BOOL) shouldInterleave {
	_shouldInterleaveVertices = shouldInterleave;
	if (!_shouldInterleaveVertices)
		LogInfo(@"%@ has been configured to use non-interleaved vertex content. To improve performance, it is recommended that you interleave all vertex content, unless you need to frequently update one type of vertex content without updating the others.", self);
}

-(CC3VertexContent) vertexContentTypes {
	CC3VertexContent vtxContent = kCC3VertexContentNone;
	if (self.hasVertexLocations) vtxContent |= kCC3VertexContentLocation;
	if (self.hasVertexNormals) vtxContent |= kCC3VertexContentNormal;
	if (self.hasVertexTangents) vtxContent |= kCC3VertexContentTangent;
	if (self.hasVertexBitangents) vtxContent |= kCC3VertexContentBitangent;
	if (self.hasVertexColors) vtxContent |= kCC3VertexContentColor;
	if (self.hasVertexTextureCoordinates) vtxContent |= kCC3VertexContentTextureCoordinates;
	if (self.hasVertexWeights) vtxContent |= kCC3VertexContentWeights;
	if (self.hasVertexMatrixIndices) vtxContent |= kCC3VertexContentMatrixIndices;
	if (self.hasVertexPointSizes) vtxContent |= kCC3VertexContentPointSize;
	return vtxContent;
}

-(void) setVertexContentTypes: (CC3VertexContent) vtxContentTypes {
	[self createVertexContent: vtxContentTypes];
	[self updateVertexStride];
}

-(void) createVertexContent: (CC3VertexContent) vtxContentTypes {
	
	// Always create a new vertex locations
	if (!_vertexLocations) self.vertexLocations = [CC3VertexLocations vertexArray];
	
	// Vertex normals
	if (vtxContentTypes & kCC3VertexContentNormal) {
		if (!_vertexNormals) self.vertexNormals = [CC3VertexNormals vertexArray];
	} else {
		self.vertexNormals = nil;
	}
	
	// Vertex tangents
	if (vtxContentTypes & kCC3VertexContentTangent) {
		if (!_vertexTangents) self.vertexTangents = [CC3VertexTangents vertexArray];
	} else {
		self.vertexTangents = nil;
	}
	
	// Vertex bitangents
	if (vtxContentTypes & kCC3VertexContentBitangent) {
		if (!_vertexBitangents) self.vertexBitangents = [CC3VertexTangents vertexArray];
	} else {
		self.vertexBitangents = nil;
	}
	
	// Vertex colors
	if (vtxContentTypes & kCC3VertexContentColor) {
		if (!_vertexColors) {
			CC3VertexColors* vCols = [CC3VertexColors vertexArray];
			vCols.elementType = GL_UNSIGNED_BYTE;
			self.vertexColors = vCols;
		}
	} else {
		self.vertexColors = nil;
	}
	
	// Vertex texture coordinates
	if (vtxContentTypes & kCC3VertexContentTextureCoordinates) {
		if (!_vertexTextureCoordinates) self.vertexTextureCoordinates = [CC3VertexTextureCoordinates vertexArray];
	} else {
		[self removeAllTextureCoordinates];
	}
	
	// Weights
	if (vtxContentTypes & kCC3VertexContentWeights) {
		if (!_vertexWeights) self.vertexWeights = [CC3VertexWeights vertexArray];
	} else {
		self.vertexWeights = nil;
	}
	
	// Matrix indices
	if (vtxContentTypes & kCC3VertexContentMatrixIndices) {
		if (!_vertexMatrixIndices) self.vertexMatrixIndices = [CC3VertexMatrixIndices vertexArray];
	} else {
		self.vertexMatrixIndices = nil;
	}
	
	// Point sizes
	if (vtxContentTypes & kCC3VertexContentPointSize) {
		if (!_vertexPointSizes) self.vertexPointSizes = [CC3VertexPointSizes vertexArray];
	} else {
		self.vertexPointSizes = nil;
	}
	
}

-(GLuint) vertexStride {
	GLuint stride = 0;
	if (_vertexLocations) stride += _vertexLocations.elementLength;
	if (_vertexNormals) stride += _vertexNormals.elementLength;
	if (_vertexTangents) stride += _vertexTangents.elementLength;
	if (_vertexBitangents) stride += _vertexBitangents.elementLength;
	if (_vertexColors) stride += _vertexColors.elementLength;
	if (_vertexMatrixIndices) stride += _vertexMatrixIndices.elementLength;
	if (_vertexWeights) stride += _vertexWeights.elementLength;
	if (_vertexPointSizes) stride += _vertexPointSizes.elementLength;
	if (_vertexTextureCoordinates) stride += _vertexTextureCoordinates.elementLength;
	for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) stride += otc.elementLength;
	return stride;
}

-(void) setVertexStride: (GLuint) vtxStride {
	if ( !_shouldInterleaveVertices ) return;

	_vertexLocations.vertexStride = vtxStride;
	_vertexNormals.vertexStride = vtxStride;
	_vertexTangents.vertexStride = vtxStride;
	_vertexBitangents.vertexStride = vtxStride;
	_vertexColors.vertexStride = vtxStride;
	_vertexMatrixIndices.vertexStride = vtxStride;
	_vertexWeights.vertexStride = vtxStride;
	_vertexPointSizes.vertexStride = vtxStride;
	_vertexTextureCoordinates.vertexStride = vtxStride;
	for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) otc.vertexStride = vtxStride;
}

-(GLuint) updateVertexStride {
	GLuint stride = 0;
	
	if (_vertexLocations) {
		if (_shouldInterleaveVertices) _vertexLocations.elementOffset = stride;
		stride += _vertexLocations.elementLength;
	}
	if (_vertexNormals) {
		if (_shouldInterleaveVertices) _vertexNormals.elementOffset = stride;
		stride += _vertexNormals.elementLength;
	}
	if (_vertexTangents) {
		if (_shouldInterleaveVertices) _vertexTangents.elementOffset = stride;
		stride += _vertexTangents.elementLength;
	}
	if (_vertexBitangents) {
		if (_shouldInterleaveVertices) _vertexBitangents.elementOffset = stride;
		stride += _vertexBitangents.elementLength;
	}
	if (_vertexColors) {
		if (_shouldInterleaveVertices) _vertexColors.elementOffset = stride;
		stride += _vertexColors.elementLength;
	}
	if (_vertexTextureCoordinates) {
		if (_shouldInterleaveVertices) _vertexTextureCoordinates.elementOffset = stride;
		stride += _vertexTextureCoordinates.elementLength;
	}
	for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) {
		if (_shouldInterleaveVertices) otc.elementOffset = stride;
		stride += otc.elementLength;
	}
	if (_vertexWeights) {
		if (_shouldInterleaveVertices) _vertexWeights.elementOffset = stride;
		stride += _vertexWeights.elementLength;
	}
	if (_vertexMatrixIndices) {
		if (_shouldInterleaveVertices) _vertexMatrixIndices.elementOffset = stride;
		stride += _vertexMatrixIndices.elementLength;
	}
	if (_vertexPointSizes) {
		if (_shouldInterleaveVertices) _vertexPointSizes.elementOffset = stride;
		stride += _vertexPointSizes.elementLength;
	}
	
	self.vertexStride = stride;
	return stride;
}

-(GLuint) allocatedVertexCapacity { return _vertexLocations ? _vertexLocations.allocatedVertexCapacity : 0; }

-(void) setAllocatedVertexCapacity: (GLuint) vtxCount {
	if (!_vertexLocations) self.vertexLocations = [CC3VertexLocations vertexArray];
	_vertexLocations.allocatedVertexCapacity = vtxCount;
	if (self.shouldInterleaveVertices) {
		[_vertexNormals interleaveWith: _vertexLocations];
		[_vertexTangents interleaveWith: _vertexLocations];
		[_vertexBitangents interleaveWith: _vertexLocations];
		[_vertexColors interleaveWith: _vertexLocations];
		[_vertexMatrixIndices interleaveWith: _vertexLocations];
		[_vertexWeights interleaveWith: _vertexLocations];
		[_vertexPointSizes interleaveWith: _vertexLocations];
		[_vertexTextureCoordinates interleaveWith: _vertexLocations];
		for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) {
			[otc interleaveWith: _vertexLocations];
		}
	} else {
		_vertexNormals.allocatedVertexCapacity = vtxCount;
		_vertexTangents.allocatedVertexCapacity = vtxCount;
		_vertexBitangents.allocatedVertexCapacity = vtxCount;
		_vertexColors.allocatedVertexCapacity = vtxCount;
		_vertexMatrixIndices.allocatedVertexCapacity = vtxCount;
		_vertexWeights.allocatedVertexCapacity = vtxCount;
		_vertexPointSizes.allocatedVertexCapacity = vtxCount;
		_vertexTextureCoordinates.allocatedVertexCapacity = vtxCount;
		for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) {
			otc.allocatedVertexCapacity = vtxCount;
		}
	}
}

-(BOOL) ensureVertexCapacity: (GLuint) vtxCount {
	GLuint currVtxCap = self.allocatedVertexCapacity;
	if (currVtxCap > 0 && currVtxCap < vtxCount) {
		self.allocatedVertexCapacity = (vtxCount * self.capacityExpansionFactor);
		return (self.allocatedVertexCapacity > currVtxCap);
	}
	return NO;
}

-(BOOL) ensureCapacity: (GLuint) vtxCount { return [self ensureVertexCapacity: vtxCount]; }

-(GLvoid*) interleavedVertices {
	return (_shouldInterleaveVertices && _vertexLocations) ? _vertexLocations.vertices : NULL;
}

-(GLuint) allocatedVertexIndexCapacity { return _vertexIndices ? _vertexIndices.allocatedVertexCapacity : 0; }

-(void) setAllocatedVertexIndexCapacity: (GLuint) vtxCount {
	if ( !_vertexIndices && vtxCount > 0 ) self.vertexIndices = [CC3VertexIndices vertexArray];
	_vertexIndices.allocatedVertexCapacity = vtxCount;
}

-(void) copyVertices: (GLuint) vtxCount from: (GLuint) srcIdx to: (GLuint) dstIdx {
	[_vertexLocations copyVertices: vtxCount from: srcIdx to: dstIdx];
	if ( !_shouldInterleaveVertices ) {
		[_vertexNormals copyVertices: vtxCount from: srcIdx to: dstIdx];
		[_vertexTangents copyVertices: vtxCount from: srcIdx to: dstIdx];
		[_vertexBitangents copyVertices: vtxCount from: srcIdx to: dstIdx];
		[_vertexColors copyVertices: vtxCount from: srcIdx to: dstIdx];
		[_vertexMatrixIndices copyVertices: vtxCount from: srcIdx to: dstIdx];
		[_vertexWeights copyVertices: vtxCount from: srcIdx to: dstIdx];
		[_vertexPointSizes copyVertices: vtxCount from: srcIdx to: dstIdx];
		[_vertexTextureCoordinates copyVertices: vtxCount from: srcIdx to: dstIdx];
		for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) {
			[otc copyVertices: vtxCount from: srcIdx to: dstIdx];
		}
	}
}

-(void) copyVertices: (GLuint) vtxCount
				from: (GLuint) srcIdx
			  inMesh: (CC3Mesh*) srcMesh
				  to: (GLuint) dstIdx {
	// If both meshes have the same interleaved content,
	// the copying can be optimized to a memory copy.
	if ((self.vertexContentTypes == srcMesh.vertexContentTypes) &&
		self.vertexStride == srcMesh.vertexStride &&
		(self.shouldInterleaveVertices && srcMesh.shouldInterleaveVertices)) {
		LogTrace(@"%@ using optimized memory copy from %@ due to identical vertex content.", self, srcMesh);
		[self.vertexLocations copyVertices: vtxCount
							   fromAddress: srcMesh.interleavedVertices
										to: dstIdx];
	} else {
		// Can't optimize, so must default to copying vertex element by vertex element
		LogTrace(@"%@ using vertex-by-vertex copy from %@ due to different vertex content.", self, srcMesh);
		for (GLuint i = 0; i < vtxCount; i++) {
			[self copyVertexAt: (srcIdx + i) from: srcMesh to: (dstIdx + i)];
		}
	}
}

-(void) copyVertexAt: (GLuint) srcIdx from: (CC3Mesh*) srcMesh to: (GLuint) dstIdx {
	if (self.hasVertexLocations) [self setVertexLocation: [srcMesh vertexLocationAt: srcIdx] at: dstIdx];
	if (self.hasVertexNormals) [self setVertexNormal: [srcMesh vertexNormalAt: srcIdx] at: dstIdx];
	if (self.hasVertexTangents) [self setVertexTangent: [srcMesh vertexTangentAt: srcIdx] at: dstIdx];
	if (self.hasVertexBitangents) [self setVertexBitangent: [srcMesh vertexBitangentAt: srcIdx] at: dstIdx];
	if (self.hasVertexColors) [self setVertexColor4F: [srcMesh vertexColor4FAt: srcIdx] at: dstIdx];
	if (self.hasVertexWeights) [self setVertexWeights: [srcMesh vertexWeightsAt: srcIdx] at: dstIdx];
	if (self.hasVertexMatrixIndices) [self setVertexMatrixIndices: [srcMesh vertexMatrixIndicesAt: srcIdx] at: dstIdx];
	if (self.hasVertexPointSizes) [self setVertexPointSize: [srcMesh vertexPointSizeAt: srcIdx] at: dstIdx];
	GLuint tcCount = self.textureCoordinatesArrayCount;
	for (GLuint i = 0; i < tcCount; i++) {
		[self setVertexTexCoord2F: [srcMesh vertexTexCoord2FForTextureUnit: i at: srcIdx] forTextureUnit: i at: dstIdx];
	}
}

-(void) copyVertexIndices: (GLuint) vtxCount from: (GLuint) srcIdx to: (GLuint) dstIdx offsettingBy: (GLint) offset {
	[_vertexIndices copyVertices: vtxCount from: srcIdx to: dstIdx offsettingBy: offset];
}

-(void) copyVertexIndices: (GLuint) vtxCount
					 from: (GLuint) srcIdx
				   inMesh: (CC3Mesh*) srcMesh
					   to: (GLuint) dstIdx
			 offsettingBy: (GLint) offset {
	
	if ( !_vertexIndices ) return;	// If there are no vertex indices, leave
	
	CC3VertexIndices* srcVtxIdxs = srcMesh.vertexIndices;
	if (srcVtxIdxs) {
		// If the template mesh has vertex indices, copy them over and offset them.
		// If both vertex index arrays are of the same type, we can optimize to a fast copy.
		if (srcVtxIdxs.elementType == _vertexIndices.elementType) {
			[_vertexIndices copyVertices: vtxCount
							 fromAddress: [srcVtxIdxs addressOfElement: srcIdx]
									  to: dstIdx
							offsettingBy: offset];
		} else {
			for (GLuint vtxIdx = 0; vtxIdx < vtxCount; vtxIdx++) {
				GLuint srcVtx = [srcVtxIdxs indexAt: (srcIdx + vtxIdx)];
				[_vertexIndices setIndex: (srcVtx + offset) at: (dstIdx + vtxIdx)];
			}
		}
	} else {
		// If the source mesh does NOT have vertex indices, manufacture one for each vertex,
		// simply pointing directly to that vertex, taking the offset into consideration.
		// There will be a 1:1 mapping of indices to vertices.
		for (GLuint vtxIdx = 0; vtxIdx < vtxCount; vtxIdx++) {
			[_vertexIndices setIndex: (offset + vtxIdx) at: (dstIdx + vtxIdx)];
		}
	}
}


#pragma mark Accessing vertex content

-(GLuint) vertexCount { return _vertexLocations ? _vertexLocations.vertexCount : 0; }

-(void) setVertexCount: (GLuint) vCount {
	// If we're attempting to set too many vertices for indexed drawing, log an error, but don't abort.
	if(_vertexIndices && (vCount > (kCC3MaxGLushort + 1))) LogError(@"Setting vertexCount property of %@ to %i vertices. This mesh uses indexed drawing, which is limited by OpenGL ES to %i vertices. Vertices beyond that limit will not be drawn.", self, vCount, (kCC3MaxGLushort + 1));
	
	_vertexLocations.vertexCount = vCount;
	_vertexNormals.vertexCount = vCount;
	_vertexTangents.vertexCount = vCount;
	_vertexBitangents.vertexCount = vCount;
	_vertexColors.vertexCount = vCount;
	_vertexMatrixIndices.vertexCount = vCount;
	_vertexWeights.vertexCount = vCount;
	_vertexPointSizes.vertexCount = vCount;
	_vertexTextureCoordinates.vertexCount = vCount;
	for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) {
		otc.vertexCount = vCount;
	}
}

-(GLuint) vertexIndexCount { return _vertexIndices ? _vertexIndices.vertexCount : self.vertexCount; }

-(void) setVertexIndexCount: (GLuint) vCount { _vertexIndices.vertexCount = vCount; }
-(CC3Vector) vertexLocationAt: (GLuint) index {
	return _vertexLocations ? [_vertexLocations locationAt: index] : kCC3VectorZero;
}

-(void) setVertexLocation: (CC3Vector) aLocation at: (GLuint) index {
	[_vertexLocations setLocation: aLocation at: index];
}

-(CC3Vector4) vertexHomogeneousLocationAt: (GLuint) index {
	return _vertexLocations ? [_vertexLocations homogeneousLocationAt: index] : kCC3Vector4ZeroLocation;
}

-(void) setVertexHomogeneousLocation: (CC3Vector4) aLocation at: (GLuint) index {
	[_vertexLocations setHomogeneousLocation: aLocation at: index];
}

-(CC3Vector) vertexNormalAt: (GLuint) index {
	return _vertexNormals ? [_vertexNormals normalAt: index] : kCC3VectorUnitZPositive;
}

-(void) setVertexNormal: (CC3Vector) aNormal at: (GLuint) index {
	[_vertexNormals setNormal: aNormal at: index];
}

-(CC3Vector) vertexTangentAt: (GLuint) index {
	return _vertexTangents ? [_vertexTangents tangentAt: index] : kCC3VectorUnitXPositive;
}

-(void) setVertexTangent: (CC3Vector) aTangent at: (GLuint) index {
	[_vertexTangents setTangent: aTangent at: index];
}

-(CC3Vector) vertexBitangentAt: (GLuint) index {
	return _vertexBitangents ? [_vertexBitangents tangentAt: index] : kCC3VectorUnitYPositive;
}

-(void) setVertexBitangent: (CC3Vector) aTangent at: (GLuint) index {
	[_vertexBitangents setTangent: aTangent at: index];
}

-(ccColor4F) vertexColor4FAt: (GLuint) index {
	return _vertexColors ? [_vertexColors color4FAt: index] : kCCC4FBlackTransparent;
}

-(void) setVertexColor4F: (ccColor4F) aColor at: (GLuint) index {
	[_vertexColors setColor4F: aColor at: index];
}

-(ccColor4B) vertexColor4BAt: (GLuint) index {
	return _vertexColors ? [_vertexColors color4BAt: index] : (ccColor4B){ 0, 0, 0, 0 };
}

-(void) setVertexColor4B: (ccColor4B) aColor at: (GLuint) index {
	[_vertexColors setColor4B: aColor at: index];
}

-(GLuint) vertexUnitCount { return _vertexWeights ? _vertexWeights.elementSize : 0; }

-(GLfloat) vertexWeightForVertexUnit: (GLuint) vertexUnit at: (GLuint) index {
	return _vertexWeights ? [_vertexWeights weightForVertexUnit: vertexUnit at: index] : 0.0f;
}

-(void) setVertexWeight: (GLfloat) aWeight forVertexUnit: (GLuint) vertexUnit at: (GLuint) index {
	[_vertexWeights setWeight: aWeight forVertexUnit: vertexUnit at: index];
}

-(GLfloat*) vertexWeightsAt: (GLuint) index {
	return _vertexWeights ? [_vertexWeights weightsAt: index] : NULL;
}

-(void) setVertexWeights: (GLfloat*) weights at: (GLuint) index {
	[_vertexWeights setWeights: weights at: index];
}

-(GLuint) vertexMatrixIndexForVertexUnit: (GLuint) vertexUnit at: (GLuint) index {
	return _vertexMatrixIndices ? [_vertexMatrixIndices matrixIndexForVertexUnit: vertexUnit at: index] : 0;
}

-(void) setVertexMatrixIndex: (GLuint) aMatrixIndex forVertexUnit: (GLuint) vertexUnit at: (GLuint) index {
	[_vertexMatrixIndices setMatrixIndex: aMatrixIndex forVertexUnit: vertexUnit at: index];
}

-(GLvoid*) vertexMatrixIndicesAt: (GLuint) index {
	return _vertexMatrixIndices ? [_vertexMatrixIndices matrixIndicesAt: index] : NULL;
}

-(void) setVertexMatrixIndices: (GLvoid*) mtxIndices at: (GLuint) index {
	[_vertexMatrixIndices setMatrixIndices: mtxIndices at: index];
}

-(GLenum) matrixIndexType { return _vertexMatrixIndices.elementType; }

-(GLfloat) vertexPointSizeAt: (GLuint) vtxIndex {
	return _vertexPointSizes ? [_vertexPointSizes pointSizeAt: vtxIndex] : 0.0f;
}

-(void) setVertexPointSize: (GLfloat) aSize at: (GLuint) vtxIndex {
	[_vertexPointSizes setPointSize: aSize at: vtxIndex];
}

-(void) updatePointSizesGLBuffer { [_vertexPointSizes updateGLBuffer]; }

-(ccTex2F) vertexTexCoord2FAt: (GLuint) index {
	return [self vertexTexCoord2FForTextureUnit: 0 at: index];
}

-(void) setVertexTexCoord2F: (ccTex2F) aTex2F at: (GLuint) index {
	[self setVertexTexCoord2F: aTex2F forTextureUnit: 0 at: index];
}

-(ccTex2F) vertexTexCoord2FForTextureUnit: (GLuint) texUnit at: (GLuint) index {
	CC3VertexTextureCoordinates* texCoords = [self textureCoordinatesForTextureUnit: texUnit];
	return texCoords ? [texCoords texCoord2FAt: index] : (ccTex2F){ 0.0, 0.0 };
}

-(void) setVertexTexCoord2F: (ccTex2F) aTex2F forTextureUnit: (GLuint) texUnit at: (GLuint) index {
	CC3VertexTextureCoordinates* texCoords = [self textureCoordinatesForTextureUnit: texUnit];
	[texCoords setTexCoord2F: aTex2F at: index];
}

// Deprecated
-(ccTex2F) vertexTexCoord2FAt: (GLuint) index forTextureUnit: (GLuint) texUnit {
	return [self vertexTexCoord2FForTextureUnit: texUnit at: index];
}

// Deprecated
-(void) setVertexTexCoord2F: (ccTex2F) aTex2F at: (GLuint) index forTextureUnit: (GLuint) texUnit {
	[self setVertexTexCoord2F: aTex2F forTextureUnit: texUnit at: index];
}

-(GLuint) vertexIndexAt: (GLuint) index {
	return _vertexIndices ? [_vertexIndices indexAt: index] : 0;
}

-(void) setVertexIndex: (GLuint) vertexIndex at: (GLuint) index {
	[_vertexIndices setIndex: vertexIndex at: index];
}


#pragma mark Faces

-(CC3FaceArray*) faces {
	if ( !_faces ) {
		NSString* facesName = [NSString stringWithFormat: @"%@-Faces", self.name];
		self.faces = [CC3FaceArray faceArrayWithName: facesName];
	}
	return _faces;
}

-(void) setFaces: (CC3FaceArray*) aFaceArray {
	id old = _faces;
	_faces = [aFaceArray retain];
	[old release];
	_faces.mesh = self;
}

-(BOOL) shouldCacheFaces { return _faces ? _faces.shouldCacheFaces : NO; }

-(void) setShouldCacheFaces: (BOOL) shouldCache { self.faces.shouldCacheFaces = shouldCache; }

-(GLuint) faceCount {
	if (_vertexIndices) return _vertexIndices.faceCount;
	if (_vertexLocations) return _vertexLocations.faceCount;
	return 0;
}

-(CC3Face) faceFromIndices: (CC3FaceIndices) faceIndices {
	return _vertexLocations ? [_vertexLocations faceFromIndices: faceIndices] : kCC3FaceZero;
}

-(CC3FaceIndices) uncachedFaceIndicesAt: (GLuint) faceIndex {
	if (_vertexIndices) return [_vertexIndices faceIndicesAt: faceIndex];
	if (_vertexLocations) return [_vertexLocations faceIndicesAt: faceIndex];
	CC3Assert(NO, @"%@ has no drawable vertex array and cannot retrieve indices for a face.", self);
	return kCC3FaceIndicesZero;
}

-(GLuint) faceCountFromVertexIndexCount: (GLuint) vc {
	if (_vertexIndices) return [_vertexIndices faceCountFromVertexIndexCount: vc];
	if (_vertexLocations) return [_vertexLocations faceCountFromVertexIndexCount: vc];
	CC3Assert(NO, @"%@ has no drawable vertex array and cannot convert vertex count to face count.", self);
	return 0;
}

-(GLuint) vertexIndexCountFromFaceCount: (GLuint) fc {
	if (_vertexIndices) return [_vertexIndices vertexIndexCountFromFaceCount: fc];
	if (_vertexLocations) return [_vertexLocations vertexIndexCountFromFaceCount: fc];
	CC3Assert(NO, @"%@ has no drawable vertex array and cannot convert face count to vertex count.", self);
	return 0;
}

// Deprecated
-(GLuint) faceCountFromVertexCount: (GLuint) vc { return [self faceCountFromVertexIndexCount: vc]; }
-(GLuint) vertexCountFromFaceCount: (GLuint) fc { return [self vertexIndexCountFromFaceCount: fc]; }

-(CC3Face) faceAt: (GLuint) faceIndex {
	return [self faceFromIndices: [self faceIndicesAt: faceIndex]];
}

-(CC3FaceIndices) faceIndicesAt: (GLuint) faceIndex { return [self.faces indicesAt: faceIndex]; }

-(CC3Vector) faceCenterAt: (GLuint) faceIndex { return [self.faces centerAt: faceIndex]; }

-(CC3Vector) faceNormalAt: (GLuint) faceIndex { return [self.faces normalAt: faceIndex]; }

-(CC3Plane) facePlaneAt: (GLuint) faceIndex { return [self.faces planeAt: faceIndex]; }

-(CC3FaceNeighbours) faceNeighboursAt: (GLuint) faceIndex { return [self.faces neighboursAt: faceIndex]; }

-(GLuint) findFirst: (GLuint) maxHitCount
	  intersections: (CC3MeshIntersection*) intersections
		 ofLocalRay: (CC3Ray) aRay
	acceptBackFaces: (BOOL) acceptBackFaces
	acceptBehindRay: (BOOL) acceptBehind {
	
	GLuint hitIdx = 0;
	GLuint faceCount = self.faceCount;
	for (int faceIdx = 0; faceIdx < faceCount && hitIdx < maxHitCount; faceIdx++) {
		CC3MeshIntersection* hit = &intersections[hitIdx];
		hit->faceIndex = faceIdx;
		hit->face = [self faceAt: faceIdx];
		hit->facePlane = CC3FacePlane(hit->face);
		
		// Check if the ray is not parallel to the face, is approaching from the front,
		// or is approaching from the back and that is okay.
		GLfloat dirDotNorm = CC3VectorDot(aRay.direction, CC3PlaneNormal(hit->facePlane));
		hit->wasBackFace = dirDotNorm > 0.0f;
		if (dirDotNorm < 0.0f || (hit->wasBackFace && acceptBackFaces)) {
			
			// Find the point of intersection of the ray with the plane
			// and check that it is not behind the start of the ray.
			CC3Vector4 loc4 = CC3RayIntersectionWithPlane(aRay, hit->facePlane);
			if (acceptBehind || loc4.w >= 0.0f) {
				hit->location = CC3VectorFromTruncatedCC3Vector4(loc4);
				hit->distance = loc4.w;
				hit->barycentricLocation = CC3FaceBarycentricWeights(hit->face, hit->location);
				if ( CC3BarycentricWeightsAreInsideTriangle(hit->barycentricLocation) ) hitIdx++;
			}
		}
	}
	return hitIdx;
}


#pragma mark Buffering content to GL engine

/**
 * If the interleavesVertices property is set to NO, creates GL vertex buffer objects for all
 * vertex arrays used by this mesh by invoking createGLBuffer on each contained vertex array.
 *
 * If the shouldInterleaveVertices property is set to YES, indicating that the underlying data is
 * shared across the contained vertex arrays, this method invokes createGLBuffer only on the
 * vertexLocations and vertexIndices vertex arrays, and copies the bufferID property from
 * the vertexLocations vertex array to the other vertex arrays (except vertexIndicies).
 */
-(void) createGLBuffers {
	[_vertexLocations createGLBuffer];
	if (_shouldInterleaveVertices) {
		GLuint commonBufferId = _vertexLocations.bufferID;
		_vertexNormals.bufferID = commonBufferId;
		_vertexTangents.bufferID = commonBufferId;
		_vertexBitangents.bufferID = commonBufferId;
		_vertexColors.bufferID = commonBufferId;
		_vertexMatrixIndices.bufferID = commonBufferId;
		_vertexWeights.bufferID = commonBufferId;
		_vertexPointSizes.bufferID = _vertexLocations.bufferID;
		_vertexTextureCoordinates.bufferID = commonBufferId;
		for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) otc.bufferID = commonBufferId;
	} else {
		[_vertexNormals createGLBuffer];
		[_vertexTangents createGLBuffer];
		[_vertexBitangents createGLBuffer];
		[_vertexColors createGLBuffer];
		[_vertexMatrixIndices createGLBuffer];
		[_vertexWeights createGLBuffer];
		[_vertexPointSizes createGLBuffer];
		[_vertexTextureCoordinates createGLBuffer];
		for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) [otc createGLBuffer];
	}
	[_vertexIndices createGLBuffer];
}

-(void) deleteGLBuffers {
	[_vertexLocations deleteGLBuffer];
	[_vertexNormals deleteGLBuffer];
	[_vertexTangents deleteGLBuffer];
	[_vertexBitangents deleteGLBuffer];
	[_vertexColors deleteGLBuffer];
	[_vertexMatrixIndices deleteGLBuffer];
	[_vertexWeights deleteGLBuffer];
	[_vertexPointSizes deleteGLBuffer];
	[_vertexTextureCoordinates deleteGLBuffer];
	for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) [otc deleteGLBuffer];
	[_vertexIndices deleteGLBuffer];
}

-(BOOL) isUsingGLBuffers {
	if (_vertexLocations && _vertexLocations.isUsingGLBuffer) return YES;
	if (_vertexNormals && _vertexNormals.isUsingGLBuffer) return YES;
	if (_vertexTangents && _vertexTangents.isUsingGLBuffer) return YES;
	if (_vertexBitangents && _vertexBitangents.isUsingGLBuffer) return YES;
	if (_vertexColors && _vertexColors.isUsingGLBuffer) return YES;
	if (_vertexMatrixIndices && _vertexMatrixIndices.isUsingGLBuffer) return YES;
	if (_vertexWeights && _vertexWeights.isUsingGLBuffer) return YES;
	if (_vertexPointSizes && _vertexPointSizes.isUsingGLBuffer) return YES;
	if (_vertexTextureCoordinates && _vertexTextureCoordinates.isUsingGLBuffer) return YES;
	for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) if (otc.isUsingGLBuffer) return YES;
	return NO;
}

-(void) releaseRedundantContent {
	[_vertexLocations releaseRedundantContent];
	[_vertexNormals releaseRedundantContent];
	[_vertexTangents releaseRedundantContent];
	[_vertexBitangents releaseRedundantContent];
	[_vertexColors releaseRedundantContent];
	[_vertexMatrixIndices releaseRedundantContent];
	[_vertexWeights releaseRedundantContent];
	[_vertexPointSizes releaseRedundantContent];
	[_vertexTextureCoordinates releaseRedundantContent];
	for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) [otc releaseRedundantContent];
	[_vertexIndices releaseRedundantContent];
}

// Deprecated
-(void) releaseRedundantData { [self releaseRedundantContent]; }

-(void) retainVertexContent {
	[self retainVertexLocations];
	[self retainVertexNormals];
	[self retainVertexTangents];
	[self retainVertexBitangents];
	[self retainVertexColors];
	[self retainVertexMatrixIndices];
	[self retainVertexWeights];
	[self retainVertexPointSizes];
	[self retainVertexTextureCoordinates];
}

-(void) retainVertexLocations { _vertexLocations.shouldReleaseRedundantContent = NO; }

-(void) retainVertexNormals {
	if ( !self.hasVertexNormals ) return;
	
	if (_shouldInterleaveVertices) [self retainVertexLocations];
	_vertexNormals.shouldReleaseRedundantContent = NO;
}

-(void) retainVertexTangents {
	if ( !self.hasVertexTangents ) return;
	
	if (_shouldInterleaveVertices) [self retainVertexLocations];
	_vertexTangents.shouldReleaseRedundantContent = NO;
}

-(void) retainVertexBitangents {
	if ( !self.hasVertexBitangents ) return;
	
	if (_shouldInterleaveVertices) [self retainVertexLocations];
	_vertexBitangents.shouldReleaseRedundantContent = NO;
}

-(void) retainVertexColors {
	if ( !self.hasVertexColors ) return;
	
	if (_shouldInterleaveVertices) [self retainVertexLocations];
	_vertexColors.shouldReleaseRedundantContent = NO;
}

-(void) retainVertexMatrixIndices {
	if ( !self.hasVertexMatrixIndices ) return;
	
	if (_shouldInterleaveVertices) [self retainVertexLocations];
	_vertexMatrixIndices.shouldReleaseRedundantContent = NO;
}

-(void) retainVertexWeights {
	if ( !self.hasVertexWeights ) return;
	
	if (_shouldInterleaveVertices) [self retainVertexLocations];
	_vertexWeights.shouldReleaseRedundantContent = NO;
}

-(void) retainVertexPointSizes {
	if ( !self.hasVertexPointSizes ) return;
	
	if (_shouldInterleaveVertices) [self retainVertexLocations];
	_vertexPointSizes.shouldReleaseRedundantContent = NO;
}

-(void) retainVertexTextureCoordinates {
	if ( !self.hasVertexTextureCoordinates ) return;
	
	if (_shouldInterleaveVertices) [self retainVertexLocations];
	_vertexTextureCoordinates.shouldReleaseRedundantContent = NO;
	for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates)
		otc.shouldReleaseRedundantContent = NO;
}

-(void) retainVertexIndices { _vertexIndices.shouldReleaseRedundantContent = NO; }

-(void) doNotBufferVertexContent {
	[self doNotBufferVertexLocations];
	[self doNotBufferVertexNormals];
	[self doNotBufferVertexTangents];
	[self doNotBufferVertexBitangents];
	[self doNotBufferVertexColors];
	[self doNotBufferVertexMatrixIndices];
	[self doNotBufferVertexWeights];
	[self doNotBufferVertexPointSizes];
	[self doNotBufferVertexTextureCoordinates];
}

-(void) doNotBufferVertexLocations { _vertexLocations.shouldAllowVertexBuffering = NO; }

-(void) doNotBufferVertexNormals {
	if (_shouldInterleaveVertices) [self doNotBufferVertexLocations];
	_vertexNormals.shouldAllowVertexBuffering = NO;
}

-(void) doNotBufferVertexTangents {
	if (_shouldInterleaveVertices) [self doNotBufferVertexLocations];
	_vertexTangents.shouldAllowVertexBuffering = NO;
}

-(void) doNotBufferVertexBitangents {
	if (_shouldInterleaveVertices) [self doNotBufferVertexLocations];
	_vertexBitangents.shouldAllowVertexBuffering = NO;
}

-(void) doNotBufferVertexColors {
	if (_shouldInterleaveVertices) [self doNotBufferVertexLocations];
	_vertexColors.shouldAllowVertexBuffering = NO;
}

-(void) doNotBufferVertexMatrixIndices {
	if (_shouldInterleaveVertices) [self doNotBufferVertexLocations];
	_vertexMatrixIndices.shouldAllowVertexBuffering = NO;
}

-(void) doNotBufferVertexWeights {
	if (_shouldInterleaveVertices) [self doNotBufferVertexLocations];
	_vertexWeights.shouldAllowVertexBuffering = NO;
}

-(void) doNotBufferVertexPointSizes {
	if (_shouldInterleaveVertices) [self doNotBufferVertexLocations];
	_vertexPointSizes.shouldAllowVertexBuffering = NO;
}

-(void) doNotBufferVertexTextureCoordinates {
	if (_shouldInterleaveVertices) [self doNotBufferVertexLocations];
	_vertexTextureCoordinates.shouldAllowVertexBuffering = NO;
	for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) {
		otc.shouldAllowVertexBuffering = NO;
	}
}

-(void) doNotBufferVertexIndices { _vertexIndices.shouldAllowVertexBuffering = NO; }


#pragma mark Updating

-(void) updateGLBuffersStartingAt: (GLuint) offsetIndex forLength: (GLuint) vertexCount {
	[_vertexLocations updateGLBufferStartingAt: offsetIndex forLength: vertexCount];
	if ( !_shouldInterleaveVertices ) {
		[_vertexNormals updateGLBufferStartingAt: offsetIndex forLength: vertexCount];
		[_vertexTangents updateGLBufferStartingAt: offsetIndex forLength: vertexCount];
		[_vertexBitangents updateGLBufferStartingAt: offsetIndex forLength: vertexCount];
		[_vertexColors updateGLBufferStartingAt: offsetIndex forLength: vertexCount];
		[_vertexMatrixIndices updateGLBufferStartingAt: offsetIndex forLength: vertexCount];
		[_vertexWeights updateGLBufferStartingAt: offsetIndex forLength: vertexCount];
		[_vertexPointSizes updateGLBufferStartingAt: offsetIndex forLength: vertexCount];
		[_vertexTextureCoordinates updateGLBufferStartingAt: offsetIndex forLength: vertexCount];
		for (CC3VertexTextureCoordinates* otc in _overlayTextureCoordinates) {
			[otc updateGLBufferStartingAt: offsetIndex forLength: vertexCount];
		}
	}
}

-(void) updateGLBuffers { [self updateGLBuffersStartingAt: 0 forLength: self.vertexCount]; }

-(void) updateVertexLocationsGLBuffer { [_vertexLocations updateGLBuffer]; }

-(void) updateVertexNormalsGLBuffer { [_vertexNormals updateGLBuffer]; }

-(void) updateVertexTangentsGLBuffer { [_vertexTangents updateGLBuffer]; }

-(void) updateVertexBitangentsGLBuffer { [_vertexBitangents updateGLBuffer]; }

-(void) updateVertexColorsGLBuffer { [_vertexColors updateGLBuffer]; }

-(void) updateVertexWeightsGLBuffer { [_vertexWeights updateGLBuffer]; }

-(void) updateVertexMatrixIndicesGLBuffer { [_vertexMatrixIndices updateGLBuffer]; }

-(void) updateVertexTextureCoordinatesGLBuffer {
	[self updateVertexTextureCoordinatesGLBufferForTextureUnit: 0];
}

-(void) updateVertexTextureCoordinatesGLBufferForTextureUnit: (GLuint) texUnit {
	[[self textureCoordinatesForTextureUnit: texUnit] updateGLBuffer];
}

-(void) updateVertexIndicesGLBuffer { [_vertexIndices updateGLBuffer]; }


#pragma mark Mesh Geometry

-(CC3Vector) centerOfGeometry { return _vertexLocations ? _vertexLocations.centerOfGeometry : kCC3VectorZero; }

-(CC3BoundingBox) boundingBox { return _vertexLocations ? _vertexLocations.boundingBox : kCC3BoundingBoxNull; }

-(GLfloat) radius { return _vertexLocations ? _vertexLocations.radius : 0.0; }

-(void) moveMeshOriginTo: (CC3Vector) aLocation { [_vertexLocations moveMeshOriginTo: aLocation]; }

-(void) moveMeshOriginToCenterOfGeometry { [_vertexLocations moveMeshOriginToCenterOfGeometry]; }

// Deprecated methods
-(void) movePivotTo: (CC3Vector) aLocation { [self moveMeshOriginTo: aLocation]; }
-(void) movePivotToCenterOfGeometry { [self moveMeshOriginToCenterOfGeometry]; }


#pragma mark CCRGBAProtocol support

-(ccColor3B) color { return _vertexColors ? _vertexColors.color : ccBLACK; }

-(void) setColor: (ccColor3B) aColor { _vertexColors.color = aColor; }

-(GLubyte) opacity { return _vertexColors ? _vertexColors.opacity : 0; }

-(void) setOpacity: (GLubyte) opacity { _vertexColors.opacity = opacity; }


#pragma mark Textures

-(BOOL) expectsVerticallyFlippedTextures {
	GLuint tcCount = self.textureCoordinatesArrayCount;
	for (GLuint texUnit = 0; texUnit < tcCount; texUnit++)
		if ( [self expectsVerticallyFlippedTextureInTextureUnit: texUnit] ) return YES;
	return NO;
}

-(void) setExpectsVerticallyFlippedTextures: (BOOL) expectsFlipped {
	GLuint tcCount = self.textureCoordinatesArrayCount;
	for (GLuint texUnit = 0; texUnit < tcCount; texUnit++)
		[self expectsVerticallyFlippedTexture: expectsFlipped inTextureUnit: texUnit];
}

-(BOOL) expectsVerticallyFlippedTextureInTextureUnit: (GLuint) texUnit {
	return [self textureCoordinatesForTextureUnit: texUnit].expectsVerticallyFlippedTextures;
}

-(void) expectsVerticallyFlippedTexture: (BOOL) expectsFlipped inTextureUnit: (GLuint) texUnit {
	[self textureCoordinatesForTextureUnit: texUnit].expectsVerticallyFlippedTextures = expectsFlipped;
}

-(void) alignTextureUnit: (GLuint) texUnit withTexture: (CC3Texture*) aTexture {
	[[self textureCoordinatesForTextureUnit: texUnit] alignWithTexture: aTexture];
}

// Deprecated - delegate to protected method so it can be invoked from other deprecated library methods.
-(void) alignWithTexturesIn: (CC3Material*) aMaterial {
	[self deprecatedAlignWithTexturesIn: aMaterial];
}

// Deprecated
-(void) deprecatedAlignWithTexturesIn: (CC3Material*) aMaterial {
	GLuint tcCount = self.textureCoordinatesArrayCount;
	for (GLuint texUnit = 0; texUnit < tcCount; texUnit++) {
		CC3Texture* tex = [aMaterial textureForTextureUnit: texUnit];
		[[self textureCoordinatesForTextureUnit: texUnit] alignWithTexture: tex];
	}
}

// Deprecated - delegate to protected method so it can be invoked from other deprecated library methods.
-(void) alignWithInvertedTexturesIn: (CC3Material*) aMaterial {
	[self deprecatedAlignWithInvertedTexturesIn: aMaterial];
}
// Deprecated - invert or not depends on subclass.
-(void) deprecatedAlignWithInvertedTexturesIn: (CC3Material*) aMaterial {
	GLuint tcCount = self.textureCoordinatesArrayCount;
	for (GLuint texUnit = 0; texUnit < tcCount; texUnit++) {
		CC3Texture* tex = [aMaterial textureForTextureUnit: texUnit];
		[self deprecatedAlign: [self textureCoordinatesForTextureUnit: texUnit] withInvertedTexture: tex];
	}
}

// Deprecated texture inversion template method. Inversion is now automatic.
-(void) deprecatedAlign: (CC3VertexTextureCoordinates*) texCoords
	withInvertedTexture: (CC3Texture*) aTexture {
	[texCoords alignWithTexture: aTexture];
}

-(void) flipVerticallyTextureUnit: (GLuint) texUnit {
	[[self textureCoordinatesForTextureUnit: texUnit] flipVertically];
}

-(void) flipTexturesVertically {
	GLuint tcCount = self.textureCoordinatesArrayCount;
	for (GLuint texUnit = 0; texUnit < tcCount; texUnit++)
		[[self textureCoordinatesForTextureUnit: texUnit] flipVertically];
}

-(void) flipHorizontallyTextureUnit: (GLuint) texUnit {
	[[self textureCoordinatesForTextureUnit: texUnit] flipHorizontally];
}

-(void) flipTexturesHorizontally {
	GLuint tcCount = self.textureCoordinatesArrayCount;
	for (GLuint texUnit = 0; texUnit < tcCount; texUnit++)
		[[self textureCoordinatesForTextureUnit: texUnit] flipHorizontally];
}

-(void) repeatTexture: (ccTex2F) repeatFactor forTextureUnit: (GLuint) texUnit {
	[[self textureCoordinatesForTextureUnit: texUnit] repeatTexture: repeatFactor];
}

-(void) repeatTexture: (ccTex2F) repeatFactor {
	GLuint tcCount = self.textureCoordinatesArrayCount;
	for (GLuint texUnit = 0; texUnit < tcCount; texUnit++)
		[[self textureCoordinatesForTextureUnit: texUnit] repeatTexture: repeatFactor];
}

-(CGRect) textureRectangleForTextureUnit: (GLuint) texUnit {
	CC3VertexTextureCoordinates* texCoords = [self textureCoordinatesForTextureUnit: texUnit];
	return texCoords ? texCoords.textureRectangle : kCC3UnitTextureRectangle;
}

-(void) setTextureRectangle: (CGRect) aRect forTextureUnit: (GLuint) texUnit {
	[self textureCoordinatesForTextureUnit: texUnit].textureRectangle = aRect;
}

-(CGRect) textureRectangle { return [self textureRectangleForTextureUnit: 0]; }

-(void) setTextureRectangle: (CGRect) aRect {
	GLuint tcCount = self.textureCoordinatesArrayCount;
	for (GLuint i = 0; i < tcCount; i++)
		[self textureCoordinatesForTextureUnit: i].textureRectangle = aRect;
}


#pragma mark Drawing

-(GLenum) drawingMode {
	if (_vertexIndices) return _vertexIndices.drawingMode;
	if (_vertexLocations) return _vertexLocations.drawingMode;
	return super.drawingMode;
}

-(void) setDrawingMode: (GLenum) aMode {
	_vertexIndices.drawingMode = aMode;
	_vertexLocations.drawingMode = aMode;
}

-(void) drawWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	[self bindWithVisitor: visitor];
	[self drawVerticesWithVisitor: visitor];
}

-(void) drawFrom: (GLuint) vertexIndex
		forCount: (GLuint) vertexCount
	 withVisitor: (CC3NodeDrawingVisitor*) visitor {
	[self bindWithVisitor: visitor];
	[self drawVerticesFrom: vertexIndex forCount: vertexCount withVisitor: visitor];
}

-(void) bindWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	if (self.switchingMesh)
		[visitor.gl bindMesh: self withVisitor: visitor];
	else
		LogTrace(@"Reusing currently bound %@", self);
}

/**
 * Populates any shader program uniform variables that have draw scope,
 * and then draws the mesh vertices to the GL engine.
 *
 * If the vertexIndices property is not nil, the draw method is invoked on that
 * CC3VertexIndices instance. Otherwise, the draw method is invoked on the
 * CC3VertexLocations instance in the vertexLocations property.
 */
-(void) drawVerticesWithVisitor: (CC3NodeDrawingVisitor*) visitor {
	LogTrace(@"Drawing %@", self);

	[visitor.currentShaderProgram populateDrawScopeUniformsWithVisitor: visitor];
	
	if (_vertexIndices) {
		[_vertexIndices drawWithVisitor: visitor];
	} else {
		[_vertexLocations drawWithVisitor: visitor];
	}
}

/**
 * Populates any shader program uniform variables that have draw scope,
 * and then draws the specified range of mesh vertices to the GL engine.
 *
 * If the vertexIndices property is not nil, the draw method is invoked on that
 * CC3VertexIndices instance. Otherwise, the draw method is invoked on the
 * CC3VertexLocations instance in the vertexLocations property.
 */
-(void) drawVerticesFrom: (GLuint) vertexIndex
				forCount: (GLuint) vertexCount
			 withVisitor: (CC3NodeDrawingVisitor*) visitor {
	LogTrace(@"Drawing %@ from %u for %u vertices", self, vertexIndex, vertexCount);

	[visitor.currentShaderProgram populateDrawScopeUniformsWithVisitor: visitor];

	if (_vertexIndices) {
		[_vertexIndices drawFrom: vertexIndex forCount: vertexCount withVisitor: visitor];
	} else {
		[_vertexLocations drawFrom: vertexIndex forCount: vertexCount withVisitor: visitor];
	}
}

/**
 * Returns a bounding volume that first checks against the spherical boundary, and then checks
 * against a bounding box. The spherical boundary is fast to check, but is not as accurate as
 * the bounding box for many meshes. The bounding box is more accurate, but is more expensive
 * to check than the spherical boundary. The bounding box is only checked if the spherical
 * boundary does not indicate that the mesh is outside the frustum.
 */
-(CC3NodeBoundingVolume*) defaultBoundingVolume { return [CC3NodeSphereThenBoxBoundingVolume boundingVolume]; }

// The tag of the mesh that was most recently drawn to the GL engine.
// The GL engine is only updated when a mesh with a different tag is presented.
// This allows for optimization by ordering the drawing of objects so that objects with
// the same mesh are drawn together, to minimize context switching within the GL engine.
static GLuint currentMeshTag = 0;

/**
 * Returns whether this mesh is different than the mesh that was most recently
 * drawn to the GL engine. To improve performance, meshes are only bound if they need to be.
 *
 * If appropriate, the application can arrange CC3MeshNodes in the CC3Scene so that nodes
 * using the same mesh are drawn together, to minimize the number of mesh binding
 * changes in the GL engine.
 *
 * This method is invoked automatically by the draw method to test whether this mesh needs
 * to be bound to the GL engine before drawing.
 */
-(BOOL) switchingMesh {
	BOOL shouldSwitch = currentMeshTag != _tag;
	currentMeshTag = _tag;		// Set anyway - either it changes or it doesn't.
	return shouldSwitch;
}

+(void) resetSwitching { currentMeshTag = 0; }


#pragma mark Allocation and initialization

-(id) initWithTag: (GLuint) aTag withName: (NSString*) aName {
	if ( (self = [super initWithTag: aTag withName: aName]) ) {
		_faces = nil;
		_shouldInterleaveVertices = YES;
		_vertexLocations = nil;
		_vertexNormals = nil;
		_vertexTangents = nil;
		_vertexBitangents = nil;
		_vertexColors = nil;
		_vertexMatrixIndices = nil;
		_vertexWeights = nil;
		_vertexPointSizes = nil;
		_vertexTextureCoordinates = nil;
		_overlayTextureCoordinates = nil;
		_vertexIndices = nil;
		_capacityExpansionFactor = 1.25;
	}
	return self;
}

// Protected properties for copying
-(CCArray*) overlayTextureCoordinates { return _overlayTextureCoordinates; }

-(void) populateFrom: (CC3Mesh*) another {
	[super populateFrom: another];
	
	self.faces = another.faces;											// retained but not copied
	
	// Share vertex arrays between copies
	self.vertexLocations = another.vertexLocations;						// retained but not copied
	self.vertexNormals = another.vertexNormals;							// retained but not copied
	self.vertexTangents = another.vertexTangents;						// retained but not copied
	self.vertexBitangents = another.vertexBitangents;					// retained but not copied
	self.vertexColors = another.vertexColors;							// retained but not copied
	self.vertexMatrixIndices = another.vertexMatrixIndices;				// retained but not copied
	self.vertexWeights = another.vertexWeights;							// retained but not copied
	self.vertexPointSizes = another.vertexPointSizes;					// retained but not copied
	self.vertexTextureCoordinates = another.vertexTextureCoordinates;	// retained but not copied
	
	// Remove any existing overlay textures and add the overlay textures from the other vertex array.
	[_overlayTextureCoordinates removeAllObjects];
	CCArray* otherOTCs = another.overlayTextureCoordinates;
	if (otherOTCs)
		for (CC3VertexTextureCoordinates* otc in otherOTCs)
			[self addTextureCoordinates: [otc autoreleasedCopy]];		// retained by collection
	
	self.vertexIndices = another.vertexIndices;							// retained but not copied
	_shouldInterleaveVertices = another.shouldInterleaveVertices;
	_capacityExpansionFactor = another.capacityExpansionFactor;
}

+(id) mesh { return [[[self alloc] init] autorelease]; }

+(id) meshWithTag: (GLuint) aTag { return [[[self alloc] initWithTag: aTag] autorelease]; }

+(id) meshWithName: (NSString*) aName { return [[[self alloc] initWithName: aName] autorelease]; }

+(id) meshWithTag: (GLuint) aTag withName: (NSString*) aName {
	return [[[self alloc] initWithTag: aTag withName: aName] autorelease];
}


#pragma mark Tag allocation

// Class variable tracking the most recent tag value assigned for CC3Meshs.
// This class variable is automatically incremented whenever the method nextTag is called.
static GLuint lastAssignedMeshTag;

-(GLuint) nextTag { return ++lastAssignedMeshTag; }

+(void) resetTagAllocation { lastAssignedMeshTag = 0; }

@end


#pragma mark -
#pragma mark CC3FaceArray

@implementation CC3FaceArray

@synthesize mesh, shouldCacheFaces;

-(void) dealloc {
	mesh = nil;					// not retained
	[self deallocateIndices];
	[self deallocateCenters];
	[self deallocateNormals];
	[self deallocatePlanes];
	[self deallocateNeighbours];
	[super dealloc];
}

/**
 * Clears all caches so that they will be lazily initialized
 * on next access using the new mesh data.
 */
-(void) setMesh: (CC3Mesh*) aMesh {
	mesh = aMesh;		// not retained
	[self deallocateIndices];
	[self deallocateCenters];
	[self deallocateNormals];
	[self deallocatePlanes];
	[self deallocateNeighbours];
}

/** If turning off, clears all caches except neighbours. */
-(void) setShouldCacheFaces: (BOOL) shouldCache {
	shouldCacheFaces = shouldCache;
	if (!shouldCacheFaces) {
		[self deallocateIndices];
		[self deallocateCenters];
		[self deallocateNormals];
		[self deallocatePlanes];
	}
}

-(GLuint) faceCount { return mesh ? mesh.faceCount : 0;}

-(CC3Face) faceAt: (GLuint) faceIndex { return mesh ? [mesh faceAt: faceIndex] : kCC3FaceZero; }


#pragma mark Allocation and initialization

-(id) initWithTag: (GLuint) aTag withName: (NSString*) aName {
	if ( (self = [super initWithTag: aTag withName: aName]) ) {
		mesh = nil;
		shouldCacheFaces = NO;
		indices = NULL;
		indicesAreRetained = NO;
		indicesAreDirty = YES;
		centers = NULL;
		centersAreRetained = NO;
		centersAreDirty = YES;
		normals = NULL;
		normalsAreRetained = NO;
		normalsAreDirty = YES;
		planes = NULL;
		planesAreRetained = NO;
		planesAreDirty = YES;
		neighbours = NULL;
		neighboursAreRetained = NO;
		neighboursAreDirty = YES;
	}
	return self;
}

+(id) faceArray { return [[[self alloc] init] autorelease]; }

+(id) faceArrayWithTag: (GLuint) aTag { return [[[self alloc] initWithTag: aTag] autorelease]; }

+(id) faceArrayWithName: (NSString*) aName { return [[[self alloc] initWithName: aName] autorelease]; }

+(id) faceArrayWithTag: (GLuint) aTag withName: (NSString*) aName {
	return [[[self alloc] initWithTag: aTag withName: aName] autorelease];
}

// Phantom properties used during copying
-(BOOL) indicesAreRetained { return indicesAreRetained; }
-(BOOL) centersAreRetained { return centersAreRetained; }
-(BOOL) normalsAreRetained { return normalsAreRetained; }
-(BOOL) planesAreRetained { return planesAreRetained; }
-(BOOL) neighboursAreRetained { return neighboursAreRetained; }

-(BOOL) indicesAreDirty { return indicesAreDirty; }
-(BOOL) centersAreDirty { return centersAreDirty; }
-(BOOL) normalsAreDirty { return normalsAreDirty; }
-(BOOL) planesAreDirty { return planesAreDirty; }
-(BOOL) neighboursAreDirty { return neighboursAreDirty; }


// Template method that populates this instance from the specified other instance.
// This method is invoked automatically during object copying via the copyWithZone: method.
-(void) populateFrom: (CC3FaceArray*) another {
	[super populateFrom: another];
	
	mesh = another.mesh;		// not retained
	
	shouldCacheFaces = another.shouldCacheFaces;
	
	// If indices should be retained, allocate memory and copy the data over.
	[self deallocateIndices];
	if (another.indicesAreRetained) {
		[self allocateIndices];
		memcpy(indices, another.indices, (self.faceCount * sizeof(CC3FaceIndices)));
	} else {
		indices = another.indices;
	}
	indicesAreDirty = another.indicesAreDirty;
	
	// If centers should be retained, allocate memory and copy the data over.
	[self deallocateCenters];
	if (another.centersAreRetained) {
		[self allocateCenters];
		memcpy(centers, another.centers, (self.faceCount * sizeof(CC3Vector)));
	} else {
		centers = another.centers;
	}
	centersAreDirty = another.centersAreDirty;
	
	// If normals should be retained, allocate memory and copy the data over.
	[self deallocateNormals];
	if (another.normalsAreRetained) {
		[self allocateNormals];
		memcpy(normals, another.normals, (self.faceCount * sizeof(CC3Vector)));
	} else {
		normals = another.normals;
	}
	normalsAreDirty = another.normalsAreDirty;
	
	// If planes should be retained, allocate memory and copy the data over.
	[self deallocatePlanes];
	if (another.planesAreRetained) {
		[self allocatePlanes];
		memcpy(planes, another.planes, (self.faceCount * sizeof(CC3Plane)));
	} else {
		planes = another.planes;
	}
	planesAreDirty = another.planesAreDirty;
	
	// If neighbours should be retained, allocate memory and copy the data over.
	[self deallocateNeighbours];
	if (another.neighboursAreRetained) {
		[self allocateNeighbours];
		memcpy(neighbours, another.neighbours, (self.faceCount * sizeof(CC3FaceNeighbours)));
	} else {
		neighbours = another.neighbours;
	}
	neighboursAreDirty = another.neighboursAreDirty;
}


#pragma mark Indices

-(CC3FaceIndices*) indices {
	if (indicesAreDirty || !indices) {
		[self populateIndices];
	}
	return indices;
}

-(void) setIndices: (CC3FaceIndices*) faceIndices {
	[self deallocateIndices];			// Safely disposes existing vertices
	indices = faceIndices;
}

-(CC3FaceIndices) uncachedIndicesAt: (GLuint) faceIndex {
	return [mesh uncachedFaceIndicesAt: faceIndex];
}

-(CC3FaceIndices) indicesAt: (GLuint) faceIndex {
	if (shouldCacheFaces) return self.indices[faceIndex];
	return [self uncachedIndicesAt: faceIndex];
}

-(CC3FaceIndices*) allocateIndices {
	[self deallocateIndices];
	GLuint faceCount = self.faceCount;
	if (faceCount) {
		indices = calloc(faceCount, sizeof(CC3FaceIndices));
		indicesAreRetained = YES;
		LogTrace(@"%@ allocated space for %u face indices", self, faceCount);
	}
	return indices;
}

-(void) deallocateIndices {
	if (indicesAreRetained && indices) {
		free(indices);
		indices = NULL;
		indicesAreRetained = NO;
		LogTrace(@"%@ deallocated %u previously allocated indices", self, self.faceCount);
	}
}

-(void) populateIndices {
	LogTrace(@"%@ populating %u face indices", self, self.faceCount);
	if ( !indices ) [self allocateIndices];
	
	GLuint faceCount = self.faceCount;
	for (int faceIdx = 0; faceIdx < faceCount; faceIdx++) {
		indices[faceIdx] = [self uncachedIndicesAt: faceIdx];
		
		LogTrace(@"Face %i has indices %@", faceIdx,
					  NSStringFromCC3FaceIndices(indices[faceIdx]));
	}
	indicesAreDirty = NO;
}

-(void) markIndicesDirty { indicesAreDirty = YES; }


#pragma mark Centers

-(CC3Vector*) centers {
	if (centersAreDirty || !centers) [self populateCenters];
	return centers;
}

-(void) setCenters: (CC3Vector*) faceCenters {
	[self deallocateCenters];			// Safely disposes existing vertices
	centers = faceCenters;
}

-(CC3Vector) centerAt: (GLuint) faceIndex {
	if (shouldCacheFaces) return self.centers[faceIndex];
	return CC3FaceCenter([self faceAt: faceIndex]);
}

-(CC3Vector*) allocateCenters {
	[self deallocateCenters];
	GLuint faceCount = self.faceCount;
	if (faceCount) {
		centers = calloc(faceCount, sizeof(CC3Vector));
		centersAreRetained = YES;
		LogTrace(@"%@ allocated space for %u face centers", self, faceCount);
	}
	return centers;
}

-(void) deallocateCenters {
	if (centersAreRetained && centers) {
		free(centers);
		centers = NULL;
		centersAreRetained = NO;
		LogTrace(@"%@ deallocated %u previously allocated centers", self, self.faceCount);
	}
}

-(void) populateCenters {
	LogTrace(@"%@ populating %u face centers", self, self.faceCount);
	if ( !centers ) [self allocateCenters];
	
	GLuint faceCount = self.faceCount;
	for (int faceIdx = 0; faceIdx < faceCount; faceIdx++) {
		centers[faceIdx] = CC3FaceCenter([self faceAt: faceIdx]);

		LogTrace(@"Face %i has vertices %@ and center %@", faceIdx,
					  NSStringFromCC3Face([self faceAt: faceIdx]),
					  NSStringFromCC3Vector(centers[faceIdx]));
	}
	centersAreDirty = NO;
}

-(void) markCentersDirty { centersAreDirty = YES; }


#pragma mark Normals

-(CC3Vector*) normals {
	if (normalsAreDirty || !normals) [self populateNormals];
	return normals;
}

-(void) setNormals: (CC3Vector*) faceNormals {
	[self deallocateNormals];			// Safely disposes existing vertices
	normals = faceNormals;
}

-(CC3Vector) normalAt: (GLuint) faceIndex {
	if (shouldCacheFaces) return self.normals[faceIndex];
	return CC3FaceNormal([self faceAt: faceIndex]);
}

-(CC3Vector*) allocateNormals {
	[self deallocateNormals];
	GLuint faceCount = self.faceCount;
	if (faceCount) {
		normals = calloc(faceCount, sizeof(CC3Vector));
		normalsAreRetained = YES;
		LogTrace(@"%@ allocated space for %u face normals", self, faceCount);
	}
	return normals;
}

-(void) deallocateNormals {
	if (normalsAreRetained && normals) {
		free(normals);
		normals = NULL;
		normalsAreRetained = NO;
		LogTrace(@"%@ deallocated %u previously allocated normals", self, self.faceCount);
	}
}

-(void) populateNormals {
	LogTrace(@"%@ populating %u face normals", self, self.faceCount);
	if ( !normals ) [self allocateNormals];
	
	GLuint faceCount = self.faceCount;
	for (int faceIdx = 0; faceIdx < faceCount; faceIdx++) {
		normals[faceIdx] = CC3FaceNormal([self faceAt: faceIdx]);
		
		LogTrace(@"Face %i has vertices %@ and normal %@", faceIdx,
					  NSStringFromCC3Face([self faceAt: faceIdx]),
					  NSStringFromCC3Vector(normals[faceIdx]));
	}
	normalsAreDirty = NO;
}

-(void) markNormalsDirty { normalsAreDirty = YES; }


#pragma mark Planes

-(CC3Plane*) planes {
	if (planesAreDirty || !planes) [self populatePlanes];
	return planes;
}

-(void) setPlanes: (CC3Plane*) facePlanes {
	[self deallocatePlanes];			// Safely disposes existing vertices
	planes = facePlanes;
}

-(CC3Plane) planeAt: (GLuint) faceIndex {
	if (shouldCacheFaces) return self.planes[faceIndex];
	return CC3FacePlane([self faceAt: faceIndex]);
}

-(CC3Plane*) allocatePlanes {
	[self deallocatePlanes];
	GLuint faceCount = self.faceCount;
	if (faceCount) {
		planes = calloc(faceCount, sizeof(CC3Plane));
		planesAreRetained = YES;
		LogTrace(@"%@ allocated space for %u face planes", self, faceCount);
	}
	return planes;
}

-(void) deallocatePlanes {
	if (planesAreRetained && planes) {
		free(planes);
		planes = NULL;
		planesAreRetained = NO;
		LogTrace(@"%@ deallocated %u previously allocated planes", self, self.faceCount);
	}
}

-(void) populatePlanes {
	LogTrace(@"%@ populating %u face planes", self, self.faceCount);
	if ( !planes ) [self allocatePlanes];
	
	GLuint faceCount = self.faceCount;
	for (int faceIdx = 0; faceIdx < faceCount; faceIdx++) {
		planes[faceIdx] = CC3FacePlane([self faceAt: faceIdx]);
		
		LogTrace(@"Face %i has vertices %@ and plane %@", faceIdx,
					  NSStringFromCC3Face([self faceAt: faceIdx]),
					  NSStringFromCC3Plane(planes[faceIdx]));
	}
	planesAreDirty = NO;
}

-(void) markPlanesDirty { planesAreDirty = YES; }


#pragma mark Neighbours

-(CC3FaceNeighbours*) neighbours {
	if (neighboursAreDirty || !neighbours) [self populateNeighbours];
	return neighbours;
}

-(void) setNeighbours: (CC3FaceNeighbours*) faceNeighbours {
	[self deallocateNeighbours];		// Safely disposes existing vertices
	neighbours = faceNeighbours;
}

-(CC3FaceNeighbours) neighboursAt: (GLuint) faceIndex {
	return self.neighbours[faceIndex];
}

-(CC3FaceNeighbours*) allocateNeighbours {
	[self deallocateNeighbours];
	GLuint faceCount = self.faceCount;
	if (faceCount) {
		neighbours = calloc(faceCount, sizeof(CC3FaceNeighbours));
		neighboursAreRetained = YES;
		LogTrace(@"%@ allocated space for %u face neighbours", self, faceCount);
	}
	return neighbours;
}

-(void) deallocateNeighbours {
	if (neighboursAreRetained && neighbours) {
		free(neighbours);
		neighbours = NULL;
		neighboursAreRetained = NO;
		LogTrace(@"%@ deallocated %u previously allocated neighbour structures", self, self.faceCount);
	}
}

-(void) populateNeighbours {
	LogTrace(@"%@ populating neighbours for %u faces", self, self.faceCount);
	if ( !neighbours ) [self allocateNeighbours];
	
	GLuint faceCnt = self.faceCount;
	
	// Break all neighbour links. Done in batch so that we can skip
	// testing neighbour connections from both directions later.
	for (int faceIdx = 0; faceIdx < faceCnt; faceIdx++) {
		GLuint* neighbourEdge = neighbours[faceIdx].edges;
		neighbourEdge[0] = neighbourEdge[1] = neighbourEdge[2] = kCC3FaceNoNeighbour;
	}
	
	// Iterate through all the faces
	for (int f1Idx = 0; f1Idx < faceCnt; f1Idx++) {

		// Get the neighbours of the current face, and if any of the edges still
		// need to have a neighbour assigned, look for them. We check this early
		// to avoid iterating through the remaining faces
		GLuint* f1Neighbours = neighbours[f1Idx].edges;
		if (f1Neighbours[0] == kCC3FaceNoNeighbour ||
			f1Neighbours[1] == kCC3FaceNoNeighbour ||
			f1Neighbours[2] == kCC3FaceNoNeighbour) {

			// For the current face, retrieve the vertex indices
			GLuint* f1Vertices = [mesh faceIndicesAt: f1Idx].vertices;
			
			// Iterate through all the faces beyond the current face
			for (int f2Idx = f1Idx + 1; f2Idx < faceCnt; f2Idx++) {

				// Get the neighbours of the other face, and if any of the edges still
				// need to have a neighbour assigned, see if any of the edges between
				// the current face and other face match. We check for neighbours early
				// to avoid iterating through all the face combinations.
				GLuint* f2Neighbours = neighbours[f2Idx].edges;
				if (f2Neighbours[0] == kCC3FaceNoNeighbour ||
					f2Neighbours[1] == kCC3FaceNoNeighbour ||
					f2Neighbours[2] == kCC3FaceNoNeighbour) {
				
					// For the other face, retrieve the vertex indices
					GLuint* f2Vertices = [mesh faceIndicesAt: f2Idx].vertices;
					
					// Compare each edge of the current face with each edge of the other face
					for (int f1EdgeIdx = 0; f1EdgeIdx < 3; f1EdgeIdx++) {
						
						// If this edge already has a neighbour, skip it
						if (f1Neighbours[f1EdgeIdx] == (GLuint)kCC3FaceNoNeighbour) {
							
							// Get the end points of an edge of the current face
							GLuint f1EdgeStart = f1Vertices[f1EdgeIdx];
							GLuint f1EdgeEnd = f1Vertices[(f1EdgeIdx < 2) ? (f1EdgeIdx + 1) : 0];
							
							// Iterate each edge of other face and compare against current face edge
							for (int f2EdgeIdx = 0; f2EdgeIdx < 3; f2EdgeIdx++) {
								
								// If this edge already has a neighbour, skip it
								if (f2Neighbours[f2EdgeIdx] == (GLuint)kCC3FaceNoNeighbour) {
									
									// Get the end points of an edge of the other face
									GLuint f2EdgeStart = f2Vertices[f2EdgeIdx];
									GLuint f2EdgeEnd = f2Vertices[(f2EdgeIdx < 2) ? (f2EdgeIdx + 1) : 0];
									
									// If the two edges have the same endpoints, mark each as a neighbour of the other
									if ((f1EdgeStart == f2EdgeStart && f1EdgeEnd == f2EdgeEnd) ||
										(f1EdgeStart == f2EdgeEnd && f1EdgeEnd == f2EdgeStart) ){
										f1Neighbours[f1EdgeIdx] = f2Idx;
										f2Neighbours[f2EdgeIdx] = f1Idx;
										LogTrace(@"Matched face %@ with face %@",
													  NSStringFromCC3FaceIndices(f1Indices),
													  NSStringFromCC3FaceIndices(f2Indices));
									}
								}
							}
						}
					}
				}
			}
			LogTrace(@"Face %i has indices %@ and neighbours %@", f1Idx,
						  NSStringFromCC3FaceIndices([mesh faceIndicesAt: f1Idx]),
						  NSStringFromCC3FaceNeighbours(neighbours[f1Idx]));
		}
		
	}
	neighboursAreDirty = NO;
	LogTrace(@"%@ finished building neighbours", self);
}

-(void) markNeighboursDirty { neighboursAreDirty = YES; }

@end
