//
//  ViewController.swift
//  BluetoothTest
//
//  Created by 张逸 on 16/3/14.
//  Copyright © 2016年 MonzyZhang. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {
    @IBOutlet weak var messageInutField: UITextField!
    @IBOutlet weak var messageBox: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    
    var discoveredPeripheral: CBPeripheral?
    var centralManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    var transferCharacteristic: CBMutableCharacteristic?
    var dataToSend: NSData?
    let dataIncoming = NSMutableData()
    var sendDataIndex: Int?
    var sendingEOM = false

    var adJsonString: String = ""
    
    // peripheralmanagerDelegate delegate methods
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .PoweredOn:
            print("peripheralManager PowerdOn")
            //add service
            let transferService = CBMutableService(type: transferServiceUUID, primary: true)
            transferCharacteristic = CBMutableCharacteristic(type: transferCharacteristicUUID, properties: .Notify, value: nil, permissions: .Readable)
            transferService.characteristics = [transferCharacteristic!]
            peripheralManager?.addService(transferService)
        default:
            print("peripheralManager changeState default")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        print("Central subscribed to characteristic, Central: \(central)")
        // Get the data
        dataToSend = messageInutField.text?.dataUsingEncoding(NSUTF8StringEncoding)
        // Reset the index
        sendDataIndex = 0;
        // Start sending
        sendData()
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        print("Central unsubscribed to characteristic")
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        print(error)
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        // Start sending again
        sendData()
    }
    
    
    
    // centralManagerDelegate delegate methods
    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("\(#line) \(#function)")
        
        if central.state != .PoweredOn {
            print("central powerOff")
            return
        }
        
        scan()
    }
    
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("Discovered \(peripheral.name) at \(RSSI)")
        
        // Ok, it's in range - have we already seen it?
        
        if discoveredPeripheral != peripheral {
            // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
            discoveredPeripheral = peripheral
            
            // And connect
            print("Connecting to peripheral \(peripheral)")
            
            centralManager?.connectPeripheral(peripheral, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")
        
        cleanUp()
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Peripheral Connected")
        
        // Stop scanning
        centralManager?.stopScan()
        print("Scanning stopped")
        
        // Clear the data that we may already have
        dataIncoming.length = 0
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices([transferServiceUUID])
    }
    
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            cleanUp()
            return
        }
        
        // Discover the characteristic we want...
        
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        for service in peripheral.services as [CBService]! {
            peripheral.discoverCharacteristics([transferCharacteristicUUID], forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        // Deal with errors (if any)
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            cleanUp()
            return
        }
        
        // Again, we loop through the array, just in case.
        for characteristic in service.characteristics as [CBCharacteristic]! {
            // And check if it's the right one
            if characteristic.UUID.isEqual(transferCharacteristicUUID) {
                // If it is, subscribe to it
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
        // Once this is complete, we just need to wait for the data to come in.
    }
    
    
    /** This callback lets us know more data has arrived via notification on the characteristic
     */
    // MARK: All data get, perform segue to show ads
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        // Have we got everything we need?
        if let stringFromData = NSString(data: characteristic.value!, encoding: NSUTF8StringEncoding) {
            if stringFromData.isEqualToString("EOM") {
                // Cancel our subscription to the characteristic
                peripheral.setNotifyValue(false, forCharacteristic: characteristic)
                
                // and disconnect from the peripehral
                centralManager?.cancelPeripheralConnection(peripheral)
                print("allGet: \(JSON.parse(adJsonString))")
                self.performSegueWithIdentifier(MADSegues.showAd, sender: self)
            } else {
                adJsonString = "\(adJsonString)\(stringFromData)"
                messageBox.text = "\(messageBox.text)\(stringFromData)\n"
            }
            
            // Otherwise, just add the data on to what we already have
            dataIncoming.appendData(characteristic.value!)
            
            // Log it
            print("Received: \(stringFromData)")
        } else {
            print("Invalid data")
        }
    }
    
    
    /** The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Error changing notification state: \(error?.localizedDescription)")
        
        // Exit if it's not the transfer characteristic
        if !characteristic.UUID.isEqual(transferCharacteristicUUID) {
            return
        }
        
        // Notification has started
        if (characteristic.isNotifying) {
            print("Notification began on \(characteristic)")
        } else { // Notification has stopped
            print("Notification stopped on (\(characteristic))  Disconnecting")
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    /** Once the disconnection happens, we need to clean up our local copy of the peripheral
     */
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Peripheral Disconnected")
        discoveredPeripheral = nil
        
        // We're disconnected, so start scanning again
        scan()
    }
    
    
    
    
    
    func cleanUp() {
        // Don't do anything if we're not connected
        // self.discoveredPeripheral.isConnected is deprecated
        if discoveredPeripheral?.state != CBPeripheralState.Connected { // explicit enum required to compile here?
            return
        }
        
        // See if we are subscribed to a characteristic on the peripheral
        if let services = discoveredPeripheral?.services as [CBService]? {
            for service in services {
                if let characteristics = service.characteristics as [CBCharacteristic]? {
                    for characteristic in characteristics {
                        if characteristic.UUID.isEqual(transferCharacteristicUUID) && characteristic.isNotifying {
                            discoveredPeripheral?.setNotifyValue(false, forCharacteristic: characteristic)
                            // And we're done.
                            return
                        }
                    }
                }
            }
        }
        
        // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
        centralManager?.cancelPeripheralConnection(discoveredPeripheral!)
    }
    
    
    func scan() {
        centralManager?.scanForPeripheralsWithServices(
            [transferServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(bool: true)])
        print("Scanning started")
    }
    
    @IBAction func sendButtonPressed(sender: UIButton) {
        if messageInutField.text == "" {
            return
        }
        messageBox.text = "\(messageBox.text ?? "")\(messageInutField.text ?? "")\n"
        view.endEditing(true)
        peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [transferServiceUUID]
            ])
    }
    
    
    private func sendData() {
        
        if sendingEOM {
            // send it
            let didSend = peripheralManager?.updateValue(
                "EOM".dataUsingEncoding(NSUTF8StringEncoding)!,
                forCharacteristic: transferCharacteristic!,
                onSubscribedCentrals: nil
            )
            
            // Did it send?
            if (didSend == true) {
                
                // It did, so mark it as sent
                sendingEOM = false
                
                print("Sent: EOM")
            }
            
            // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return
        }
        
        if sendDataIndex >= dataToSend?.length {
            return
        }
        
        var didSend = true
        
        while didSend {
            // Make the next chunk
            
            // Work out how big it should be
            var amountToSend = dataToSend!.length - sendDataIndex!;
            
            // Can't be longer than 20 bytes
            if (amountToSend > NOTIFY_MTU) {
                amountToSend = NOTIFY_MTU;
            }
            
            // Copy out the data we want
            let chunk = NSData(
                bytes: dataToSend!.bytes + sendDataIndex!,
                length: amountToSend
            )
            
            // Send it
            didSend = peripheralManager!.updateValue(
                chunk,
                forCharacteristic: transferCharacteristic!,
                onSubscribedCentrals: nil
            )
            
            // If it didn't work, drop out and wait for the callback
            if (!didSend) {
                return
            }
            
            let stringFromData = NSString(
                data: chunk,
                encoding: NSUTF8StringEncoding
            )
            
            print("Sent: \(stringFromData)")
            
            // It did send, so update our index
            sendDataIndex! += amountToSend;
            
            // Was it the last one?
            if (sendDataIndex! >= dataToSend!.length) {
                
                // It was - send an EOM
                
                // Set this so if the send fails, we'll send it next time
                sendingEOM = true
                
                // Send it
                let eomSent = peripheralManager!.updateValue(
                    "EOM".dataUsingEncoding(NSUTF8StringEncoding)!,
                    forCharacteristic: transferCharacteristic!,
                    onSubscribedCentrals: nil
                )
                
                if (eomSent) {
                    // It sent, we're all done
                    sendingEOM = false
                    print("Sent: EOM")
                }
                messageInutField.text = ""
                peripheralManager?.stopAdvertising()
                return
            }
        }
    }
    
    

    // MARK: lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        centralManager = CBCentralManager(delegate: self, queue: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardFrame = view.convertRect((notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue(), fromView: nil)
        let fr1 = messageInutField.frame
        let fr2 = sendButton.frame
        UIView.animateWithDuration(0.25, animations: {
            [unowned self] in
            self.messageInutField.frame = CGRectMake(fr1.minX, self.view.frame.height - keyboardFrame.height - fr1.height, fr1.width, fr1.height)
            self.sendButton.frame = CGRectMake(fr2.minX, self.view.frame.height - keyboardFrame.height - fr2.height, fr2.width, fr2.height)
            })
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let fr1 = messageInutField.frame
        let fr2 = sendButton.frame
        UIView.animateWithDuration(0.25, animations: {
            [unowned self] in
            self.messageInutField.frame = CGRectMake(fr1.minX, self.view.frame.height - fr1.height, fr1.width, fr1.height)
            self.sendButton.frame = CGRectMake(fr2.minX, self.view.frame.height - fr2.height, fr2.width, fr2.height)
            })
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case MADSegues.showAd:
                let adVC = segue.destinationViewController as! MADAdViewController
                adVC.adJson = JSON.parse(adJsonString)
            default:
                break
            }
        }
    }

}

