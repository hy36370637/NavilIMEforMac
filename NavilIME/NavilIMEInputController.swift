//
//  NavilIMEInputController.swift
//  NavilIME
//
//  Created by Manwoo Yi on 9/4/22.
//

import InputMethodKit

@objc(NavilIMEInputController)
open class NavilIMEInputController: IMKInputController {
    let key_code:String =       "asdfhgzxcv\tbqweryt123465=97-80]ou[ip\tlj'k;\\,/nm.\t `"
    let shift_key_code:String = "ASDFHGZXCV\tBQWERYT!@#$^%+(&_*)}OU{IP\tLJ\"K:|<?NM>\t ~"
    
    var hangul:Hangul!
    
    override open func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        
        PrintLog.shared.Log(log: "Server Activated")
        self.hangul = Hangul()
        self.hangul.Start(type: HangulMenu.shared.selected_keyboard)
        
        // Emacs 영문 고정 옵션이 켜져 있을 때만 적용
        if OptHandler.shared.emacs_eng_mode {
            if let client = sender as? IMKTextInput,
               let bundleID = client.bundleIdentifier() {
                PrintLog.shared.Log(log: "App activated: \(bundleID)")
                if bundleID == "org.gnu.Emacs" {
                    HangulMenu.shared.self_eng_mode = true
                    PrintLog.shared.Log(log: "Forced English mode for: \(bundleID)")
                } else {
                    HangulMenu.shared.self_eng_mode = false
                }
            }
        }
    }
    
    override open func deactivateServer(_ sender: Any!) {
        super.deactivateServer(sender)
        
        PrintLog.shared.Log(log: "Server deactivating")
        
        self.hangul.Flush()
        self.update_display(client: sender)
        
        self.hangul.Stop()
    }
    
    override open func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        if OptHandler.shared.Is_han_eng_changed(keycode: event.keyCode, modi: event.modifierFlags) {
            self.hangul.ToggleSuspend()
            self.commitComposition(sender)
                return true
        }
        
        switch event.type {
        case .keyDown:
            let eaten = self.keydown_event_handler(event: event, client: sender)
            if eaten == false {
                self.commitComposition(sender)
            }
            return eaten
        case .leftMouseDown, .leftMouseUp, .leftMouseDragged, .rightMouseDown, .rightMouseUp, .rightMouseDragged:
            self.commitComposition(sender)
        default:
            PrintLog.shared.Log(log: "unhandled event keycode=\(event.keyCode) modi=\(event.modifierFlags.rawValue)")
        }
        return false
    }
    
    func keydown_event_handler(event:NSEvent, client:Any!) -> Bool {
        let keycode = event.keyCode
        let flag = event.modifierFlags
        
        // 특정 패턴 입력은 한글로 변환하지 않는다.
        Hotfix.shared.add(keycode)
        let is_matched = Hotfix.shared.check()
        if is_matched == true {
            return false
        }
        
        if flag.contains(.command)
            || flag.contains(.option)
            || flag.contains(.control) {
            PrintLog.shared.Log(log: "Modikey - \(keycode) with \(flag.rawValue)")
            // Emacs에서 수식키 조합 시 자동 영문 전환
            if OptHandler.shared.emacs_eng_mode,
               let client = client as? IMKTextInput,
               let bundleID = client.bundleIdentifier(),
               bundleID == "org.gnu.Emacs" {
                if HangulMenu.shared.self_eng_mode == false {
                    HangulMenu.shared.self_eng_mode = true
                    self.hangul.Flush()
                    PrintLog.shared.Log(log: "Auto switched to English for Emacs shortcut")
                }
            }
            return false
        }
        
        let enter_return = 0x24 // MacOS defined
        let tab = 0x30          // MacOS defined
        if keycode == enter_return || keycode == tab {
            PrintLog.shared.Log(log: "Enter or Tab")
            
            self.hangul.Flush()
            self.update_display(client: client)
            
            return false
        }
        
        let backspace = 0x33    // MacOS defined
        if keycode == backspace {
            PrintLog.shared.Log(log: "Backspace")
            
            let remain = self.hangul.Backspace()
            if remain == true {
                self.update_display(client: client, backspace: true)
            }
            return remain
        }
        
        if keycode >= self.key_code.count {
            PrintLog.shared.Log(log: "Bypassd keycode: \(keycode) >= \(self.key_code.count)")
            
            self.hangul.Flush()
            self.update_display(client: client)
            
            return false
        }
        
        let ascii_idx = self.key_code.index(self.key_code.startIndex, offsetBy: Int(keycode))
        var ascii = self.key_code[ascii_idx]
        let shift:Bool = flag.contains(.shift)
        if shift == true {
            ascii = self.shift_key_code[ascii_idx]
        }
        
        let is_hangul:Bool = self.hangul.Process(ascii: String(ascii))
        if is_hangul == false {
            PrintLog.shared.Log(log: "Not Hangul: \(ascii)")
            
            self.hangul.Flush()
            
            var extra:String = String(ascii)
            if let etc = hangul.Additional(ascii: String(ascii)) {
                extra = etc
            }
            self.update_display(client: client, backspace: false, additional: extra)
        } else {
            self.update_display(client: client)
        }
        return true
    }
    
    func update_display(client:Any!, backspace:Bool = false, additional:String = "") {
        let commit_unicode:[unichar] = self.hangul.GetCommit()
        let preedit_unicode:[unichar] = self.hangul.GetPreedit()
        var commited:String = String(utf16CodeUnits:commit_unicode , count: commit_unicode.count)
        let preediting:String = String(utf16CodeUnits: preedit_unicode, count: preedit_unicode.count)
        
        PrintLog.shared.Log(log: "C:'\(commited)' - \(commited.count) P:'\(preediting)' - \(preediting.count)")
        
        guard let disp = client as? IMKTextInput else {
            return
        }
        
        commited += additional
        
        let build_count = 303
        if commited.count != 0 {
            disp.insertText(commited, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
            
            PrintLog.shared.Log(log: "\(build_count) Commit: \(commited)")
        }
        
        // replacementRange 가 아래 코드와 같아야만 잘 동작한다.
        if (preediting.count != 0) || (backspace == true) {
            let sr = NSRange(location: 0, length: preediting.count)
            let rr = NSRange(location: NSNotFound, length: NSNotFound)
            PrintLog.shared.Log(log: "RR: \(rr) SR: \(sr) on \(String(describing: disp.bundleIdentifier()))")
            disp.setMarkedText(preediting, selectionRange: sr, replacementRange: rr)
            
            PrintLog.shared.Log(log: "\(build_count) Predit: \(preediting)")
        }
    }
    
    override open func commitComposition(_ sender: Any!) {
        PrintLog.shared.Log(log: "Commit Composition")
        self.hangul.Flush()
        self.update_display(client: sender)
    }
    
    override open func recognizedEvents(_ sender: Any!) -> Int {
        return Int(NSEvent.EventTypeMask(arrayLiteral: .keyDown, .flagsChanged,
            .leftMouseUp, .rightMouseUp, .leftMouseDown, .rightMouseDown,
            .leftMouseDragged, .rightMouseDragged,
            .appKitDefined, .applicationDefined, .systemDefined).rawValue)
    }
    
    override open func mouseDown(onCharacterIndex index: Int, coordinate point: NSPoint, withModifier flags: Int, continueTracking keepTracking: UnsafeMutablePointer<ObjCBool>!, client sender: Any!) -> Bool {
        PrintLog.shared.Log(log: "Mouse Down")
        
        self.commitComposition(sender)
        return false
    }
    
   override open func menu() -> NSMenu! {
        return HangulMenu.shared.menu
   }
    
    @objc func select_menu(_ sender:Any?) {
        guard let menuitem = sender as? Dictionary<String, Any> else {
            PrintLog.shared.Log(log: "WTF \(sender.debugDescription)")
            return
        }
        
        if let kbd:NSMenuItem = menuitem["IMKCommandMenuItem"] as? NSMenuItem {
            PrintLog.shared.Log(log: "Selected Keyboard: \(kbd.title)")
            if kbd.tag == OptHandler.shared.opt_menu_tag {
                PrintLog.shared.Log(log: "This is Option: \(kbd.title)")
                self.hangul.Flush()
                OptHandler.shared.Open_opt_window(sender)
                return
            }
            HangulMenu.shared.change_selected_keyboard(id: kbd.tag)
            for mi in HangulMenu.shared.menu.items {
                mi.state = NSControl.StateValue.off
            }
            kbd.state = NSControl.StateValue.on
            
            self.hangul.Flush()
            self.hangul.Stop()
            self.hangul.Start(type: HangulMenu.shared.selected_keyboard)
        } else {
            PrintLog.shared.Log(log: "Not NSMenuItem????")
        }
    }
}
