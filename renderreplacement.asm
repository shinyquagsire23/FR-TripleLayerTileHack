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
@ Write bottom blocks
ldr r0, overworld_bg3_tilemap
bl write_bottom_blocks

@ Write top blocks
ldr r0, overworld_bg2_tilemap
bl write_top_blocks

push {r2}
mov r0, r6
mov r1, r7
ldr r2, getBlockIDAt
bl bx_r2
mov r2, r0

ldr r1, =0x27F
cmp r2, r1
ble blockset_1
add r1, #0x1
sub r2, r2, r1
mov r1, #0x4
blockset_1:
add r1, #0x10
ldr r0, cur_mapheader
ldr r0, [r0] @ Get mapdata header
ldr r3, [r0, #0x10] @ Store blockset 1 pointer for later
ldr r5, [r0, #0x14] @ Store blockset 2 pointer for later
ldr r0, [r0, r1] @ Get blockset pointer
ldr r0, [r0, #0x14] @ Get blockset background bytes
lsl r1, r2, #0x2
ldr r0, [r0, r1] @ Get background byte
lsl r1, r0, #0x8
lsr r1, r1, #0x16 @Isolate bits we want
ldr r0, =0x27F
cmp r1, r0
bgt blockset2_tiles

@sub r1, r1, #0x8 @Get top layer
b write_third_layer

blockset2_tiles:
add r0, #0x1
sub r1, r1, r0
mov r3, r5
@sub r1, r1, #0x8 @Get top layer

write_third_layer:
ldr r4, [r3, #0xC] @ Get blockset pointer
lsl r1, r1, #0x4
add r4, r1, r4
pop {r2}

@ Write third layer
ldr r0, overworld_bg1_tilemap
lsl r3, r2, #0x1
bl write_top_blocks
b render

legacytriple:


@ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @
@ All blocks are underneath the player  @
@ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @
underplayer:
@ Write bottom blocks
ldr r0, overworld_bg3_tilemap
bl write_bottom_blocks

@ Write top blocks
ldr r0, overworld_bg2_tilemap
bl write_top_blocks

@ Clear other existing blocks
ldr r0, overworld_bg1_tilemap
bl write_nothing
b render


@ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @
@ The top layer of blocks is rendered over the player @
@ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @
overplayer:
@ Write bottom blocks
ldr r0, overworld_bg2_tilemap
bl write_bottom_blocks

@ Write top blocks
ldr r0, overworld_bg1_tilemap
bl write_top_blocks

@ Write nothing to bottom 
ldr r0, overworld_bg3_tilemap
bl write_nothing
b render

@ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @
@ Write first 4 blocks to bottom-most layer @
@ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @
write_bottom_blocks:
ldr r0, [r0]
lsl r3,r2,#0x1
add r0, r3, r0
ldrh r1, [r4]
strh r1, [r0] @ Write top left bg tile
ldrh r1, [r4,#0x2]
strh r1, [r0,#0x2]
add r0, #0x40
ldrh r1, [r4, #0x4]
strh r1, [r0]
ldrh r1, [r4, #0x6]
strh r1, [r0, #0x2]
bx lr

@ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @
@ Write last 4 blocks to top-most layer @
@ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @
write_top_blocks:
ldr r0, [r0]
add r0, r3, r0
ldrh r1, [r4,#0x8]
strh r1, [r0]
ldrh r1, [r4, #0xA]
strh r1, [r0,#0x2]
add r0, #0x40
ldrh r1, [r4,#0xC]
strh r1, [r0]
ldrh r1, [r4,#0xE]
strh r1, [r0, #0x2]
bx lr

@ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @
@ Write out 0's in the unused layer @
@ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @ @
write_nothing:
ldr r0, [r0]
lsl r3, r2, #1
add r0, r3, r0
mov r2, #0x0
strh r2, [r0]
strh r2, [r0,#0x2]
add r0, #0x40
strh r2, [r0]
strh r2, [r0, #0x2]
bx lr

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

bx_r2:
bx r2

.align 2
overworld_bg1_tilemap: .long 0x03005018
overworld_bg2_tilemap: .long 0x03005014
overworld_bg3_tilemap: .long 0x0300501C
render_bgmap: .long 0x080F67A4+1
getBlockIDAt: .long 0x08058E48+1
cur_mapheader: .long 0x02036DFC



