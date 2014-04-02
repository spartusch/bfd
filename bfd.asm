;
;          Brainfucked version 1.0.0 - A nice DOS/Windows compiler for brainfuck
;
;          Copyright (c) 2002, 2005 by Stefan Partusch
;
;          This software is provided 'as-is', without any express or implied
;          warranty.  In no event will the author be held liable for any damages
;          arising from the use of this software.
;          For more details see the GNU General Public License!
;
;          Brainfucked is assembled with NASM:      nasm -fbin -obfd.com bfd.asm
;
;          Brainfuck:        Equivalent in asm:       Opcode (hex/byte):
;              +             add byte [si], xx        80 04 xx
;                            inc byte [si]            FE 04
;              -             sub byte [si], xx        80 2C xx
;                            dec byte [si]            FE 0C
;              >             add si, byte xx          83 C6 xx
;                            inc si                   46
;              <             sub si, byte xx          83 EE xx
;                            dec si                   4E
;              [             cmp byte [si], 0         80 3C 00
;                            je "]+1"                 0F 84 xx xx
;              ]             jmp "["                  E9 xx xx
;              .             call "11Bh"              E8 xx xx
;              ,             call "10Fh"              E8 xx xx
;
org         100h
BITS 16


section .data

newLine     db  13, 10, 13, 10, "$"
extension   db  "com", 0
header      db  "Brainfucked 1.0.0 by S. Partusch$"
errUsage    db  "Usage: bfd [-n] file", 13, 10, 9, "-n native mode$"
errFile     db  "ERR: File$"
errBracket  db  "ERR: Loop$"
wrnBracket  db  "WRN: Range", 13, 10
success     db  "File assembled$"

; opInit is (create zero-initialized array of 44000 bytes):
    ; mov si, 0FE70h / DECSI: dec si / mov byte [si], 0 / cmp si, 0528Fh / jne DECSI / jmp short
opInit      db 14, 0BEh, 070h, 0FEh, 04Eh, 0C6h, 004h, 000h, 081h, 0FEh, 08Fh, 052h, 075h, 0F6h, 0EBh

; opProcTxt (CRLF-translation) is:
    ; read char, store and print it - entry point 10Fh
    ; END / mov ah, 08h / int 21h / cmp al, 13 / jne STORE / xor al, 7 / STORE: mov [si], al
    ; print char - entry point 11Bh
    ; mov ah, 02h / mov dl, [si] / cmp dl, 10 / jne WRITE / xor dl, 7 / int 21h / xor dl, 7 / WRITE: int 21h / ret
    ; END:
opProcTxt   db 33, 020h, 0B4h, 008h, 0CDh, 021h, 03Ch, 00Dh, 075h, 002h, 034h, 007h, 088h, 004h, 0B4h, 002h, 08Ah, 014h, 080h, 0FAh, 00Ah, 075h, 008h, 080h, 0F2h, 007h, 0CDh, 021h, 080h, 0F2h, 007h, 0CDh, 021h, 0C3h

; opProcBin (no CRLF-translation) is:
    ; read char, store it - entry point 10Fh
    ; END / mov ah, 08h / int 21h / mov [si], al / ret / nop / nop / nop / nop / nop
    ; print char - entry point 11Bh
    ; mov ah, 02h / mov dl, [si] / int 21h / ret / END:
opProcBin   db 20, 013h, 0B4h, 008h, 0CDh, 021h, 088h, 004h, 0C3h, 090h, 090h, 90h, 090h, 090h, 0B4h, 002h, 08Ah, 014h, 0CDh, 021h, 0C3h

; opOut is (end program): mov ah, 4Ch / int 21h
opOut       db  4, 0B4h, 04Ch, 0CDh, 021h

opPlusInc   db  2, 0FEh, 004h                                   ;  0
opMinusDec  db  2, 0FEh, 00Ch                                   ;  1
opAnglODec  db  1, 04Eh                                         ;  2
opAnglCInc  db  1, 046h                                         ;  3
opSqurOpen  db  7, 080h, 03Ch, 000h, 00Fh, 084h, 000h, 000h     ;  4
opCallSub1  db  1, 0E8h                                         ;  5
opCallSub2  db  1, 0E8h                                         ;  6
opSqurClose db  1, 0E9h                                         ;  7
opPlusAdd   db  2, 080h, 004h                                   ;  8
opMinusSub  db  2, 080h, 02Ch                                   ;  9
opAnglOSub  db  2, 083h, 0EEh                                   ; 10
opAnglCAdd  db  2, 083h, 0C6h                                   ; 11

opProc      dw  opProcTxt
outPos      dw  0

