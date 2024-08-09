//
//  ShaderTypes.h
//  2DParticles
//
//  Created by Andrey Karpets on 03.08.2024.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
typedef metal::int32_t EnumBackingType;
#else
#import <Foundation/Foundation.h>
typedef NSInteger EnumBackingType;
#endif

#include <simd/simd.h>

struct Particle {
	simd_float2 position;
	simd_float2 initialPosition;
	simd_float2 velocity;
	float mass;
};

struct Uniforms {
	bool attractToPosition;
	simd_float2 touchPosition;
	float dt;
};

#endif /* ShaderTypes_h */

