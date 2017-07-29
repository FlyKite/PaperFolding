//
//  PaperFolding.swift
//  FKFakeTransition
//
//  Created by FlyKite on 2017/7/29.
//  Copyright © 2017年 FlyKite. All rights reserved.
//

import UIKit

typealias KeyframeParametricBlock = (CGFloat) -> CGFloat

enum PaperFoldingDirection: Int {
    case right = 0, left, top, bottom
}

enum PaperFoldingTransitionState {
    case idle, update, show
}

let openFunction: KeyframeParametricBlock = { (time) in
    return sin(time * CGFloat.pi / 2)
}
let closeFunction: KeyframeParametricBlock = { (time) in
    return -cos(time * CGFloat.pi / 2) + 1
}

var paperFoldingCurrentState: PaperFoldingTransitionState = .idle

extension CAKeyframeAnimation {
    static func animationWith(keyPath path: String, function block: KeyframeParametricBlock, fromValue: CGFloat, toValue: CGFloat) -> CAKeyframeAnimation {
        
        // get a keyframe animation to set up
        let animation = CAKeyframeAnimation(keyPath: path)
        // break the time into steps (the more steps, the smoother the animation)
        let steps = 100
        var values: [CGFloat] = []
        var time: CGFloat = 0.0
        let timeStep = 1.0 / CGFloat(steps - 1)
        for _ in 0 ..< steps {
            let value = fromValue + block(time) * (toValue - fromValue)
            values.append(value)
            time += timeStep
        }
        // we want linear animation between keyframes, with equal time steps
        animation.calculationMode = kCAAnimationLinear
        // set keyframes and we're done
        animation.values = values
        return animation
    }
}

extension UIView {
    
