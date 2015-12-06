[BITS 16]
[ORG 0x7C00]

jmp 0:main

main: 
  cli
  mov ax, 0x0
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, ax

  mov si, message
  call print_message

print_message:
  lodsb
  or al, al
  jz .done
  mov ah, 0x0E
  int 0x10
  jmp print_message
  .done ret

message db 'Hello from memory!', 13, 10, 0

; bootable flag at bytes 511-55 and 512-AA
times 510-($-$$) db 0
dw 0xAA55
