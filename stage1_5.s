[BITS 16]
[ORG 0x2e00]

start:
  jmp main

%include "bios_print.inc"

main: 
  mov ax, cs
  mov ds, ax

  call test_a20
  call clear_screen
  xchg bx, bx
  cmp ax, 0
  je .error
  
  print message_enabled
  jmp halt

  .error: 
    print message_disabled

halt:
  jmp $

; ax will be 1 if A20 is enabled; otherwise ax will be 0
test_a20:
  push es
  push ds

  cli

  ; write 0x00 at 0x0000:0500
  xor ax, ax
  mov es, ax  
  mov di, 0x0500 

  ; save original value
  mov al, byte[es:di]
  push ax

  mov byte[es:di], 0x00

  ; write 0xFF at 0xFFFF:0510 
  mov ax, 0xFFFF
  mov ds, ax
  xor ax, ax
  mov si, 0x510
  
  ; save original value
  mov al, byte[ds:si]
  push ax

  mov byte[ds:si], 0xFF
  
  ; if 0x0:500 is 0xFF, there was a wrap around
  cmp byte[es:di], 0xFF

  ; restore memory
  pop ax
  mov byte[ds:si], al

  pop ax
  mov byte[es:di], al
  
  mov ax, 0
  je .exit

  mov ax, 1
  
  .exit:
    pop ds
    pop es
    ret

  message_enabled: db "A20 is enabled", 0
  message_disabled: db "A20 cannot be enabled", 0
