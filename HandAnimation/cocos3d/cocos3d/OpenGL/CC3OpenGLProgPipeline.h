/*
 * CC3OpenGLProgPipeline.h
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
 */

/** @file */	// Doxygen marker

#import "CC3OpenGL.h"

#if CC3_GLSL

/**
 * Maximum number of lights under when using GLSL.
 *
 * Although under GLSL, there is no explicit maximum number of lights available, this setting
 * defines the number of possible lights that will be allocated and tracked within cocos3d, and can
 * be set by the application to confirm the maximum number of lights programmed into the shaders.
 *
 * The default value is 8. This can be changed by either setting the value of this compiler
 * build setting, or by setting the value of the value_GL_MAX_LIGHTS public instance variable
 * of the CC3OpenGL instance.
 */
#ifndef kCC3MaxGLSLLights
#	define kCC3MaxGLSLLights				8
#endif

/**
 * Maximum number of user clip planes when using GLSL.
 *
 * Although under GLSL, there is no explicit maximum number of clip planes available, this
 * setting defines the number of possible user clip planes that will be allocated and tracked
 * within cocos3d, and can be set by the application to confirm the maximum number of user clip
 * planes programmed into the shaders.
 *
 * The default value is 6. This can be changed by either setting the value of this compiler
 * build setting, or by setting the value of the value_GL_MAX_CLIP_PLANES public instance
 * variable of the CC3OpenGL instance.
 */
#ifndef kCC3MaxGLSLClipPlanes
#	define kCC3MaxGLSLClipPlanes			6
#endif

/**
 * Maximum number of palette matrices used for vertex skinning when using GLSL.
 *
 * Although under GLSL, there is no explicit maximum number of palette matrices available,
 * this setting defines the number of possible matrices that will be allocated and tracked within
 * cocos3d, and can be set by the application to confirm the maximum number of palettes programmed
 * into the shaders.
 *
 * The default value is 12. This can be changed by either setting the value of this compiler
 * build setting, or by setting the value of the value_GL_MAX_PALETTE_MATRICES public instance
 * variable of the CC3OpenGL instance.
 */
#ifndef kCC3MaxGLSLPaletteMatrices
#	define kCC3MaxGLSLPaletteMatrices		12
#endif

/** 
 * Maximum number of vertex units used for vertex skinning when using GLSL. 
 *
 * The default value is 4. This can be changed by either setting the value of this compiler
 * build setting, or by setting the value of the value_GL_MAX_VERTEX_UNITS public instance
 * variable of the CC3OpenGL instance.
 */
#ifndef kCC3MaxGLSLVertexUnits
#	define kCC3MaxGLSLVertexUnits			4
#endif

/** 
 * CC3OpenGLProgPipeline is an abstract class that manages the OpenGL state for a single GL context
 * that supports a programmable pipeline running GLSL.
 */
@interface CC3OpenGLProgPipeline : CC3OpenGL {
	NSString* value_GL_SHADING_LANGUAGE_VERSION;
}
@end

#endif	// CC3_GLSL