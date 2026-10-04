import UIKit

#if targetEnvironment(simulator)
enum SimulatorDocumentCapture {
    static func makeImage() -> UIImage {
        let size = CGSize(width: 1200, height: 1600)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: size))

            UIColor(white: 0.84, alpha: 1).setStroke()
            context.cgContext.setLineWidth(2)

            for index in 0..<12 {
                let y = 300 + CGFloat(index) * 82
                context.cgContext.move(to: CGPoint(x: 120, y: y))
                context.cgContext.addLine(to: CGPoint(x: 1080, y: y))
            }
            context.cgContext.strokePath()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left

            let title = NSAttributedString(
                string: "ATHAR",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 72, weight: .bold),
                    .foregroundColor: UIColor(white: 0.16, alpha: 1),
                    .paragraphStyle: paragraph
                ]
            )
            title.draw(in: CGRect(x: 120, y: 120, width: 960, height: 100))
        }
    }
}
#endif
