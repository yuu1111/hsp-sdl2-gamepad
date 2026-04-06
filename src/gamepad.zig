const std = @import("std");

// Windows API for DLL loading
const HMODULE = ?*anyopaque;
extern "kernel32" fn LoadLibraryA(lpLibFileName: [*:0]const u8) callconv(.winapi) HMODULE;
extern "kernel32" fn GetProcAddress(hModule: HMODULE, lpProcName: [*:0]const u8) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn FreeLibrary(hLibModule: HMODULE) callconv(.winapi) i32;

// SDL2 type definitions
const SDL_bool = c_int;
const SDL_TRUE: SDL_bool = 1;
const SDL_FALSE: SDL_bool = 0;

const SDL_GameController = opaque {};
const SDL_Joystick = opaque {};
const SDL_JoystickID = i32;

const SDL_INIT_GAMECONTROLLER: u32 = 0x00002000;
const SDL_INIT_NOPARACHUTE: u32 = 0x00100000;

// SDL_Event struct (simplified)
const SDL_Event = extern struct {
    type: u32,
    padding: [56]u8 = undefined,
};

// SDL Event types for filtering
const SDL_JOYAXISMOTION: u32 = 0x600;
const SDL_JOYDEVICEREMOVED: u32 = 0x606;
const SDL_CONTROLLERAXISMOTION: u32 = 0x650;
const SDL_CONTROLLERDEVICEREMAPPED: u32 = 0x655;

// SDL_GameControllerButton enum
const SDL_CONTROLLER_BUTTON_A: c_int = 0;
const SDL_CONTROLLER_BUTTON_B: c_int = 1;
const SDL_CONTROLLER_BUTTON_X: c_int = 2;
const SDL_CONTROLLER_BUTTON_Y: c_int = 3;
const SDL_CONTROLLER_BUTTON_BACK: c_int = 4;
const SDL_CONTROLLER_BUTTON_START: c_int = 6;
const SDL_CONTROLLER_BUTTON_LEFTSTICK: c_int = 7;
const SDL_CONTROLLER_BUTTON_RIGHTSTICK: c_int = 8;
const SDL_CONTROLLER_BUTTON_LEFTSHOULDER: c_int = 9;
const SDL_CONTROLLER_BUTTON_RIGHTSHOULDER: c_int = 10;
const SDL_CONTROLLER_BUTTON_DPAD_UP: c_int = 11;
const SDL_CONTROLLER_BUTTON_DPAD_DOWN: c_int = 12;
const SDL_CONTROLLER_BUTTON_DPAD_LEFT: c_int = 13;
const SDL_CONTROLLER_BUTTON_DPAD_RIGHT: c_int = 14;

// SDL_GameControllerAxis enum
const SDL_CONTROLLER_AXIS_LEFTX: c_int = 0;
const SDL_CONTROLLER_AXIS_LEFTY: c_int = 1;
const SDL_CONTROLLER_AXIS_RIGHTX: c_int = 2;
const SDL_CONTROLLER_AXIS_RIGHTY: c_int = 3;
const SDL_CONTROLLER_AXIS_TRIGGERLEFT: c_int = 4;
const SDL_CONTROLLER_AXIS_TRIGGERRIGHT: c_int = 5;

// SDL_EventFilter callback type
const SDL_EventFilter = *const fn (?*anyopaque, *SDL_Event) callconv(.c) c_int;

