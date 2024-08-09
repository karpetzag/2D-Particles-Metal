#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

kernel void clearTexture(texture2d<half, access::write> texture [[texture(0)]], uint2 pxID [[thread_position_in_grid]]) {
	texture.write(half4(0,0,0,1), pxID);
}

kernel void updateParticles(texture2d<half, access::write> texture [[texture(0)]],
						device Particle *particles [[buffer(0)]],
						constant Uniforms *uniforms [[buffer(1)]],
						uint particleID [[thread_position_in_grid]]) {
	float dt = uniforms->dt;

	float pxWidth = texture.get_width();
	float pxHeight = texture.get_height();
	float2 screenSize = float2(pxWidth, pxHeight);

	float2 velocity = particles[particleID].velocity;
	float2 initialPosition = particles[particleID].initialPosition;
	float frictionRate = 1 / (1 + dt);
	velocity *= frictionRate;

	float ratio = screenSize.x / screenSize.y;
	float2 position = particles[particleID].position;
	float mass = particles[particleID].mass;

	float2 fixedPosition = position;
	fixedPosition.x *= ratio;

	if (uniforms->attractToPosition) {
		float2 touchPosition = uniforms->touchPosition;
		touchPosition.x *= ratio;
		float2 direction = touchPosition - fixedPosition;
		float distance = length(direction) + 1;
		float force = 35 * mass / (distance * distance);
		float2 n = normalize(direction);
		if (distance > 1.2) {
			velocity += n * force * dt;
		} else {
			velocity += -n * 1.6 * force * dt;
		}


		if (distance < 1.25) {
			velocity += (simd_float2(n.y, -n.x) * 5 * mass / (distance)) * dt;
		}
	}

	float2 direction = initialPosition - position;
	float minDistance = 0.00001;
	if (abs(direction.x) > minDistance || abs(direction.y) > minDistance) {
		float distance = length(direction) + 1;
		float force = 15 * mass / (distance * distance);
		velocity += normalize(direction) * dt * force;
	}

	half4 color = mix(mix(half4(1,0,0,1), half4(0,1,0,1), position.x), half4(1,1,1,1), position.y);
	float2 pxPosition = float2(position.x * pxWidth, position.y * pxHeight);

	pxPosition += velocity;

	if (pxPosition.x <= 0 || pxPosition.x >= pxWidth) {
		velocity.x *= -1;
	}

	if (pxPosition.y <= 0 || pxPosition.y >= pxHeight) {
		velocity.y *= -1;
	}

	position = float2(pxPosition.x / pxWidth, pxPosition.y / pxHeight);
	particles[particleID].velocity = velocity;
	particles[particleID].position = position;
	uint2 texturePosition = uint2(pxPosition.x, pxPosition.y);

	texture.write(half4(color), texturePosition);
}
