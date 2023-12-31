;; ============================================================================
;; RetrOS
;; ============================================================================
;; v0.2.5
;; ----------------------------------------------------------------------------
;; A simple boot sector

	[org 0x7c00]		; Intel x86 boot sectors start at address 7c00
	
	mov bp, 0x8000		; Here we set our stack safely out of the
	mov sp, bp		; way, at 0x8000

	mov [BOOT_DRIVE], dl	; Preserve the boot-drive number
	
clear_screen:
	mov ah, 0x00		; Set video mode
	mov al, 0x01		; 720x400 VGA (?)
	int 0x10
	
load_kernel:	
	push KERNEL_SEGMENT
	pop es
	mov bx, KERNEL_OFFSET
	mov dh, 3		; Read 2 sectors
	mov dl, 0		; from floppy disk B
	mov cl, 0x02 		; Start reading from first sector
	call disk_read

exit:
	jmp KERNEL_SEGMENT:KERNEL_OFFSET	; Jump to the start of the kernel

	;; ===================================================================
	;; Print String
	;; ===================================================================
	;; Prints the zero-terminated string pointed to by si
	;; -------------------------------------------------------------------
print_string:
	push ax
	push si
.next_char:
	cld			; Clear the direction flag (print forwards)
	lodsb			; Get the character from the string
	or al, al		; Is it zero (end of string indicator)?
	jz .print_string_done	; If yes, we're done
	mov ah, 0x0e		; Interrupt 10, command 0e: print single character
	int 0x10		; Interrupt 10 (Video Interrupts) to print the character
	jmp .next_char		; Loop back for the next character
.print_string_done:
	pop si
	pop ax
	ret

	;; ===================================================================
	;; Disk Read
	;; -------------------------------------------------------------------
	;; Loads AL sectors to ES:BX from drive DL sector CL
	;; -------------------------------------------------------------------
disk_read:
	push ax
	push cx
	push dx
	mov dh, al		; Save how many sectors were requested
	push dx
	mov ah, 0x02		; BIOS read sector function
	mov ch, 0x00		; Select cylinder 0
	mov dh, 0x00		; Select head 0
	int 0x13		; BIOS interrupt
	jc .disk_read_error	; Jump if error (i.e. carry flag set)
	pop dx		        ; Restore DX from the stack
	cmp dh, al		; if AL (sectors read) == DH (sectors expected)
	je .exit		; All ok

.disk_read_error:
	push si
	mov si, DISK_ERROR_MSG
	call print_string
	pop si
	jmp $

.exit:
	pop dx
	pop cx
	pop ax
	ret
	
; Variables
BOOT_DRIVE db 0
	
DISK_ERROR_MSG db "Disk read error!", 0

KERNEL_SEGMENT equ 0x0060	; Load the kernel near the bottom of the
KERNEL_OFFSET  equ 0x0000	; available memory

padding:	
	times 510-($-$$) db 0	; Pad to 510 bytes with zero bytes

	dw 0xaa55		; Last two bytes (one word) form the magic number ,
				; so BIOS knows we are a boot sector.
