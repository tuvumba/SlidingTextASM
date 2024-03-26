.cseg ; nasledujici umistit do pameti programu (implicitni)
; Zacatek programu - po resetu
.org 0
    jmp start

.org 0x100
.include "printlib.inc"
retez: .db "@tuvumba was here, don't tell anyone please lol ",0 ; retezec zakonceny nulou (nikoli znakem "0") 1


start:
    call init_disp
    call reset_Z
     
; r26 -- carrierCounter (0 - 15, 64 - 79)
; r27 -- wordCounter (0 as first letter)
; r22 -- used for direction of text (0 -- RL, 1 -- LR(usual))
; r23 stores text length 
; r28, r29 are used for wait-loops    
; supports up to 256 characters 

ldi r22, 1
cpi r22, 0
breq main_FWD

       
main_BWD: ; initialization process BWD
ldi r26, 0x4f 
call calculate_text_len_to_r27
mov r21, r27 ; store text len to r21
ldi r27, 0
ldi r22, 0

main_cycle_beginBWD:
    call show_text_from_position
    inc r22
    call wait_cycle
    call wait_cycle
    call wait_cycle
    
    call cursor_backward ; cursor always moves backwards, sticking
    cpi r22, 32
    brlo main_BWD_tag1
	inc r27
	cp r27, r21 ; if we already showed whole text
	brlo main_BWD_tag1
	    jmp main_cycle_endBWD ; end cycle
main_BWD_tag1:
    call lcd_clear
    jmp main_cycle_beginBWD
    
    
main_cycle_endBWD:
call lcd_clear
call wait_cycle
call wait_cycle
call wait_cycle
jmp main_FWD      


main_FWD:    ; initialization process for FWD movement
ldi r26, 0
ldi r27, 0
call calculate_text_len_to_r27 
ldi r22, 0
    
main_cycle_beginFWD:    
    
call show_text_from_position
call wait_cycle
call wait_cycle
call wait_cycle
    
inc r22    
    
cpi r27, 0 
brne cycle_fwd_tag1    
    call cursor_forward ; call cursor forward if r27 is equal to 0 (reached start of text)
    jmp cycle_fwd_tag2  
cycle_fwd_tag1:    
    dec r27
cycle_fwd_tag2: 
    cpi r26, 0x50 ; check if carrier at last pos
    brne cycle_fwd_tag3
	cpi r27, 0 ; check if from beginning AND last pos
	brne cycle_fwd_tag3
	jmp main_cycle_endFWD ; then end programm
cycle_fwd_tag3:
    call lcd_clear
    jmp main_cycle_beginFWD
 
      
main_cycle_endFWD:
call lcd_clear
call wait_cycle
call wait_cycle
call wait_cycle
call wait_cycle
jmp main_BWD    
    
    
end: jmp end    


show_text_from_position:
    ; r26 is display cursor
    ; r27 is text position
    mov r17, r26
    call reset_Z
    ldi r23, 0
    cp r23, r27
    breq from_pos_tag1
    
from_pos_inc_start: ; this thing is basically a for loop to get Z up to desired place
    lpm r16, Z+ ; get next symbol, inc Z
    inc r23 ; increment inner counter
    cp r23, r27 ; check if at needed symbol
    brne from_pos_inc_start
    
from_pos_tag1:
    lpm r16, Z+ ; get new char
    cpi r16, 0 ; check if '0'
    brne from_pos_tag2 ; if not, continue
    jmp from_pos_end ; if yes, jump to end
    
from_pos_tag2:    
    call show_char ; print character at r17
    cpi r17, 0x4f ; check if r17 is at end
    breq from_pos_end ; if it is, end
    cpi r17, 15 ; check if r17 is 15 (end of upper row)
    brne from_pos_tag3 
    ldi r17, 63 ; if it is, set to 0x40 - 1 (inc later)
 from_pos_tag3:
    inc r17 ; inc r17
    jmp from_pos_tag1 ; repeat cycle

from_pos_end:
    ret
        
reset_Z:
    ldi r30, low(2*retez)
    ldi r31, high(2*retez)
    ret
    
    
    
cursor_forward: ; moves r26 forward, with sticking
    cpi r26, 15
    brne next_fwd
	ldi r26, 0x40
	ret
    next_fwd:
    cpi r26, 0x50
    brne next_fwd2
    ret
    next_fwd2:
    inc r26
    ret
    
cursor_backward: ; moves r27 backwards, with sticking
    cpi r26, 0x40
    brne next_bwd
	ldi r26, 0x0f
	ret
    next_bwd:
    cpi r26, 0
    brne next_bwd2
    ret
    next_bwd2:
    dec r26
    ret   
    
calculate_text_len_to_r27:
    ldi r27, 0
    call reset_Z
    calc_start:
	lpm r16, Z+
	inc r27
	cpi r16, 0
	brne calc_start
	
    ret

wait_cycle:
    ldi r18, 72
cek3: ldi r28, 100
cek2: ldi r29, 120
cek: dec r29
    brne cek
    dec r28
    brne cek2
    dec r18
    brne cek3
    ret