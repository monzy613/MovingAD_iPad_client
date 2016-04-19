//
//  Animation.swift
//  MovingAD_iPhone_client
//
//  Created by 张逸 on 16/3/21.
//  Copyright © 2016年 MonzyZhang. All rights reserved.
//

import UIKit
import pop

class MZAnim {
    static func move(object obj: AnyObject, destPoint: CGPoint) {
        let anim = POPSpringAnimation(propertyNamed: kPOPViewCenter)
        anim.springBounciness = 8
        anim.springSpeed = 7
        anim.toValue = NSValue(CGPoint: destPoint)
        obj.pop_addAnimation(anim, forKey: "MovingAD.move")
    }
    
    static func size(object obj: AnyObject, destSize: CGSize) {
        let anim = POPSpringAnimation(propertyNamed: kPOPViewSize)
        anim.springBounciness = 8
        anim.springSpeed = 7
        anim.toValue = NSValue(CGSize: destSize)
        obj.pop_addAnimation(anim, forKey: "MovingAD.size")
    }
    
    static func animConstraint(constraint cons: AnyObject, destConstant: Float) {
        let layoutAnim = POPSpringAnimation(propertyNamed: kPOPLayoutConstraintConstant)
        layoutAnim.springBounciness = 8
        layoutAnim.springSpeed = 7
        layoutAnim.toValue = destConstant
        cons.pop_addAnimation(layoutAnim, forKey: "MovingAD.ConstraintConstant")
    }
}