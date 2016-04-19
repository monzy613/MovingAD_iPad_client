//
//  UIImage+Downloader.swift
//  M_fm
//
//  Created by 张逸 on 16/4/11.
//  Copyright © 2016年 MonzyZhang. All rights reserved.
//

import UIKit

extension UIImage {
    class func download(withURL url: String) -> UIImage? {
        if let url = NSURL(string: url) {
            if let data = NSData(contentsOfURL: url) {
                if let image = UIImage(data: data) {
                    return image
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}