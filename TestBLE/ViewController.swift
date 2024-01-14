//
//  ViewController.swift
//  TestBLE
//
//  Created by Shane Whitehead on 10/2/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import UIKit
import CoreBluetooth
import Cadmus

class ViewController: UIViewController {
	
	@IBOutlet weak var scanButton: UIButton!
	@IBOutlet weak var scanningIndicator: UIActivityIndicatorView!
	
	var peripheralsTableViewController: PeripheralsTableViewController!
	
	var isScanning: Bool = false {
		didSet {
			scanningIndicator.isHidden = !isScanning
			if isScanning {
				scanningIndicator.startAnimating()
			} else {
				scanningIndicator.stopAnimating()
			}
			
			scanButton.setTitle(isScanning ? "Stop" : "Start", for: [])
			if isScanning {
				startScanningForDevices()
			} else {
				stopScanningForDevices()
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		BTManager.shared.start()
		BTManager.shared.add(delegate: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "Segue.tableView" {
			guard let controller = segue.destination as? PeripheralsTableViewController else {
				return
			}
			peripheralsTableViewController = controller
		}
	}

	@IBAction func scanButtonTapped(_ sender: Any) {
		isScanning = !isScanning
	}
	
}

extension ViewController: CBCentralManagerDelegate {
	
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		changeNavigationBarBackground(forState: central.state)
		switch BTManager.shared.state {
		case .unknown: fallthrough
		case .resetting: fallthrough
		case .unsupported: fallthrough
		case .unauthorized: fallthrough
		case .poweredOff:
			isScanning = false
			peripheralsTableViewController.removeAllRows()
		case .poweredOn: break
		}
	}
	
	func stopScanningForDevices() {
		guard BTManager.shared.isScanning else {
			return
		}
		log(debug: "Stop Scanning")
		BTManager.shared.stopScan()
	}
	
	func startScanningForDevices() {
		peripheralsTableViewController.removeAllRows()
		switch BTManager.shared.state {
		case .unknown: fallthrough
		case .resetting: fallthrough
		case .unsupported: fallthrough
		case .unauthorized: fallthrough
		case .poweredOff:
			log(warning: "CentralManager state = \(BTManager.shared.state)")
			isScanning = false
		case .poweredOn:
			log(debug: "isScanning = \(isScanning)")
			guard isScanning && !BTManager.shared.isScanning else {
				return
			}
			log(debug: "Start Scanning")
			BTManager.shared.scanForPeripherals(withServices: nil, options: nil)
		}
	}
	
	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		guard let controller = peripheralsTableViewController else {
			log(error: "Peripherals table view controller is nil")
			return
		}
		let pName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
		let wrapper = PeriperialWrapper(name: pName, peripheral: peripheral)
		controller.add(wrapper)
	}
	
}

