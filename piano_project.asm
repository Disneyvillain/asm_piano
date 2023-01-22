IDEAL
MODEL small
STACK 100h
DATASEG

Octave_num db 4
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



CODESEG
proc Key_press							;gets charachter from stack and switches graphics to matching key




endp Key_press

proc Release_key						;activated when mouse clicks: calls Keys_up and stops sound





endp Release_key

proc Key_sound							;gets a character from stack and produces matching sound for the piano (stops previous sound before)
;formula for frequency of note when changing octaves: (frequency in first octave)* 2^(Octave_num-1)
;formula for the number given to the program to play the sound: 1193180/frequency of note




endp Key_sound

proc Keys_up							;changes graphics to screen with no keys pressed




endp Keys_up

;proc Octave_change						;gets chararcter from stack and saves it's number valew in Octave_num


proc kind_of_char						;gets a character from keyboard and decides what to do with it(which other proc to call)
	mov	ah,1
	int	21h								;recieves the character
	mov ah,al
	sub ah,48							;ah has number valew of char if char is a number
	cmp ah,7
	jg not_num
	cmp ah,1
	jl not_num
	xor al,al
	in    al, 61h						;closing the sound
	and  al, 11111100b
	out    61h, al
	mov Octave_num,ah					;Octave_num has the new octave number
	jmp finish_proc
	
	not_num:
	cmp al,97							;checks if char is letter a-m
	jl finish_proc
	cmp al,109
	jg finish_proc
	;push al 							;not sure if through stack, register or memory
	call Key_sound
	;push al
	call Key_press
	
	finish_proc:
	ret 
endp kind_of_char

main_code:
	mov	ax, 13h
	int	10h								;changes to graphic mode
	