// SDL2 function pointer types (SDL2 uses cdecl on Windows)
const FnSDL_Init = *const fn (u32) callconv(.c) c_int;
const FnSDL_QuitSubSystem = *const fn (u32) callconv(.c) void;
const FnSDL_SetHint = *const fn ([*:0]const u8, [*:0]const u8) callconv(.c) SDL_bool;
const FnSDL_GameControllerUpdate = *const fn () callconv(.c) void;
const FnSDL_NumJoysticks = *const fn () callconv(.c) c_int;
const FnSDL_IsGameController = *const fn (c_int) callconv(.c) SDL_bool;
const FnSDL_GameControllerOpen = *const fn (c_int) callconv(.c) ?*SDL_GameController;
const FnSDL_GameControllerClose = *const fn (*SDL_GameController) callconv(.c) void;
const FnSDL_GameControllerGetAttached = *const fn (*SDL_GameController) callconv(.c) SDL_bool;
const FnSDL_GameControllerGetJoystick = *const fn (*SDL_GameController) callconv(.c) ?*SDL_Joystick;
const FnSDL_GameControllerGetButton = *const fn (*SDL_GameController, c_int) callconv(.c) u8;
const FnSDL_GameControllerGetAxis = *const fn (*SDL_GameController, c_int) callconv(.c) i16;
const FnSDL_GameControllerRumble = *const fn (*SDL_GameController, u16, u16, u32) callconv(.c) c_int;
const FnSDL_JoystickOpen = *const fn (c_int) callconv(.c) ?*SDL_Joystick;
const FnSDL_JoystickClose = *const fn (*SDL_Joystick) callconv(.c) void;
const FnSDL_JoystickInstanceID = *const fn (*SDL_Joystick) callconv(.c) SDL_JoystickID;
const FnSDL_SetEventFilter = *const fn (?SDL_EventFilter, ?*anyopaque) callconv(.c) void;

// SDL2 function pointers
var pSDL_Init: ?FnSDL_Init = null;
var pSDL_QuitSubSystem: ?FnSDL_QuitSubSystem = null;
var pSDL_SetHint: ?FnSDL_SetHint = null;
var pSDL_GameControllerUpdate: ?FnSDL_GameControllerUpdate = null;
var pSDL_NumJoysticks: ?FnSDL_NumJoysticks = null;
var pSDL_IsGameController: ?FnSDL_IsGameController = null;
var pSDL_GameControllerOpen: ?FnSDL_GameControllerOpen = null;
var pSDL_GameControllerClose: ?FnSDL_GameControllerClose = null;
var pSDL_GameControllerGetAttached: ?FnSDL_GameControllerGetAttached = null;
var pSDL_GameControllerGetJoystick: ?FnSDL_GameControllerGetJoystick = null;
var pSDL_GameControllerGetButton: ?FnSDL_GameControllerGetButton = null;
var pSDL_GameControllerGetAxis: ?FnSDL_GameControllerGetAxis = null;
var pSDL_GameControllerRumble: ?FnSDL_GameControllerRumble = null;
var pSDL_JoystickOpen: ?FnSDL_JoystickOpen = null;
var pSDL_JoystickClose: ?FnSDL_JoystickClose = null;
var pSDL_JoystickInstanceID: ?FnSDL_JoystickInstanceID = null;
var pSDL_SetEventFilter: ?FnSDL_SetEventFilter = null;

const MAX_CONTROLLERS = 4;

const Controller = struct {
    handle: ?*SDL_GameController = null,
    joystick_id: SDL_JoystickID = -1,
};

var controllers: [MAX_CONTROLLERS]Controller = [_]Controller{.{}} ** MAX_CONTROLLERS;
var sdl2_dll: HMODULE = null;
var initialized: bool = false;

// D-Pad bit mapping (XInput compatible, bits 0-3)
const DPAD_UP: u32 = 1 << 0;
const DPAD_DOWN: u32 = 1 << 1;
const DPAD_LEFT: u32 = 1 << 2;
const DPAD_RIGHT: u32 = 1 << 3;

// Button bit mapping (XInput compatible, bits 4-15)
const BTN_START: u32 = 1 << 4;
const BTN_BACK: u32 = 1 << 5;
const BTN_L3: u32 = 1 << 6;
const BTN_R3: u32 = 1 << 7;
const BTN_LB: u32 = 1 << 8;
const BTN_RB: u32 = 1 << 9;
const BTN_LT: u32 = 1 << 10;
const BTN_RT: u32 = 1 << 11;
const BTN_A: u32 = 1 << 12;
const BTN_B: u32 = 1 << 13;
const BTN_X: u32 = 1 << 14;
const BTN_Y: u32 = 1 << 15;