commands    db  "+-<>[.,]"
prevCommand db  0FFh
commCount   db  1

squrBrack   db  0
anglBrack   db  0
anglState   db  0


section .bss

fileName    resb    130
fileNLen    resw    1
fileIn      resw    1
fileOut     resw    1
addressBuf  resw    1
buffer      resb    1


section .text

; read command line and get arguments:
    ;cld
    mov     si, 80h                     ; see Program Segment Prefix (PSP) for details
    lodsb
    cbw                                 ; ax = length of command line
    mov     cx, ax
    mov     di, fileName                ; si = source/command line, di = destination/fileName
    RMV_SPACE:
        cmp     byte [si], 20h          ; ignore leading spaces (ASCII 20h)
        jne     short RMV_END
        inc     si
        dec     cx
        jmp     short RMV_SPACE
    RMV_END:
    cmp     word [si], "-n"
    jne     short CONTINUE
    add     si, 2
    sub     cx, 2
    mov     word [opProc], opProcBin
    jmp     short RMV_SPACE
    CONTINUE:
    dec     cx                          ; cmp cx, 0
    jns     short ARGUMENTS_OK
    mov     si, errUsage
    jmp     near QUIT_NOFILE
    ARGUMENTS_OK:
    inc     cx
    mov     word [fileNLen], cx
    rep     movsb
    mov     byte [di], cl               ; fileName terminates with 0

; open input
    mov     ax, 3D00h                   ; al = 00, ah = 3D; open fileName
    mov     dx, fileName
    int     21h
    jc      near ERROR_FILE
    mov     word [fileIn], ax

; compute output filename
    ;mov     di, fileName
    ;add     di, [fileNLen]             ; go to end of fileName
    std
    mov     cl, [fileNLen]
    mov     al, "."                     ; search first "." backwards
    repne   scasb
    dec     cx                          ; cmp cx, 0
    js      near ERROR_FILE
    cld
    mov     cx, 4
    mov     si, extension
    inc     di
    inc     di
    rep     movsb
    
; create output
    mov     ax, 3C00h                   ; al = 00, ah = 3C; create file fileName
    mov     dx, fileName
    int     21h
    jc      near ERROR_FILE
    mov     word [fileOut], ax

; write output code (i.e. compile)
    mov     si, opInit
    call    WRITE_OPCODE
    mov     si, [opProc]
    call    WRITE_OPCODE
    
    ; translate brainfuck
    TRANSLATION:
        mov     ah, 3Fh                 ; read input
        mov     bx, [fileIn]
        mov     cx, 1
        mov     dx, buffer
        int     21h
        jc      near ERROR_FILE
        ;cmp     ax, 0                  ; number of bytes read
        dec     ax
        js      short TRANSLATION_END
        
        ; ignore non-brainfuck characters
        mov     al, byte [buffer]
        mov     cx, 9
        mov     di, commands
        repne   scasb
        dec     cx                      ; cmp cx, 0
        js      short TRANSLATION
        
        ; calculate bf-command's number (0-7)
        mov     bx, di
        sub     bx, commands
        dec     bl
        mov     byte [buffer], bl       ; buffer now number between 0 and 7 "+-<>[.,]"
        
        cmp     bl, 3
        jg      short NO_COUNT_CMD_READ ; no "countable" command read

        ; one of +-<> read
        jne     short NO_ANGLC          ; ">" (number 3) read
            inc     byte [anglBrack]    ; for syntax-check
        NO_ANGLC:
        cmp     bl, 2                   ; "<" (number 2) read
        jne     short ANGL_OK
            dec     byte [anglBrack]    ; syntax-check
            jns     short ANGL_OK
            mov     byte [anglState], 0FFh
        ANGL_OK:
        cmp     byte [prevCommand], bl
        jne     short NEW_COUNT         ; new "countable" command read
        inc     byte [commCount]
        jmp     short TRANSLATION
        NEW_COUNT:
        mov     al, byte [prevCommand]
        call    WRITE_COMMAND
        mov     bl, byte [buffer]
        mov     byte [prevCommand], bl  ; save new command as old command
        jmp     short TRANSLATION
        
        ; one of [.,] read
        NO_COUNT_CMD_READ:
        mov     al, byte [prevCommand]
        call    WRITE_COMMAND
        mov     al, byte [buffer]
        call    WRITE_COMMAND
        jmp     short TRANSLATION

    TRANSLATION_END:
    mov     si, opOut
    call    WRITE_OPCODE

    mov     si, success

    QUIT:
    mov     ah, 3Eh                     ; close files
    mov     bx, word [fileIn]
    int     21h
    mov     bx, word [fileOut]
    int     21h
    
    ; check syntax and set error messages
    cmp     byte [squrBrack], 0
    jne     short ERROR_SQURBRACK

    cmp     byte [anglState], 0
    je      short QUIT_NOFILE
    mov     si, wrnBracket

    QUIT_NOFILE:
    mov     dx, header
    call    PRINTLINE

    xor     al, al
    cmp     si, success
    je      short $+2
    inc     al                          ; return code 1 to indicate error
    
    mov     dx, si
    call    PRINTLINE

    mov     ah, 4Ch                     ; ah = 4C; end program
    int     21h


