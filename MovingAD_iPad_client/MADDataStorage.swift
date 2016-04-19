//
//  MADDataStorage.swift
//  MovingAD_iPhone_client
//
//  Created by 张逸 on 16/3/24.
//  Copyright © 2016年 MonzyZhang. All rights reserved.
//

import CoreData

class MADData {
    class func save(data data: AnyObject, withKey key: MADDataKey) {
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: key.rawValue)
    }
}