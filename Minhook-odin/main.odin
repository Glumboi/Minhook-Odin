package main

import c "core:c/libc"
import "core:fmt"
import "core:sys/windows"
import "minhook"

// Hook messagebox

MessageBox_t :: distinct
proc(
	hwnd: windows.HWND,
	lpText: windows.LPCSTR,
	lpCation: windows.LPCSTR,
	uType: windows.UINT,
) -> int
MessageBox_o: MessageBox_t

MyMessageBoxHook :: proc(
	hwnd: windows.HWND,
	lpText: windows.LPCSTR,
	lpCation: windows.LPCSTR,
	uType: windows.UINT,
) -> int {
	c.printf("Messagebox hook called!\n")
	return MessageBox_o(hwnd, lpText, lpCation, uType)
}

SetupHooks :: proc() {
	modHandle := windows.GetModuleHandleA("User32.dll")
	MessageBox_o = MessageBox_t(windows.GetProcAddress(modHandle, "MessageBoxA"))

	c.printf("MessageBox_o: %p\n", MessageBox_o)

	stat := minhook.MH_CreateHook(
		windows.LPVOID(MessageBox_o),
		windows.LPVOID(MyMessageBoxHook),
		transmute(^rawptr)&MessageBox_o,
	)

	if stat != minhook.MH_STATUS.MH_OK {
		c.printf("Failed to create hook, error: %d\n", stat)
		return
	}

	stat = minhook.MH_EnableHook(minhook.MH_ALL_HOOKS())
	if stat != minhook.MH_STATUS.MH_OK {
		c.printf("Failed to enable hook, error: %d\n", stat)
		return
	}
	c.printf("Enabled hook, stat: %s\n", minhook.MH_StatusToString(stat))
	windows.MessageBoxA(nil, "Test", "Test2", windows.MB_OK | windows.MB_ICONHAND)
}

main :: proc() {
	consoleRes := windows.AllocConsole()
	if consoleRes == false {return}
	c.freopen("conout$", "w", c.stdout)
	stat := minhook.MH_Initialize()
	if stat != minhook.MH_STATUS.MH_OK {
		c.printf("Failed to initialize Minhook, error: %d\n", stat)
		return
	}
	c.printf("Initialized Minhook, stat: %d\n", stat)
	SetupHooks()
}
