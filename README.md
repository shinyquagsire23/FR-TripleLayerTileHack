So for a long time there has been a bit of an underground-ish ASM routine (made by diegoisawesome) that's gone around which enabled a hacker to have a triple layered blocks, which is done by using the bottom layer of the next block as the third layer of the tripled block. To demonstrate graphically, imagine this is your average block:



[bottom layer (4 bytes)] [top layer (4 bytes)]



Depending on the background byte, these two layers will be loaded with either both underneath the player or the top layer above the player. With the triple layer tiles, it will load like this:



[bottom layer (4 bytes)] [middle layer layer (4 bytes)] {player} [top layer (4 bytes)]



However, I found this system to be slightly inefficient, and given all the extra bits that Fire Red has been blessed with by GameFreak due to the fact that Fire Red has 4 bytes for block behaviors instead of 2, we can utilise these extra bits available to us to create a reference-based triple-layer tile. That is, a tile which will tell the game which block to pull it's top layer from.



To start, I wrote out the original block rendering routine, which can be compiled and inserted at 0805A9B4. In it's current state, it is very inefficient and has a lot of repeating code:

```
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
@ Commented out due to space restrictions. This code block is unused anyhow.
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
```

I should probably note that this version was actually slightly larger due to the bl's at the end, and as such part of the unused part of the routine was cut out. But, after some optimisations we can come out with a much cleaner version of this renderer which is a lot more efficient:

```
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
b render

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
```

In this version we cut out a lot of the repetition and junk, bringing our routine down to a slim 188 bytes, 100 bytes smaller than the original 288. With some modification, I added my triple layer tile hack:

```
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
```(To insert this, compile the routine and overwrite the bytes at 0x05A9B4. The compiled size should be 288 (0x120) bytes long. Any larger will overwrite part of the next routine.)



So how does it work? There are a few parts to this. First, the background byte must be set to 0x60, which will trigger the triple layer tile code. Next, we need to select our block which will be the top layer donor. In vanilla Fire Red, block 0xF contains a top layer for trees. Now since we're using only unused bits, we are required to use the following mask for identifying our block:

```
00FFC000
```

Which is basically just 10 bits bitshifted left by 14.



So how can I use this in A-Map? Well, it's a bit complicated. First you need to take your block number (in our case 0xF) and bit shift it left by 14. For us, we get 38000, or if we pad it with 0's to get a full dword, 00038000. Now the trick here is inserting it into A-Map's behavior byte editor properly. As of now, A-Map's byte editor literally just takes the four bytes and gives them textboxes. The problem is, we need to split up our value into the right boxes. This is the current byte order it uses for Fire Red:

```

[0][1]

[2][3]

```

So if we split up our dword by bytes (00 03 80 00), we'll get something like this:


```

[00][80]

[03][60]

```

Now the reason why I put a 60 in there, is because that is what triggers the triple tile. Now obviously your tile might have additional bits set for block behaviors and wild encounters, and the solution to that is to only modify boxes 1 and 2, and the upper half of box 3 (which we replace with a 6).



With that set, you can go ahead and test it in VBA. Here's a sample screen of what you can do using this system:

![Triple Layer Tiles as shown in Fire Red](http://i.imgur.com/rVdQkYu.png)

As you can see, you have the ground underneath the fence, the fence itself, and a tree above both. This system is especially useful for trees in particular because it allows you to have more dynamic environments with better looking trees without having to sacrifice additional tiles in your tileset.