    func showPaperFoldingTransition(with view: UIView, numberOf folds: Int, duration: TimeInterval, direction: PaperFoldingDirection, completion: ((Bool) -> Void)?) {
        if paperFoldingCurrentState != .idle {
            return
        }
        paperFoldingCurrentState = .update
        
        //add view as parent subview
        if view.superview == nil {
            self.superview?.insertSubview(view, belowSubview: self)
        }
        //set frame
        var selfFrame = self.frame
        var anchorPoint: CGPoint!
        if direction == .right {
            selfFrame.origin.x = self.frame.origin.x - view.bounds.size.width
            view.frame = CGRect(x: self.frame.origin.x + self.frame.size.width - view.frame.size.width,
                                y: self.frame.origin.y,
                                width: view.frame.size.width,
                                height: view.frame.size.height)
            
            anchorPoint = CGPoint(x: 1, y: 0.5)
        } else if direction == .left {
            selfFrame.origin.x = self.frame.origin.x + view.bounds.size.width
            view.frame = CGRect(x: self.frame.origin.x,
                                y: self.frame.origin.y,
                                width: view.frame.size.width,
                                height: view.frame.size.height)
            
            anchorPoint = CGPoint(x: 0, y: 0.5)
        } else if direction == .top {
            selfFrame.origin.y = self.frame.origin.y + view.bounds.size.height
            view.frame = CGRect(x: self.frame.origin.x,
                                y: self.frame.origin.y,
                                width: view.frame.size.width,
                                height: view.frame.size.height)
            
            anchorPoint = CGPoint(x: 0.5, y: 0)
        } else if direction == .bottom {
            selfFrame.origin.y = self.frame.origin.y - view.bounds.size.height
            view.frame = CGRect(x: self.frame.origin.x,
                                y: self.frame.origin.y + self.frame.size.height - view.frame.size.height,
                                width: view.frame.size.width,
                                height: view.frame.size.height)
            
            anchorPoint = CGPoint(x: 0.5, y: 1)
        }
        
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let viewSnapShot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //set 3D depth
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 800.0
        let paperFoldingLayer = CALayer()
        paperFoldingLayer.frame = view.bounds
        paperFoldingLayer.backgroundColor = UIColor(white: 0.2, alpha: 1).cgColor
        paperFoldingLayer.sublayerTransform = transform
        view.layer.addSublayer(paperFoldingLayer)
        
        //setup rotation angle
        var startAngle: Double = 0
        let frameWidth = view.bounds.size.width
        let frameHeight = view.bounds.size.height
        let foldWidth = direction.rawValue < 2 ? frameWidth / CGFloat(folds * 2) : frameHeight / CGFloat(folds * 2)
        var prevLayer = paperFoldingLayer
        for b in 0 ..< folds * 2 {
            var imageFrame: CGRect!
            if direction == .right {
                if(b == 0) {
                    startAngle = -Double.pi / 2
                } else {
                    if b % 2 != 0 {
                        startAngle = Double.pi
                    } else {
                        startAngle = -Double.pi
                    }
                }
                imageFrame = CGRect(x: frameWidth - CGFloat(b + 1) * foldWidth,
                                    y: 0,
                                    width: foldWidth,
                                    height: frameHeight)
            }
            else if direction == .left {
                if b == 0 {
                    startAngle = Double.pi / 2
                } else {
                    if b % 2 != 0 {
                        startAngle = -Double.pi
                    } else {
                        startAngle = Double.pi
                    }
                }
                imageFrame = CGRect(x: CGFloat(b) * foldWidth,
                                    y: 0,
                                    width: foldWidth,
                                    height: frameHeight)
            }
            else if direction == .top {
                if b == 0 {
                    startAngle = -Double.pi / 2
                } else {
                    if b % 2 != 0 {
                        startAngle = Double.pi
                    } else {
                        startAngle = -Double.pi
                    }
                }
                imageFrame = CGRect(x: 0,
                                    y: CGFloat(b) * foldWidth,
                                    width: frameWidth,
                                    height: foldWidth)
            }
            else if direction == .bottom {
                if b == 0 {
                    startAngle = Double.pi / 2
                } else {
                    if b % 2 != 0 {
                        startAngle = -Double.pi
                    } else {
                        startAngle = Double.pi
                    }
                }
                imageFrame = CGRect(x: 0,
                                    y: frameHeight - CGFloat(b + 1) * foldWidth,
                                    width: frameWidth,
                                    height: foldWidth)
            }
            let transLayer = self.transformLayerFrom(image: viewSnapShot!, frame: imageFrame, duration: duration, anchorPoint: anchorPoint, startAngle: startAngle, endAngle: 0)
            prevLayer.addSublayer(transLayer)
            prevLayer = transLayer
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.frame = selfFrame
            paperFoldingLayer.removeFromSuperlayer()
            paperFoldingCurrentState = .show
            
            completion?(true)
        }
        
        CATransaction.setValue(duration, forKey: kCATransactionAnimationDuration)
        
        var openAnimation: CAKeyframeAnimation!
        if direction.rawValue < 2 {
            openAnimation = CAKeyframeAnimation.animationWith(keyPath: "position.x",
                                                               function: openFunction,
                                                               fromValue: self.frame.origin.x + self.frame.size.width / 2,
                                                               toValue: selfFrame.origin.x + self.frame.size.width / 2)
        } else {
            openAnimation = CAKeyframeAnimation.animationWith(keyPath: "position.y",
                                                               function: openFunction,
                                                               fromValue: self.frame.origin.y + self.frame.size.height / 2,
                                                               toValue: selfFrame.origin.y + self.frame.size.height / 2)
        }
        openAnimation.fillMode = kCAFillModeForwards
        openAnimation.isRemovedOnCompletion = false
        self.layer.add(openAnimation, forKey: "position")
        CATransaction.commit()
    }
    
