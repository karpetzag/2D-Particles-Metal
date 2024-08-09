import Metal
import MetalKit
import simd

class ParticleRenderer: NSObject {

	private let view: MetalView
	private let commandQueue: MTLCommandQueue
	private let clearState: MTLComputePipelineState
	private let drawState: MTLComputePipelineState
	private let buffer: MTLBuffer
	private let numberOfParticle: UInt

	private var lastTime: CFTimeInterval?

	init?(metalView: MetalView, numberOfParticle: UInt) {
		self.view = metalView
		let particles = ParticleRenderer.makeParticles(numberOfParticle: numberOfParticle)

		guard
			let device = MTLCreateSystemDefaultDevice(),
			let queue = device.makeCommandQueue(),
			let buffer = device.makeBuffer(bytes: particles, length: MemoryLayout<Particle>.stride * particles.count, options: .storageModeShared),
			let library = device.makeDefaultLibrary(),
			let clearState = ParticleRenderer.makeState(device: device, library: library, name: "clearTexture"),
			let drawState = ParticleRenderer.makeState(device: device, library: library, name: "updateParticles")
		else {
			return nil
		}

		self.buffer = buffer
		self.clearState = clearState
		self.drawState = drawState
		self.numberOfParticle = numberOfParticle
		self.commandQueue = queue
		super.init()

		self.view.device = device
		self.view.framebufferOnly = false
		self.view.delegate = self
	}

	class func makeState(device: MTLDevice, library: MTLLibrary, name: String) -> MTLComputePipelineState? {
		guard let function = library.makeFunction(name: name) else {
			fatalError("Failed to make the function \(name)")
		}
		return try? device.makeComputePipelineState(function: function)
	}

	class func makeParticles(numberOfParticle: UInt) -> [Particle] {
		var particles = [Particle]()

		for _ in 0...numberOfParticle {
			let position = simd_float2(Float.random(in: 0...1), Float.random(in: 0...1))
			let particle = Particle(
				position: position,
				initialPosition: position,
				velocity: .zero,
				mass: 1
			)
			particles.append(particle)
		}
		return particles
	}
}

extension ParticleRenderer: MTKViewDelegate {

	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

	func draw(in view: MTKView) {
		guard let lastTime = self.lastTime else {
			self.lastTime = CACurrentMediaTime()
			return
		}
		guard
			let drawable = view.currentDrawable,
			let commandBuffer = self.commandQueue.makeCommandBuffer(),
			let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }

		let time = CACurrentMediaTime()
		let dt = time - lastTime
		self.lastTime = time

		commandEncoder.setComputePipelineState(self.clearState)
		commandEncoder.setTexture(drawable.texture, index: 0)
		self.encodeClearPassThreads(encoder: commandEncoder, drawable: drawable)

		commandEncoder.setComputePipelineState(self.drawState)
		commandEncoder.setBuffer(self.buffer, offset: 0, index: 0)
		let location = self.view.normalizedLocation ?? .zero
		let attract = self.view.normalizedLocation != nil
		var uniforms = Uniforms(
			attractToPosition: attract,
			touchPosition: vector_float2(Float(location.x), Float(location.y)),
			dt: Float(dt)
		)
		commandEncoder.setBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
		self.encodeDrawPassThreads(encoder: commandEncoder)

		commandEncoder.endEncoding()
		commandBuffer.present(drawable)
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
	}

	func encodeClearPassThreads(encoder: MTLComputeCommandEncoder, drawable: CAMetalDrawable) {
		let threadgroupWidth = self.clearState.threadExecutionWidth
		let threadgroupHeight = self.clearState.maxTotalThreadsPerThreadgroup / threadgroupWidth
		let threadsPerGroup = MTLSize(width: threadgroupWidth, height: threadgroupHeight, depth: 1)
		let gridSize = MTLSize(width: drawable.texture.width, height: drawable.texture.height, depth: 1)
		encoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerGroup)
	}

	func encodeDrawPassThreads(encoder: MTLComputeCommandEncoder) {
		let threadgroupWidth = min(self.drawState.maxTotalThreadsPerThreadgroup, Int(self.numberOfParticle))
		let threadsPerGroup = MTLSize(width: threadgroupWidth, height: 1, depth: 1)
		let gridSize = MTLSize(width: Int(self.numberOfParticle), height: 1, depth: 1)
		encoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerGroup)
	}
}
