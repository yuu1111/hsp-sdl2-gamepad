; gamepad.as - SDL2 GameController Wrapper for HSP

#ifndef __GAMEPAD_AS__
#define __GAMEPAD_AS__

#uselib "hsp-sdl2-gamepad.dll"

#func GPINIT "GPINIT"
#func GPEND "GPEND"
#func GPGETJOYNUM "GPGETJOYNUM"
#func GPGETJOYSTATE "GPGETJOYSTATE" var, int
#cfunc GPBITCHECK "GPBITCHECK" int, int

#func GPGETSTICK "GPGETSTICK" var, var, var, var, int
#func GPGETTRIGGER "GPGETTRIGGER" var, var, int
#func GPRUMBLE "GPRUMBLE" int, int, int, int
#func GPRUMBLESTOP "GPRUMBLESTOP" int
#func GPISCONNECTED "GPISCONNECTED" int
#func GPPOLL "GPPOLL"

; Bit definitions for GPGETJOYSTATE (XInput compatible)
; D-Pad (bits 0-3)
#const GP_DPAD_UP     0
#const GP_DPAD_DOWN   1
#const GP_DPAD_LEFT   2
#const GP_DPAD_RIGHT  3

; Buttons (bits 4-15)
#const GP_BTN_START   4
#const GP_BTN_BACK    5
#const GP_BTN_L3      6
#const GP_BTN_R3      7
#const GP_BTN_LB      8
#const GP_BTN_RB      9
#const GP_BTN_LT      10
#const GP_BTN_RT      11
#const GP_BTN_A       12
#const GP_BTN_B       13
#const GP_BTN_X       14
#const GP_BTN_Y       15

; Left Stick directions (bits 16-19)
#const GP_LSTICK_UP     16
#const GP_LSTICK_DOWN   17
#const GP_LSTICK_LEFT   18
#const GP_LSTICK_RIGHT  19

; Right Stick directions (bits 20-23)
#const GP_RSTICK_UP     20
#const GP_RSTICK_DOWN   21
#const GP_RSTICK_LEFT   22
#const GP_RSTICK_RIGHT  23

; Helper macros
#define global gamepad_init GPINIT
#define global gamepad_end GPEND
#define global gamepad_rumble(%1, %2, %3 = 0) GPRUMBLE %1, %1, %2, %3
#define global gamepad_rumble_stop(%1 = 0) GPRUMBLESTOP %1

#endif