    func hidePaperFoldingTransition(with view: UIView, numberOf folds: Int, duration: TimeInterval, direction: PaperFoldingDirection, completion: ((Bool) -> Void)?) {
        if paperFoldingCurrentState != .show {
            return
        }
        
        paperFoldingCurrentState = .update
        
        //set frame
        var selfFrame = self.frame
        var anchorPoint: CGPoint!
        if direction == .right {
            selfFrame.origin.x = self.frame.origin.x + view.bounds.size.width
            anchorPoint = CGPoint(x: 1, y: 0.5)
        } else if direction == .left {
            selfFrame.origin.x = self.frame.origin.x - view.bounds.size.width
            anchorPoint = CGPoint(x: 0, y: 0.5)
        } else if direction == .top {
            selfFrame.origin.y = self.frame.origin.y - view.bounds.size.height
            anchorPoint = CGPoint(x: 0.5, y: 0)
        } else if direction == .bottom {
            selfFrame.origin.y = self.frame.origin.y + view.bounds.size.height
            anchorPoint = CGPoint(x: 0.5, y: 1)
        }
        
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let viewSnapShot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //set 3D depth
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 800.0
        let paperFoldingLayer = CALayer()
        paperFoldingLayer.frame = view.bounds
        paperFoldingLayer.backgroundColor = UIColor(white: 0.2, alpha: 1).cgColor
        paperFoldingLayer.sublayerTransform = transform
        view.layer.addSublayer(paperFoldingLayer)
        
        //setup rotation angle
        var endAngle: Double = 0
        let frameWidth = view.bounds.size.width
        let frameHeight = view.bounds.size.height
        let foldWidth = direction.rawValue < 2 ? frameWidth / CGFloat(folds * 2) : frameHeight / CGFloat(folds * 2)
        var prevLayer = paperFoldingLayer
        for b in 0 ..< folds * 2 {
            var imageFrame: CGRect!
            if direction == .right {
                if b == 0 {
                    endAngle = -Double.pi / 2
                } else {
                    if b % 2 != 0 {
                        endAngle = Double.pi
                    } else {
                        endAngle = -Double.pi
                    }
                }
                imageFrame = CGRect(x: frameWidth - CGFloat(b + 1) * foldWidth,
                                    y: 0,
                                    width: foldWidth,
                                    height: frameHeight)
            }
            else if direction == .left {
                if b == 0 {
                    endAngle = Double.pi / 2
                } else {
                    if b % 2 != 0 {
                        endAngle = -Double.pi
                    } else {
                        endAngle = Double.pi
                    }
                }
                imageFrame = CGRect(x: CGFloat(b) * foldWidth,
                                    y: 0,
                                    width: foldWidth,
                                    height: frameHeight)
            } else if direction == .top {
                if b == 0 {
                    endAngle = -Double.pi / 2
                } else {
                    if b % 2 != 0 {
                        endAngle = Double.pi
                    } else {
                        endAngle = -Double.pi
                    }
                }
                imageFrame = CGRect(x: 0,
                                    y: CGFloat(b) * foldWidth,
                                    width: frameWidth,
                                    height: foldWidth)
            }
            else if direction == .bottom {
                if b == 0 {
                    endAngle = Double.pi / 2
                } else {
                    if b % 2 != 0 {
                        endAngle = -Double.pi
                    } else {
                        endAngle = Double.pi
                    }
                }
                imageFrame = CGRect(x: 0,
                                    y: frameHeight - CGFloat(b + 1) * foldWidth,
                                    width: frameWidth,
                                    height: foldWidth)
            }
            let transLayer = self.transformLayerFrom(image: viewSnapShot!, frame: imageFrame, duration: duration, anchorPoint: anchorPoint, startAngle: 0, endAngle: endAngle)
            prevLayer.addSublayer(transLayer)
            prevLayer = transLayer
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.frame = selfFrame
            paperFoldingLayer.removeFromSuperlayer()
            paperFoldingCurrentState = .idle
            
            completion?(true)
        }
        
        CATransaction.setValue(duration, forKey: kCATransactionAnimationDuration)
        
        var openAnimation: CAKeyframeAnimation!
        if direction.rawValue < 2 {
            openAnimation = CAKeyframeAnimation.animationWith(keyPath: "position.x",
                                                               function: closeFunction,
                                                               fromValue: self.frame.origin.x + self.frame.size.width / 2,
                                                               toValue: selfFrame.origin.x + self.frame.size.width / 2)
        } else {
            openAnimation = CAKeyframeAnimation.animationWith(keyPath: "position.y",
                                                               function: closeFunction,
                                                               fromValue: self.frame.origin.y + self.frame.size.height / 2,
                                                               toValue: selfFrame.origin.y + self.frame.size.height / 2)
        }
        openAnimation.fillMode = kCAFillModeForwards
        openAnimation.isRemovedOnCompletion = false
        self.layer.add(openAnimation, forKey: "position")
        CATransaction.commit()
    }
    
