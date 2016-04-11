;----------------------------------------------------------------------------
; Copyright (C) 2006 Arturo Ragozini and Daniel Vik
;
;  This software is provided 'as-is', without any express or implied
;  warranty.  In no event will the authors be held liable for any damages
;  arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any purpose,
;  including commercial applications, and to alter it and redistribute it
;  freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you must not
;     claim that you wrote the original software. If you use this software
;     in a product, an acknowledgment in the product documentation would be
;     appreciated but is not required.
;  2. Altered source versions must be plainly marked as such, and must not be
;     misrepresented as being the original software.
;  3. This notice may not be removed or altered from any source distribution.
;----------------------------------------------------------------------------

;
; Replayer core to play RLE encoded 44.1kHz samples generated by pcmenc
;
; pcmenc should use the following command line arguments:
;
;    pcmenc -p 1 -dt1 73 -dt2 84 -dt3 291 file.wav
;
; and optionally -r to split sample into 8kB blocks for rom replayer
;



;-------------------------------------
; Plays one sample
; IN   HL - Encoded sample start address
;      DE - Sample length (#pcm samples)
;-------------------------------------
PLAY_SAMPLE:
        push    hl
        ld      h,d
        inc     h
        ld      a,e
        exx
        pop     hl
        ld      b,a
        ld      c,$00       ; 8
        ld      de,$0000    ; 11

PsgLoop:
; Calculate channel A volume
        ld      a,c         ; 5
        sub     $20         ; 8
        jr      nc,PsgWaitA ; 8/13
        ld      a,8         ; 8
        out     ($a0),a     ; 12
        ld      a,(hl)      ; 8
        inc     hl          ; 7
        ld      c,a         ; 5
        out     ($a1),a     ; 12    -> 73
PsgDoneA:

; Calculate channel B volume
        ld      a,d         ; 5
        sub     $20         ; 8
        jr      nc,PsgWaitB ; 8/13
        ld      a,9         ; 8
        out     ($a0),a     ; 12
        ld      a,(hl)      ; 8
        inc     hl          ; 7
        ld      d,a         ; 5
        out     ($a1),a     ; 12    -> 73
PsgDoneB:
        
; Calculate channel C volume
        ld      a,e         ; 5
        sub     $20         ; 8
        jr      nc,PsgWaitC ; 8/13
        ld      a,10        ; 8
        out     ($a0),a     ; 12
        ld      a,(hl)      ; 8
        inc     hl          ; 7
        ld      e,a         ; 5
        out     ($a1),a     ; 12    -> 73
PsgDoneC:

        call    Wait212     ; 212

        ; Decrement length and return if zero
        djnz    PsgLoop     ; 9/14  -> 14   Total: 447
        exx                 ; 5
        dec     h           ; 5
        exx                 ; 5     -> 5
        jp      nz,PsgLoop  ; 11
        ret

        
PsgWaitA:
        ld      c,a         ; 5
        inc     hl          ; 7
        dec     hl          ; 7
        nop                 ; 5
        nop                 ; 5
        nop                 ; 5
        jr      PsgDoneA    ; 13   -> 60 including branch
        
PsgWaitB:
        ld      d,a         ; 5
        inc     hl          ; 7
        dec     hl          ; 7
        nop                 ; 5
        nop                 ; 5
        nop                 ; 5
        jr      PsgDoneB    ; 13   -> 60 including branch
        
PsgWaitC:
        ld      e,a         ; 5
        inc     hl          ; 7
        dec     hl          ; 7
        nop                 ; 5
        nop                 ; 5
        nop                 ; 5
        jr      PsgDoneC    ; 11   -> 60 including branch

Wait212:
        ex      (sp),ix     ; 25
        ex      (sp),ix     ; 25
        ex      (sp),ix     ; 25
        ex      (sp),ix     ; 25
        ex      (sp),ix     ; 25
        ex      (sp),ix     ; 25
        inc     hl          ; 7
        dec     hl          ; 7
        inc     hl          ; 7
        dec     hl          ; 7
        nop                 ; 5
        ret                 ; 11   -> 212 including branch
        