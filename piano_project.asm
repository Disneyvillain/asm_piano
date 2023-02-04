IDEAL
MODEL small
STACK 100h
DATASEG

Octave_num db 3
;graphics files:
starting_keys_g db 'start_pkeys.bmp',0			;the g in the name is for graphics
do1_g db '1first_do.bmp',0				
re_g db '2re.bmp',0
mi_g db '3mi.bmp',0
fa_g db '4fa.bmp',0
sol_g db '5sol.bmp',0
la_g db '6la.bmp',0
si_g db '7si.bmp',0
do2_g db '8second_do.bmp',0
do#_g db 'do#.bmp',0
mi_b_g db 'mi^b.bmp',0
fa#_g db 'fa#.bmp',0
la_b_g db 'la^b.bmp',0
si_b_g db 'si^b.bmp',0

Graphics_ARR db 1 dup(do1_g,re_g,mi_g,fa_g,sol_g,la_g,si_g,do2_g,do#_g,mi_b_g,fa#_g,la_b_g,si_b_g)

freq_ARR db 1 dup(32.703,36.708,41.203,43.654,48.999,55,61.735,65.406,34.648,38.891,46.249,51.913,58.27) 
;index of frequency is according to the order of the notes 
;order notes: lower_do, re, mi, fa, sol, la, si, higher_do, do_sharp, mi_flat, fa_sharp, la_flat, si_flat


CODESEG
proc Key_press							;gets charachter from stack and switches graphics to matching key
	push bp 
	mov bp,sp 
	push ax 
	push cx 
	xor ax,ax
	add ax,[bp+4]						;ax has char
	mov dx,'a'
	mov cx,13
bloop:
		cmp ax,dx
		je print_graphic
		inc dx
	loop bloop
not_char:
	jmp finish_key_press
print_graphic:
	;copy the printing part
	;dx-97= index of picture it needs to print inside Graphics_ARR.


finish_key_press:
	pop cx 
	pop ax 
	pop bp 
	ret 2
endp Key_press

proc Release_key						;checks if mouse clicks: if so calls Keys_up and stops sound
	push ax
	mov ah,0
	int 33h								;activate mouse
	mov ah,3
	int 33h								;read mouse status. if mouse didnt click, last 2 bits are 00
	mov dl,bl
	shl dl,6							
	cmp dl,00000000b					
	je end_of_Release					;if not equal, there was a mouse click
	
	;stop sound:
	in al,61h
	and al,11111100b
	out 61h,al
	
	;change graphics:
	call Keys_up
end_of_Release:
	pop ax
	ret
	
endp Release_key


proc Key_sound							;gets a character from stack and produces matching sound for the piano (stops previous sound before)
;formula for frequency of note when changing octaves: (frequency in first octave)* 2^(Octave_num)
;formula for the number given to the program to play the sound: 1193180/frequency of note
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push si
	;open speaker
	in al,61h
	or al,00000011b
	out 61h,al
	;getting access to speaker
	mov al,0B6h
	out 43h,al
	;calculating the number we give the computer
	mov cx,[Octave_num]
	mov al,2
	mov dl,2
	power_loop:
		mul dl				;at the end we get 2^(Octave_num)
	loop power_loop
	add bx,[bp+4]
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
	out 42,al				
	mov al,ah
	out 42,al

endp Key_sound


proc Keys_up							;changes graphics to screen with no keys pressed




endp Keys_up




proc kind_of_char						;gets a character from keyboard and decides what to do with it(which other proc to call)
	push ax								;saves current ax valew
	xor ax,ax
	mov	ah,1
	int	21h								;recieves the character
	mov ah,al
	sub ah,48							;ah has number valew of char if char is a number
	cmp ah,7
	jg not_num
	cmp ah,1
	jl not_num
	xor al,al
	in al, 61h						;closing the sound
	and al, 11111100b
	out 61h, al
	dec ah					
	mov Octave_num,ah				;Octave_num has the new octave number-1
	jmp finish_proc
	
	not_num:
	cmp al,97							;checks if char is letter a-m
	jl finish_proc
	cmp al,109
	jg finish_proc
	xor ah,ah
	push ax							;char now in stack
	call Key_sound
	xor ah,ah
	push ax							;char in stack again
	call Key_press
	
	finish_proc:
	pop ax
	ret 
endp kind_of_char

main_code:
	mov ax, @data
	mov ds, ax
	mov	ax, 13h
	int	10h								;changes to graphic mode
	
	call Keys_up
	call kind_of_char
	
	
	
	
	
	
	
	
	
	exit:
	mov ax, 4c00h
	int 21h
end main_code

	
	