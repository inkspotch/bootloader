%macro print 1 ; message, row, column 
  mov ax, VIDEO_BUFFER
  mov es, ax

  mov ax, 0
  mov ds, ax
  mov si, %1

  mov ax, 80
  shl ax, 1 
  mov bx, word [row]
  mul bx

  mov di, ax

  call _print
%endmacro

_print:
  lodsb
  or al, al
  jz .done

  mov ah, 0x2a
  stosw
  jmp _print

  .done:
    inc word [row]
    ret

clear_screen:
  mov ax, VIDEO_BUFFER
  mov es, ax
  xor di, di
  
  xor ax, ax

  mov cx, 2000
  rep stosw
  ret

row dw 0
VIDEO_BUFFER equ 0xb800
