//
//  URLs.swift
//  MovingAD_iPhone_client
//
//  Created by 张逸 on 16/3/20.
//  Copyright © 2016年 MonzyZhang. All rights reserved.
//

import Foundation

class MADURL {
    // Mark urls
    static var ip = "115.28.206.58"
    static var port = "5000"
    
    class var baseURL: String {
        get {
            return "http://\(MADURL.ip):\(port)"
        }
    }
    
    class var login: String {
        get {
            return "\(MADURL.baseURL)/app/check_login"
        }
    }
    
    class var registerPhone: String {
        get {
            return "\(MADURL.baseURL)/app/registerPhone"
        }
    }
    
    class var registerVerify: String {
        get {
            return "\(MADURL.baseURL)/app/registerVerify"
        }
    }
    
    class var register: String {
        get {
            return "\(MADURL.baseURL)/app/register"
        }
    }

    class var get_all_advs: String {
        get {
            return "\(MADURL.baseURL)/app/get_all_advs"
        }
    }

    class func imageURLWrapper(imageFileName name: String) -> String {
        return "http://\(ip):\(port)/static/image/adv_pic/\(name)"
    }
    
    
    //parameters
    class param {
        static let phone = "phone"
        static let password = "password"
        static let verifyNumber = "verifyNumber"
        static let name = "name"
        static let gender = "gender"
    }
    
    
    //e.g. statusCodeDictionary[status][0]   statusCodeDictionary[status][1]
    static let statusCodeDictionary = [
        "000": ["无法连接服务器", false],
        "200": ["登陆成功", true],
        "210": ["账号不存在或密码不正确", false],
        "300": ["验证码已发送", true],
        "310": ["手机号已被注册", false],
        "320": ["验证码正确", true],
        "330": ["验证码不正确", false],
        "340": ["注册成功", true],
        "350": ["注册失败", false]
    ]
}

/*
 
 登陆接口
 baseURL/login POST
 参数
 "account": string not null
 "password": string not null
 
 返回json串
 说明: error 和 userinfo 至少一个不为 null, error 的数字代表出错信息代码。
 {
    "error": int can null,
    "userinfo": {"name": string can null} can null
 }
 
 
 注册接口
 baseURL/register POST
 参数
 "account": string not null
 "password": string not null
 "name": string can null
 
 返回json串
 说明: 同login返回要求。
 {
    "error": int can null,
    "userinfo": {"name": string can null} can null
 }
 */