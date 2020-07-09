; ///////////////////////////////////////////////////
; ---------------------------------------------------
; // GameOS - Operating System 
; // but more than nothing
; ---------------------------------------------------
; // Version:	0.00.01b
; // Author: 	ojeseus1
; ---------------------------------------------------
; ///////////////////////////////////////////////////

; -----------------------------------------
; Assembler Syntax [IntelAsm] (!=GNUAsm)
; -----------------------------------------

; 	Syntax				Beschreibung

; Die Reihenfolge der Instruktionsparameter
;	mov b, a 	 		Kopiert a nach b
;	add b, a 			Addiert a auf b (Ergebnis in b)

; Konstanten und Registerkennzeichnung
;	mov reg, konst 		Kopiert Konstante konst in das Register reg
;	add reg, konst 		Addiert Konstante konst auf das Register reg

; Datentypsuffixe
;	mov bl, al 			Kopiert 1 Byte-Register (b=byte)
;	mov bx, ax 			Kopiert 2 Byte-Register (w=word)
;	mov ebx, eax 		Kopiert 4 Byte-Register (l=long)

; Komentare
;	; Kommentar 		Platziert ein Kommentar 

; -----------------------------------------
; GameOS Bootloader
; -----------------------------------------

org 0x7C00  							; set up start address 

jmp 0x0000:start

start:
  ; setup a stack
  mov ax, 0x9000  						; address of the stack SS:SP
  mov ss, ax      						; SS = 0x9000 (stack segment)
  xor sp, sp      						; SP = 0x0000 (stack pointer)

  ; Segmentregister initialisieren (für Zugriff auf bootdrv notwendig)
  mov ax, 0x0000
  mov es, ax
  mov ds, ax

  mov [bootdrive], dl 					; boot drive from DL
  call load_kernel    					; load kernel
 
  ; Springe zu diesem Kernel
  mov ax, 0x1000 						; Die Adresse des Programms
  mov es, ax     						; Segmentregister updaten
  mov ds, ax
  jmp 0x1000:0x0000

; -------------------------------------------------
; GameOS Variablen
; -------------------------------------------------

bootdrive db 0      					; boot drive
msg_load db "GameOS wird geladen...", 0x0D, 0x0A, 0

; -------------------------------------------------
; GameOS Funktionen
; -------------------------------------------------
 
; Stringausgabe
print_string:
  lodsb             					; grab a byte from SI
  or al, al         					; NUL?
  jz .done          					; if the result is zero, get out
  mov ah, 0x0E
  int 0x10          					; otherwise, print out the character!
  jmp print_string

  .done:
	ret

; read kernel from floppy disk
load_kernel:
  mov dl, [bootdrive] 					; select boot drive
  xor ax, ax         					; mov ax, 0  => function "reset"
  int 0x13
  jc load_kernel     					; trouble? try again

load_kernel1:
  mov ax, 0x1000
  mov es, ax         					; ES:BX = 0x10000
  xor bx, bx         					; mov bx, 0

  ; set parameters for reading function
  ; 8-Bit-wise for better overview
  mov ax, 0x020A         				; function "read", read 5 sectors
  mov cx, 0x0002          				; cylinder = 0 sector   = 2
  mov dh, 0x00         					; head     = 0
  mov dl, [bootdrive] 					; select boot drive
  int 0x13
  jc load_kernel1    					; trouble? try again

  ; show loading message
  mov si, msg_load
  call print_string
  retn

  times 512-($-$$)-2 db 0				; Dateilänge: 512 Bytes
  dw 0xAA55                 				; Bootsignatur