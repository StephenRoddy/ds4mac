//
//  Dualshock4Controller.swift
//  GamePad
//
//  Created by Marco Luglio on 30/05/20.
//  Copyright © 2020 Marco Luglio. All rights reserved.
//

import Foundation



class DualShock4Controller {

	static let VENDOR_ID_SONY:Int64 = 0x054C // 1356
	static let CONTROLLER_ID_DUALSHOCK_4_USB:Int64 = 0x05C4 // 1476
	static let CONTROLLER_ID_DUALSHOCK_4_USB_V2:Int64 = 0x09CC // 2508, this controller has an led strip above the trackpad
	static let CONTROLLER_ID_DUALSHOCK_4_BLUETOOTH:Int64 = 0x081F //

	static var nextId:UInt8 = 0

	var id:UInt8 = 0

	let productID:Int64
	let transport:String

	let device:IOHIDDevice

	var isBluetooth = false
	var enableIMUReport = false

	/// Used for inertial measurement calculations (gyro and accel)

	var time:Date = Date()
	var previousTime:Date = Date()
	var timeInterval:TimeInterval = 0

	var reportTime:Int32 = 0
	var previousReportTime:Int32 = 0
	var reportTimeInterval:Int32 = 0

	/// contains triangle, circle, cross, square and directional pad buttons
	var mainButtons:UInt8 = 0
	var previousMainButtons:UInt8 = 0

	// top button
	var triangleButton = false
	var previousTriangleButton = false

	// right button
	var circleButton = false
	var previousCircleButton = false

	// bottom button
	var crossButton = false
	var previousCrossButton = false

	// left button
	var squareButton = false
	var previousSquareButton = false

	var directionalPad:UInt8 = 0
	var previousDirectionalPad:UInt8 = 0

	/// contains the shoulder buttons, triggers (digital input), thumbstick buttons, share and options buttons
	var secondaryButtons:UInt8 = 0
	var previousSecondaryButtons:UInt8 = 0

	// shoulder buttons
	var l1 = false
	var previousL1 = false
	var r1 = false
	var previousR1 = false
	/// digital reading for left trigger
	/// for the analog reading see leftTrigger
	var l2 = false
	var previousL2 = false
	/// digital reading for right trigger
	/// for the analog reading see rightTrigger
	var r2 = false
	var previousR2 = false

	// thumbstick buttons
	var l3 = false
	var previousL3 = false
	var r3 = false
	var previousR3 = false

	// other buttons

	var shareButton = false
	var previousShareButton = false
	var optionsButton = false
	var previousOptionsButton = false

	var psButton = false
	var previousPsButton = false

	// analog buttons

	var leftStickX:UInt8 = 0 // TODO transform to Int16 because of xbox? or do this in the notification?
	var previousLeftStickX:UInt8 = 0
	var leftStickY:UInt8 = 0
	var previousLeftStickY:UInt8 = 0
	var rightStickX:UInt8 = 0
	var previousRightStickX:UInt8 = 0
	var rightStickY:UInt8 = 0
	var previousRightStickY:UInt8 = 0

	var leftTrigger:UInt8 = 0
	var previousLeftTrigger:UInt8 = 0
	var rightTrigger:UInt8 = 0
	var previousRightTrigger:UInt8 = 0

	// touchpad

	var touchpadButton = false
	var previousTouchpadButton = false

	/*
	Touchpad resolution:

	The touch coordinates are stored in Int16, but are actually 12 bits only, which would give us a max possible value of 4096
	However, the actual resolution of the hardware is smaller than those values

	From https://www.psdevwiki.com/ps4/DualShock_4
	52mmx23mm (external approximately) with resolution: 
	CUH-ZCT1x series (Retail) 1920x943 (44.86 dots/mm)
	CAP-ZCT1x series (NonRetail) 1920x943
	JDX-1000x series (NonRetail) 1920x754
	*/

	var touchpadTouch0IsActive = false
	var previousTouchpadTouch0IsActive = false
	var touchpadTouch0Id:UInt8 = 0
	var previousTouchpadTouch0Id:UInt8 = 0
	var touchpadTouch0X:Int16 = 0
	var previousTouchpadTouch0X:Int16 = 0
	var touchpadTouch0Y:Int16 = 0
	var previousTouchpadTouch0Y:Int16 = 0

	var touchpadTouch1IsActive = false
	var previousTouchpadTouch1IsActive = false
	var touchpadTouch1Id:UInt8 = 0
	var previousTouchpadTouch1Id:UInt8 = 0
	var touchpadTouch1X:Int16 = 0
	var previousTouchpadTouch1X:Int16 = 0
	var touchpadTouch1Y:Int16 = 0
	var previousTouchpadTouch1Y:Int16 = 0

	// TODO create the other 3 touch samples

	// inertial measurement unit

	var gyroPitch:Int32 = 0
	var previousGyroPitch:Int32 = 0
	var gyroYaw:Int32 = 0
	var previousGyroYaw:Int32 = 0
	var gyroRoll:Int32 = 0
	var previousGyroRoll:Int32 = 0

	var accelX:Int32 = 0
	var previousAccelX:Int32 = 0
	var accelY:Int32 = 0
	var previousAccelY:Int32 = 0
	var accelZ:Int32 = 0
	var previousAccelZ:Int32 = 0

	//var rotationZ:Float32 = 0

	// battery

	var cableConnected = false
	var batteryCharging = false
	var batteryLevel:UInt8 = 0 // 0 to 9 on USB, 0 - 10 on Bluetooth
	var previousBatteryLevel:UInt8 = 0

	// misc

	var reportIterator:UInt8 = 0
	var previousReportIterator:UInt8 = 0

