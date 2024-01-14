//
//  ServicesTableViewController.swift
//  TestBLE
//
//  Created by Shane Whitehead on 10/2/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import UIKit
import CoreBluetooth
import Cadmus

class ServicesTableViewController: UITableViewController {
	
	struct CellIdentifier {
		static let service = "Cell.service"
	}
	
	struct SegueIdentifer {
		static let characteristics = "Segue.characteristics"
	}
	
	var peripheral: PeriperialWrapper?
	var services: [CBService] = []
	
	var selectedService: CBService? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		guard let peripheral = peripheral else {
			return
		}
		removeAllRows()
		
//		BTManager.shared.cancelPeripheralConnection(peripheral.peripheral)
		
		peripheral.peripheral.delegate = self
		BTManager.shared.add(delegate: self)

		BTManager.shared.connect(peripheral.peripheral)
		
		title = peripheral.name ?? "Unknown"
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		BTManager.shared.remove(delegate: self)
		guard let peripheral = peripheral else {
			return
		}
		peripheral.peripheral.delegate = nil
		BTManager.shared.cancelPeripheralConnection(peripheral.peripheral)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return services.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.service, for: indexPath)
		
		// Configure the cell...
		let service = services[indexPath.row]
		cell.textLabel?.text = "\(service.uuid.description) (\(service.uuid.uuidString))"
		cell.detailTextLabel?.text = "Is Primary: \(service.isPrimary ? "Yes" : "No")"
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		selectedService = services[indexPath.row]
		performSegue(withIdentifier: SegueIdentifer.characteristics, sender: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == SegueIdentifer.characteristics {
			guard let selectedService = selectedService, let peripheral = peripheral else {
				return
			}
			guard let controller = segue.destination as? CharacteristicsTableViewController else {
				return
			}
			controller.peripheral = peripheral
			controller.service = selectedService
		}
	}
		
}

extension ServicesTableViewController: CBCentralManagerDelegate {
	
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		changeNavigationBarBackground(forState: central.state)
	}
	
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		peripheral.discoverServices(nil)
	}
	
	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
	}
	
	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		log(error: "peripheral: \(peripheral)")
		guard let error = error else {
			return
		}
		log(error: "Error: \(error)")
	}
}

extension ServicesTableViewController: CBPeripheralDelegate {
	
	func index(of service: CBService) -> Int? {
		return services.index { $0.uuid == service.uuid }
	}
	
	func removeAllRows() {
		var paths: [IndexPath] = []
		log(debug: "Rows = \(services.count)")
		for row in 0..<services.count {
			paths.append(IndexPath(row: row, section: 0))
		}
		services.removeAll()
		log(debug: "Count = \(paths.count)")
		guard paths.count > 0 else {
			return
		}
		tableView.beginUpdates()
		tableView.deleteRows(at: paths, with: .automatic)
		tableView.endUpdates()
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let wrapper = self.peripheral else {
			return
		}
		guard peripheral.identifier == wrapper.peripheral.identifier else {
			return
		}
		
		log(debug: "\(peripheral)")
		if let error = error {
			log(error: "Error: \(error)")
			return
		}
		guard let services = peripheral.services else {
			log(warning: "No services?")
			return
		}

//		removeAllRows()
		
		var newRows: [IndexPath] = []
		var updateRows: [IndexPath] = []
		for service in services {
			if let existingIndex = self.index(of: service) {
				self.services[existingIndex] = service
				updateRows.append(IndexPath(row: existingIndex, section: 0))
			} else {
				let index = self.services.count
				newRows.append(IndexPath(row: index, section: 0))
				self.services.append(service)
			}
			
			log(debug: "Service = \(service)")
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
	
	func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
		guard let wrapper = self.peripheral else {
			return
		}
		guard peripheral.identifier == wrapper.peripheral.identifier else {
			return
		}
		log(debug: "peripheral = \(peripheral)")
	}
	
	func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
		guard let wrapper = self.peripheral else {
			return
		}
		guard peripheral.identifier == wrapper.peripheral.identifier else {
			return
		}
		log(debug: "\(peripheral.identifier); rssi = \(RSSI)")
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
		
		for characteristic in characteristics {
			log(debug: "characteristic = \(characteristic)")
		}
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
}
