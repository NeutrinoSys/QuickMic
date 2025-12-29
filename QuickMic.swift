import Cocoa
import UserNotifications
import CoreAudio
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let hasShownAutoStartPromptKey = "hasShownAutoStartPrompt"

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "QuickMic")
            button.image?.isTemplate = true
        }

        setupMenu()
        checkFirstLaunch()
    }

    func checkFirstLaunch() {
        let hasShownPrompt = UserDefaults.standard.bool(forKey: hasShownAutoStartPromptKey)

        if !hasShownPrompt {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showAutoStartPrompt()
            }
        }
    }

    func showAutoStartPrompt() {
        let alert = NSAlert()
        alert.messageText = "Launch QuickMic at Login?"
        alert.informativeText = "Would you like QuickMic to start automatically when you log in? You can change this later in the menu."
        alert.addButton(withTitle: "Yes, Start at Login")
        alert.addButton(withTitle: "No, I'll Launch Manually")
        alert.alertStyle = .informational

        let response = alert.runModal()
        UserDefaults.standard.set(true, forKey: hasShownAutoStartPromptKey)

        if response == .alertFirstButtonReturn {
            enableAutoStart()
        }
    }

    func isAutoStartEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return false
        }
    }

    func enableAutoStart() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                showNotification(title: "Auto-Start Enabled", message: "QuickMic will start automatically at login")
                setupMenu() // Refresh menu to update checkmark
            } catch {
                showNotification(title: "Error", message: "Could not enable auto-start: \(error.localizedDescription)")
            }
        } else {
            showNotification(title: "Not Available", message: "Auto-start requires macOS 13.0 or later")
        }
    }

    func disableAutoStart() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                showNotification(title: "Auto-Start Disabled", message: "QuickMic will not start automatically")
                setupMenu() // Refresh menu to update checkmark
            } catch {
                showNotification(title: "Error", message: "Could not disable auto-start: \(error.localizedDescription)")
            }
        } else {
            showNotification(title: "Not Available", message: "Auto-start requires macOS 13.0 or later")
        }
    }

    @objc func toggleAutoStart() {
        if isAutoStartEnabled() {
            disableAutoStart()
        } else {
            enableAutoStart()
        }
    }

    func setupMenu() {
        let menu = NSMenu()

        // Switch Microphone submenu
        let switchMicItem = NSMenuItem(title: "Switch Microphone", action: nil, keyEquivalent: "")
        let micSubmenu = NSMenu()

        let inputDevices = getAudioInputDevices()
        let currentDeviceID = getCurrentInputDevice()

        if inputDevices.isEmpty {
            let noDevicesItem = NSMenuItem(title: "No input devices found", action: nil, keyEquivalent: "")
            noDevicesItem.isEnabled = false
            micSubmenu.addItem(noDevicesItem)
        } else {
            for device in inputDevices {
                let item = NSMenuItem(title: device.name, action: #selector(switchToDevice(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = device.id

                // Show checkmark for current device
                if device.id == currentDeviceID {
                    item.state = .on
                }

                micSubmenu.addItem(item)
            }
        }

        switchMicItem.submenu = micSubmenu
        menu.addItem(switchMicItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Reset Dictation (Nuclear)", action: #selector(resetDictation), keyEquivalent: "r"))

        menu.addItem(NSMenuItem.separator())

        // Auto-start toggle
        let autoStartItem = NSMenuItem(title: "Start at Login", action: #selector(toggleAutoStart), keyEquivalent: "")
        autoStartItem.state = isAutoStartEnabled() ? .on : .off
        menu.addItem(autoStartItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    struct AudioDevice {
        let id: AudioDeviceID
        let name: String
    }

    func getAudioInputDevices() -> [AudioDevice] {
        var devices: [AudioDevice] = []
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize) == noErr else {
            return devices
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceIDs) == noErr else {
            return devices
        }

        for deviceID in deviceIDs {
            // Check if device has input streams
            var inputAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreamConfiguration,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: 0
            )

            var inputSize: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(deviceID, &inputAddress, 0, nil, &inputSize) == noErr else { continue }

            let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
            defer { bufferList.deallocate() }

            guard AudioObjectGetPropertyData(deviceID, &inputAddress, 0, nil, &inputSize, bufferList) == noErr else { continue }

            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            var channelCount = 0
            for buffer in buffers {
                channelCount += Int(buffer.mNumberChannels)
            }

            guard channelCount > 0 else { continue }

            // Get device name
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            var nameSize = UInt32(MemoryLayout<CFString>.size)
            var name: Unmanaged<CFString>?

            withUnsafeMutablePointer(to: &name) { ptr in
                _ = AudioObjectGetPropertyData(deviceID, &nameAddress, 0, nil, &nameSize, ptr)
            }

            if let name = name?.takeUnretainedValue() as String? {
                devices.append(AudioDevice(id: deviceID, name: name))
            }
        }

        return devices
    }

    func getCurrentInputDevice() -> AudioDeviceID? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceID) == noErr else {
            return nil
        }

        return deviceID
    }

    func setInputDevice(_ deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceIDCopy = deviceID
        let dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        return AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, dataSize, &deviceIDCopy) == noErr
    }

    @objc func switchToDevice(_ sender: NSMenuItem) {
        guard let deviceID = sender.representedObject as? AudioDeviceID else { return }

        if setInputDevice(deviceID) {
            showNotification(title: "Microphone Switched", message: "Now using: \(sender.title)")
            setupMenu() // Refresh menu to update checkmarks
        } else {
            showNotification(title: "Error", message: "Failed to switch microphone")
        }
    }

    @objc func resetDictation() {
        let script = """
        do shell script "killall localspeechrecognition assistant_service corespeechd assistantd; sudo killall coreaudiod" with administrator privileges
        """

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)

            if error != nil {
                showNotification(title: "Error", message: "Failed to reset dictation services")
            } else {
                showNotification(title: "Success", message: "Dictation services reset")
            }
        }
    }

    func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