// Left stick direction (bits 16-19)
const LSTICK_UP: u32 = 1 << 16;
const LSTICK_DOWN: u32 = 1 << 17;
const LSTICK_LEFT: u32 = 1 << 18;
const LSTICK_RIGHT: u32 = 1 << 19;

// Right stick direction (bits 20-23)
const RSTICK_UP: u32 = 1 << 20;
const RSTICK_DOWN: u32 = 1 << 21;
const RSTICK_LEFT: u32 = 1 << 22;
const RSTICK_RIGHT: u32 = 1 << 23;

const STICK_DEADZONE: i16 = 8000;
const TRIGGER_THRESHOLD: i16 = 8000;

fn loadSDL2() bool {
    sdl2_dll = LoadLibraryA("SDL2.dll");
    if (sdl2_dll == null) return false;

    // Load all required functions
    pSDL_Init = @ptrCast(GetProcAddress(sdl2_dll, "SDL_Init") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_QuitSubSystem = @ptrCast(GetProcAddress(sdl2_dll, "SDL_QuitSubSystem") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_SetHint = @ptrCast(GetProcAddress(sdl2_dll, "SDL_SetHint") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_GameControllerUpdate = @ptrCast(GetProcAddress(sdl2_dll, "SDL_GameControllerUpdate") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_NumJoysticks = @ptrCast(GetProcAddress(sdl2_dll, "SDL_NumJoysticks") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_IsGameController = @ptrCast(GetProcAddress(sdl2_dll, "SDL_IsGameController") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_GameControllerOpen = @ptrCast(GetProcAddress(sdl2_dll, "SDL_GameControllerOpen") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_GameControllerClose = @ptrCast(GetProcAddress(sdl2_dll, "SDL_GameControllerClose") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_GameControllerGetAttached = @ptrCast(GetProcAddress(sdl2_dll, "SDL_GameControllerGetAttached") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_GameControllerGetJoystick = @ptrCast(GetProcAddress(sdl2_dll, "SDL_GameControllerGetJoystick") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_GameControllerGetButton = @ptrCast(GetProcAddress(sdl2_dll, "SDL_GameControllerGetButton") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_GameControllerGetAxis = @ptrCast(GetProcAddress(sdl2_dll, "SDL_GameControllerGetAxis") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_JoystickOpen = @ptrCast(GetProcAddress(sdl2_dll, "SDL_JoystickOpen") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_JoystickClose = @ptrCast(GetProcAddress(sdl2_dll, "SDL_JoystickClose") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_JoystickInstanceID = @ptrCast(GetProcAddress(sdl2_dll, "SDL_JoystickInstanceID") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    pSDL_SetEventFilter = @ptrCast(GetProcAddress(sdl2_dll, "SDL_SetEventFilter") orelse {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return false;
    });

    // SDL_GameControllerRumble is optional (SDL 2.0.9+)
    if (GetProcAddress(sdl2_dll, "SDL_GameControllerRumble")) |ptr| {
        pSDL_GameControllerRumble = @ptrCast(ptr);
    } else {
        pSDL_GameControllerRumble = null;
    }

    return true;
}

fn eventFilter(_: ?*anyopaque, event: *SDL_Event) callconv(.c) c_int {
    const event_type = event.type;
    if (event_type >= SDL_JOYAXISMOTION and event_type <= SDL_JOYDEVICEREMOVED) return 1;
    if (event_type >= SDL_CONTROLLERAXISMOTION and event_type <= SDL_CONTROLLERDEVICEREMAPPED) return 1;
    return 0;
}

fn openControllers() void {
    var controller_index: usize = 0;
    const num_joysticks = pSDL_NumJoysticks.?();

    var i: c_int = 0;
    while (i < num_joysticks and controller_index < MAX_CONTROLLERS) : (i += 1) {
        if (pSDL_IsGameController.?(i) == SDL_TRUE) {
            const handle = pSDL_GameControllerOpen.?(i);
            if (handle) |h| {
                controllers[controller_index].handle = h;
                if (pSDL_GameControllerGetJoystick.?(h)) |joystick| {
                    controllers[controller_index].joystick_id = pSDL_JoystickInstanceID.?(joystick);
                }
                controller_index += 1;
            }
        }
    }
}

fn closeControllers() void {
    for (&controllers) |*ctrl| {
        if (ctrl.handle) |handle| {
            pSDL_GameControllerClose.?(handle);
            ctrl.handle = null;
            ctrl.joystick_id = -1;
        }
    }
}

fn getConnectedCount() c_int {
    var count: c_int = 0;
    for (controllers) |ctrl| {
        if (ctrl.handle != null) count += 1;
    }
    return count;
}

fn gpinit_impl() callconv(.winapi) c_int {
    if (initialized) return getConnectedCount();

    if (!loadSDL2()) return -1;

    _ = pSDL_SetHint.?("SDL_NO_SIGNAL_HANDLERS", "1");
    _ = pSDL_SetHint.?("SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS", "1");
    _ = pSDL_SetHint.?("SDL_WINDOWS_DISABLE_THREAD_NAMING", "1");
    _ = pSDL_SetHint.?("SDL_GRAB_KEYBOARD", "0");
    _ = pSDL_SetHint.?("SDL_IME_INTERNAL_EDITING", "0");
    _ = pSDL_SetHint.?("SDL_IME_SHOW_UI", "0");

    const init_result = pSDL_Init.?(SDL_INIT_GAMECONTROLLER | SDL_INIT_NOPARACHUTE);
    if (init_result < 0) {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
        return -1;
    }

    pSDL_SetEventFilter.?(eventFilter, null);
    initialized = true;
    openControllers();
    return getConnectedCount();
}

fn gpend_impl() callconv(.winapi) void {
    if (!initialized) return;
    closeControllers();
    pSDL_SetEventFilter.?(null, null);
    pSDL_QuitSubSystem.?(SDL_INIT_GAMECONTROLLER);

    if (sdl2_dll != null) {
        _ = FreeLibrary(sdl2_dll);
        sdl2_dll = null;
    }

    // Clear function pointers
    pSDL_Init = null;
    pSDL_QuitSubSystem = null;
    pSDL_SetHint = null;
    pSDL_GameControllerUpdate = null;
    pSDL_NumJoysticks = null;
    pSDL_IsGameController = null;
    pSDL_GameControllerOpen = null;
    pSDL_GameControllerClose = null;
    pSDL_GameControllerGetAttached = null;
    pSDL_GameControllerGetJoystick = null;
    pSDL_GameControllerGetButton = null;
    pSDL_GameControllerGetAxis = null;
    pSDL_GameControllerRumble = null;
    pSDL_JoystickOpen = null;
    pSDL_JoystickClose = null;
    pSDL_JoystickInstanceID = null;
    pSDL_SetEventFilter = null;

    initialized = false;
}

fn gpgetjoynum_impl() callconv(.winapi) c_int {
    if (!initialized) return 0;
    pSDL_GameControllerUpdate.?();
    return getConnectedCount();
}

fn gpgetjoystate_impl(state: ?*c_int, index: c_int) callconv(.winapi) c_int {
    if (!initialized or state == null) return -1;
    if (index < 0 or index >= MAX_CONTROLLERS) return -1;

    const ctrl = &controllers[@intCast(index)];
    if (ctrl.handle == null) {
        state.?.* = 0;
        return -1;
    }

    pSDL_GameControllerUpdate.?();

    var result: u32 = 0;
    const handle = ctrl.handle.?;

    // D-Pad (bits 0-3)
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_DPAD_UP) != 0) result |= DPAD_UP;
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_DPAD_DOWN) != 0) result |= DPAD_DOWN;
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_DPAD_LEFT) != 0) result |= DPAD_LEFT;
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_DPAD_RIGHT) != 0) result |= DPAD_RIGHT;

    // Buttons (bits 4-15)
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_START) != 0) result |= BTN_START;
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_BACK) != 0) result |= BTN_BACK;
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_LEFTSTICK) != 0) result |= BTN_L3;
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_RIGHTSTICK) != 0) result |= BTN_R3;
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_LEFTSHOULDER) != 0) result |= BTN_LB;
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_RIGHTSHOULDER) != 0) result |= BTN_RB;

    const lt = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_TRIGGERLEFT);
    const rt = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_TRIGGERRIGHT);
    if (lt > TRIGGER_THRESHOLD) result |= BTN_LT;
    if (rt > TRIGGER_THRESHOLD) result |= BTN_RT;

    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_A) != 0) result |= BTN_A;
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_B) != 0) result |= BTN_B;
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_X) != 0) result |= BTN_X;
    if (pSDL_GameControllerGetButton.?(handle, SDL_CONTROLLER_BUTTON_Y) != 0) result |= BTN_Y;

    // Left stick direction (bits 16-19)
    const lx = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_LEFTX);
    const ly = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_LEFTY);
    if (ly < -STICK_DEADZONE) result |= LSTICK_UP;
    if (ly > STICK_DEADZONE) result |= LSTICK_DOWN;
    if (lx < -STICK_DEADZONE) result |= LSTICK_LEFT;
    if (lx > STICK_DEADZONE) result |= LSTICK_RIGHT;

    // Right stick direction (bits 20-23)
    const rx = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_RIGHTX);
    const ry = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_RIGHTY);
    if (ry < -STICK_DEADZONE) result |= RSTICK_UP;
    if (ry > STICK_DEADZONE) result |= RSTICK_DOWN;
    if (rx < -STICK_DEADZONE) result |= RSTICK_LEFT;
    if (rx > STICK_DEADZONE) result |= RSTICK_RIGHT;

    state.?.* = @bitCast(result);
    return 0;
}

