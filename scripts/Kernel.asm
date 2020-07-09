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

; ---------------------------------------------------
; GameOS Kernel
; ---------------------------------------------------
 
mov ax, 0x1000 							; Segmentregister updaten
mov ds, ax
mov es, ax

kernelstart:
  mov si, msg_welcome
  call print_string   					; Schicke Bootmessage :)

kernelloop:
  mov si, prompt						; promt (">") anziegen
  call print_string

  mov di, buffer
  call read_string

  mov si, buffer
  cmp byte [si], 0  					; blank line?
  je kernelloop           				; yes, ignore it

  mov di, cmd_info  					; "info" command
  call compare_string
  jz .info

  mov si, buffer
  mov di, cmd_reboot  					; "reboot" command
  call compare_string
  jz .reboot

  mov si, msg_badcommand
  call print_string
  jmp kernelloop
  
  .info:
  	mov si, msg_info_osname
  	call print_string

  	mov si, msg_info_version
  	call print_string

  	mov si, msg_info_author
  	call print_string

  	mov si, msg_info_cmd
  	call print_string

  	jmp kernelloop						; Springe zurück auf kernelloop

  .reboot:
 	call reboot
 
; -------------------------------------------------
; GameOS Variablen
; -------------------------------------------------

; db = Define Byte

; Bildschirmtextausgaben
msg_welcome db "Herzlich Willkommen zu GameOS...", 0x0D, 0x0A, 0
msg_goodbye db "GameOS wird nun neu gestartet, auf Wiedersehen...", 0x0D, 0x0A, 0

msg_info_osname db  "Name:    GameOS", 0x0D, 0x0A, 0
msg_info_version db "Version: 0.00.01a", 0x0D, 0x0A, 0
msg_info_author db  "Author:  Daniel Pogodda", 0x0D, 0x0A, 0
msg_info_cmd db     "Befehle: info, reboot", 0x0D, 0x0A, 0

msg_badcommand db "Befehl nicht gefunden.", 0x0D, 0x0A, 0

; Eingabepromt
prompt db "> ", 0

; Befehle
cmd_info db "info", 0
cmd_reboot db "reboot", 0

buffer times 32 db 0

; -------------------------------------------------
; GameOS Funktionen
; -------------------------------------------------

; Stringausgabe
print_string:
  lodsb            						; Byte laden (Load Sting Byte)
  or al, al
  jz short .done 						; 0-Byte? -> print_string.done!
  mov ah, 0x0E      					; Funktion 0x0E
  mov bx, 0x0007    					; Atrribut-Byte
  int 0x10         						; schreiben
  jmp print_string       				; nächstes Byte

  .done:
	ret

read_string:
  xor cl, cl							; mov cl, 0

  .loop:								; read_string.loop
    xor ah, ah							; mov ah, 0
    int 0x16   							; Tastendruck abwarten

    cmp al, 0x08    					; Wurde backspace gedrückt? (0x08 = backspace)
    je .backspace   					; ja? handle it!

    cmp al, 0x0D  						; enter pressed?
    je .done      						; yes, we're done

    cmp cl, 31  						; 31 chars inputted?
    je .loop    						; yes, only let in backspace and enter

    mov ah, 0x0E
    int 0x10      						; print out character

    stosb  								; put character in buffer
    inc cl
    jmp .loop

  .backspace:
    or cl, cl							; Sind wir noch am Anfang vom String?
    jz .loop							; ja? Dann ignoriere die Eingabe und ab zurück auf read_string.loop!

    dec di								; Decrementiere di um 1 (vergleichbar mit di--)
    mov byte [di], 0					; Zeichen löschen
    dec cl								; Decrementiere cl um 1

    mov ax, 0x0E08
    int 10h								; backspace on the screen

    mov al, ' '
    int 10h								; blank character out

    mov al, 0x08
    int 10h								; backspace again

    jmp .loop							; go to the read_string.loop

  .done:
    xor al, al							; mov al, 0 ; null terminator
    stosb

    mov ax, 0x0E0D						; 0x0D = carriage return
    int 0x10
    mov al, 0x0A						; 0x0A = new line
    int 0x10

    ret

compare_string:
  .loop:								; compare_string.loop
    mov al, [si]   						; grab a byte from SI
    cmp al, [di]   						; are SI and DI equal?
    jne .done							; if no, we're done.

	or al, al      						; zero?
  	jz .done       						; if yes, we're done.

    inc di     							; increment DI
    inc si     							; increment SI
    jmp .loop  							; looooop!

  .done:
    ret

reboot:
  mov si, msg_goodbye
  call print_string
  jmp 0xffff:0x0000

shutdown:
; tba...