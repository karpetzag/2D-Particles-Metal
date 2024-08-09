import UIKit
import MetalKit

class MainViewController: UIViewController {

    private var renderer: ParticleRenderer?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = view as? MetalView else {
            return
        }

		self.renderer = ParticleRenderer(metalView: mtkView, numberOfParticle: 1_000_000)
		self.renderer?.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    }
}
