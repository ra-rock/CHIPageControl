//
//  CHIPageControlAji.swift
//  CHIPageControl  ( https://github.com/ChiliLabs/CHIPageControl )
//
//  Copyright (c) 2017 Chili ( http://chi.lv )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

open class CHIPageControlAji: CHIBasePageControl {
    fileprivate var maxDiamater: CGFloat {
        return max(inactiveDiameter, activeDiameter)
    }
    
    fileprivate var inactiveDiameter: CGFloat {
        return radius * 2
    }
    
    fileprivate var activeDiameter: CGFloat {
        return realCurrentPageRadius * 2
    }

    fileprivate var inactive = [CHILayer]()
    fileprivate var active = CHILayer()

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func updateNumberOfPages(_ count: Int) {
        inactive.forEach { $0.removeFromSuperlayer() }
        inactive = [CHILayer]()
        inactive = (0..<count).map {_ in
            let layer = CHILayer()
            self.layer.addSublayer(layer)
            return layer
        }

        self.layer.addSublayer(active)
        setNeedsLayout()
        self.invalidateIntrinsicContentSize()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        
        let floatCount = CGFloat(inactive.count)
        let x = (self.bounds.size.width - self.maxDiamater*floatCount - self.padding*(floatCount-1))*0.5
        let y = (self.bounds.size.height - self.maxDiamater)*0.5
        
        var frame = CGRect(x: x, y: y, width: self.maxDiamater, height: self.maxDiamater)

        active.frame = frame
        var activeLayer = active
        if self.activeDiameter < self.inactiveDiameter {
            let insideActiveLayer = CHILayer()
            let activeX = x + ((self.inactiveDiameter - self.activeDiameter)*0.5)
            let activeY = y + ((self.inactiveDiameter - self.activeDiameter)*0.5)
            insideActiveLayer.frame = CGRect(x: activeX, y: activeY, width: self.activeDiameter, height: self.activeDiameter)
            active.addSublayer(insideActiveLayer)
            activeLayer = insideActiveLayer
        }
        activeLayer.cornerRadius = self.realCurrentPageRadius
        activeLayer.backgroundColor = (self.currentPageTintColor ?? self.tintColor)?.cgColor
        activeLayer.borderWidth = currentPageBorderWidth
        activeLayer.borderColor = currentPageBorderColor?.cgColor ?? active.backgroundColor
        
        inactive.enumerated().forEach() { index, layer in
            var renderedLayer = layer
            if self.activeDiameter > self.inactiveDiameter {
                let insideLayer = CHILayer()
                let inactiveX = (self.activeDiameter - self.inactiveDiameter)*0.5
                let inactiveY = (self.activeDiameter - self.inactiveDiameter)*0.5
                insideLayer.frame = CGRect(x: inactiveX, y: inactiveY, width: self.inactiveDiameter, height: self.inactiveDiameter)
                layer.addSublayer(insideLayer)
                renderedLayer = insideLayer
            }
        
            renderedLayer.backgroundColor = self.tintColor(position: index).withAlphaComponent(self.inactiveTransparency).cgColor
            if self.borderWidth > 0 {
                renderedLayer.borderWidth = self.borderWidth
                renderedLayer.borderColor = self.tintColor(position: index).cgColor
            }
            renderedLayer.cornerRadius = self.radius
            layer.frame = frame
            frame.origin.x += self.maxDiamater + self.padding
        }
        update(for: progress)
    }

    override func update(for progress: Double) {
        guard let min = inactive.first?.frame,
              let max = inactive.last?.frame,
              numberOfPages > 1,
              progress >= 0 && progress <= Double(numberOfPages - 1) else {
                return
        }

        let total = Double(numberOfPages - 1)
        let dist = max.origin.x - min.origin.x
        let percent = CGFloat(progress / total)

        let offset = dist * percent
        active.frame.origin.x = min.origin.x + offset
    }

    override open var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize.zero)
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: CGFloat(inactive.count) * self.maxDiamater + CGFloat(inactive.count - 1) * self.padding,
                      height: maxDiamater)
    }
    
    override open func didTouch(gesture: UITapGestureRecognizer) {
        var touchIndex: Int?
        let point = gesture.location(ofTouch: 0, in: self)
        inactive.enumerated().forEach({ count, layer in
            if layer.hitTest(point) != nil {
                touchIndex = count
            }
        })
        if touchIndex != nil {
            delegate?.didTouch(pager: self, index: touchIndex!)
        }
    }
}
