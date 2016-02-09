[BITS 16]

mov ax, 0x2e00
mov bx, ax
mov BYTE [es:bx], 'X'

jmp $