fn gpbitcheck_impl(state: c_int, bit: c_int) callconv(.winapi) c_int {
    if (bit < 0 or bit > 31) return 0;
    return if ((@as(u32, @bitCast(state)) >> @intCast(bit)) & 1 != 0) 1 else 0;
}

fn gpgetstick_impl(lx: ?*c_int, ly: ?*c_int, rx: ?*c_int, ry: ?*c_int, index: c_int) callconv(.winapi) c_int {
    if (!initialized) return -1;
    if (index < 0 or index >= MAX_CONTROLLERS) return -1;

    const ctrl = &controllers[@intCast(index)];
    if (ctrl.handle == null) return -1;

    pSDL_GameControllerUpdate.?();
    const handle = ctrl.handle.?;

    if (lx) |p| p.* = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_LEFTX);
    if (ly) |p| p.* = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_LEFTY);
    if (rx) |p| p.* = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_RIGHTX);
    if (ry) |p| p.* = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_RIGHTY);

    return 0;
}

fn gpgettrigger_impl(left: ?*c_int, right: ?*c_int, index: c_int) callconv(.winapi) c_int {
    if (!initialized) return -1;
    if (index < 0 or index >= MAX_CONTROLLERS) return -1;

    const ctrl = &controllers[@intCast(index)];
    if (ctrl.handle == null) return -1;

    pSDL_GameControllerUpdate.?();
    const handle = ctrl.handle.?;

    if (left) |p| p.* = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_TRIGGERLEFT);
    if (right) |p| p.* = pSDL_GameControllerGetAxis.?(handle, SDL_CONTROLLER_AXIS_TRIGGERRIGHT);

    return 0;
}

