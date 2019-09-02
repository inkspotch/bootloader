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
  cmp ax, 0
  je .error
  
  print message_enabled
  call boot2
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

; GDT
gdt_start:
  dq 0x0
gdt_code:
  dw 0xFFFF
  dw 0x0
  dw 0x0
  db 10011010b
  db 11001111b
  db 0x0
gdt_data:
  dw 0xFFFF
  dw 0x0
  dw 0x0
  db 0x0
  db 10010010b
  db 11001111b
  db 0x0
gdt_end:

gdt_pointer: 
  dw gdt_end - gdt_start
  dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

message_enabled: db "A20 is enabled", 0
message_disabled: db "A20 cannot be enabled", 0

bits 32
boot2:
  mov ax, DATA_SEG
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax
  ret
