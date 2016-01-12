[BITS 16]
[ORG 0x7C00]

jmp start 
nop

; FAT12 BIOS Parameter Block
oem_label db "BSD  4.4"
bytes_per_sector  dw 512
sectors_per_cluster db 1
reserved_sectors dw 1
number_of_fats db 2
root_directory_entries dw 244 
number_of_sectors dw 2880
media_descriptor db 0xF0
sectors_per_fat dw 9
sectors_per_track dw 18
number_of_heads dw 2
hidden_sectors dd 0
large_sectors dd 0
drive_number db 0
reserved_windows_nt db 0
extended_boot_signature db 0x29
serial_number dd 0x00000001
volume_label db "RPN OS     "
filesystem_id db "FAT12   "
; END FAT12 Parameter Block

start:
  cli
  xor ax, ax
  mov ds, ax 
  mov es, ax 
  mov ss, ax
  mov sp, 0xFFFF

  jmp 0:main ; canonizing cs:offset to 0:7c00

%include "print.inc"

main: 
  sti

  call clear_screen
  print message

  mov ax, 0x7E0
  mov es, ax
  xor bx, bx
  call load_root_directory_table
  
  ;call find_file

  jmp halt

halt: jmp $

load_root_directory_table:
  ; calculate starting logical sector 

  xor ax, ax
  mov al, BYTE [number_of_fats]
  mul WORD [sectors_per_fat]
  add ax, WORD [reserved_sectors]
  mov WORD [logical_address], ax
  
  ; calculate number of sectors to read
  mov ax, 32
  mul WORD [root_directory_entries]
  div WORD [bytes_per_sector]
  
  mov cx, ax
  mov ax, WORD [logical_address]
  
  call read_sectors
  ret

; ax - logical address
; cx - number of sectors to read
; es:bx - buffer to write to
read_sectors:
  .main:
    mov di, 5

  .loop:
    push ax
    push bx
    push cx

    call lba_chs_convert
    mov ah, 0x2
    mov al, 1
    mov ch, BYTE [cylinder]
    mov cl, BYTE [sector]
    mov dh, BYTE [head]
    mov dl, BYTE [drive_number]
    int 0x13
    
    jnc .success

    ; reset
    xor ax, ax
    int 0x13
    pop cx
    pop bx
    pop ax
    dec di
    jnz .loop
    
    print error
    jmp halt

  .success:
    pop cx
    pop bx
    pop ax
    add bx, WORD [bytes_per_sector]
    inc ax
    loop .main

  ret

lba_chs_convert:
  xor dx, dx
  div WORD [sectors_per_track]
  inc dl
  mov BYTE [sector], dl
  
  xor dx, dx
  div WORD [number_of_heads]
  mov BYTE [head], dl
  mov BYTE [cylinder], al
  ret

file_name: db 'TEXT    '
find_file:
  mov cx, [root_directory_entries]
  xor di, di

  .next_entry:
    push cx
    mov cx, 8 ; 11 character names 8 byte name + 3 byte extension
    mov si, file_name
    rep cmpsb
    je .success_loading
    pop cx
    add di, 32 ; next entry is 32 bytes later
    loop .next_entry
    
    print error
    ret

    .success_loading:
      print file_name
  ret

logical_address: dw 0
cylinder: db 0
head: db 0
sector: db 0
message: db "Booting...", 0
error: db "error", 0
filename: times 8 db 'A'
          db 0

times 510-($-$$) db 0
db 0x55
db 0xAA
