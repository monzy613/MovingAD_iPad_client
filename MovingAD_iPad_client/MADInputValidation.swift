//
//  MADInputValidation.swift
//  MovingAD_iPhone_client
//
//  Created by 张逸 on 16/3/24.
//  Copyright © 2016年 MonzyZhang. All rights reserved.
//

import Foundation

class MADInputValidation {
    enum MADInputValidationResult: String {
        case Valid = "valid"
        
        //phone validation
        case PhoneNumberEmpty = "手机号不能为空"
        case InvalidPhoneNumber = "请输入正确手机号"
        
        //password validation
        case PasswordEmpty = "密码不可为空"
        case PasswordTooShort = "密码应大于等于六位"
        case PasswordConfirmFail = "两次输入密码不一致"
        
        //verify code
        case VerifyNumberInvalid = "请输入正确6位验证码"
    }
    
    class func phoneNumber(phonenumber no: String?) -> MADInputValidationResult {
        if let no = no {
            if no == "adm" { return .Valid }
            if no == "" {
                return .PhoneNumberEmpty
            } else {
                if no.length == 11 {
                    let pattern = "1[34578][0-9]{9}"
                    let isValid = no.rangeOfString(pattern, options: .RegularExpressionSearch)
                    if isValid != nil {
                        return .Valid
                    } else {
                        return .InvalidPhoneNumber
                    }
                } else {
                    return .InvalidPhoneNumber
                }
            }
        } else {
            return .PhoneNumberEmpty
        }
    }
    
    class func password(pwd1 pwd1: String?, pwd2: String?) -> MADInputValidationResult {
        if let pwd1 = pwd1, pwd2 = pwd2 {
            if pwd1 == "" || pwd2 == "" {
                return .PasswordEmpty
            } else if pwd1.length < 6 || pwd2.length < 6{
                return .PasswordTooShort
            } else if pwd1 != pwd2 {
                return .PasswordConfirmFail
            } else {
                return .Valid
            }
        } else {
            return .PasswordEmpty
        }
    }
    
    class func password(pwd pwd: String?) -> MADInputValidationResult {
        if let pwd = pwd {
            if pwd == "adm" { return .Valid }
            if pwd == "" {
                return .PasswordEmpty
            } else {
                return .Valid
            }
        } else {
            return .PasswordEmpty
        }
    }
    
    class func verifyNumber(verifyNumber no: String?) -> MADInputValidationResult {
        if let no = no {
            if no.length == 6 {
                return .Valid
            }
        }
        return .VerifyNumberInvalid
    }
}