    fileprivate func transformLayerFrom(image: UIImage, frame: CGRect, duration: TimeInterval, anchorPoint: CGPoint, startAngle: Double, endAngle: Double) -> CATransformLayer {
        let jointLayer = CATransformLayer()
        jointLayer.anchorPoint = anchorPoint
        let imageLayer = CALayer()
        let shadowLayer = CAGradientLayer()
        var shadowAniOpacity: Double = 0
        
        if anchorPoint.y == 0.5 {
            var layerWidth: CGFloat = 0
            if anchorPoint.x == 0 { // from left to right
                layerWidth = image.size.width - frame.origin.x
                jointLayer.frame = CGRect(x: 0, y: 0, width: layerWidth, height: frame.size.height)
                if frame.origin.x != 0 {
                    jointLayer.position = CGPoint(x: frame.size.width, y: frame.size.height / 2)
                } else {
                    jointLayer.position = CGPoint(x: 0, y: frame.size.height / 2)
                }
            } else { // from right to left
                layerWidth = frame.origin.x + frame.size.width
                jointLayer.frame = CGRect(x: 0, y: 0, width: layerWidth, height: frame.size.height)
                jointLayer.position = CGPoint(x: layerWidth, y: frame.size.height / 2)
            }
            
            //map image onto transform layer
            imageLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            imageLayer.anchorPoint = anchorPoint
            imageLayer.position = CGPoint(x: layerWidth * anchorPoint.x, y: frame.size.height / 2)
            jointLayer.addSublayer(imageLayer)
            let imageCrop = image.cgImage?.cropping(to: frame)
            imageLayer.contents = imageCrop
            imageLayer.backgroundColor = UIColor.clear.cgColor
            
            //add shadow
            let index = Int(frame.origin.x / frame.size.width)
            shadowLayer.frame = imageLayer.bounds
            shadowLayer.backgroundColor = UIColor.darkGray.cgColor
            shadowLayer.opacity = 0.0
            shadowLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
            if index % 2 != 0 {
                shadowLayer.startPoint = CGPoint(x: 0, y: 0.5)
                shadowLayer.endPoint = CGPoint(x: 1, y: 0.5)
                shadowAniOpacity = anchorPoint.x != 0 ? 0.24 : 0.32
            } else {
                shadowLayer.startPoint = CGPoint(x: 1, y: 0.5)
                shadowLayer.endPoint = CGPoint(x: 0, y: 0.5)
                shadowAniOpacity = anchorPoint.x != 0 ? 0.32 : 0.24
            }
        } else {
            var layerHeight: CGFloat = 0
            if anchorPoint.y == 0 { // from top
                layerHeight = image.size.height - frame.origin.y
                jointLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: layerHeight)
                if frame.origin.y != 0 {
                    jointLayer.position = CGPoint(x: frame.size.width / 2, y: frame.size.height)
                } else {
                    jointLayer.position = CGPoint(x: frame.size.width / 2, y: 0)
                }
            } else { // from bottom
                layerHeight = frame.origin.y + frame.size.height
                jointLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: layerHeight)
                jointLayer.position = CGPoint(x: frame.size.width / 2, y: layerHeight)
            }
            
            // map image onto transform layer
            imageLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            imageLayer.anchorPoint = anchorPoint
            imageLayer.position = CGPoint(x: frame.size.width/2, y: layerHeight*anchorPoint.y)
            jointLayer.addSublayer(imageLayer)
            let imageCrop = image.cgImage?.cropping(to: frame)
            imageLayer.contents = imageCrop
            imageLayer.backgroundColor = UIColor.clear.cgColor
            
            //add shadow
            let index = Int(frame.origin.y / frame.size.height)
            shadowLayer.frame = imageLayer.bounds
            shadowLayer.backgroundColor = UIColor.darkGray.cgColor
            shadowLayer.opacity = 0.0
            shadowLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]

            if index % 2 != 0 {
                shadowLayer.startPoint = CGPoint(x: 0.5, y: 0)
                shadowLayer.endPoint = CGPoint(x: 0.5, y: 1)
                shadowAniOpacity = anchorPoint.x != 0 ? 0.24 : 0.32
            } else {
                shadowLayer.startPoint = CGPoint(x: 0.5, y: 1)
                shadowLayer.endPoint = CGPoint(x: 0.5, y: 0)
                shadowAniOpacity = anchorPoint.x != 0 ? 0.32 : 0.24
            }
        }
        imageLayer.addSublayer(shadowLayer)
        
        // animate open/close animation
        var animation = CABasicAnimation(keyPath: "transform.rotation.\(anchorPoint.y == 0.5 ? "y" : "x")")
        animation.duration = duration
        animation.fromValue = startAngle
        animation.toValue = endAngle
        animation.isRemovedOnCompletion = false
        jointLayer.add(animation, forKey: "jointAnimation")
        
        // animate shadow opacity
        animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = duration
        animation.fromValue = startAngle != 0 ? shadowAniOpacity : 0
        animation.toValue = startAngle != 0 ? 0 : shadowAniOpacity
        animation.isRemovedOnCompletion = false
        shadowLayer.add(animation, forKey: nil)
        
        return jointLayer

    }
    
}
