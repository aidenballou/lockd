import SwiftUI
import UIKit

struct ShareCardRenderer {
    func render(title: String, detail: String, style: ShareCardStyle) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1080))

        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor(style.background).cgColor)
            cgContext.fill(CGRect(x: 0, y: 0, width: 1080, height: 1080))

            let headline = NSAttributedString(
                string: title.uppercased(),
                attributes: [
                    .font: UIFont.systemFont(ofSize: 72, weight: .bold),
                    .foregroundColor: UIColor(style.foreground)
                ]
            )
            headline.draw(in: CGRect(x: 80, y: 220, width: 920, height: 180))

            let body = NSAttributedString(
                string: detail,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 44, weight: .medium),
                    .foregroundColor: UIColor(style.foreground)
                ]
            )
            body.draw(in: CGRect(x: 80, y: 440, width: 920, height: 240))

            cgContext.setFillColor(UIColor(style.successAccent).cgColor)
            cgContext.fillEllipse(in: CGRect(x: 80, y: 760, width: 48, height: 48))

            let signature = NSAttributedString(
                string: "LOCKD",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 40, weight: .semibold),
                    .foregroundColor: UIColor(style.foreground)
                ]
            )
            signature.draw(in: CGRect(x: 150, y: 760, width: 300, height: 80))
        }
    }
}