	init(_ device:IOHIDDevice, productID:Int64, transport:String, enableIMUReport:Bool) {

		self.id = DualShock4Controller.nextId
		DualShock4Controller.nextId = DualShock4Controller.nextId + 1

		self.transport = transport
		if self.transport == "Bluetooth" {
			self.isBluetooth = true
		}

		self.productID = productID
		self.device = device
		self.enableIMUReport = enableIMUReport

		IOHIDDeviceOpen(self.device, IOOptionBits(kIOHIDOptionsTypeNone)) // or kIOHIDManagerOptionUsePersistentProperties

		NotificationCenter.default
			.addObserver(
				self,
				selector: #selector(self.changeRumble),
				name: DualShock4ChangeRumbleNotification.Name,
				object: nil
			)

		NotificationCenter.default
			.addObserver(
				self,
				selector: #selector(self.changeLed),
				name: DualShock4ChangeLedNotification.Name,
				object: nil
			)

		if self.enableIMUReport {
			self.requestCalibrationDataReport()
		}

		/*
		Sony "official" driver maintained by Sony employee:
		https://github.com/torvalds/linux/blob/master/drivers/hid/hid-sony.c


		Structure HID transaction (portion)

		Input and output reports specify control data and feature reports specify configuration data.

		Data Format

		|----------|-----|-----|-----|-----|-----|-----|-----|-------|
		|byte index|bit 7|bit 6|bit 5|bit 4|bit 3|bit 2|bit 1|bit 0  |
		|----------|-----|-----|-----|-----|-----|-----|-----|-------|
		|[0]       |transaction type:      |parameters:|report type: |
		|          |                       |           |             |
		|          |0x04: GET REPORT       |0x00       |0x01: input  |
		|          |0x05: SET REPORT       |0x01       |0x02: output |
		|          |0x0A: DATA             |0x02       |0x03: feature|
		|----------|-----|-----|-----|-----|-----|-----|-----|-------|

		*/

	}

	// MARK: - Input reports

	/*public private(set) var gyroZ:Float32 {

		get {
			return self._gyroZ
		}

		set(newValue) {

			var newGyroZ = newValue

			if newGyroZ > 128 {
				newGyroZ = newGyroZ - 255
			}
			//newGyroZ /= 64.0 // according to joyshock, unit is radians / second when divided by 64, need the timestamp

			self._gyroZ = newGyroZ
			self.rotationZ += self._gyroZ
		}

	}*/

