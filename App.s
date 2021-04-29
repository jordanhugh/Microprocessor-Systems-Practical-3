			AREA		AsmTemplate, CODE, READONLY
			IMPORT		main	
			EXPORT		start
start

; Setup GPIO
IO1DIR		equ		0xE0028018
IO1SET		equ		0xE0028014
IO1CLR		equ		0xE002801C
IO1PIN  	equ     0xE0028010
	
; Setup Buttons
incr		equ     20
decr   		equ     21
addit   	equ     22
subtr   	equ     23
clear   	equ     -22
allclear	equ     -23
        
; Setup State Machine States
initial_state   equ     0
getnum_state    equ     1
getop_state     equ     2     

; Setup Calculator Operators
op         		equ     0
op_add        	equ     1
op_sub        	equ     2			
	
;Press Times
regpress  		equ     20000    		; Short press time
longpress  		equ     200000  		; Long press time

        
;initialise the LEDs
			ldr		r1,	=IO1DIR			;
			ldr		r2,	=0x000f0000		; Select P1.19--P1.16
			str		r2,[r1]				; Set as outputs

clear_all
		mov     r1, #initial_state   	; Set r1 to initial state
		mov     r2, #0                  ; Set all registers to 0
		mov     r3, #0                  ;
		mov     r4, #op              	;
		mov     r0, #0					;
		bl      update_leds         	; Set all LEDS off
	
main_loop
		bl      getbut                 	; Get the next key
		mov     r5, #initial_state		; 
		cmp     r1, r5					; Check if in initial state
		bne     get_number				; If not, get number

		mov     r5, #incr				; 
		cmp     r5, r0           		; If "+" was not pressed
		beq     elseifincr              ; Else branch if it was pressed
		mov     r5, #decr				; If "-" was not pressed
		cmp     r5,r0                  	; Else branch back to the beginning of main_loop 
		bne     main_loop              	;
		sub     r3, #1                  ; x = x - 1
		mov     r0, r3                  ; 
		mov     r1, #getnum_state   	; Change from initial to getnum state
		b       update_leds				; Update LEDS
elseifincr
		add     r3, #1                  ;
		mov     r0, r3					;
		mov     r1, #getnum_state		;
		b       update_leds				;

get_number
		mov     r5, #getnum_state		;
		cmp     r1, r5					;
		bne     get_operator			;

						
		mov     r5, #incr				;
		cmp     r5, r0					;
		bne     elseifneg0        		;
		add     r3, #1           		;
		mov     r0, r3           		;
		b       update_leds				;
elseifneg0
		mov     r5, #decr				;
		cmp     r5, r0					;
		bne     elseifsub0        		;
		sub     r3, #1					;
		mov     r0, r3					;
		b       update_leds				;
elseifsub0
		mov     r5, #subtr				;
		cmp     r5, r0					;
		bne     elseifadd0        		;
		bl      complete_operation		;
		mov     r4, #op_sub      		;
		mov     r1, #getop_state		;
		b       main_loop				;
elseifadd0
		mov     r5, #addit				;
		cmp     r5, r0					;
		bne     elseifclear0        	;
		bl      complete_operation		;
		mov     r4, #op_add      		;  
		mov     r1, #getop_state		;
		b       main_loop				;
elseifclear0
		mov     r5,#clear				;
		cmp     r5,r0					;
		bne     elseifallclear0        	;
		mov     r3,#0					;
		mov     r0,r3					;
		b       update_leds				;
elseifallclear0
		mov     r5, #allclear			;
		cmp     r5, r0					;
		bne     main_loop      			;
		b       clear_all				;
get_operator
		mov     r5, #getop_state		;
		cmp     r1, r5					;
		bne     main_loop      			;
		mov     r5, #incr				;
		cmp     r5, r0					;
		bne     elseifneg1        		;
		mov     r1,#getnum_state		;
		mov     r3,#0           		;
		mov     r0,r3					;
		b       update_leds				;
elseifneg1
		mov     r5,#decr				;
		cmp     r5,r0					;
		bne     elseifsub1        		;
		mov     r1,#getnum_state		;
		mov     r3,#0           		;
		mov     r0,r3					;
		b       update_leds				;
elseifsub1
		mov     r5,#subtr				;
		cmp     r5,r0					;
		bne     elseifadd1        		;
		mov     r4,#op_sub				;
		b       main_loop				;
elseifadd1
		mov     r5,#addit				;
		cmp     r5,r0					;
		bne     elseifclear1        	;
		mov     r4,#op_add				;
		b       main_loop				;
