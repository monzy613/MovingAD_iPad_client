//
//  MADAdDisplayViewController.swift
//  MovingAD_iPad_client
//
//  Created by Monzy Zhang on 6/13/16.
//  Copyright © 2016 MonzyZhang. All rights reserved.
//

import UIKit
import BabyBluetooth
import SnapKit
import SDWebImage

private let adDuration: NSTimeInterval = 8

class MADAdDisplayViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var baby: BabyBluetooth!
    var adPeripheral: CBPeripheral!
    var adCharacteristic: CBCharacteristic!

    var currentAD: MADAd?
    var adTimer: NSTimer?

    var currentSourceDeviceName: String?
    var devices = [String]()
    var peripherals = [CBPeripheral]()

    lazy var deviceTableview: UITableView = {
        let tableView = UITableView()
        self.view.addSubview(tableView)
        tableView.backgroundColor = UIColor.lightGrayColor()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.self.description())
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    lazy var adImageView: UIImageView = {
        let imageView = UIImageView()
        self.view.addSubview(imageView)
        imageView.alpha = 0.0
        imageView.snp_makeConstraints(closure: { (make) in
            make.edges.equalTo(self.view)
        })
        imageView.contentMode = .ScaleAspectFit
        return imageView
    }()

    lazy var adRollLabel: MZRollingLabel = {
        let label = MZRollingLabel(frame: CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 100))
        self.view.addSubview(label)
        label.snp_makeConstraints {
            make in
            make.edges.equalTo(self.view)
        }
        label.center = self.view.center
        label.duration = 3.0
        label.textLabel.font = UIFont.systemFontOfSize(100)
        return label
    }()

    // MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
        view.translatesAutoresizingMaskIntoConstraints = false
        baby = BabyBluetooth.shareBabyBluetooth()
        setupBabyBluetooth()
        baby.scanForPeripherals()().begin()()
    }

    // MARK: - delegate
    // MARK: - UITableViewDelegate -
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.row >= devices.count || indexPath.row >= peripherals.count {
            return
        }
        adPeripheral = peripherals[indexPath.row]
        currentSourceDeviceName = devices[indexPath.row]
        baby.centralManager().connectPeripheral(adPeripheral, options: nil)
        self.baby.AutoReconnect(self.adPeripheral)
        deviceTableview.removeFromSuperview()
    }
    // MARK: - UITableViewDatasource -
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 40.0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = deviceTableview.dequeueReusableCellWithIdentifier(UITableViewCell.self.description(), forIndexPath: indexPath)
        cell.textLabel?.text = devices[indexPath.row]
        return cell
    }

    // MARK: - timer handler
    func nextAd() {
        hideAdView()
        adPeripheral.readValueForCharacteristic(adCharacteristic)
    }

    // MARK: - privates
    private func setupConstraints() {
        deviceTableview.snp_makeConstraints { (make) in
            make.center.equalTo(view)
            make.height.equalTo(200)
            make.width.equalTo(200)
        }
    }

    private func showAdView() {
        if let ad = currentAD {
            if ad.is_img {
                view.addSubview(adImageView)
                if let url = NSURL(string: "http://115.28.206.58:5000/static/image/adv_img/wanglaoju.jpg") {
                    SDWebImageDownloader.sharedDownloader().downloadImageWithURL(url, options: .AllowInvalidSSLCertificates, progress: nil, completed: { (image, data, error, finished) in
                        self.adImageView.image = image
                        UIView.animateWithDuration(0.25, animations: {
                            self.adImageView.alpha = 1.0
                        })
                    })
                }
            } else {
                view.addSubview(adRollLabel)
                adRollLabel.textLabel.text = ad.text
                adRollLabel.animate()
            }
        }
    }

    private func hideAdView() {
        UIView.animateWithDuration(0.25, animations: {
            self.adImageView.alpha = 0.0
        })
        adRollLabel.stop()
    }

    private func startGettingAdFromPeripheral() {
        adTimer?.invalidate()
        adTimer = NSTimer.scheduledTimerWithTimeInterval(adDuration, target: self, selector: #selector(nextAd), userInfo: nil, repeats: true)
    }
    
    private func setupBabyBluetooth() {
        baby.setBlockOnDiscoverToPeripherals { (centralManager, peripheral, adData, num) in
            let deviceName = peripheral.name ?? "defaultDeviceName"
            print(deviceName)
            if !self.devices.contains(deviceName) {
                self.devices.append(deviceName)
                self.peripherals.append(peripheral)
                self.deviceTableview.reloadData()
            }
        }

        baby.setBlockOnDiscoverServices { (peripheral, error) in
            if let services = peripheral.services {
                for service in services {
                    peripheral.discoverCharacteristics(nil, forService: service)
                }
            }
        }

        baby.setBlockOnDiscoverCharacteristics { (peripheral, service, error) in
            if error != nil {
                print("error: \(error)")
                return
            }
            guard let characteristics = service.characteristics else {
                print("service without characteristic")
                return
            }
            for characteristic in characteristics {
                if characteristic.UUID.UUIDString == MADADINFO_CHARACTERSTIC_UUID {
                    self.adCharacteristic = characteristic
                    print("find ad characteristic")
                    self.baby.centralManager().stopScan()
                    self.startGettingAdFromPeripheral()
                    self.nextAd()
                    break
                }
            }
        }

        baby.setBlockOnReadValueForCharacteristic { (peripheral, characteristic, error) in
            if error != nil {
                print("Read Error: \(error)")
                peripheral.readValueForCharacteristic(characteristic)
                return
            }
            self.hideAdView()
            self.startGettingAdFromPeripheral()
            let data = characteristic.value
            let jsonString = NSString(data: data ?? NSData(), encoding: NSUTF8StringEncoding) as! String
            let json = JSON.parse(jsonString)
            print("JSOnString: \(jsonString)")
            print("JSON: \(json)")
            self.currentAD = MADAd(json: json)
            self.showAdView()
            self.baby.AutoReconnectCancel(self.adPeripheral)
        }

        baby.setBlockOnConnected { (centralManager, peripheral) in
            peripheral.discoverServices([CBUUID(string: MADADINFO_SERVICE_UUID)])
        }

        baby.setBlockOnDisconnect { (centralManager, peripheral, error) in
            self.adPeripheral = nil
            self.adTimer?.invalidate()
        }

    }
}