	/// Gets called by GamePadMonitor
	func parseReport(_ report:Data) {

		self.previousTime = self.time
		self.time = Date()
		self.timeInterval = self.time.timeIntervalSince(self.previousTime) * 1_000_000

		let bluetoothOffset = self.isBluetooth ? 2 : 0

		self.mainButtons = report[5 + bluetoothOffset]

		self.triangleButton = self.mainButtons & 0b10000000 == 0b10000000
		self.circleButton   = self.mainButtons & 0b01000000 == 0b01000000
		self.squareButton   = self.mainButtons & 0b00010000 == 0b00010000
		self.crossButton    = self.mainButtons & 0b00100000 == 0b00100000

		self.directionalPad = self.mainButtons & 0b00001111
		/*
		self.upButton: (self.directionalPad == 0 || self.directionalPad == 1 || self.directionalPad == 7),
		self.rightButton: (self.directionalPad == 2 || self.directionalPad == 1 || self.directionalPad == 3),
		self.downButton: (self.directionalPad == 4 || self.directionalPad == 3 || self.directionalPad == 5),
		self.leftButton: (self.directionalPad == 6 || self.directionalPad == 5 || self.directionalPad == 7),
		*/

		self.secondaryButtons = report[6 + bluetoothOffset]

		self.l1            = self.secondaryButtons & 0b00000001 == 0b00000001
		self.r1            = self.secondaryButtons & 0b00000010 == 0b00000010
		self.l2            = self.secondaryButtons & 0b00000100 == 0b00000100
		self.r2            = self.secondaryButtons & 0b00001000 == 0b00001000

		self.l3            = self.secondaryButtons & 0b01000000 == 0b01000000
		self.r3            = self.secondaryButtons & 0b10000000 == 0b10000000

		self.shareButton   = self.secondaryButtons & 0b00010000 == 0b00010000
		self.optionsButton = self.secondaryButtons & 0b00100000 == 0b00100000

		self.psButton = report[7 + bluetoothOffset] & 0b00000001 == 0b00000001

		self.reportIterator = report[7 + bluetoothOffset] >> 2 // [7] 	Counter (counts up by 1 per report), I guess this is only relevant to bluetooth

		if self.previousMainButtons != self.mainButtons
			|| self.previousSecondaryButtons != self.secondaryButtons
			|| self.previousPsButton != self.psButton
			|| self.previousTouchpadButton != self.touchpadButton
		{

			DispatchQueue.main.async {
				NotificationCenter.default.post(
					name: GamepadButtonChangedNotification.Name,
					object: GamepadButtonChangedNotification(
						leftTriggerButton: self.l2,
						leftShoulderButton: self.l1,
						minusButton:false,
						leftSideTopButton:false,
						leftSideBottomButton:false,
						upButton: (self.directionalPad == 0 || self.directionalPad == 1 || self.directionalPad == 7),
						rightButton: (self.directionalPad == 2 || self.directionalPad == 1 || self.directionalPad == 3),
						downButton: (self.directionalPad == 4 || self.directionalPad == 3 || self.directionalPad == 5),
						leftButton: (self.directionalPad == 6 || self.directionalPad == 5 || self.directionalPad == 7),
						socialButton: self.shareButton,
						leftStickButton: self.l3,
						trackPadButton: self.touchpadButton,
						centralButton: self.psButton,
						rightStickButton: self.r3,
						rightAuxiliaryButton: self.optionsButton,
						faceNorthButton: self.triangleButton,
						faceEastButton: self.circleButton,
						faceSouthButton: self.crossButton,
						faceWestButton: self.squareButton,
						rightSideBottomButton:false,
						rightSideTopButton:false,
						plusButton:false,
						rightShoulderButton: self.r1,
						rightTriggerButton: self.r2
					)
				)
			}

			self.previousMainButtons = self.mainButtons

			self.previousSquareButton = self.squareButton
			self.previousCrossButton = self.crossButton
			self.previousCircleButton = self.circleButton
			self.previousTriangleButton = self.triangleButton

			self.previousDirectionalPad = self.directionalPad

			self.previousSecondaryButtons = self.secondaryButtons

			self.previousL1 = self.l1
			self.previousR1 = self.r1
			self.previousL2 = self.l2
			self.previousR2 = self.r2
			self.previousL3 = self.l3
			self.previousR3 = self.r3

			self.previousShareButton = self.shareButton
			self.previousOptionsButton = self.optionsButton

			self.previousPsButton = self.psButton
			self.previousTouchpadButton = self.touchpadButton

		}

		if report.count < 11 {
			return
		}

		// analog buttons
		// origin left top
		self.leftStickX = report[1 + bluetoothOffset] // 0 left
		self.leftStickY = report[2 + bluetoothOffset] // 0 up
		self.rightStickX = report[3 + bluetoothOffset]
		self.rightStickY = report[4 + bluetoothOffset]
		self.leftTrigger = report[8 + bluetoothOffset] // 0 - 255
		self.rightTrigger = report[9 + bluetoothOffset] // 0 - 255

		if self.previousLeftStickX != self.leftStickX
			|| self.previousLeftStickY != self.leftStickY
			|| self.previousRightStickX != self.rightStickX
			|| self.previousRightStickY != self.rightStickY
			|| self.previousLeftTrigger != self.leftTrigger
			|| self.previousRightTrigger != self.rightTrigger
		{

			DispatchQueue.main.async {
				NotificationCenter.default.post(
					name: GamepadAnalogChangedNotification.Name,
					object: GamepadAnalogChangedNotification(
						leftStickX: Int16(self.leftStickX),
						leftStickY: Int16(self.leftStickY),
						rightStickX: Int16(self.rightStickX),
						rightStickY: Int16(self.rightStickY),
						leftTrigger: self.leftTrigger,
						rightTrigger: self.rightTrigger
					)
				)
			}

			self.previousLeftStickX = self.leftStickX
			self.previousLeftStickY = self.leftStickY
			self.previousRightStickX = self.rightStickX
			self.previousRightStickY = self.rightStickY
			self.previousLeftTrigger = self.leftTrigger
			self.previousRightTrigger = self.rightTrigger

		}

		// trackpad

		self.touchpadButton = report[7 + bluetoothOffset] & 0b00000010 == 0b00000010

		self.previousReportTime = self.reportTime
		self.reportTime = Int32(report[11 + bluetoothOffset]) << 8 | Int32(report[10 + bluetoothOffset]) // this is little endian
		self.reportTimeInterval = self.reportTime - self.previousReportTime
		if self.reportTimeInterval < 0 {
			self.reportTimeInterval += UINT16_MAX
		}

		/*

		trackpad can send up to 4 packets per report
		it is sampled at a higher frequency

		The Dualshock 4 multi-touch trackpad data starts at offset 33 on USB
		and 35 on Bluetooth.
		The first byte indicates the number of touch data in the report.
		Trackpad data starts 2 bytes later (e.g. 35 for USB).

		*/

		let numberOfPackets = report[33 + bluetoothOffset] // 1 to 4

		// report[34 + bluetoothOffset] // packet counter??

		self.touchpadTouch0IsActive = report[35 + bluetoothOffset] & 0b10000000 != 0b10000000

		if self.touchpadTouch0IsActive {
			self.touchpadTouch0Id = report[35 + bluetoothOffset] & 0b01111111
			 // 12 bits only
			self.touchpadTouch0X = Int16((UInt16(report[37 + bluetoothOffset]) << 8 | UInt16(report[36 + bluetoothOffset]))      & 0b0000_1111_1111_1111)
			self.touchpadTouch0Y = Int16((UInt16(report[38 + bluetoothOffset]) << 4 | UInt16(report[37 + bluetoothOffset]) >> 4) & 0b0000_1111_1111_1111)
		}

		self.touchpadTouch1IsActive = report[39 + bluetoothOffset] & 0b10000000 != 0b10000000 // if not active, no need to parse the rest

		if self.touchpadTouch1IsActive {
			self.touchpadTouch1Id = report[39 + bluetoothOffset] & 0b01111111
			// 12 bits only
			self.touchpadTouch1X = Int16((UInt16(report[41 + bluetoothOffset]) << 8 | UInt16(report[40 + bluetoothOffset]))      & 0b0000_1111_1111_1111)
			self.touchpadTouch1Y = Int16((UInt16(report[42 + bluetoothOffset]) << 4 | UInt16(report[41 + bluetoothOffset]) >> 4) & 0b0000_1111_1111_1111)
		}

		/*
		to move mouse

		import core graphics I guess
		func CGDisplayMoveCursorToPoint(_ display: CGDirectDisplayID, _ point: CGPoint) -> CGError
		The coordinates of a point in local display space. The origin is the upper-left corner of the specified display.
		func CGMainDisplayID() -> CGDirectDisplayID

		for multiple monitors, check finding displays https://developer.apple.com/documentation/coregraphics/quartz_display_services#1655882
		*/

		if self.previousTouchpadTouch0IsActive != self.touchpadTouch0IsActive
			|| self.previousTouchpadTouch0Id != self.touchpadTouch0Id
			|| self.previousTouchpadTouch0X != self.touchpadTouch0X
			|| self.previousTouchpadTouch0Y != self.touchpadTouch0Y
			|| self.previousTouchpadTouch1IsActive != self.touchpadTouch1IsActive
			|| self.previousTouchpadTouch1Id != self.touchpadTouch1Id
			|| self.previousTouchpadTouch1X != self.touchpadTouch1X
			|| self.previousTouchpadTouch1Y != self.touchpadTouch1Y
		{

			DispatchQueue.main.async {
				NotificationCenter.default.post(
					name: DualShock4TouchpadChangedNotification.Name,
					object: DualShock4TouchpadChangedNotification(
						touchpadTouch0IsActive: self.touchpadTouch0IsActive,
						touchpadTouch0Id: self.touchpadTouch0Id,
						touchpadTouch0X: self.touchpadTouch0X,
						touchpadTouch0Y: self.touchpadTouch0Y,
						touchpadTouch1IsActive: self.touchpadTouch1IsActive,
						touchpadTouch1Id: self.touchpadTouch1Id,
						touchpadTouch1X: self.touchpadTouch1X,
						touchpadTouch1Y: self.touchpadTouch1Y
					)
				)
			}

			self.previousTouchpadTouch0IsActive = self.touchpadTouch0IsActive
			self.previousTouchpadTouch0Id = self.touchpadTouch0Id
			self.previousTouchpadTouch0X = self.touchpadTouch0X
			self.previousTouchpadTouch0Y = self.touchpadTouch0Y
			self.previousTouchpadTouch1IsActive = self.touchpadTouch1IsActive
			self.previousTouchpadTouch1Id = self.touchpadTouch1Id
			self.previousTouchpadTouch1X = self.touchpadTouch1X
			self.previousTouchpadTouch1Y = self.touchpadTouch1Y

		}

		// TODO IMU

		/*
		linux driver uses Default to 4ms poll interval, which is same as USB (not adjustable).
		#define DS4_BT_DEFAULT_POLL_INTERVAL_MS 4
		#define DS4_BT_MAX_POLL_INTERVAL_MS 62




		static void dualshock4_send_output_report(struct sony_sc *sc)
		{
			struct hid_device *hdev = sc->hdev;
			u8 *buf = sc->output_report_dmabuf;
			int offset;

			/*
			 * NOTE: The lower 6 bits of buf[1] field of the Bluetooth report
			 * control the interval at which Dualshock 4 reports data:
			 * 0x00 - 1ms
			 * 0x01 - 1ms
			 * 0x02 - 2ms
			 * 0x3E - 62ms
			 * 0x3F - disabled
			 */
			if (sc->quirks & (DUALSHOCK4_CONTROLLER_USB | DUALSHOCK4_DONGLE)) {
				memset(buf, 0, DS4_OUTPUT_REPORT_0x05_SIZE);
				buf[0] = 0x05;
				buf[1] = 0x07; /* blink + LEDs + motor */
				offset = 4;
			} else {
				memset(buf, 0, DS4_OUTPUT_REPORT_0x11_SIZE);
				buf[0] = 0x11;
				buf[1] = 0xC0 /* HID + CRC */ | sc->ds4_bt_poll_interval;
				buf[3] = 0x07; /* blink + LEDs + motor */
				offset = 6;
			}

		#ifdef CONFIG_SONY_FF
			buf[offset++] = sc->right;
			buf[offset++] = sc->left;
		#else
			offset += 2;
		#endif

			/* LED 3 is the global control */
			if (sc->led_state[3]) {
				buf[offset++] = sc->led_state[0];
				buf[offset++] = sc->led_state[1];
				buf[offset++] = sc->led_state[2];
			} else {
				offset += 3;
			}

			/* If both delay values are zero the DualShock 4 disables blinking. */
			buf[offset++] = sc->led_delay_on[3];
			buf[offset++] = sc->led_delay_off[3];

			if (sc->quirks & (DUALSHOCK4_CONTROLLER_USB | DUALSHOCK4_DONGLE))
				hid_hw_output_report(hdev, buf, DS4_OUTPUT_REPORT_0x05_SIZE);
			else {
				/* CRC generation */
				u8 bthdr = 0xA2;
				u32 crc;

				crc = crc32_le(0xFFFFFFFF, &bthdr, 1);
				crc = ~crc32_le(crc, buf, DS4_OUTPUT_REPORT_0x11_SIZE-4);
				put_unaligned_le32(crc, &buf[74]);
				hid_hw_output_report(hdev, buf, DS4_OUTPUT_REPORT_0x11_SIZE);
			}
		}

