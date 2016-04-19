//
//  MADAdViewController.swift
//  MovingAD_iPad_client
//
//  Created by 张逸 on 16/4/19.
//  Copyright © 2016年 MonzyZhang. All rights reserved.
//

import UIKit

class MADAdViewController: UIViewController {
    @IBOutlet weak var adImageView: UIImageView!
    @IBOutlet weak var adTextField: UITextView!

    //properties
    var adJson: JSON?
    var imageURL: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let json = adJson {
            let oneAd = json[0]
            if let imageName = oneAd["image_src"].string {
                let url = MADURL.imageURLWrapper(imageFileName: imageName)
                print("adsImageURL: \(url)")
                self.imageURL = url
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    let adImage = UIImage.download(withURL: url)
                    if let image = adImage {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.adImageView.image = image
                        })
                    } else {
                        print("wrong image url")
                    }
                })
            } else {
                print("no key names image_src")
            }
            if let rawString = oneAd.rawString() {
                adTextField.text = rawString
            }
        }
    }
}
