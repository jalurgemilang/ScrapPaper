//
//  HotKeyManager.swift
//  ScrapPaper
//
//  Created by Long Fong Yee on 06/05/2025.
//


import Cocoa
import Carbon

class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerUPP?

    func registerHotKey() {
        // Key: space (keyCode 49), Modifier: control (controlKey = 0x00020000)
        let hotKeyCode: UInt32 = 49
        let hotKeyModifiers: UInt32 = UInt32(controlKey)

        let hotKeyID = EventHotKeyID(signature: OSType("htk1".fourCharCode), id: 1)

        eventHandler = {
            (nextHandler, event, userData) -> OSStatus in

            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil, &hkID)

            if hkID.signature == OSType("htk1".fourCharCode), hkID.id == 1 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .triggerShowWindow, object: nil)
                }
            }

            return noErr
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), eventHandler, 1, &eventType, nil, nil)
        RegisterEventHotKey(hotKeyCode, hotKeyModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}

extension Notification.Name {
    static let triggerShowWindow = Notification.Name("triggerShowWindow")
}

private extension String {
    var fourCharCode: FourCharCode {
        return utf8.reduce(0) { ($0 << 8) + FourCharCode($1) }
    }
}