		*/

		self.gyroPitch = Int32(report[14 + bluetoothOffset]) << 8 | Int32(report[13 + bluetoothOffset])
		self.gyroYaw =   Int32(report[16 + bluetoothOffset]) << 8 | Int32(report[15 + bluetoothOffset])
		self.gyroRoll =  Int32(report[18 + bluetoothOffset]) << 8 | Int32(report[17 + bluetoothOffset])


		self.accelX = Int32(report[20 + bluetoothOffset]) << 8 | Int32(report[19 + bluetoothOffset]) // changes when we roll
		self.accelY = Int32(report[22 + bluetoothOffset]) << 8 | Int32(report[21 + bluetoothOffset]) // changes when we pitch or roll
		self.accelZ = Int32(report[24 + bluetoothOffset]) << 8 | Int32(report[23 + bluetoothOffset]) // changes when we pitch

		/*self.applyCalibration(
			pitch: &self.gyroPitch,
			yaw: &self.gyroYaw,
			roll: &self.gyroRoll,
			accelX: &self.accelX,
			accelY: &self.accelY,
			accelZ: &self.accelZ
		)*/

		if self.previousGyroPitch != self.gyroPitch
			|| self.previousGyroYaw != self.gyroYaw
			|| self.previousGyroRoll != self.gyroRoll
			|| self.previousAccelX != self.accelX
			|| self.previousAccelY != self.accelY
			|| self.previousAccelZ != self.accelZ
		{

			self.previousGyroPitch = self.gyroPitch
			self.previousGyroYaw   = self.gyroYaw
			self.previousGyroRoll  = self.gyroRoll

			self.previousAccelX = self.accelX
			self.previousAccelY = self.accelY
			self.previousAccelZ = self.accelZ

			DispatchQueue.main.async {
				NotificationCenter.default.post(
					name: GamepadIMUChangedNotification.Name,
					object: GamepadIMUChangedNotification(
						gyroPitch: self.gyroPitch,
						gyroYaw: self.gyroYaw,
						gyroRoll: self.gyroRoll,
						accelX: self.accelX,
						accelY: self.accelY,
						accelZ: self.accelZ
					)
				)
			}

		}

		// battery

		let timestamp = UInt32(report[11 + bluetoothOffset]) << 8 | UInt32(report[10 + bluetoothOffset])
		let timestampUS = (timestamp * 16) / 3

		self.cableConnected = ((report[30 + bluetoothOffset] >> 4) & 0b00000001) == 1
		self.batteryLevel = report[30 + bluetoothOffset] & 0b00001111

		if !self.cableConnected || self.batteryLevel > 10 {
			self.batteryCharging = false
		} else {
			self.batteryCharging = true
		}