fn gprumble_impl(low_freq: c_int, high_freq: c_int, duration_ms: c_int, index: c_int) callconv(.winapi) c_int {
    if (!initialized) return -1;
    if (index < 0 or index >= MAX_CONTROLLERS) return -1;
    if (pSDL_GameControllerRumble == null) return -1;

    const ctrl = &controllers[@intCast(index)];
    if (ctrl.handle == null) return -1;

    const low: u16 = @intCast(std.math.clamp(low_freq, 0, 65535));
    const high: u16 = @intCast(std.math.clamp(high_freq, 0, 65535));
    const duration: u32 = @intCast(std.math.clamp(duration_ms, 0, 60000));

    if (pSDL_GameControllerRumble.?(ctrl.handle.?, low, high, duration) < 0) return -1;
    return 0;
}

fn gprumblestop_impl(index: c_int) callconv(.winapi) c_int {
    return gprumble_impl(0, 0, 0, index);
}

fn gpisconnected_impl(index: c_int) callconv(.winapi) c_int {
    if (!initialized) return 0;
    if (index < 0 or index >= MAX_CONTROLLERS) return 0;

    const ctrl = &controllers[@intCast(index)];
    if (ctrl.handle == null) return 0;

    return if (pSDL_GameControllerGetAttached.?(ctrl.handle.?) == SDL_TRUE) 1 else 0;
}

