[BITS 16]

start:
  jmp main

main: 
  call test_a20

halt:
  jmp $

test_a20:
  push es

  mov ax, 0
  mov ax, WORD [0x7C00 + 510]
  xchg bx, bx

  pop es
  ret
  
A20_FLAG_VALUE: EQU 0xFF