		// on usb battery ranges from 0 to 10, but on bluetooth the range is 0 to 9
		if !self.cableConnected && self.batteryLevel < 10  {
			self.batteryLevel += 1
		}

		if self.cableConnected && self.batteryLevel > 10  {
			self.batteryLevel = 10
		}

		if self.previousBatteryLevel != self.batteryLevel {

			self.previousBatteryLevel = self.batteryLevel

			DispatchQueue.main.async {
				NotificationCenter.default.post(
					name: GamepadBatteryChangedNotification.Name,
					object: GamepadBatteryChangedNotification(
						battery: self.batteryLevel,
						batteryMin: 0,
						batteryMax: 10,
						isConnected: self.cableConnected,
						isCharging: self.batteryCharging
					)
				)
			}

		}

		/*
		[30] 	EXT/HeadSet/Earset: bitmask // 32??

		01111011 is headset with mic (0x7B)
		00111011 is headphones (0x3B)
		00011011 is nothing attached (0x1B)
		00001000 is bluetooth? (0x08)
		00000101 is ? (0x05)
		*/

		//self.sendReport()

	}

	// MARK: - Output reports

	@objc func changeRumble(_ notification:Notification) {

		let o = notification.object as! DualShock4ChangeRumbleNotification

		sendReport(
			leftHeavySlowRumble: o.leftHeavySlowRumble,
			rightLightFastRumble: o.rightLightFastRumble,
			red: 0,
			green: 0,
			blue: 255
		)

	}

	@objc func changeLed(_ notification:Notification) {

		let o = notification.object as! DualShock4ChangeLedNotification

		sendReport(
			leftHeavySlowRumble: 0,
			rightLightFastRumble: 0,
			red: UInt8(o.red * 255),
			green: UInt8(o.green * 255),
			blue: UInt8(o.blue * 255)
		)

	}

	/// How to document parameters?
	/// - Parameter leftHeavySlowRumble: Intensity of the heavy motor
	/// - Parameter rightLightFastRumble: Intensity of the light motor
	/// - Parameter red: Red component of the controller led
	/// - Parameter green: Green component of the controller led
	/// - Parameter blue: Blue component of the controller led
	/// - Parameter flashOn: Duration in a cycle which the led remains on
	/// - Parameter flashOff: Duration in a cycle which the led remains off
	func sendReport(leftHeavySlowRumble:UInt8, rightLightFastRumble:UInt8, red:UInt8, green:UInt8, blue:UInt8, flashOn:UInt8 = 0, flashOff:UInt8 = 0) {

		// let toggleMotor:UInt8 = 0xf0 // 0xf0 disable 0xf3 enable or 0b00001111 // enable unknown, flash, color, rumble

		// let flashOn:UInt8 = 0x00 // flash on duration (in what units??)
		// let flashOff:UInt8 = 0x00 // flash off duration (in what units??)

		let bluetoothOffset = self.isBluetooth ? 2 : 0

		var dualshock4ControllerOutputReport:[UInt8]

		if self.isBluetooth {
			// TODO check this with docs and other projects
			dualshock4ControllerOutputReport = [UInt8](repeating: 0, count: 74)
			dualshock4ControllerOutputReport[0] = 0x15 // 0x11
			dualshock4ControllerOutputReport[1] = 0x0 //(0xC0 | btPollRate) // (0x80 | btPollRate) // input report rate // FIXME check this
			// enable rumble (0x01), lightbar (0x02), flash (0x04) // TODO check this too
			dualshock4ControllerOutputReport[2] = 0xA0
		} else {
			dualshock4ControllerOutputReport = [UInt8](repeating: 0, count: 11)
			dualshock4ControllerOutputReport[0] = 0x05
		}


		// enable rumble (0x01), lightbar (0x02), flash (0x04) 0b00000111
		dualshock4ControllerOutputReport[1 + bluetoothOffset] = 0xf7 // 0b11110111
		dualshock4ControllerOutputReport[2 + bluetoothOffset] = 0x04
		dualshock4ControllerOutputReport[4 + bluetoothOffset] = rightLightFastRumble
		dualshock4ControllerOutputReport[5 + bluetoothOffset] = leftHeavySlowRumble
		dualshock4ControllerOutputReport[6 + bluetoothOffset] = red
		dualshock4ControllerOutputReport[7 + bluetoothOffset] = green
		dualshock4ControllerOutputReport[8 + bluetoothOffset] = blue
		dualshock4ControllerOutputReport[9 + bluetoothOffset] = flashOn
		dualshock4ControllerOutputReport[10 + bluetoothOffset] = flashOff

		if self.isBluetooth {
			// TODO calculate CRC32 here
			/*let dualshock4ControllerInputReportBluetoothCRC = CRC32.checksum(bytes: dualshock4ControllerInputReportBluetooth)
			dualshock4ControllerInputReportBluetooth.append(contentsOf: dualshock4ControllerInputReportBluetoothCRC)*/
		}

		// print("size of report: \(dualshock4ControllerOutputReport.count)")

		IOHIDDeviceSetReport(
			device,
			kIOHIDReportTypeOutput,
			0x01, // report id
			dualshock4ControllerOutputReport,
			dualshock4ControllerOutputReport.count
		)

	}

	// MARK: - Gryroscope calibration

	/*
	DualShock 4 uses Bosch bmi055 imu:
	https://www.bosch-sensortec.com/products/motion-sensors/imus/bmi055.html
	driver pages:
	https://github.com/BoschSensortec/BMG160_driver
	https://github.com/BoschSensortec/BMA2x2_driver (mentions bmi055 is a combination of bma2x2 + bmg160)

	Digital resolution
	------------------
	Accelerometer (A): 12 bit
	Gyroscope (G): 16bit


	Resolution
	----------
	(A): 0,98 mg (milli Gs) so G / 10000
	(G): 0.004°/s


	Measurement ranges (programmable)
	---------------------------------
	(A): ± 2 g, ± 4 g, ± 8 g, ± 16 g
	(G): ± 125°/s, ± 250°/s, ± 500°/s, ± 1000°/s, ± 2000°/s


	Sensitivity (calibrated)
	------------------------

	LSB = least significant bit

	(A):
	± 2 g 1024 LSB/g
	± 4 g 512 LSB/g
	± 8 g 256 LSB/g
	± 16 g 128 LSB/g

	(G):
	± 125°/s 262.4 LSB/°/s
	± 250°/s: 131.2 LSB/°/s
	± 500°/s: 65.6 LSB/°/s
	± 1000°/s: 32.8 LSB/°/s
	± 2000°/s: 16.4 LSB/°/s


	Zero offset (typ., over life-time)
	----------------------------------
	(A): ± 70mg
	(G): ± 1°/s


	Noise density (typ.)
	--------------------
	(A): 150μg/√Hz
	(G): 0.014 °/s/√Hz


	Bandwidths (programmable)
	-------------------------
	1000Hz … 8 Hz


	Temperature range
	-----------------
	-40 … +85°C


	FIFO data buffer
	----------------
	(A) 32 samples depth /
	(G) 100 samples
	(each axis)


	Shock resistance
	----------------
	10,000 g x 200 μs



	mg = milli Gs (just like milli liters)
	1mG = 0.001 G's of acceleration, so 1000mG = 1G
	LSB = Least Significant bit, which is the last bit on the right (for little endian)
	The raw values from the accelerometer are  multiplied by the sensitive level to get the value in G
	If the range is ±2, this would be a total of 4g. Or 4,000 milli Gs
	The output is 12 bits. 12 bits equals 8192.
	This means we can get 8192 different readings for the range between -2 and +2. (or -2,000 milli Gs and +2,000 milli Gs)
	4,000 MilliGs / 8192 = 0.48828125
	Each time the LSB changes by one, the value changes by 0.48828125

	However, the spec sheet for the sensor mentions LSB is 1024 for ±2G so???


	PSMoveService uses raw - drift * scale + offset or raw * gain + bias


	*/

	/// Max G value (±2 to ±16 G) uses 12 bits
	static let ACC_DIGITAL_RESOLUTION:Int32 = 8192

	/// Max °/s uses 16 bits
	static let GYRO_RES_IN_DEG_SEC:Int32 = 16 // means 1 degree/second is 16 (4 bits) 0b0000 ??

	func requestCalibrationDataReport() {

		/*
		* The default behavior of the Dualshock 4 is to send reports using
		* report type 1 when running over Bluetooth. However, when feature
		* report 2 is requested during the controller initialization it starts
		* sending input reports in report 17. Since report 17 is undefined
		* in the default HID descriptor, the HID layer won't generate events.
		* While it is possible (and this was done before) to fixup the HID
		* descriptor to add this mapping, it was better to do this manually.
		* The reason is there were various pieces software both open and closed
		* source, relying on the descriptors to be the same across various
		* operating systems. If the descriptors wouldn't match some
		* applications e.g. games on Wine would not be able to function due
		* to different descriptors, which such applications are not parsing.
		*/

		var dualshock4CalibrationDataReport = [UInt8](repeating: 0, count: 41)
		var dualshock4CalibrationDataReportLength = dualshock4CalibrationDataReport.count

		let dualshock4CalibrationDataReportPointer = UnsafeMutablePointer(mutating: dualshock4CalibrationDataReport)
		let dualshock4CalibrationDataReportLengthPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
		dualshock4CalibrationDataReportLengthPointer.pointee = dualshock4CalibrationDataReportLength

		IOHIDDeviceGetReport(
			device,
			kIOHIDReportTypeFeature,
			self.isBluetooth ? 0x05 : 0x02, // TODO test bluetooth
			dualshock4CalibrationDataReportPointer,
			dualshock4CalibrationDataReportLengthPointer
		)

		// TODO validar CRC aqui

		self.parseCalibrationFeatureReport(calibrationReport: &dualshock4CalibrationDataReport, fromUSB: self.isBluetooth)

		/*
		// for reference:
		[0] 5 // report type
		[1] 251
		[2] 255
		[3] 252
		[4] 255
		[5] 255
		[6] 255
		[7] 157
		[8] 33
		[9] 165
		[10] 34
		[11] 102
		[12] 36
		[13] 94
		[14] 222
		[15] 91
		[16] 221
		[17] 143
		[18] 219
		[19] 28
		[20] 2
		[21] 28
		[22] 2
		[23] 87
		[24] 31
		[25] 169
		[26] 224
		[27] 218
		[28] 32
		[29] 38
		[30] 223
		[31] 207
		[32] 31
		[33] 49
		[34] 224
		[35] 6
		[36] 0
		[37] 212 crc32
		[38] 77  crc32
		[39] 82  crc32
		[40] 113 crc32
		*/

	}

	func parseCalibrationFeatureReport(calibrationReport:inout [UInt8], fromUSB:Bool) {

		// gyroscopes

		var pitchPlus:Int32 = 0
		var pitchMinus:Int32 = 0
		var yawPlus:Int32 = 0
		var yawMinus:Int32 = 0
		var rollPlus:Int32 = 0
		var rollMinus:Int32 = 0

		if !fromUSB {

			pitchPlus  = Int32(calibrationReport[8]  << 8) | Int32(calibrationReport[7])
			yawPlus    = Int32(calibrationReport[10] << 8) | Int32(calibrationReport[9])
			rollPlus   = Int32(calibrationReport[12] << 8) | Int32(calibrationReport[11])
			pitchMinus = Int32(calibrationReport[14] << 8) | Int32(calibrationReport[13])
			yawMinus   = Int32(calibrationReport[16] << 8) | Int32(calibrationReport[15])
			rollMinus  = Int32(calibrationReport[18] << 8) | Int32(calibrationReport[17])

		} else {

			pitchPlus  = Int32(calibrationReport[8]  << 8) | Int32(calibrationReport[7])
			pitchMinus = Int32(calibrationReport[10] << 8) | Int32(calibrationReport[9])
			yawPlus    = Int32(calibrationReport[12] << 8) | Int32(calibrationReport[11])
			yawMinus   = Int32(calibrationReport[14] << 8) | Int32(calibrationReport[13])
			rollPlus   = Int32(calibrationReport[16] << 8) | Int32(calibrationReport[15])
			rollMinus  = Int32(calibrationReport[18] << 8) | Int32(calibrationReport[17])

		}

		self.calibration[Calibration.GyroPitchIndex].rawPositive1GValue  = pitchPlus
		self.calibration[Calibration.GyroPitchIndex].rawNegative1GValue = pitchMinus

		// TODO is this inverted? Or are all values inverted? This is the only where the plus values is bigger than the minus value
		self.calibration[Calibration.GyroYawIndex].rawPositive1GValue    = yawPlus
		self.calibration[Calibration.GyroYawIndex].rawNegative1GValue   = yawMinus

		self.calibration[Calibration.GyroRollIndex].rawPositive1GValue   = rollPlus
		self.calibration[Calibration.GyroRollIndex].rawNegative1GValue  = rollMinus

		self.calibration[Calibration.GyroPitchIndex].gyroBias = Int32(calibrationReport[2] << 8) | Int32(calibrationReport[1])
		self.calibration[Calibration.GyroYawIndex].gyroBias   = Int32(calibrationReport[4] << 8) | Int32(calibrationReport[3])
		self.calibration[Calibration.GyroRollIndex].gyroBias  = Int32(calibrationReport[6] << 8) | Int32(calibrationReport[5])

		self.gyroSpeedPlus  = Int32(calibrationReport[20] << 8) | Int32(calibrationReport[19])
		self.gyroSpeedMinus = Int32(calibrationReport[22] << 8) | Int32(calibrationReport[21])

		// accelerometers

		// TODO is this inverted? plus x is smaller than minus x
		let accelXPlus  = Int32(calibrationReport[24] << 8) | Int32(calibrationReport[23])
		let accelXMinus = Int32(calibrationReport[26] << 8) | Int32(calibrationReport[25])

		let accelYPlus  = Int32(calibrationReport[28] << 8) | Int32(calibrationReport[27])
		let accelYMinus = Int32(calibrationReport[30] << 8) | Int32(calibrationReport[29])

		let accelZPlus  = Int32(calibrationReport[32] << 8) | Int32(calibrationReport[31])
		let accelZMinus = Int32(calibrationReport[34] << 8) | Int32(calibrationReport[33])

		self.calibration[Calibration.AccelXIndex].rawPositive1GValue  = accelXPlus
		self.calibration[Calibration.AccelXIndex].rawNegative1GValue = accelXMinus

		self.calibration[Calibration.AccelYIndex].rawPositive1GValue  = accelYPlus
		self.calibration[Calibration.AccelYIndex].rawNegative1GValue = accelYMinus

		self.calibration[Calibration.AccelZIndex].rawPositive1GValue  = accelZPlus
		self.calibration[Calibration.AccelZIndex].rawNegative1GValue = accelZMinus

	}

	func applyCalibration(
		pitch:inout Int32, yaw:inout Int32, roll:inout Int32,
		accelX:inout Int32, accelY:inout Int32, accelZ:inout Int32
	) {

		pitch = DualShock4Controller.applyGyroCalibration(
			pitch,
			self.calibration[Calibration.GyroPitchIndex].gyroBias!,
			self.gyroSpeed2x,
			// sensorResolution: DualShock4Controller.GYRO_RES_IN_DEG_SEC
			sensorRange: self.calibration[Calibration.GyroPitchIndex].rawPositive1GValue! - self.calibration[Calibration.GyroPitchIndex].rawNegative1GValue!
		)

		yaw = DualShock4Controller.applyGyroCalibration(
			yaw,
			self.calibration[Calibration.GyroYawIndex].gyroBias!,
			self.gyroSpeed2x,
			sensorRange: self.calibration[Calibration.GyroYawIndex].rawPositive1GValue! - self.calibration[Calibration.GyroYawIndex].rawNegative1GValue!
		)

		roll = DualShock4Controller.applyGyroCalibration(
			roll,
			self.calibration[Calibration.GyroRollIndex].gyroBias!,
			self.gyroSpeed2x,
			sensorRange: self.calibration[Calibration.GyroRollIndex].rawPositive1GValue! - self.calibration[Calibration.GyroRollIndex].rawNegative1GValue!
		)

		accelX = DualShock4Controller.applyAccelCalibration(
			accelX,
			sensorRawPositive1GValue: self.calibration[Calibration.AccelXIndex].rawPositive1GValue!,
			sensorRawNegative1GValue: self.calibration[Calibration.AccelXIndex].rawNegative1GValue!
			// sensorResolution: DualShock4Controller.ACC_DIGITAL_RESOLUTION
		)

		accelY = DualShock4Controller.applyAccelCalibration(
			accelY,
			sensorRawPositive1GValue: self.calibration[Calibration.AccelYIndex].rawPositive1GValue!,
			sensorRawNegative1GValue: self.calibration[Calibration.AccelYIndex].rawNegative1GValue!
		)

		accelZ = DualShock4Controller.applyAccelCalibration(
			accelZ,
			sensorRawPositive1GValue: self.calibration[Calibration.AccelZIndex].rawPositive1GValue!,
			sensorRawNegative1GValue: self.calibration[Calibration.AccelZIndex].rawNegative1GValue!
		)

	}

	static func applyGyroCalibration(_ sensorRawValue:Int32, _ sensorBias:Int32, _ gyroSpeed2x:Int32, sensorRange:Int32) -> Int32 {

		/*

		From PSMove: https://github.com/psmoveservice/psmoveapi/blob/master/src/psmove_calibration.c

		Calculation of gyroscope mapping (in radians per second):

		               raw
		calibrated = -------- * 2 PI
		              rpm60

		         60 * rpm80
		rpm60 = ------------
		             80

		with:
		raw ..... Raw sensor reading
		rpm80 ... Sensor reading at 80 RPM (from calibration blob)
		rpm60 ... Sensor reading at 60 RPM (1 rotation per second)

		Or combined:
		              80 * raw * 2 PI
		calibrated = -----------------
		                60 * rpm80

		Now define:
		     2 * PI * 80
		f = -------------
		      60 * rpm80

		then we get:
		calibrated = f * raw



		// The calibration stores 6 gyroscope readings when the controller is spun at 90RPM
		// on the +X, +Y, +Z, -X, -Y, and -Z axis (bluetooth).

		// There is also one vector containing drift compensation values.
		// When the controller is sitting still each axis will report a small constant non-zero value.
		// Subtracting these drift values per-frame will give more accurate gyro readings.

		const float k_rpm_to_rad_per_sec = (2.0f * k_real_pi) / 60.0f;
		const float k_calibration_rpm= 90.f;
		const float y_hi= k_calibration_rpm * k_rpm_to_rad_per_sec;
		const float y_low= -k_calibration_rpm * k_rpm_to_rad_per_sec;
		std::vector< std::vector<int> > gyro_dim_lohi = { {3, 0}, {4, 1}, {5, 2} };
        for (int dim_ix = 0; dim_ix < 3; dim_ix++)
        {
			// Read the low and high values for each axis
			std::vector<short> res_lohi(2, 0);
            for (int lohi_ix = 0; lohi_ix < 2; lohi_ix++)
            {
                res_lohi[lohi_ix] = decode16bitSigned(usb_calibration, 0x30 + 6*gyro_dim_lohi[dim_ix][lohi_ix] + 2*dim_ix);
            }
			short raw_gyro_drift= decode16bitSigned(usb_calibration, 0x26 + 2*dim_ix);

			// Compute the gain value (the slope of the gyro reading/angular speed line)
			const float x_low = res_lohi[0];
			const float x_hi = res_lohi[1];
			const float m = (y_hi - y_low) / (x_hi - x_low);
            cfg.cal_ag_xyz_kbd[1][dim_ix][0] = m;

            // Use zero bias value.
			// Given the slightly asymmetrical min and max 90RPM readings you might think
			// that there is a bias in the gyros that you should compute by finding
			// the y-intercept value (the y-intercept of the gyro reading/angular speed line)
			// using the formula b= y_hi - m * x_hi, but this results in pretty bad
			// controller drift. We get much better results ignoring the y-intercept
			// and instead use the presumed "drift" values stored at 0x26
			cfg.cal_ag_xyz_kbd[1][dim_ix][1] = 0.f;

			// Store off the drift value
			cfg.cal_ag_xyz_kbd[1][dim_ix][2] = raw_gyro_drift;

			// The final result:
			// rad/s = (raw_gyro_value-drift) * gain + bias

		*/

		var calibratedValue:Int32 = 0 // TODO not sure why I would need this to be an integer

		// plus and minus values are symmetrical, so bias is also 0
		if sensorRange == 0 {
			calibratedValue = Int32(sensorRawValue * gyroSpeed2x)
			return calibratedValue
		}

		// breaking up expression because swift compiler complains...
		let sensorRawOffset = Int32(sensorRawValue - sensorBias)
		let gyroSpeed2x32 = Int32(gyroSpeed2x)
		//let sensorResolution32 = Int32(sensorResolution)
		let sensorRange32 = Int32(sensorRange)
		calibratedValue = Int32((sensorRawOffset * gyroSpeed2x32) / sensorRange32)
		return calibratedValue

	}

	static func applyAccelCalibration(_ sensorRawValue:Int32, sensorRawPositive1GValue:Int32, sensorRawNegative1GValue:Int32) -> Int32 {

		/*

		From PSMove:
		https://github.com/psmoveservice/psmoveapi/blob/master/src/psmove_calibration.c
		https://github.com/psmoveservice/PSMoveService/blob/master/src/psmoveservice/PSMoveController/PSMoveController.cpp
		https://github.com/psmoveservice/PSMoveService/blob/master/src/psmoveservice/PSDualShock4/PSDualShock4Controller.cpp

		Calculation of accelerometer mapping (as factor of gravity, 1g):

		              2 * (raw - low)
		calibrated = -----------------  - 1
		               (high - low)
		with:
		raw .... Raw sensor reading
		high ... Raw reading at +1g
		low .... Raw reading at -1g

		Now define:

		             2
		gain = --------------
		        (high - low)

		And combine constants:
		bias as the amount the min reading differs from -1.0g
		bias = - (gain * low) - 1

		Then we get:
		calibrated = raw * gain + bias

		*/

		var calibratedValue:Int32 = 0 // TODO I don't need this to be an integer
		calibratedValue = (2 * (sensorRawValue - sensorRawNegative1GValue) / (sensorRawPositive1GValue - sensorRawNegative1GValue)) - 1 // using the non precomputed constant version (at least for now)

		return calibratedValue

		/*
		sensorBias (accelXPlus - ((accelXPlus - accelXMinus) / 2))
		sensorRange: self.calibration[Calibration.AccelYIndex].rawPositive1GValue! - self.calibration[Calibration.AccelYIndex].rawNegative1GValue!

		// breaking up expression because swift compiler complains...
		let sensorRawOffset = Int32(sensorRawValue - sensorBias)
		let sensorResolution32 = Int32(sensorResolution)
		let sensorRange32 = Int32(sensorRange)
		calibratedValue = Int32((sensorRawOffset * 2 * sensorResolution32) / sensorRange32)
		return calibratedValue
		*/

	}

	var gyroSpeedPlus:Int32 = 0
	var gyroSpeedMinus:Int32 = 0
	var gyroSpeed2x:Int32 = 0

	// TODO change this to a struct or object with properties, array with indexes is kind of ugly
	var calibration = [
		Calibration(),
		Calibration(),
		Calibration(),
		Calibration(),
		Calibration(),
		Calibration()
	]

}

class Calibration {

	static let GyroPitchIndex:Int = 0
	static let GyroYawIndex:Int = 1
	static let GyroRollIndex:Int = 2
	static let AccelXIndex:Int = 3
	static let AccelYIndex:Int = 4
	static let AccelZIndex:Int = 5

	public init() {
		//
	}

	/// raw reading at +1G
	var rawPositive1GValue:Int32?

	/// raw reading at -1G
	var rawNegative1GValue:Int32?

	var gyroBias:Int32?

}
