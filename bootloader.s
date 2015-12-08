[BITS 16]
[ORG 0x7C00]

jmp 0:start

%include "print.inc"

start:
  mov ax, 0
  mov ss, ax

  call clear_screen
  print message

  jmp halt

halt: jmp $

message db "Booting...", 0

times 510-($-$$) db 0
db 0x55
db 0xAA
