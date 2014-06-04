.thumb
.thumb_func

main:
push {r4,lr}
mov r4, r1
lsl r2, r2, #0x10
lsr r2, r2, #0x10
cmp r0, #0x1
beq underplayer
cmp r0, #0x1
bgt triple
cmp r0, #0x0
beq overplayer
b render

triple:
cmp r0, #0x2
bne render

triplestuffing:
@ Write bottom blocks
@ldr r0, overworld_bg3_tilemap
@ldr r0, [r0]
@lsl r3,r2,#0x1
@add r0, r3, r0
ldrh r1, [r4]
strh r1, [r0] @ Write top left bg tile
ldrh r1, [r4,#0x2]
strh r1, [r0,#0x2]
mov r2, r0
add r2, #0x40
ldrh r1, [r4, #0x4]
strh r1, [r2]
add r0, #0x42
ldrh r1, [r4, #0x6]
strh r1, [r0]

@ Write top blocks
ldr r0, overworld_bg2_tilemap
ldr r0, [r0]
add r0, r3, r0
mov r2, #0x0
strh r2, [r0]
strh r2, [r0,#0x2]
mov r1, r0
add r1, #0x40
strh r2, [r1]
add r0, #0x42
strh r2, [r0]
b overplayer_bg1

underplayer:
@ Write bottom blocks
ldr r0, overworld_bg3_tilemap
ldr r0, [r0]
lsl r3,r2,#0x1
add r0, r3, r0
ldrh r1, [r4]
strh r1, [r0] @ Write top left bg tile
ldrh r1, [r4,#0x2]
strh r1, [r0,#0x2]
mov r2, r0
add r2, #0x40
ldrh r1, [r4, #0x4]
strh r1, [r2]
add r0, #0x42
ldrh r1, [r4, #0x6]
strh r1, [r0]

@ Write top blocks
ldr r0, overworld_bg2_tilemap
ldr r0, [r0]
add r0, r3, r0
ldrh r1, [r4,#0x8]
strh r1, [r0]
ldrh r1, [r4, #0xA]
strh r1, [r0,#0x2]
mov r2, r0
add r2, #0x40
ldrh r1, [r4,#0xC]
strh r1, [r2]
add r0, #0x42
ldrh r1, [r4,#0xE]
strh r1, [r0]

@ Clear other existing blocks
ldr r0, overworld_bg1_tilemap
ldr r0, [r0]
add r3, r3, r0
mov r1, #0x0
strh r1, [r3]
strh r1, [r3,#0x2]
mov r0, r3
add r0, #0x40
strh r1, [r0]
add r3, #0x42
str r1, [r3]
b render

overplayer:
@ Write nothing to bottom (not sure why they use 0x3014 :/)
ldr r0, overworld_bg3_tilemap
ldr r0, [r0]
lsl r3,r2, #1
add r0, r3, r0
ldr r1, _3014
mov r2, r1
strh r2, [r0]
strh r2, [r0,#0x2]
mov r1, r0
add r1, #0x40
strh r2, [r1]
add r0, #0x42
strh r2, [r0]

ldr r0, overworld_bg2_tilemap
ldr r0, [r0]
add r0, r3, r0
ldrh r1, [r4]
strh r1, [r0]
ldrh r1, [r4,#0x2]
strh r1, [r0,#0x2]
mov r2, r0
add r2, #0x40
ldrh r1, [r4,#0x4]
strh r1, [r2]
add r0, #0x42
ldrh r1, [r4,#0x6]
strh r1, [r0]

overplayer_bg1:
ldr r0, overworld_bg1_tilemap
ldr r0, [r0]
add r3, r3, r0
ldrh r0, [r4,#0x8]
strh r0, [r3]
ldrh r0, [r4,#0xA]
strh r0, [r3,#0x2]
mov r1, r3
add r1, #0x40
ldrh r0, [r4,#0xC]
strh r0, [r1]
add r3, #0x42
ldrh r0, [r4,#0xE]
strh r0, [r3]

render:
mov r0, #0x1
ldr r1, render_bgmap
bl bx_r1
mov r0, #0x2
ldr r1, render_bgmap
bl bx_r1
mov r0, #0x3
ldr r1, render_bgmap
bl bx_r1
pop {r4}
pop {r0}
bx r0

bx_r1:
bx r1

.align 2
overworld_bg1_tilemap: .long 0x03005018
overworld_bg2_tilemap: .long 0x03005014
overworld_bg3_tilemap: .long 0x0300501C
_3014: .long 0x3014
render_bgmap: .long 0x080F67A4+1



