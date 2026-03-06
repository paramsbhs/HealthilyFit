import CoreGraphics
import simd

extension CGPoint {
    var simd2f: SIMD2<Float> {
        SIMD2(Float(x), Float(y))
    }

    func denormalized(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}

extension SIMD2 where Scalar == Float {
    var cgPoint: CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}
