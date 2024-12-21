ORG 0x7C00
BITS 16

%define ENDL 0x0D, 0x0A 

jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           ; 8 Bytes
bdb_bytes_per_sector:       dw 512                  ;
bdb_sectors_per_cluster:    db 1                    ;
bdb_reserved_sectors:       dw 1                    ;
bdb_fat_count:              db 2                    ;
bdb_dir_entries_count:      dw 0E0h                 ;
bdb_total_sectors:          dw 2880                 ;
bdb_media_descriptor_type:  db 0F0h                 ;
bdb_sectors_per_fat:        dw 9                    ;
bdb_sectors_per_track:      dw 18                   ;
bdb_heads:                  dw 2                    ;
bdb_hidden_sectors:         dd 0                    ;
bdb_large_sector_count:     dd 0

ebr_drive_number:           db 0                    ; Floppy set to Drive 0
ebr_reserved:               db 0                    ; Reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; Serial Number
ebr_volume_label:           db 'RYOS       '        ; 11 byte string, padded with spaces
ebr_system_id:              db 'FAT12   '           ; 8 byte string, padded with spaces



; Print Units To Screen 
puts:
    push si
    push ax

.loop:
    lodsb
    or al, al
    jz .done

    mov ah, 0x0e
    mov bh, 0
    int 0x10
    jmp .loop

.done:
    pop ax
    pop si
    ret

start:
    mov ax, 0
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00

    ; Load from disk
    mov [ebr_drive_number], dl

    mov ax, 1
    mov cl, 1
    mov bx, 0x7E00
    call disk_read

    mov si, msg_hello
    call puts

    cli
    hlt

floppy_error:
    mov si, floppy_fail
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h
    jmp 0FFFFH:0
    hlt

.halt:
    cli
    hlt

; Convert LBA Address
lba_to_chs:
    push ax                             ; Preserve
    push dx                             ; Preserve

    xor dx, dx                          ; 
    div word [bdb_sectors_per_track]    ; 

    inc dx                              ; 
    mov cx, dx                          ; 
    
    xor dx, dx                          ; 
    div word [bdb_heads]                ; 

    mov dh, dl                          ; 
    mov ch, al                          ; 
    shl ah, 6                           ; 
    or cl, ah                           ; 

    pop ax                              ; 
    mov dl, al                          ; Restore DL
    pop ax                              ; 
    ret                                 ; return

disk_read:
    push ax                             ;;;
    push bx                             ;
    push cx                             ; Temporarily save Registers
    push dx                             ;
    push di                             ;;;

    push cx
    call lba_to_chs
    pop ax  

    mov ah, 02h                         ;
    mov di, 3                           ; retry 3 times

.retry:
    pusha                               ; Save all registers
    stc                                 ; Set Carry Flag
    int 13h                             ; Issue the Floppy disk interrupt
    jnc .done                           ; Jump to done if complete

    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppy_error

.done:
    popa
    pop di                             ;;;
    pop dx                             ;
    pop cx                             ; Temporarily save Registers
    pop bx                             ;
    pop ax                             ;;;
    ret

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_hello:      db 'RYOS is booting...',        ENDL, 0
floppy_fail:    db 'Failed to read from disk!', ENDL, 0

times 510 - ($ - $$) db 0
dw 0AA55h
