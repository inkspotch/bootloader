%macro print 1 ; message, row, column 
  mov si, %1 
  call _print
%endmacro

_print:
  push es
  mov ax, VIDEO_BUFFER
  mov es, ax

  mov ax, 80
  shl ax, 1 
  mov bx, word [row]
  mul bx

  mov di, ax

  .print_character:
    lodsb
    or al, al
    jz .done

    mov ah, 0x2a
    stosw
    jmp .print_character

  .done:
    inc WORD [row]
    pop es
    ret

clear_screen:
  push es
  mov ax, VIDEO_BUFFER
  mov es, ax
  xor di, di
  
  xor ax, ax

  mov cx, 2000
  rep stosw
  
  mov WORD [row], 0
  pop es
  ret

row dw 0
VIDEO_BUFFER equ 0xb800
