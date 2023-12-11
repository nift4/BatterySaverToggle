//
// AppDelegate.swift
// BatterySaverToggle
//
// Created by nift4 on 11.12.2023.
//

import Cocoa
import LetsMove

@main @MainActor class AppDelegate: NSObject, NSApplicationDelegate {

    private nonisolated let sudoersFile = "/private/etc/sudoers.d/lowpowermode"
    private nonisolated let sudoersText = "# Created by BatterySaverToggle.app\nALL ALL=NOPASSWD: /usr/bin/pmset -a lowpowermode 0\nALL ALL=NOPASSWD: /usr/bin/pmset -a lowpowermode 1\n"
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.orderFrontStandardAboutPanel()
        return false
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #if !DEBUG
        PFMoveToApplicationsFolderIfNecessary()
        #endif
        NotificationCenter.default.addObserver(self, selector: #selector(onPowerStateDidChange), name: .NSProcessInfoPowerStateDidChange, object: nil)
        statusItem.behavior = .terminationOnRemoval
        statusItem.isVisible = true // show menu bar icon if user removed it
        statusItem.button?.action = #selector(onButtonPress)
        updateStatusItem()
        #if !DEBUG
        LaunchAtLoginController().launchAtLogin = true
        #endif
    }
    
    private func updateStatusItem() {
        if (ProcessInfo.processInfo.isLowPowerModeEnabled) {
            statusItem.button?.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Low Power Mode enabled")
        } else {
            statusItem.button?.image = NSImage(systemSymbolName: "bolt.slash.fill", accessibilityDescription: "Low Power Mode disabled")
        }
    }
    
    private func handleButtonPress() {
        statusItem.button?.isHighlighted = true
        if (!self.haveLowPowerSudoFile()) {
            self.createLowPowerSudoFile()
        } else {
            DispatchQueue.global().async {
                self.setLowPowerMode(!ProcessInfo.processInfo.isLowPowerModeEnabled)
                DispatchQueue.main.async {
                    self.statusItem.button?.isHighlighted = false
                }
            }
        }
    }
    
    private nonisolated func setLowPowerMode(_ enable: Bool) {
        let process = Process()
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["--non-interactive", "/usr/bin/pmset", "-a", "lowpowermode", enable ? "1" : "0"]
        try? process.run()
        process.waitUntilExit()
        let output = try? outputPipe.fileHandleForReading.readToEnd()
        showErrorAlertIfNeeded(output)
    }
    
    private func createLowPowerSudoFile() {
        let alert = NSAlert()
        alert.messageText = "Do you want to allow all apps on the system to toggle Low Power Mode? This is required for Battery Saver Toggle. If yes, please authorize Battery Saver Toggle to use authopen to change your system configuration."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        let result = alert.runModal() == .alertFirstButtonReturn
        DispatchQueue.global().async {
            if (result) {
                let process = Process()
                let inputPipe = Pipe()
                let outputPipe = Pipe()
                process.standardInput = inputPipe
                process.standardOutput = outputPipe
                process.standardError = outputPipe
                process.executableURL = URL(fileURLWithPath: "/usr/libexec/authopen")
                process.arguments = ["-c", "-w", self.sudoersFile]
                try? process.run()
                inputPipe.fileHandleForWriting.write(self.sudoersText.data(using: .ascii)!)
                try? inputPipe.fileHandleForWriting.close()
                process.waitUntilExit()
                let output = try? outputPipe.fileHandleForReading.readToEnd()
                self.showErrorAlertIfNeeded(output)
                if (self.haveLowPowerSudoFile()) {
                    self.setLowPowerMode(!ProcessInfo.processInfo.isLowPowerModeEnabled)
                }
            }
            DispatchQueue.main.async {
                self.statusItem.button?.isHighlighted = false
            }
        }
    }
    
    private nonisolated func haveLowPowerSudoFile() -> Bool {
        return FileManager.default.fileExists(atPath: self.sudoersFile)
    }
    
    private nonisolated func showErrorAlertIfNeeded(_ output: Data?) {
        let str = output != nil ? String(decoding: output!, as: UTF8.self) : nil
        if (str?.isEmpty == false) {
            NSLog(str!)
            DispatchQueue.main.async {
                Task {
                    let alert = NSAlert()
                    alert.messageText = "Uh oh, something went wrong!\n" + str!
                    alert.runModal()
                }
            }
        }
    }

    @objc func onPowerStateDidChange() {
        DispatchQueue.main.async {
            self.updateStatusItem()
        }
    }
    
    @objc func onButtonPress() {
        DispatchQueue.main.async {
            self.handleButtonPress()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: .NSProcessInfoPowerStateDidChange, object: nil)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

