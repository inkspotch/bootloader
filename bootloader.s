[BITS 16]
[ORG 0x7C00]

jmp 0:start

start:
  mov ax, 0
  mov ss, ax

  mov ax, VIDEO_BUFFER
  mov es, ax
  mov di, 0

  mov ax, 0
  mov ds, ax
  mov si, message 

  call print
  jmp halt

halt: jmp $

print:
  lodsb
  or al, al
  jz .done
  
  mov ah, 0x2a
  stosw 
  jmp print
  
  .done:
    ret

message db "Hello video memory buffer!", 0
VIDEO_BUFFER equ 0xb800

times 510-($-$$) db 0
db 0x55
db 0xAA
