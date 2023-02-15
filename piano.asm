IDEAL
MODEL small
STACK 100h
DATASEG
char db ?
Octave_num db 3
;graphics files:
starting_keys_g db 'Skeys.bmp',0			;the g in the name is for graphics
do1_g db '1do.bmp',0				
re_g db '2re.bmp',0
mi_g db '3mi.bmp',0
fa_g db '4fa.bmp',0
sol_g db '5sol.bmp',0
la_g db '6la.bmp',0
si_g db '7si.bmp',0
do2_g db '8do.bmp',0
doDiez_g db 'do#.bmp',0
mi_b_g db 'mi_b.bmp',0
faDiez_g db 'fa#.bmp',0
la_b_g db 'la_b.bmp',0
si_b_g db 'si_b.bmp',0

Graphics_offset dw 1 dup(offset do1_g,offset re_g,offset mi_g,offset fa_g,offset sol_g,offset la_g,offset si_g,offset do2_g,offset doDiez_g,offset mi_b_g,offset faDiez_g,offset la_b_g,offset si_b_g)

freq_ARR db 1 dup(33,37,41,44,49,55,62,65,35,39,46,52,58)
;index of frequency is according to the order of the notes 
;order notes: lower_do, re, mi, fa, sol, la, si, higher_do, do_sharp, mi_flat, fa_sharp, la_flat, si_flat

;printing variables:
filename db 'Skeys.bmp',0			;find how to change filename each time
filehandle dw ?
Header db 54 dup (0)
Palette db 256*4 dup (0)
ScrLine db 320 dup (0)
ErrorMsg db 'Error', 13, 10

CODESEG
proc Key_press							;gets charachter from stack and switches graphics to matching key
	push ax 
	push bx
	push cx
	push dx
	push si
	push di
	xor ax,ax
	mov al,[char]
	sub al,97	
	mov bl,2
	mul bl								;ax has index of correct thing in Graphics_offset
	mov si,ax
	mov bx,offset Graphics_offset
	mov di,[bx+si]						;di has offset of variable that has the name of image
	mov al,[di]							;al has name of image
	mov [filename],al
	;printing:
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	
finish_key_press:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret 
endp Key_press

proc Key_sound							;gets char from memory and produces matching sound for the piano. 
;formula for frequency of note when changing octaves: (frequency in first octave)* 2^(Octave_num)
;formula for the number given to the program to play the sound: 1193180/frequency of note
	push ax
	push bx
	push cx
	push dx
	push si
	;calculating the number we give the computer
	mov cl,[Octave_num]
	mov al,2
	mov dl,2
	power_loop:
		mul dl				;at the end ax= 2^(Octave_num)
	loop power_loop
	mov bl,[char]
	sub bx,97 				;bx has index of note's frequency inside freq_ARR
	mov si,offset freq_ARR
	xor dx,dx
	mov dl,[si+bx]			;dl has the frequency of the note in lowest octave
	mul dl					;ax has frequency of note in correct octave
	mov bx,ax
	xor dx,dx
	xor ax,ax
	mov ax,34DCh			;1193180 in hex is 1234DCh
	mov dx,12h
	div bx					;ax has the number we need to give the computer
	;getting the number to the port
	out 42h,al				
	mov al,ah
	out 42h,al
	
finish_Key_sound:
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret 
endp Key_sound


proc Keys_up							;changes graphics to screen with no keys pressed
	push ax
	mov al,[starting_keys_g]
	mov [filename],al
	; Process BMP file
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	pop ax
endp Keys_up


proc kind_of_char					;stops sound, gets a character from keyboard, and does something accordingly.
;char= q: quit program. char= nums 1-7: change Octave_num. char= small a-m: calls procs that play sound and graphics accordingly.
;char= other character: calls proc that changes graphics to no keys pressed
	push ax							 
	in al, 61h						;closing the sound
	and al, 11111100b
	out 61h, al
	xor ax,ax
	
	mov ah,[char]
	sub ah,48						;ah has number valew of char if char is a number
	cmp ah,7
	jg not_num
	cmp ah,1
	jl not_num
	xor al,al
	dec ah					
	mov [Octave_num],ah				;Octave_num has the new octave number-1
	call Keys_up
	jmp finish_proc
	
	not_num:
	mov al,[char]
	cmp al,97						;checks if char is letter a-m
	jl finish_proc
	cmp al,109
	jg is_q
	;open speaker
	in al,61h
	or al,00000011b
	out 61h,al
	;getting access to speaker
	mov al,0B6h
	out 43h,al
	call Key_sound
	call Key_press
	jmp finish_proc
	
	is_q:
	cmp al,113
	jne is_other_thing
	jmp exit						;finish the program
	
	is_other_thing:
	call Keys_up
	
	finish_proc:
	pop ax
	ret 
endp kind_of_char



;printing code procs:

proc OpenFile
	; Open file
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename
	int 21h
	jc openerror
	mov [filehandle], ax
	ret
openerror :
	mov dx, offset ErrorMsg
	mov ah, 9h
	int 21h
	ret
endp OpenFile

proc ReadHeader
	; Read BMP file header, 54 bytes
	mov ah,3fh
	mov bx, [filehandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	ret
endp ReadHeader

proc ReadPalette
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	ret
endp ReadPalette

proc CopyPal
	; Copy the colors palette to the video memory
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0
	; Copy starting color to port 3C8h
	out dx,al
	; Copy palette itself to port 3C9h
	inc dx

PalLoop:
	; Note: Colors in a BMP file are saved as BGR values rather than RGB .
	mov al,[si+2] ; Get red value .
	shr al,2 ; Max. is 255, but video palette maximal
	; ; value is 63. Therefore dividing by 4.
	out dx,al ; Send it .
	mov al,[si+1] ; Get green value .
	shr al,2
	out dx,al ; Send it .
	mov al,[si] ; Get blue value .
	shr al,2
	out dx,al ; Send it .
	add si,4 ; Point to next color .
	; (There is a null chr. after every color)
	loop PalLoop
	ret
endp CopyPal

proc CopyBitmap
	; BMP graphics are saved upside-down.
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx,200
	
PrintBMPLoop:
	push cx
	; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx
	; Read one line
	mov ah,3fh
	mov cx,320
	mov dx,offset ScrLine
	int 21h
	; Copy one line into video memory
	cld ; Clear direction flag, for movsb;
	mov cx,320
	mov si,offset ScrLine
	rep movsb ; Copy line to the screen
	pop cx
	loop PrintBMPLoop
	ret
endp CopyBitmap
	

main_code:
	mov ax, @data
	mov ds, ax
	mov	ax, 13h
	int	10h								;changes to graphic mode

	call Keys_up
	;open speaker
	in al,61h
	or al,00000011b
	out 61h,al
	;getting access to speaker
	mov al,0B6h
	out 43h,al
the_loop:
	;recieve character:
	mov	ah,1
	int	21h	
	mov [char],al
	call kind_of_char
jmp the_loop
	
	
exit:
	mov ax, 4c00h
	int 21h
end main_code

	
	