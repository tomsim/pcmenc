;----------------------------------------------------------------------------
; Copyright (C) 2006 Arturo Ragozini and Daniel Vik
;
; This software is provided 'as-is', without any express or implied
; warranty. In no event will the authors be held liable for any damages
; arising from the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must not
; claim that you wrote the original software. If you use this software
; in a product, an acknowledgment in the product documentation would be
; appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
; misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;----------------------------------------------------------------------------

; Modified in 2016 by Maxim for operation on Sega 8-bit consoles (and similar 
; hardware with IO-mapped SN76489 variants)

;
; Replayer core to play packed-volume 44kHz samples generated by pcmenc
;
; pcmenc should use the following command line arguments:
;
; pcmenc -rto 3 -p 4 -dt1 81 -dt2 81 -dt3 82 file.wav
;
; and optionally -r to split sample into blocks for rom replayer
;

; There is one channel update per underlying sample.
; We emit three channel updates, as evenly spaced as possible, looping
; every 244 cycles, to match an underlying sample at 44011Hz

;-------------------------------------
; Plays one sample
; HL - pointes to triplet count followed by data
;-------------------------------------
PLAY_SAMPLE:
  ld c, (hl)
  inc hl
  ld b, (hl)
  inc hl
  
.macro GetHi
  ld a,(hl)       ; 7
  .repeat 4
  rra             ; 16
  .endr
  and $0f         ; 7
.endm             ; Total 30

.macro GetLo
.ifdef colours
  ld a,$10        ; 7
  out ($bf),a     ; 11
  ld a,(hl)       ; 7
  inc hl          ; 6
  out ($be),a     ; 11
  and $0f         ; 7 -> 49
.else
  push ix         ; 15 (time wasting)
  pop ix          ; 14
  ld a,(hl)       ; 7
  inc hl          ; 6
  and $0f         ; 7 -> 49
.endif
.endm             ; Total 49

.macro PlayHi args channel
  GetHi           ; 30
  or (channel << 5) | $90 ; 7
  out ($7f),a     ; 11 -> 48
.endm

.macro PlayLo args channel
  GetLo           ; 49
  or (channel << 5) | $90 ; 7
  out ($7f),a     ; 11 -> 67
.endm
82
.macro Delay args n
  .printt "Delay "
  .printv dec n
  .printt "\n"
  .if n == 14
  or 0    ; 7
  or 0    ; 7
  .else
  .if n == 10
  jp +
  +:
  .else
  .if n == 8
  ld a,a  ; 4
  ld a,a  ; 4
  .else
  .if n == 4
  ld a,a  ; 4
  .else
  .if n == 0
  ; nothing :)
  .else
  .if n == 33
  push af     ; 11
  pop af      ; 10
  bit 0,(hl)  ; 12
  .else
  .printt "Unhandled delay "
  .printv dec n
  .printt "\n"
  .fail
  .endif
  .endif
  .endif
  .endif
  .endif
  .endif
.endm


PsgLoop:
  PlayHi 0        ;  48 -> 82

  Delay              81-67
  PlayLo 1        ;  67       ; good
  
  Delay              81-6-4-4-11-48
  dec bc          ;   6 ; We check the counter here because we are short of time on the next part
  ld a,b          ;   4
  or c            ;   4
  push af         ;  11
    PlayHi 2      ;  48 -> 81 ; bad

    Delay            82-10-5-67
  pop af          ;  10
  ret z           ;   5
  PlayLo 0        ;  67 -> 82
  
  Delay              81-48
  PlayHi 1        ;  48 -> 81
  
  Delay              81-67
  PlayLo 2        ;  67 -> 81

  Delay               82-6-4-4-10-48
  dec bc          ;   6
  ld a,b          ;   4
  or c            ;   4
  jp nz, PsgLoop  ;  10

  ret