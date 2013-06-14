/*
 * CC3BumpMapObjectSpace.fsh
 *
 * cocos3d 2.0.0
 * Author: Bill Hollings
 * Copyright (c) 2011-2013 The Brenwill Workshop Ltd. All rights reserved.
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

/**
 * This fragment shader performs object-space bump-mapping.
 *
 * The texture in texture unit 0 contains a map of object-space normals, encoded in the
 * texel RGB colors, according to the standard GL_DOT3_RGB encoding.
 *
 * An optional second texture in texture unit 1 contains the visible texture to be applied on
 * top of the bump-mapped texture. If this texture is not available, the fragment color is used.
 *
 * CC3TexturableMaterial.vsh is the vertex shader paired with this fragment shader.
 *
 * The semantics of the variables in this shader can be mapped using a
 * CC3GLProgramSemanticsByVarName instance.
 */

// Increase this if more textures are desired.
#define MAX_TEXTURES			2

// Fog modes.
#define GL_LINEAR                 0x2601
#define GL_EXP                    0x0800
#define GL_EXP2                   0x0801


precision mediump float;

//-------------- UNIFORMS ----------------------

uniform bool		u_cc3FogIsEnabled;			/**< Whether scene fogging is enabled. */
uniform lowp vec4	u_cc3FogColor;				/**< Fog color. */
uniform int			u_cc3FogAttenuationMode;	/**< Fog attenuation mode (one of GL_LINEAR, GL_EXP or GL_EXP2). */
uniform highp float	u_cc3FogDensity;			/**< Fog density. */
uniform highp float	u_cc3FogStartDistance;		/**< Distance from camera at which fogging effect starts. */
uniform highp float	u_cc3FogEndDistance;		/**< Distance from camera at which fogging effect ends. */

uniform lowp int	u_cc3TextureCount;						/**< Number of textures. */
uniform sampler2D	s_cc3Textures[MAX_TEXTURES];			/**< Texture samplers. */
uniform lowp vec4	u_cc3TextureUnitColor[MAX_TEXTURES];	/**< Constant color of this texure unit (often used for normal mapping). */


//-------------- VARYING VARIABLE INPUTS ----------------------
varying vec2 v_texCoord[MAX_TEXTURES];		/**< Fragment texture coordinates. */
varying lowp vec4 v_color;					/**< Fragment base color. */
varying highp float v_distEye;				/**< Fragment distance in eye coordinates. */

//-------------- CONSTANTS ----------------------
const vec3 kVec3Half = vec3(0.5, 0.5, 0.5);

//-------------- LOCAL VARIABLES ----------------------
vec4 fragColor;


//-------------- FUNCTIONS ----------------------

/**
 * Applies the texel from the bump map texture, using the specified texture fragment
 * and texture unit constant color.
 *
 * The light direction comes from the texture unit color, but is in range [0, 1].
 * Transforms the normal and light direction from range [0, 1] to [-1, 1], take dot product
 * for interaction between normal and light vector, sets it into each of the RGB components,
 * and modulates the fragment color.
 */
void applyBumpMapTexel(vec4 texColor, vec4 tuColor) {
	fragColor.rgb *= vec3(4.0 * dot(texColor.rgb - kVec3Half, tuColor.rgb - kVec3Half));
}

/** Applies the texel from the visible texture using simple modulation. */
void applyVisibleTexel(vec4 texColor) { fragColor *= texColor; }

/** Applies fog to the specified color and returns the adjusted color. */
vec4 fogify(vec4 aColor) {
	if (u_cc3FogIsEnabled) {
		int mode = u_cc3FogAttenuationMode;
		float vtxVisibility = 1.0;
		
		if (mode == GL_LINEAR) {
			vtxVisibility = (u_cc3FogEndDistance - v_distEye) / (u_cc3FogEndDistance - u_cc3FogStartDistance);
		} else if (mode == GL_EXP) {
			float d = u_cc3FogDensity * v_distEye;
			vtxVisibility = exp(-d);
		} else if (mode == GL_EXP2) {
			float d = u_cc3FogDensity * v_distEye;
			vtxVisibility = exp(-(d * d));
		}
		vtxVisibility = clamp(vtxVisibility, 0.0, 1.0);
		aColor.rgb =  mix(u_cc3FogColor.rgb, aColor.rgb, vtxVisibility);
	}
	return aColor;
}

//-------------- ENTRY POINT ----------------------
void main() {
	fragColor = v_color;

	if (u_cc3TextureCount > 0)
		applyBumpMapTexel(texture2D(s_cc3Textures[0], v_texCoord[0]), u_cc3TextureUnitColor[0]);

	if (u_cc3TextureCount > 1)
		applyVisibleTexel(texture2D(s_cc3Textures[1], v_texCoord[1]));

	gl_FragColor = fogify(fragColor);
}
