//
//  UIViewController+TitleBackground.swift
//  TestBLE
//
//  Created by Shane Whitehead on 10/2/18.
//  Copyright © 2018 Shane Whitehead. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

extension UIViewController {
	
	func changeNavigationBarBackground(forState state: CBManagerState) {
		switch state {
		case .unknown: navigationController?.navigationBar.barTintColor = nil
		case .resetting: navigationController?.navigationBar.barTintColor = UIColor.orange
		case .unsupported: navigationController?.navigationBar.barTintColor = UIColor.magenta
		case .unauthorized: navigationController?.navigationBar.barTintColor = UIColor.purple
		case .poweredOff: navigationController?.navigationBar.barTintColor = UIColor.darkGray
		case .poweredOn: navigationController?.navigationBar.barTintColor = UIColor.green
		}
	}
	
}
