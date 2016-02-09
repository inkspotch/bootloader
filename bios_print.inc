%macro print 1
  push bx
  mov si, %1
  call _print
  pop bx
%endmacro

_print:
  lodsb
  or al, al
  jz .done
  mov ah, 0xE
  mov bx, 7
  int 0x10
  jmp _print
  
  .done:
    ret

clear_screen:
  mov ah, 0
  int 0x10
  ret
