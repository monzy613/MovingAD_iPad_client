//
//  NetworkUtil.swift
//  MovingAD_iPhone_client
//
//  Created by 张逸 on 16/3/20.
//  Copyright © 2016年 MonzyZhang. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation



/*

 无法连接服务器 000
 
 登录过程中
 登陆成功 200
 账号不存在或密码不正确 210
 
 
 注册过程中
 手机号可用 300
 手机号已被注册 310
 验证码正确 320
 验证码不正确 330
 注册成功 340
 注册失败 一般就是无法连接服务器 000
 
 
 */

class MADNetwork {
    static func Post(url url: String, parameters: [String: String]?, onSuccess: String -> Void, onFailure: String -> Void) {
        print("PostURL: \(url)")
        Alamofire.request(.POST, url, parameters: parameters).responseJSON {
            response in
            let json = JSON(response.result.value ?? [])
            print("json: \(json)")
            if let _ = response.result.error {
                print("error")
                onFailure("000")
                return
            }
            if let statusInt = json["status"].int {
                let statusCode = "\(statusInt)"
                if let tuple = MADURL.statusCodeDictionary[statusCode] {
                    if tuple[1] as! Bool {
                        onSuccess(MADURL.statusCodeDictionary[statusCode]![0] as! String)
                    } else {
                        onFailure(MADURL.statusCodeDictionary[statusCode]![0] as! String)
                    }
                } else {
                    onFailure(MADURL.statusCodeDictionary["000"]![0] as! String)
                }
            } else {
                onFailure(MADURL.statusCodeDictionary["000"]![0] as! String)
            }
            
            switch url {
            case MADURL.login:
                if let userInfo = json["userinfo"].array {
                    print(userInfo)
                } else {
                    print("no userinfo")
                }
            default:
                break
            }
        }
    }

    static func getPoints(url url: String, onSuccess: [Int: [CLLocation]] -> Void, onFailure: (String -> Void)?) {
        Alamofire.request(.GET, url).responseJSON {
            res in
            print(url)
            let json = JSON(res.result.value ?? [])
            if let _ = res.result.error {
                onFailure?("error")
                return
            }
            var advLocationDic = [Int: [CLLocation]]()
            for adv in json.arrayValue {
                let tmp = adv["points"].stringValue
                let adv_ID = adv["adv_ID"].intValue
                var pointsStr = tmp.substringFromIndex(tmp.startIndex.advancedBy(2))
                let endIndex = pointsStr.endIndex.advancedBy(-2)
                pointsStr = pointsStr.substringToIndex(endIndex)
                let pointsStrArray = pointsStr.componentsSeparatedByString("], [")
                var points = [CLLocation]()
                for point in pointsStrArray {
                    let location: CLLocation = CLLocation(
                        latitude: CLLocationDegrees(point.componentsSeparatedByString(", ")[1]) ?? 0.0,
                        longitude: CLLocationDegrees(point.componentsSeparatedByString(", ")[0]) ?? 0.0)
                    points.append(location)
                }
                advLocationDic[adv_ID] = points
            }
            onSuccess(advLocationDic)
        }
    }
    
}