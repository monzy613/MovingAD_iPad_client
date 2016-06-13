//
//  MADAd.swift
//  MovingAD_iPhone_client
//
//  Created by Monzy Zhang on 5/23/16.
//  Copyright © 2016 MonzyZhang. All rights reserved.
//

import Foundation
import CoreLocation

enum MADAdType: Int {
    case Circles = 0
    case Polygon = 1
}

class MADAd {
    var type: MADAdType = .Polygon
    var is_img: Bool = false
    var money: Float = 0.0
    var adv_ID: Int = -1
    var text: String!
    var img_src: String!
    var range: Float = 0.0
    var polygonPoints: [CLLocation]!
    var centers: [CLLocation]!
    var adJSON: JSON!

    init(json: JSON) {
        adJSON = json
        type = MADAdType(rawValue: Int(json["type"].stringValue) ?? 0) ?? .Polygon
        money = json["money"].floatValue
        adv_ID = json["adv_ID"].intValue
        is_img = json["is_img"].boolValue

        if is_img {
            img_src = json["img_src"].string
        } else {
            text = json["text"].string
        }
        switch type {
        case .Circles:
            range = Float(json["range"].stringValue) ?? 0.0
            centers = [CLLocation]()
            if let centerPoints = json["center_points"].array {
                for point in centerPoints {
                    let center = CLLocation(latitude: CLLocationDegrees(point[1].floatValue), longitude: CLLocationDegrees(point[0].floatValue))
                    centers.append(center)
                }
            }
        case .Polygon:
            polygonPoints = [CLLocation]()
            if let points = json["points"].array {
                for pointArr in points {
                    let point = CLLocation(latitude: CLLocationDegrees(pointArr[1].floatValue), longitude: CLLocationDegrees(pointArr[0].floatValue))
                    polygonPoints.append(point)
                }
            }
        }
    }
}