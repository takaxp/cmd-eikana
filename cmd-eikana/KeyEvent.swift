//
//  KeyEvent.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

class KeyEvent: NSObject {
    var keyCode: UInt16? = nil
    var imeStatus: Bool = false
    var mode = 2 // {0: the original mode, 1: Shift-Space to toggle IME, 2: Right cmd to toggle IME }
    
    override init() {
        super.init()
        
        let checkOptionPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
        let options: CFDictionary = [checkOptionPrompt: true] as NSDictionary
        
        if !AXIsProcessTrustedWithOptions(options) {
            // アクセシビリティに設定されていない場合、設定されるまでループで待つ
            Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(KeyEvent.watchAXIsProcess(_:)), userInfo: nil, repeats: true)
            
        } else {

            self.setEisu()
            self.watch()
        }
    }
    
    func watchAXIsProcess(_ timer: Timer) {
        if AXIsProcessTrusted() {
            timer.invalidate()
            #if DEBUG
            print("アクセシビリティに設定されました")
            #endif
            
            self.watch()

            addLaunchAtStartup()
            loginItem.state = 1
        }
    }

    func setEisu() {
        let loc = CGEventTapLocation.cghidEventTap
        CGEvent(keyboardEventSource: nil, virtualKey: 102, keyDown: true)?.post(tap: loc)
        CGEvent(keyboardEventSource: nil, virtualKey: 102, keyDown: false)?.post(tap: loc)
    }

    func setKana() {
        let loc = CGEventTapLocation.cghidEventTap
        CGEvent(keyboardEventSource: nil, virtualKey: 104, keyDown: true)?.post(tap: loc)
        CGEvent(keyboardEventSource: nil, virtualKey: 104, keyDown: false)?.post(tap: loc)
    }

    func removeSpace() {
        let loc = CGEventTapLocation.cghidEventTap
        CGEvent(keyboardEventSource: nil, virtualKey: 51, keyDown: true)?.post(tap: loc)
        CGEvent(keyboardEventSource: nil, virtualKey: 51, keyDown: false)?.post(tap: loc)
    }
    
    func toggleIME() {
        if self.imeStatus == true {
            // IME off
            self.setEisu()
            self.imeStatus = false;
            #if DEBUG
                print("ime OFF")
            #endif
        }else{
            // IME on
            self.setKana()
            self.imeStatus = true;
            #if DEBUG
                print("ime ON")
            #endif
        }
    }

    func watch () {
        let masks = [
            NSEventMask.keyDown,
            NSEventMask.keyUp,
            NSEventMask.leftMouseDown,
            NSEventMask.leftMouseUp,
            NSEventMask.rightMouseDown,
            NSEventMask.rightMouseUp,
            NSEventMask.otherMouseDown,
            NSEventMask.otherMouseUp,
            NSEventMask.scrollWheel
            // NSEventMask.MouseMovedMask,
        ]
        let handler = {(evt: NSEvent!) -> Void in
            self.keyCode = nil
        }
        
        for mask in masks {
            NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
        }

        if self.mode == 1 {
            NSEvent.addGlobalMonitorForEvents(matching: NSEventMask.keyDown , handler: {(event: NSEvent!) -> Void in
                
                #if DEBUG
                    print(self.keyCode)
                #endif
                
                if ( event.keyCode != 49 ){
                    return;
                }
                if ( !event.modifierFlags.contains(.shift)
                    || event.modifierFlags.contains(.command)
                    || event.modifierFlags.contains(.option)
                    || event.modifierFlags.contains(.control)){
                    return;
                }
                
                #if DEBUG
                    print("value: ", event)
                #endif
                
                self.removeSpace()
                self.toggleIME()
                
            })
            
        }else{ // mode == {0, 2}
            
            NSEvent.addGlobalMonitorForEvents(matching: NSEventMask.flagsChanged, handler: {(evevt: NSEvent!) -> Void in
                if evevt.keyCode == 55 { // 左コマンドキー
                    if self.mode == 0 {
                        
                        if evevt.modifierFlags.contains(.command) {
                            self.keyCode = 55
                        }
                        else if self.keyCode == 55 {
                            #if DEBUG
                                print("英数")
                            #endif
                            
                            self.setEisu()
                        }
                    }
                }
                else if evevt.keyCode == 54 { // 右コマンドキー
                    if evevt.modifierFlags.contains(.command) {
                        self.keyCode = 54
                    }
                    else if self.keyCode == 54 {
                        #if DEBUG
                            print("かな")
                        #endif
                        
                        if self.mode == 0 {
                            self.setKana()
                        }else if self.mode == 2 {
                            self.toggleIME()
                        }
                    }
                }
                else {
                    self.keyCode = nil;
                }
            })
        }
    }
}
