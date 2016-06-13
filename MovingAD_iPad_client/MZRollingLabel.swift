//
//  MZRollingLabel.swift
//  Pods
//
//  Created by Monzy Zhang on 6/13/16.
//
//

import UIKit

private let kvoTextKey = "text"
private let kvoBoundsKey = "bounds"

public enum MZRollingType {
    case Loop
    case Rebound
}

public class MZRollingLabel: UIView {
    public let textLabel: UILabel
    public var animateType = MZRollingType.Loop

    public var duration: NSTimeInterval = 0.25
    private var timer: NSTimer?

    // MARK: - lifecycle
    public override init(frame: CGRect) {
        textLabel = UILabel()
        textLabel.textColor = UIColor.blackColor()
        textLabel.lineBreakMode = .ByWordWrapping
        textLabel.numberOfLines = 1
        super.init(frame: frame)
        addSubview(textLabel)
        initKVO()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        textLabel.removeObserver(self, forKeyPath: kvoTextKey)
        removeObserver(self, forKeyPath: kvoBoundsKey)
    }

    // MARK: - public
    public func animate() {
        replaceLabel()
        timer?.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: #selector(loop), userInfo: nil, repeats: true)
        loop()
    }

    public func stop() {
        self.textLabel.layer.removeAllAnimations()
        timer?.invalidate()
        timer = nil
        replaceLabel()
    }

    // MARK: - timer function
    @objc private func loop() {
        let labelSize = textLabel.bounds.size
        let labelY = textLabel.frame.origin.y
        UIView.animateWithDuration(duration, delay: 0.0, options: .CurveLinear, animations: { 
            self.textLabel.frame = CGRectMake(-labelSize.width, labelY, labelSize.width, labelSize.height)
            }) { (finished) in
                if finished {
                    self.replaceLabel()
                }
        }
    }

    // MARK: - kvo
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let object = object, let keyPath = keyPath {
            if object.isEqual(textLabel) && keyPath == kvoTextKey {
                textLabel.sizeToFit()
                let size = textLabel.bounds.size
                let labelFrame = CGRectMake(CGRectGetWidth(bounds), (CGRectGetHeight(bounds) - size.height) / 2, size.width, size.height)
                textLabel.frame = labelFrame
                return
            }
            if object.isEqual(self) && keyPath == kvoBoundsKey {
                replaceLabel()
                return
            }
        }
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
    }

    // MARK: - private
    private func replaceLabel() {
        let labelSize = textLabel.bounds.size
        textLabel.frame = CGRectMake(CGRectGetWidth(bounds), (CGRectGetHeight(bounds) - labelSize.height) / 2, labelSize.width, labelSize.height)
    }

    private func initKVO() {
        textLabel.addObserver(self, forKeyPath: kvoTextKey, options: .New, context: nil)
        addObserver(self, forKeyPath: kvoBoundsKey, options: .New, context: nil)
    }
}
