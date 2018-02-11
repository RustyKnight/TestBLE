//
//  PeripheralsTableViewController.swift
//  TestBLE
//
//  Created by Shane Whitehead on 10/2/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeriperialWrapper {
	var peripheral: CBPeripheral
	var name: String?
	
	var identifier: UUID {
		return peripheral.identifier
	}
	
	init(name: String?, peripheral: CBPeripheral) {
		self.name = name
		self.peripheral = peripheral
	}
}

func == (lhs: PeriperialWrapper, rhs: PeriperialWrapper) -> Bool {
	return lhs.identifier == rhs.identifier
}

class PeripheralsTableViewController: UITableViewController {
	
	struct CellIdentifer {
		static let peripherial = "Cell.peripherial"
	}
	
	struct SegueIdentifer {
		static let services = "Segue.services"
	}
	
	var peripherals: [PeriperialWrapper] = []
	var selectedPeripheral: PeriperialWrapper? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		BTManager.shared.add(delegate: self)
		for peripheral in peripherals {
			peripheral.peripheral.delegate = self
			BTManager.shared.connect(peripheral.peripheral, options: nil)
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		BTManager.shared.remove(delegate: self)
		for peripheral in peripherals {
			peripheral.peripheral.delegate = nil
			BTManager.shared.cancelPeripheralConnection(peripheral.peripheral)
		}
	}
	
	func add(_ peripheral: PeriperialWrapper) {
		guard let index = (peripherals.index { $0 == peripheral }) else {
			peripherals.append(peripheral)
			tableView.insertRows(at: [IndexPath(row: peripherals.count - 1, section: 0)], with: .automatic)
			peripheral.peripheral.delegate = self
			
			BTManager.shared.connect(peripheral.peripheral, options: nil)
			return
		}
		peripherals[index] = peripheral
		tableView.reloadRows(at: [IndexPath(row: peripherals.count - 1, section: 0)], with: .automatic)
	}
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return peripherals.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifer.peripherial, for: indexPath)
		
		let peripheral = peripherals[indexPath.row]
		if peripheral.name == nil {
			cell.textLabel?.text = "Unknown"
		} else {
			cell.textLabel?.text = peripheral.name
		}
		cell.detailTextLabel?.text = peripheral.identifier.uuidString

		cell.accessoryType = .disclosureIndicator
		
		// Configure the cell...
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		selectedPeripheral = peripherals[indexPath.row]
		performSegue(withIdentifier: SegueIdentifer.services, sender: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == SegueIdentifer.services {
			guard let controller = segue.destination as? ServicesTableViewController else {
				return
			}
			guard let peripheral = selectedPeripheral else {
				return
			}
			controller.peripheral = peripheral
		}
	}
	
	func removeAllRows() {
		var paths: [IndexPath] = []
		log(debug: "Rows = \(peripherals.count)")
		for row in 0..<peripherals.count {
			paths.append(IndexPath(row: row, section: 0))
		}
		peripherals.removeAll()
		log(debug: "Count = \(paths.count)")
		guard paths.count > 0 else {
			return
		}
		tableView.beginUpdates()
		tableView.deleteRows(at: paths, with: .automatic)
		tableView.endUpdates()
	}

}

extension PeripheralsTableViewController: CBCentralManagerDelegate {
	
	func index(of peripheral: CBPeripheral) -> Int? {
		return peripherals.index { $0.peripheral.identifier == peripheral.identifier }
	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		changeNavigationBarBackground(forState: central.state)
		switch central.state {
		case .unknown: fallthrough
		case .resetting: fallthrough
		case .unsupported: fallthrough
		case .unauthorized: fallthrough
		case .poweredOff: removeAllRows()
		case .poweredOn: break
		}
	}

	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		guard let index = index(of: peripheral) else {
			return
		}
		tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
	}
	
	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		log(debug: "\(peripheral)")
		if let error = error {
			log(error: "Error: \(error)")
			return
		}
	}
	
	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		log(debug: "peripheral = \(peripheral.name ?? "Unknown")/\(peripheral.identifier)")
		if let error = error {
			log(error: "Error: \(error)")
			return
		}
	}
	
}

extension PeripheralsTableViewController: CBPeripheralDelegate {
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		log(debug: "\(peripheral)")
		if let error = error {
			log(error: "Error: \(error)")
			return
		}
		guard let services = peripheral.services else {
			log(warning: "No services?")
			return
		}
		for service in services {
			log(debug: "Service = \(service)")
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
		log(debug: "peripheral = \(peripheral)")
	}
	
	func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
		log(debug: "\(peripheral.identifier); rssi = \(RSSI)")
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		log(debug: "peripheral = \(peripheral)")
		log(debug: "service = \(service)")
		if let error = error {
			log(error: "Error: \(error)")
		}
		guard let characteristics = service.characteristics else {
			return log(warning: "No characteristics for service?")
		}
		
		for characteristic in characteristics {
			log(debug: "characteristic = \(characteristic)")
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
		log(debug: "peripheral = \(peripheral)")
		if let error = error {
			log(error: "Error: \(error)")
		}
		log(debug: "descriptor = \(descriptor)")
	}
}
