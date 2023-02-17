; This script will toggle spamming for the configured keys on and off in the configured interval.
; Example: If the key "1" is configured and "1" is pressed on the keyboard, it will continously send "1" to the currently active window until "1" is physically pressed again.
; A small always-on-top window is created to monitor current active spam keys. Also a checkbox is provided to quickly bypass this whole script.
;
; This script requires AutoHotkey 2
config := {
	; Spammable Keys
	spamKeys: [
		"1",
		"^"
	],
	; Whether multiple keys can be spammed at once
	allowParallelSpam: false,
	; Time between each virtual keypress
	spamInterval: 200
}

spamKeyInstances := []
SpamGui := Gui()
SpamGui.Opt("+AlwaysOnTop -SysMenu -caption")
enableSpamCheckbox := SpamGui.AddCheckBox("vSpamEnabled Checked", "Enable Spam functionality")
enableSpamCheckbox.OnEvent("Click", enableSpamCheckbox_OnClick)
initializeSpamKeys()
SpamGui.Show("x400 y0")

initializeSpamKeys() {
	Loop config.spamKeys.Length {
		key := config.spamKeys[A_Index]
		keyWithModifier := "$" key
		checkboxName := "vSpamKey" A_Index
		checkbox := SpamGui.AddCheckBox(checkboxName " Disabled", "Spamming key: " key) 
		spamKeyInstance := SpamKey(key, config.spamInterval, checkbox)
		spamKeyInstances.Push(spamKeyInstance)

		HotIf isEnabled
		Hotkey(keyWithModifier, createSpamKeyHotkeyPressCallback(spamKeyInstance))
	}
}

createSpamKeyHotkeyPressCallback(spamKeyInstance) {
	callback(*) {
		if (!config.allowParallelSpam) {
			stopRunningSpamKeys(spamKeyInstance)
		}
		spamKeyInstance.Toggle()
	}

	return callback
}

stopRunningSpamKeys(except := false) {
	Loop spamKeyInstances.Length {
		spamKeyInstance := spamKeyInstances[A_Index]

		if (spamKeyInstance != except) {
			spamKeyInstance.Stop()
		}
	}
}


enableSpamCheckbox_OnClick(*) {
	if (!isEnabled()) {
		stopRunningSpamKeys()
	}
}

isEnabled(*) {
	return enableSpamCheckbox.Value
}

class SpamKey {
	__New(key, interval := 100, checkbox := false) {
		this.key := key
		this.checkbox := checkbox
		this.interval := interval
		this.running := false
		this.timer := ObjBindMethod(this, "Spam")

		if (this.checkbox) {
			this.checkbox.OnEvent("Click", ObjBindMethod(this, "Toggle"))
		}
    }
	Toggle(*) {
		if this.running {
			this.Stop()
		}
		else {
			this.Start()
		}
	}
    Start() {
		this.running := true
		if (this.checkbox) {
			this.checkbox.Value := 1
		}
        SetTimer this.timer, this.interval
    }
    Stop() {
		this.running := false
		if (this.checkbox) {
			this.checkbox.Value := 0
		}
        SetTimer this.timer, 0
    }
    Spam() {
        Send "{raw}" this.key
    }
}