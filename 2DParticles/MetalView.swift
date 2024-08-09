import MetalKit

class MetalView: MTKView {

	var location: CGPoint?

	var normalizedLocation: CGPoint? {
		guard let location = location else {
			return nil
		}

		let result = CGPoint(x: location.x / self.bounds.width, y: location.y / self.bounds.height)
		return result
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.location = touches.first?.location(in: self)
	}

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.location = touches.first?.location(in: self)
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.location = nil
	}

	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.location = nil
	}
}