elseifclear1
		mov     r5,#allclear			;
		cmp     r5,r0					;
		bne     main_loop      			;
		b       clear_all       		;  
stop		B	stop
complete_operation
		stmfd   sp!, {r0, lr}			;
		mov     r0, #op					;
		cmp     r4, r0					;
		bne     elseifadd2				;
		mov     r2, r3					;
		b       elseiferror2			;
elseifadd2   	mov     r0, #op_add		;
		cmp     r4, r0					;
		bne     elseifsub2				;
		add     r2, r3					;
		b       elseiferror2			;
elseifsub2   	mov     r0, #op_sub		;
		cmp     r4, r0					;
		bne     elseiferror2			;
		sub     r2, r3					;
elseiferror2   
		mov	r0, r2						;
		bl	update_leds					;
		ldmfd   sp!, {r0, lr}			;
		bx      lr						;
update_leds 	stmfd   sp!, {r1, r2}	;
		ldr	r2, =0x000f0000				; Select P1.19--P1.16
		ldr	r1, =IO1SET					;
		str	r2, [r1]					; Set the bit -> turn off the LED
		mov     r2, r0					;
		and     r2, #0xF      			; Remove any carry
		ldr	r1, =revbits				;
		add	r1, r2						;
		ldr	r2, [r1]					;
		mov	r2, r2, lsl #16        		;
		ldr	r1, =IO1CLR					;
		str     r2, [r1]         		; Clear the bit -> turn on the LED
		ldmfd   sp!, {r1, r2}			;
		bx      lr							;
											; Returns button pressed
											; Checks if the button was pressed for a short time
getbut  		stmfd	sp!, {r1-r8}			;
				ldr     r1, =0x00f00000 		; Mask all keys
				ldr     r2, =IO1PIN     		; GPIO 1 Pin Register
				ldr     r8, =regpress			;
nobutpress  	mov     r3, #0          		; Number of keys pressed
checkallbuts0	ldr     r4, =buts				;
				mov     r5, #4					; Number of buttons
				ldr     r6, [r2]				;
				and     r6, r6, r1      		; Mask everything except for buttons
checkallbuts1	ldr     r7, [r4]				;
				add     r4, #8          		; Check next button
				cmp     r6, r7          		; 
				beq     countpress          	;
				subs    r5, #1					;
				bne     checkallbuts1    		; Check if any other buttons were pressed
				b       nobutpress      		; Return if no button was pressed
countpress		add     r3, #1					;
				cmp     r3, r8           		; Checks if the button was pressed for long enough
				bne     checkallbuts0			;
				sub     r4, #4           		; Point to Index
				ldr     r0,[r4]        	 		; Load index into R0
												; Check if the button was pressed for a long time
				ldr     r5, =longpress			;
keepcounting0  	mov     r4, #0					;
keepcounting1	ldr     r6,[r2]					;
				and     r6, r6, r1        		; Mask everything except for buttons
				cmp     r6, r7           		; 
				bne     endif0          		; 
				cmp     r3, r5           		; Check if its a long press
				beq	endif1						;
				add   	r3, #1           		; Keep counting otherwise...
endif1
			b       keepcounting0      		 	; Keep counting...
endif0  	cmp     r6, r1           			; 
			bne     nobutpress      			; Start again
			add     r4, #1           			;       
			cmp     r4, r8           			; Check if reg time has elapsed
			bne     keepcounting1       		; Keep counting...
			cmp     r3, r5           			;
			bne     endif2						;
			rsb     r0, #0           			;
endif2  	ldmfd	sp!, {r1-r8}				;
			bx      lr							;

		AREA	mydata, DATA, READONLY

revbits	dcb	0x0     					; 0
		dcb	0x8							; 1
		dcb	0x4							; 2
		dcb	0xc							; 3
		dcb	0x2							; 4
		dcb	0xa							; 5
		dcb	0x6							; 6
		dcb	0xe							; 7
		dcb	0x1							; 8
		dcb	0x9							; 9
		dcb	0x5							; A
		dcb	0xd							; B
		dcb	0x3							; C
		dcb	0xb							; D
		dcb	0x7							; E
		dcb	0xf							; F

buts	dcd	0x00700000, 23				;Mask = 0111
		dcd	0x00B00000, 22				;Mask = 1011
		dcd	0x00D00000, 21				;Mask = 1101
		dcd	0x00E00000, 20				;Mask = 1110
                
		END