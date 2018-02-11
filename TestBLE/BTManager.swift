//
//  BTManager.swift
//  TestBLE
//
//  Created by Shane Whitehead on 10/2/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation
import CoreBluetooth

class WeakRef<T> where T: AnyObject {
	
	private(set) weak var value: T?
	
	init(value: T?) {
		self.value = value
	}
}

extension CBManagerState: CustomStringConvertible {
	public var description: String {
		switch self {
		case .unknown: return "Unknown"
		case .resetting: return "Resetting"
		case .unsupported: return "Unsupported"
		case .unauthorized: return "Unauthrosied"
		case .poweredOff: return "Powered Off"
		case .poweredOn: return "Powered On"
		}
	}
}

class BTManager: NSObject {
	
	static let shared: BTManager = BTManager()
	
	fileprivate var centralManager: CBCentralManager?
	
	fileprivate var delegates: [WeakRef<CBCentralManagerDelegate>] = []
	fileprivate var actualDelegates: [CBCentralManagerDelegate] {
		return delegates.filter { $0.value != nil }.map { $0.value! }
	}
	
	private override init() {
		super.init()
	}
	
	func start(queue: DispatchQueue? = nil) {
		guard centralManager == nil else {
			return
		}
		centralManager = CBCentralManager(delegate: self, queue: queue)
	}
	
	func stop() {
		guard let centralManager = centralManager else {
			return
		}
		centralManager.stopScan()
		self.centralManager = nil
	}
	
	fileprivate func compact() {
		delegates = delegates.filter { $0.value != nil }
	}
	
	fileprivate func index(of delegate: CBCentralManagerDelegate) -> Int? {
		return delegates.index(where: { (ref) -> Bool in
			guard let value = ref.value else {
				return false
			}
			return value === delegate
		})
	}

	func add(delegate: CBCentralManagerDelegate) {
		delegates.append(WeakRef<CBCentralManagerDelegate>(value: delegate))
	}
	
	func remove(delegate: CBCentralManagerDelegate) {
		compact()
		guard let index = index(of: delegate) else {
			return
		}
		delegates.remove(at: index)
	}
	
	// MARK: Proxy functionality
	
	var state: CBManagerState {
		return centralManager?.state ?? .unknown
	}

	var isScanning: Bool {
		return centralManager?.isScanning ?? false
	}
	
	func stopScan() {
		centralManager?.stopScan()
	}
	
	func scanForPeripherals(withServices services: [CBUUID]?, options: [String: Any]? = nil) {
		centralManager?.scanForPeripherals(withServices: services, options: options)
	}
	
	func connect(_ peripheral: CBPeripheral, options: [String: Any]? = nil) {
		centralManager?.connect(peripheral, options: options)
	}
	
	func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
		centralManager?.cancelPeripheralConnection(peripheral)
	}
	
}

extension BTManager: CBCentralManagerDelegate {
	
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
//		log(debug: "state = \(central.state)")
		compact()
		for delegate in actualDelegates {
			delegate.centralManagerDidUpdateState(central)
		}
	}
	
	func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
//		log(debug: "")
		compact()
		for delegate in actualDelegates {
			delegate.centralManager?(central, willRestoreState: dict)
		}
	}

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//		log(debug: "\(peripheral.name ?? "Unknown")/\(peripheral.identifier)")
		compact()
		for delegate in actualDelegates {
			delegate.centralManager?(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
		}
	}

	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//		log(debug: "")
		compact()
		for delegate in actualDelegates {
			delegate.centralManager?(central, didConnect: peripheral)
		}
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
//		log(error: "\(peripheral)")
		if let error = error {
//			log(error: "Error: \(error)")
		}
		compact()
		for delegate in actualDelegates {
			delegate.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
		}
	}
	
	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
//		log(debug: "")
		compact()
		for delegate in actualDelegates {
			delegate.centralManager?(central, didFailToConnect: peripheral, error: error)
		}
	}
	
	
}
