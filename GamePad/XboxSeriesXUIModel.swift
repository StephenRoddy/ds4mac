//
//  Xbox360UIModel.swift
//  GamePad
//
//  Created by Marco Luglio on 15/06/20.
//  Copyright © 2020 Marco Luglio. All rights reserved.
//

import Foundation
import Combine



class XboxSeriesXUIModel: ObservableObject {

	var leftTrigger:Float = 0
	var leftTriggerButton = false
	var leftShoulderButton = false

	var leftStickButton = false
	var leftStickX:Float = 0
	var leftStickY:Float = 0

	var upButton = false
	var rightButton = false
	var downButton = false
	var leftButton = false

	var backButton = false

	var xboxButton = false
	var uploadButton = false

	var startButton = false

	var rightStickX:Float = 0
	var rightStickY:Float = 0
	var rightStickButton = false

	var yButton = false
	var bButton = false
	var aButton = false
	var xButton = false

	var rightShoulderButton = false
	var rightTriggerButton = false
	var rightTrigger:Float = 0

	let objectWillChange = ObservableObjectPublisher()

	init() {

		NotificationCenter.default
			.addObserver(
				self,
				selector: #selector(self.updateButtons),
				name: GamepadButtonChangedNotification.Name,
				object: nil
			)

		NotificationCenter.default
			.addObserver(
				self,
				selector: #selector(self.updateAnalog),
				name: GamepadAnalogChangedNotification.Name,
				object: nil
			)

	}

	@objc func updateButtons(_ notification:Notification) {

		let o = notification.object as! GamepadButtonChangedNotification

		self.leftTriggerButton = o.leftTriggerButton
		self.leftShoulderButton = o.leftShoulderButton
		self.upButton = o.upButton
		self.rightButton = o.rightButton
		self.downButton = o.downButton
		self.leftButton = o.leftButton
		self.backButton = o.socialButton
		self.leftStickButton = o.leftStickButton
		self.xboxButton = o.centralButton
		self.rightStickButton = o.rightStickButton
		self.startButton = o.rightAuxiliaryButton
		self.yButton = o.faceNorthButton
		self.bButton = o.faceEastButton
		self.aButton = o.faceSouthButton
		self.xButton = o.faceWestButton
		self.rightShoulderButton = o.rightShoulderButton
		self.rightTriggerButton = o.rightTriggerButton

		objectWillChange.send()

	}

	@objc func updateAnalog(_ notification:Notification) {

		let o = notification.object as! GamepadAnalogChangedNotification

		self.leftTrigger = Float(o.leftTrigger)

		self.leftStickX = Float(o.leftStickX)
		self.leftStickY = Float(o.leftStickY)

		self.rightStickX = Float(o.rightStickX)
		self.rightStickY = Float(o.rightStickY)

		self.rightTrigger = Float(o.rightTrigger)

		objectWillChange.send()

	}

}