;----------------------
;   subprocedures:
;----------------------
;   write to STDIN:
;----------------------
PRINTLINE:
    mov     ah, 09h
    int     21h
    mov     dx, newLine
    int     21h
    ret

;----------------------
;   errors:
;----------------------
ERROR_FILE:
    mov     si, errFile
    jmp     short QUIT_NOFILE

ERROR_SQURBRACK:
    mov     ah, 41h                     ; delete file
    mov     dx, fileName
    int     21h
    mov     si, errBracket
    jmp     short QUIT_NOFILE

;----------------------
;   translation:
;----------------------
COMMAND_SQURCLOSE:
    dec     byte [squrBrack]            ; never < 0
    js      short QUIT
    pop     bx                          ; save return address for WRITE_COMMAND
    pop     ax
    sub     ax, 7
    push    bx
    call    WRITE_DIFF
    ; set file pointer to "["+5 (to write offset of end of loop)
    mov     cx, 0FFFFh
    mov     dx, [addressBuf]
    add     dx, 5
    mov     ax, 4201h
    int     21h
    ; offset to jmp to end of loop: FFFF - (neg_number + 1) = pos_number
    mov     bx, 0FFF9h                  ; -6 instead of -1 because of add dx,5
    sub     bx, word [addressBuf]
    mov     word [addressBuf], bx
    ; write offset
    mov     dx, addressBuf
    mov     cx, 2
    call    WRITE_OUTPUT
    sub     word [outPos], cx
    ; set file pointer to "normal" position
    xor     cx, cx
    mov     dx, [outPos]
    mov     ax, 4200h
    int     21h
    jmp     short WC_END

WRITE_COMMAND:
    cmp     al, 0FFh                    ; no command to write
    jne     short $+1
    ret
    cmp     byte [commCount], 1         ; "countable" command?
    je      short NO_COUNT

    add     al, 8                       ; use add/sub version of command
    call    WRITE_COMMAND_OP
    mov     cx, 1
    mov     dx, commCount
    call    WRITE_OUTPUT
    jmp     short WC_END

    NO_COUNT:
    push    ax                          ; save and write command
    call    WRITE_COMMAND_OP
    pop     ax

    cmp     al, 4
    jl      short WC_END
    je      short COMMAND_SQUROPEN
    cmp     al, 6
    jl      short COMMAND_POINT
    je      short COMMAND_COMMA
    jg      short COMMAND_SQURCLOSE

    WC_END:
    mov     byte [commCount], 1
    mov     byte [prevCommand], 0FFh
    ret

COMMAND_SQUROPEN:
    inc     byte [squrBrack]            ; for syntax-check
    pop     bx                          ; save return address for WRITE_COMMAND
    push    word [outPos]
    push    bx
    jmp     short WC_END

COMMAND_POINT:
    mov     ax, 1Bh
    call    WRITE_DIFF
    jmp     short WC_END

COMMAND_COMMA:
    mov     ax, 0Fh
    call    WRITE_DIFF
    jmp     short WC_END
    
WRITE_DIFF:
; ax = offset to jump to
    mov     cx, 2
    sub     ax, [outPos]
    sub     ax, cx
    mov     word [addressBuf], ax
    mov     dx, addressBuf
    call    WRITE_OUTPUT                ; write offset for jmp
    ret

WRITE_COMMAND_OP:
; al = number of command to write (0 to 11)
    mov     si, opPlusInc
    ;xor     bh, bh
    FIND_OPCODE:
        dec     al                      ; cmp al, 0
        js      short WRITE_OPCODE
        mov     bl, byte [si]
        add     si, bx
        inc     si
    jmp     short FIND_OPCODE
    
WRITE_OPCODE:
; si = address of array of opcodes, first byte must be size
    ;xor     cx, cx
    mov     cl, byte [si]
    mov     dx, si
    inc     dx
WRITE_OUTPUT:
; cx = number of bytes to write
; dx = address of bytes to write
    mov     ah, 40h
    mov     bx, [fileOut]
    int     21h
    jc      ERROR_FILE
    add     word [outPos], ax
    ret
