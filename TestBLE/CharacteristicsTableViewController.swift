//
//  CharacteristicsTableViewController.swift
//  TestBLE
//
//  Created by Shane Whitehead on 10/2/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import UIKit
import CoreBluetooth
import Hermes
import Cadmus

class CharacteristicsTableViewController: UITableViewController {
	
	struct CellIdentifier {
		static let characteristics = "Cell.characteritics"
	}
	
	var peripheral: PeriperialWrapper?
	var service: CBService?
	
	var items: [CBCharacteristic] = []
	
	var textValues: [CBCharacteristic: String] = [:]
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		removeAllRows()
		BTManager.shared.add(delegate: self)
        guard let peripheral = peripheral, service != nil else {
			return
		}
		peripheral.peripheral.delegate = self
		BTManager.shared.connect(peripheral.peripheral)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		BTManager.shared.remove(delegate: self)
		guard let peripheral = peripheral, let service = service else {
			return
		}
		peripheral.peripheral.delegate = nil
		for item in items {
            service.peripheral?.setNotifyValue(false, for: item)
		}
	}
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return items.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.characteristics, for: indexPath)
		
		let charartistic = items[indexPath.row]
		cell.textLabel?.text = "\(charartistic.uuid.description) (\(charartistic.uuid.uuidString)) "
		
		if charartistic.isNotifying {
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}

		cell.detailTextLabel?.text = textValues[charartistic]
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let charartistic = items[indexPath.row]
		if charartistic.isNotifying {
            charartistic.service?.peripheral?.setNotifyValue(false, for: charartistic)
		} else {
			charartistic.service?.peripheral?.setNotifyValue(true, for: charartistic)
		}
		log(debug: "isNotifying: \(charartistic.isNotifying)")
		tableView.deselectRow(at: indexPath, animated: true)
		
		tableView.beginUpdates()
		tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .automatic)
		tableView.endUpdates()
	}
	
}


extension CharacteristicsTableViewController: CBCentralManagerDelegate {
	
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		changeNavigationBarBackground(forState: central.state)
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		log(debug: "Find characteristics for service")
		if let error = error {
			log(error: "Error: \(error)")
			return
		}
		guard let service = service else {
			return
		}
		guard let services = peripheral.services else {
			return
		}
		for item in services {
			guard item.uuid == service.uuid else {
				return
			}
			peripheral.discoverCharacteristics(nil, for: service)
		}
	}
	
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		log(debug: "Find services for peripheral")
		guard service != nil else {
			return
		}
		peripheral.discoverServices(nil)
	}
	
}

extension CharacteristicsTableViewController: CBPeripheralDelegate {
	
	func index(of characteristic: CBCharacteristic) -> Int? {
		return items.index { $0.uuid == characteristic.uuid }
	}
	
	func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
		guard let wrapper = self.peripheral else {
			return
		}
		guard peripheral.identifier == wrapper.peripheral.identifier else {
			return
		}
		log(debug: "peripheral = \(peripheral)")
	}
	
	func removeAllRows() {
		var paths: [IndexPath] = []
		log(debug: "Rows = \(items.count)")
		for row in 0..<items.count {
			paths.append(IndexPath(row: row, section: 0))
		}
		items.removeAll()
		log(debug: "Count = \(paths.count)")
		guard paths.count > 0 else {
			return
		}
		tableView.beginUpdates()
		tableView.deleteRows(at: paths, with: .automatic)
		tableView.endUpdates()
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		guard let wrapper = self.peripheral else {
			return
		}
		guard peripheral.identifier == wrapper.peripheral.identifier else {
			return
		}
		log(debug: "peripheral = \(peripheral)")
		log(debug: "service = \(service)")
		if let error = error {
			log(error: "Error: \(error)")
		}
		guard let characteristics = service.characteristics else {
			return log(warning: "No characteristics for service?")
		}

		var newRows: [IndexPath] = []
		var updateRows: [IndexPath] = []

		for characteristic in characteristics {
			if let existingIndex = self.index(of: characteristic) {
				self.items[existingIndex] = characteristic
				updateRows.append(IndexPath(row: existingIndex, section: 0))
			} else {
				let index = self.items.count
				newRows.append(IndexPath(row: index, section: 0))
				self.items.append(characteristic)
				
				peripheral.readValue(for: characteristic)
				peripheral.discoverDescriptors(for: characteristic)
			}
			log(debug: "characteristic = \(characteristic)")
			log(debug: "characteristic = \(String(describing: characteristic.value))")
		}
		tableView.beginUpdates()
		if !newRows.isEmpty {
			tableView.insertRows(at: newRows, with: .automatic)
		}
		if !updateRows.isEmpty {
			tableView.reloadRows(at: updateRows, with: .automatic)
		}
		tableView.endUpdates()
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
		guard let wrapper = self.peripheral else {
			return
		}
		guard peripheral.identifier == wrapper.peripheral.identifier else {
			return
		}
		log(debug: "peripheral = \(peripheral)")
		if let error = error {
			log(error: "Error: \(error)")
		}
		log(debug: "descriptor = \(descriptor)")
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
		guard let wrapper = self.peripheral else {
			return
		}
		guard peripheral.identifier == wrapper.peripheral.identifier else {
			return
		}
		guard let descriptors = characteristic.descriptors else {
			return
		}
		for descriptor in descriptors{
			log(debug: "\(descriptor)")
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		guard let wrapper = self.peripheral else {
			return
		}
		guard peripheral.identifier == wrapper.peripheral.identifier else {
			return
		}
		guard let row = index(of: characteristic) else {
			return
		}
		textValues[characteristic] = nil
		guard let value = characteristic.value else {
			return
		}
		
//		let values: [Int8] = [number(from: value, range: 0...1), number(from: value, range: 2...3), number(from: value, range: 4...5)]
//
//		log(debug: "\(values)")
//		let text = values.map { String($0) }.joined(separator: ", ")
//		log(debug: "\(text)")
		let text = value.hexEncodedString()
		textValues[characteristic] = text

		tableView.beginUpdates()
		tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
		tableView.endUpdates()
		
		if UIApplication.shared.applicationState == .background {
			log(debug: "Generate background notification for \(text)")
			NotificationServiceManager.shared.addInfo(title: characteristic.uuid.description, body: text).catch { (error) -> (Void) in
				log(error: "\(error)")
			}
		}
	}
	
	func number(from data: Data, range: CountableClosedRange<UInt>) -> Int8 {
		return Int8(bigEndian: data[range].withUnsafeBytes{ $0.pointee })
	}
}

extension Data {
	
	func hexEncodedString() -> String {
		let format = "0x%02hhx"
		return map { String(format: format, $0) }.joined(separator: " ")
	}
}
