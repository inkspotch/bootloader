[BITS 16]
[ORG 0x7C00]

jmp start 
nop

; FAT12 BIOS Parameter Block
oem_label db "BSD  4.4"
bytes_per_sector dw 512
sectors_per_cluster db 1
reserved_sectors dw 1
number_of_fats db 2
root_directory_entries dw 224
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

%include "bios_print.inc"

start:
  cli
  xor ax, ax
  mov ds, ax 
  mov es, ax 
  mov ss, ax
  mov sp, 0xFFFF

  jmp 0:main ; canonizing cs:offset to 0:7c00

main: 
  sti

  call clear_screen
  print message

  mov ax, 0x50
  mov es, ax
  xor bx, bx
  call load_fat
  call load_root_directory_table
  call calculate_data_sector
  call find_file
  call load_file
  jmp 0x50:0x2e00

halt:
  jmp $

load_root_directory_table:
  ; calculate starting logical sector 

  xor ax, ax
  mov al, BYTE [number_of_fats]
  mul WORD [sectors_per_fat]
  add ax, WORD [reserved_sectors]
  mov WORD [logical_address], ax
  
  ; calculate number of sectors to read
  mov ax, SIZEOF_DIR_ENTRY_BYTES
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
    mov di, 5 ; retry count

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
    
    print disk_error
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

calculate_data_sector:
  push cx
  xor cx, cx

  ; root_dir_entry_count * sizeof(dir_entry_bytes) / bytes_per_sector
  mov ax, SIZEOF_DIR_ENTRY_BYTES
  mul WORD [root_directory_entries]
  div WORD [bytes_per_sector]

  xchg ax, cx

  ; FAT_count * sectors_per_fat
  mov al, BYTE [number_of_fats]
  mul WORD [sectors_per_fat]
  
  ; + reserved_sectors
  add ax, WORD [reserved_sectors]
  
  add ax, cx
  mov WORD [start_data_sector], ax

  pop cx
  ret

; ax will hold the cluster of the first file
find_file:
  mov cx, [root_directory_entries]
  xor di, di

  .next_entry:
    push cx
    push di
    mov cx, 8 ; 11 character names 8 byte name + 3 byte extension
    mov si, filename
    rep cmpsb
    pop di
    pop cx
    
    je .success_loading
    add di, SIZEOF_DIR_ENTRY_BYTES ; next entry is 32 bytes later
    loop .next_entry

    print error
    ret

    .success_loading:
      add di, 0x1A
      mov ax, WORD [es:di]
      mov WORD [start_cluster], ax

      print filename
  ret

load_fat:
  mov ax, 1 ; should be number of fats but simplying
  mul WORD [sectors_per_fat]
  mov cx, ax
  mov ax, WORD [reserved_sectors]

  call read_sectors

  ret

; ax is the cluster to convert
; lba is in ax
cluster_to_lba:
  push cx
  
  sub ax, 2
  xor cx, cx
  mov cl, BYTE [sectors_per_cluster]
  mul cx
  add ax, WORD [start_data_sector]

  pop cx
  ret

load_file:
  push bx

  .loop:
    mov ax, WORD [start_cluster]
    pop bx
    call cluster_to_lba
    xor cx, cx
    mov cl, BYTE [sectors_per_cluster]
    call read_sectors
    push bx

    ; find next cluser
    mov ax, WORD [start_cluster]
    mov cx, ax
    mov dx, ax
    shr dx, 1
    add cx, dx
    mov bx, cx ; FAT entry
    mov dx, WORD [es:bx]
    test ax, 1
    jnz .odd_cluster

    .even_cluster:
      and dx, 0x0FFF
      jmp .done
      
    .odd_cluster:
      shr dx, 4

    .done:
      mov WORD [start_cluster], dx   
      cmp dx, 0x0FF0
      jb .loop

  pop bx
  ret


logical_address: dw 0
cylinder: db 0
head: db 0
sector: db 0
start_data_sector: dw 0
start_cluster: dw 0
message: db "Booting...", 0
error: db "error", 0
disk_error: db "disk error", 0
filename: db "STAGE1_5", 0

times 510-($-$$) db 0
db 0x55
db 0xAA

SIZEOF_DIR_ENTRY_BYTES EQU 32 ; bytes