fn gppoll_impl() callconv(.winapi) c_int {
    if (!initialized) return 0;

    pSDL_GameControllerUpdate.?();

    var changed: c_int = 0;
    for (&controllers) |*ctrl| {
        if (ctrl.handle) |handle| {
            if (pSDL_GameControllerGetAttached.?(handle) != SDL_TRUE) {
                pSDL_GameControllerClose.?(handle);
                ctrl.handle = null;
                ctrl.joystick_id = -1;
                changed = 1;
            }
        }
    }

    const num_joysticks = pSDL_NumJoysticks.?();
    var i: c_int = 0;
    while (i < num_joysticks) : (i += 1) {
        if (pSDL_IsGameController.?(i) == SDL_TRUE) {
            const joystick = pSDL_JoystickOpen.?(i);
            if (joystick == null) continue;
            const jid = pSDL_JoystickInstanceID.?(joystick.?);
            pSDL_JoystickClose.?(joystick.?);

            var already_open = false;
            for (controllers) |ctrl| {
                if (ctrl.joystick_id == jid) {
                    already_open = true;
                    break;
                }
            }

            if (!already_open) {
                for (&controllers) |*ctrl| {
                    if (ctrl.handle == null) {
                        const handle = pSDL_GameControllerOpen.?(i);
                        if (handle) |h| {
                            ctrl.handle = h;
                            if (pSDL_GameControllerGetJoystick.?(h)) |js| {
                                ctrl.joystick_id = pSDL_JoystickInstanceID.?(js);
                            }
                            changed = 1;
                        }
                        break;
                    }
                }
            }
        }
    }

    return changed;
}

// Export with explicit names (using \x01 prefix to bypass stdcall mangling)
comptime {
    @export(&gpinit_impl, .{ .name = "\x01GPINIT" });
    @export(&gpend_impl, .{ .name = "\x01GPEND" });
    @export(&gpgetjoynum_impl, .{ .name = "\x01GPGETJOYNUM" });
    @export(&gpgetjoystate_impl, .{ .name = "\x01GPGETJOYSTATE" });
    @export(&gpbitcheck_impl, .{ .name = "\x01GPBITCHECK" });
    @export(&gpgetstick_impl, .{ .name = "\x01GPGETSTICK" });
    @export(&gpgettrigger_impl, .{ .name = "\x01GPGETTRIGGER" });
    @export(&gprumble_impl, .{ .name = "\x01GPRUMBLE" });
    @export(&gprumblestop_impl, .{ .name = "\x01GPRUMBLESTOP" });
    @export(&gpisconnected_impl, .{ .name = "\x01GPISCONNECTED" });
    @export(&gppoll_impl, .{ .name = "\x01GPPOLL" });
}
