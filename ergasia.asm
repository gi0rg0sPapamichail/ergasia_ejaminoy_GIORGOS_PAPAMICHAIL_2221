;A.M.:2221 A.M.:2140 A.M.:2120

TITLE ERGASTIRIAKO_PROJECT

data segment      
    black db 0;black color value    
             
    ;enemy info   
    enemy_x dw 155 ;STARTING FROM X MIDLE 160 - half length
    enemy_y dw 0   ;starting from the top of the screen
    enemy_len dw 10 ;enemy is 1x10 PIXELS 
    enemy_color dw 40 ;red for enemy 
    enemy_move db 0; 0 is right 1 is left  
    last_movement_msb dw 00h ;the MSB of the 32bit counter
    last_movement_lsb dw 00h ;the LSB of the 32bit counter
    enemy_move_delay db 1    ;how much to wait for enemy 
    
    ;player info        
    player_x dw  160;starting from midle
    player_y dw 180;anchored
    player_height dw 20 ; players height is 20 
    player_width dw 10 ;anti na baloyme 10 tha baloyme 11 gia na einai poio omorfo sto mati otan peta to blima    
    player_color dw 30 ;white for player   
    
    ;elements  
    missle_color dw 60  
    last_missle_msb dw 00h ;the MSB of the 32bit counter
    last_missle_lsb dw 00h ;the LSB of the 32bit counter

    
    missles_speed_MSB dw 00h; the speed delay MSB     
    missles_speed_LSB dw 00h; the speed delay LSB 
    
    missle_delay db 10     ;how much to wait until to shoot a new missle
    missle_speed db 1     ;how much to wait until to move the missle
    missles db 0; the missles that have been shot  
    
    missles_wsizeof equ 4; in the array the size of the missle data is 8byte = 4 words
    max_missles equ 6;the maximum amount of missles there can be at once
    
    missles_array dw max_missles * missles_wsizeof dup(0);array to store the missles info
    
    
    ;general
    erease_entity dw 0      
    score dw 00     
    endgame1_msg db "GAME OVER. Enemy moved: $"
    endgame2_msg db " pixels.$" 
    ascii_score db 5 dup(0)
data ends

code segment
    start: mov ax, data
    mov ds, ax
                  
    ;game initialisation  
    
    ;setup graphics            
    call setGraphicsMode                
    
    ;create player        
    push player_x
    push player_y
    push player_height
    push player_width
    push player_color                    
    call create_player
    add sp, 10
    
    ;create enemy    
    push enemy_x
    push enemy_y 
    push enemy_color  
    call create_enemy  
    add sp, 6
    
    mov ah, 8
    int 21h ;wait for user to start the game by prsessing any key  
    
    ;fix the timming variables
    mov ah, 00h
    int 1ah
    
    mov last_movement_msb, cx
    mov last_movement_lsb, dx 
    
    mov last_missle_msb, cx
    mov last_missle_lsb, dx  
    
    mov missles_speed_MSB, cx
    mov missles_speed_LSB, dx  
    
game_loop:;-----------while 1 {  
    cmp missles, 0;if there are misssles
    je nomissles
    ;move them
    lea ax, missles
    push ax
    lea ax, missles_speed_MSB
    push ax
    lea ax, missles_speed_LSB
    push ax
    lea ax, missles_array
    push ax
    call move_multi_missles
    add sp, 8
        
    nomissles:  
    
    
    mov ah, 01h
    int 16h 
    jz no_input
    mov ah, 0
    int 16h  
    ;if q quit else if input = < move player left else if > move player right
    ;else if space go to generate missele else continue code 
    
     
    
    cmp al, 'q'
    je endproc
    
    cmp ax, 04b00h;left arrow
    jne skip_left_arrow 
        lea ax, player_x
        push ax
        push 0    
        call move_player
        add sp, 2;clear the parameter    
    skip_left_arrow:
    
    cmp ax, 04d00h;right arrow
    jne skip_right_aarrow
       lea ax, player_x
       push ax
       push 1    
       call move_player 
       add sp, 2;clear the parameter
    skip_right_aarrow:
    
    cmp al, 32;space
    jne no_input   
    
    cmp missles, max_missles
    jae no_input;  
    
    mov ah, 00h
    int 1ah
    
    ;if the current time MSB is greater than the previous (time+delay)MSB then move the enemy 
    cmp cx, last_missle_msb
    ja make_missle
      
    ;if the current time LSB is smaller than the previous (time+delay)LSB then continue the loop  
    cmp dx, last_missle_lsb
    jb  no_input
    
    make_missle:
    
    mov last_missle_msb, cx
    mov last_missle_lsb, dx 
    
    lea ax, last_missle_msb
    push ax   
    
    lea ax, last_missle_lsb
    push ax   
    
    mov al, missle_delay
    xor ah, ah
    push ax
    
    call add32_8
    add sp, 6 

    ;create dump space for the missle info
;    push 0       
;    push 0
;    push 0
;    push 0
    ;create the missles existance
    call create_missle_in_array 
    
    no_input: 
    
    call search_win_condition;before moving the enemy we need to check if a missle hass hitted it
    
    mov ah, 00h
    int 1ah
    
    ;if the current time MSB is greater than the previous (time+delay)MSB then move the enemy 
    cmp cx, last_movement_msb
    ja moveenemytime 
      
    ;if the current time LSB is smaller than the previous (time+delay)LSB then continue the loop  
    cmp dx, last_movement_lsb
    jb  game_loop 
    
    
    moveenemytime:  
    ;--UPDATE NEW DELAY TIME        
    mov ah, 00h
    int 1ah
    
    mov last_movement_msb, cx
    mov last_movement_lsb, dx
      
    lea ax, last_movement_msb
    push ax 
    lea ax, last_movement_lsb
    push ax   
    xor ah, ah
    mov al, enemy_move_delay    
    push ax
    call add32_8   
    add sp, 6
    ;--UPDATE NEW DELAY TIME 

    lea ax, score ;we take it as constant 
    push ax
    lea ax, enemy_x;we take it as constant 
    push ax
    lea ax, enemy_y;we take it as constant 
    push ax
    lea ax, enemy_move
    push ax
    call move_enemy 
    
    ;if enemy_y >= 180 break
    cmp enemy_y, 180
    jae game_over
    
    jmp game_loop ;}---------------
    
game_over: 

    call endGraphicsMode 
    
    mov ah, 9
    lea dx, endgame1_msg
    int 21h
    
    call convertScoreToASCII        
    
    mov bp, sp
    
    ;push a->d 4
    
    sub bp, 20
    
    mov cx, 5
    xor si, si
    makestring:           
    mov dx, [bp]
    mov [ascii_score+si], dl
    inc si
    add bp, 2 
    loop makestring
    
    lea dx, ascii_score
    
    mov ah, 9
    int 21h        
       
    
    mov ah, 9
    lea dx, endgame2_msg
    int 21h                   
                        
endproc:
    mov ah, 4ch
    int 21h   
    
    
;--------------------end of main---------------------
          
          
setGraphicsMode proc
    push ax
    ;320x200x256         
             
    mov ah, 00h 
    mov al, 13h
    int 10h
    
    pop ax 
    ret
setGraphicsMode endp           

endGraphicsMode proc
    push ax

    mov ah, 00h
    mov al, 03h
    int 10h

    pop ax
    ret
endGraphicsMode endp  

convertScoreToASCII proc
    push ax 
    push bx
    push cx 
    push dx 
    
    mov dx, '$'
    
    push dx
    
    mov cx, 4 
    mov bl, 10  
    xor bh, bh
    mov ax, score 
    xor dx, dx
    score_convert:
        div bx
        add dl, 30h
        push dx
        xor dx, dx           
    loop score_convert 
    
    
    
    add sp, 10
    
    pop dx
    pop cx
    pop bx
    pop ax 
    ret
convertScoreToASCII endp    

;12: &MSB
;10: &LSB
;8: DB
add32_8 proc
    push ax
    push bx
    push bp
    
    
    mov bp, sp
    
    mov ax, [bp+8];store the db to ax
    mov bx, [bp+10];store to bx the &LSB
    
    add [bx], ax
    jnc end_add 
        mov bx, [bp+12];store to bx the &MSB
        inc [bx]   
    end_add:
    pop bp
    pop bx
    pop ax
    ret
add32_8 endp    

;22 x
;20 y 
;18 width                     
;16 color                     
drawhorizontalline proc
    push ax
    push bx
    push cx
    push dx
    push es
    push si
    push bp
    
    mov bp, sp
    
    mov ax, 0a000h  
    mov es, ax
 
    mov ax, [bp+20];pare y
    
    mov bx, 320
    
    mul bx
    
    add ax, [bp+22] ;parex
    
    mov si, ax
    
    mov cx, [bp+18] ;pare w
    
    mov bx, 0
    mov bl, [bp+16] ;pare xroma  
    
    cmp cx, 0
    je endproc 
    
    mov ax, [bp+22]
    
printhline: 
        cmp ax, 320
        ja skip_Wpixel
      mov es:[si], bl  
      skip_Wpixel:
      inc si      
      inc ax
    loop printhline   
    
    
    
    
    pop bp
    pop si
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret
drawhorizontalline endp


;22: x
;20: y    
;18: height                     
;16: color   
drawverticalline proc
    push ax
    push bx
    push cx
    push dx
    push es
    push si
    push bp
    
    mov bp, sp
    
    mov ax, 0a000h  
    mov es, ax
 
    mov ax, [bp+20];pare y
    
    mov bx, 320
    
    mul bx
    
    add ax, [bp+22] ;parex
    
    mov si, ax
    
    mov cx, [bp+18] ;pare h
    
    mov bx, 0
    mov bl, [bp+16] ;pare xroma   
    
    cmp cx, 0
    je endproc
    
    mov ax, [bp+20];pare y
    
printvline:  
      cmp ax, 200
      ja skip_Hpixel
      mov es:[si], bl 
      skip_Hpixel: 
      add si, 320 
      inc ax
    loop printvline   
    
    
    
    
    pop bp
    pop si
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret
drawverticalline endp       

 
;24: x
;22: y 
;20: height                     
;18: width
;16: color   
create_player proc
    push ax                                       
    push bx
    push cx  
    push dx
    push es
    push si
    push bp
              
    mov bp, sp  
    
    mov ax, 0a000h  
    mov es, ax
    
    
    mov cx, [bp+20]
    
    cmp cx, 0 
    je endproc 
    
    mov ax, [bp+20]
    shl ax, 1;ax*2
    
    mov bx, [bp+18]
    
    xor dx, dx
    
    div bx
    
    ;no we hav stored in ax the a=2y/x 
    

    
    mov bl, 1;we will use bx as a counter
    
    
    push [bp+24];-2: x
    push [bp+22];-4: y
    push 1      ;-6: w
    push [bp+16];-8: c
    triangle:     
        call drawhorizontalline 
        add [bp-4], 1;go one y down 
        
        cmp bx, ax
        jae progress_w
        
        inc bx
    loop triangle
      progress_w:  
        mov bx, 1 
        push ax
        mov ax, [bp-2]   
        sub ax, 1 
        mov [bp-2], ax
        
        mov ax, [bp-6]
        add ax,2   
        mov [bp-6], ax
        pop ax
    loop triangle  
    
    add sp, 8 
    
    mov ax, player_x 
    
    pop bp
    pop si
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret
create_player endp
   
             
;param1 x
;param2 y
;param3 color                         
create_enemy proc    
    push bp   
    
    mov bp, sp  
    
    
    push [bp+8]  
    push [bp+6]  
    push enemy_len      
    push [bp+4]
    call drawhorizontalline  
         
    add sp, 8     

    pop bp         
    ret               
create_enemy endp   

;score      10
;enemy_x    8
;enemy_y    6
;enemy_move 4
move_enemy proc
    push bp

    mov bp, sp

    push ax  
    push bx
    
    ;destroy previoys enemy
    push enemy_x        ;constant
    push enemy_y        ;constant
    push erease_entity  ;constant
    call create_enemy   ;constant
    

    mov bx, [bp+10]
    mov ax, [bx] ;store score in ax to update it after the movement
    add ax, 2;in the x direction it always moves 2 pixels    
    mov [bx], ax

    mov bx, [bp+8] 
    mov ax, [bx] ;store x in ax to check if we are in bounds after the movement
    
    cmp enemy_move, 1 ;constant
    je move_L  
;---right movement      
    add ax, 2
    mov [bx], ax
    cmp ax, 310  
    jb endmove  

    mov [bx], 310 

    mov bx, [bp+4]
    mov  [bx], 1;make next movement left

    mov bx, [bp+6]
    mov ax, [bx]
    add ax, 1; and go down
    mov [bx], ax
    
    
    mov bx, [bp+10]
    mov ax, [bx] ;store score in ax to update it after the movement
    inc ax    
    mov [bx], ax

    jmp endmove  
     
    move_L:
    sub ax, 2

    mov [bx], ax
    
    cmp ax, 0 
    ja endmove  
    
    
    xor ax, ax  
    mov [bx], ax
    
    mov bx, [bp+6]

    add [bx], 1 ;and go down
    
    mov bx, [bp+4]
    mov  [bx], 0;make next movement right
    
    mov bx, [bp+10]
    mov ax, [bx] ;store score in ax to update it after the movement
    inc ax    
    mov [bx], ax  
    endmove: 
    
    
    push enemy_x       ;constant    
    push enemy_y       ;constant    
    push enemy_color   ;constant        
    call create_enemy  ;constant        
    
    add sp, 12
     
    pop bx
    pop ax
    pop bp
    ret  
move_enemy endp                     

;8: x
;6: left right flag
move_player proc 
    push ax
    push bp  
    
    mov bp, sp

    push bx
    
    cmp [bp+6], 1
    je move_pR
    ;-----------------left movement
    cmp player_x, 6     ;constant
    jbe outofflimits 
    
    
    push player_x       ;constant
    push player_y       ;constant
    push player_height  ;constant
    push player_width   ;constant
    push erease_entity  ;constant
    call create_player  ;constant
    add sp, 10
    
    mov bx, [bp+8]
    mov ax, [bx]
    sub ax, 1
    mov [bx], ax
    
    push player_x       ;constant   
    push player_y       ;constant   
    push player_height  ;constant       
    push player_width   ;constant       
    push player_color   ;constant       
    call create_player  ;constant       
    
    add sp, 10
    
    jmp outofflimits
    move_pR:    
    ;----------------right movement
    cmp player_x, 314 ;constant
    jae outofflimits   
    
    push player_x       ;constant   
    push player_y       ;constant   
    push player_height  ;constant       
    push player_width   ;constant       
    push erease_entity  ;constant           
    call create_player  ;constant       
    add sp, 10
    
    mov bx, [bp+8]
    mov ax, [bx]
    inc ax
    mov [bx], ax
    
    push player_x       ;constant   
    push player_y       ;constant   
    push player_height  ;constant       
    push player_width   ;constant       
    push player_color   ;constant       
    call create_player 
    
    add sp, 10   
    outofflimits:
    
    pop bx
    pop bp
    pop ax
    ret
move_player endp    

create_missle_in_array proc
    push bp
    
    mov bp, sp
    
    push ax
    push bx 
    push cx
    push dx   
    push si
    
    
    

    
    ;...
    ;x[1]bp+10
    ;y[1]bp+8
    ;x[0]bp+6
    ;y[0]bp+4
    ;call
    ;push bp  
    
    ;i_time_msb = 6+missles*8  
    ;i_time_lsb = 4+missles*8            
    ;i_x= 2+missles*8
    ;i_y= missles*8 
    
    ;------------SEARCH EMPTY SLOT---------------
    lea bx, missles_array
    xor si, si
    mov cl, max_missles
    xor ch, ch 
    xor ax, ax
    
    empty_check_loop:
        mov ax, [bx+si]
        add si, 2
        mov dx, [bx+si]
        
        not ax
        not dx
        
        and ax, dx
        
        add si, 2
        mov dx, [bx+si]
        not dx
        and ax, dx  
        add si, 2
        mov dx, [bx+si]
        not dx
        and ax, dx
        
        mov dx, 0FFFFh
        cmp ax, dx
        je empty_slot
        
        add si, 2
         
    loop empty_check_loop     
    ;------------SEARCH EMPTY SLOT--------------- 
    empty_slot: 
    sub si, 6
    
    
    mov ax, player_y
    
    mov [bx+si], ax
    
    add si, 2 
    
    mov ax, player_x
    
    mov [bx+si], ax   
    
    add si, 2
    
    mov ah, 0
    int 1ah 

    mov [bx+si], dx
    add si, 2
    
    mov [bx+si], cx
    
    inc missles  
 
    pop si
    pop dx 
    pop cx
    pop bx
    pop ax
    pop bp
    ret    
create_missle_in_array endp    


;8:x
;6:y
;4:color
create_missle proc
  push bp
  
  mov bp, sp
  push ax 
  
  
  push [bp+8]
  push [bp+6] 
  mov al, 3
  xor ah, ah        
  push ax
  push [bp+4]
  call drawverticalline 
  
  add sp, 8
  pop ax
  pop bp 
  ret   
create_missle endp    
 

;10: missle_x        
;8: missle_y
;6: &Delay_MSB
;4: &delay_LSB
move_single_missle proc 
    push bp
    mov bp, sp
    
    push ax
    push bx
    push cx 
    push dx 
    
    mov ah, 0
    int 1ah
    
    mov bx, [bp+6] 
    
    ;if the current time MSB is greater than the previous (time+delay)MSB then move the enemy 
    cmp cx, [bx]
    ja move_missle  
    
    mov bx, [bp+4]
      
    ;if the current time LSB is smaller than the previous (time+delay)LSB then continue the loop  
    cmp dx, [bx]
    jb  dontmovemissle 
    
    move_missle: 
    
    mov [bx], dx
    mov bx, [bp+6] 
    mov [bx], cx 
    
    push [bp+6]
    push [bp+4]
    mov al, missle_speed
    xor ah, ah
    push ax
    call add32_8
    add sp, 6
    
    push [bp+10]
    push [bp+8]
    push erease_entity
    call create_missle
    add sp, 4;we dont have to remove the x frop the stack
    
    mov ax, [bp+8]
    sub ax, 2
    
    mov [bp+8], ax  
    
    push ax
    push missle_color
    call create_missle
    
    add sp, 6
    
    dontmovemissle:
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp             
    ret
move_single_missle endp   

;10: missles
;8: missles_speed_MSB
;6: missles_speed_LSB
;4: &missles_array
move_multi_missles proc
    push bp
    mov bp, sp
    add bp, 4
    
    push ax
    push bx
    push cx
    push dx
    push si  
    
    mov cl, max_missles
    xor ch, ch
    
    xor si, si        
    
    ;...
    ;x1
    ;y1: +2
    ;msb0: +2
    ;lsb0: +2
    ;x0: +2
    ;y0: 0
    mov  bx, [bp]
    check_movement:
        mov ax, [bx+si]
        add si, 2
        mov dx, [bx+si]
        
        not ax
        not dx
        
        and ax, dx
        
        add si, 2
        mov dx, [bx+si]
        not dx
        and ax, dx
        add si, 2
        mov dx, [bx+si]
        not dx
        and ax, dx 
        
        mov dx, 0FFFFh
        cmp ax, dx
        jne move_missles
            add si, 2  
            loop check_movement
            jmp endmulti_move       
        move_missles: 
        sub si, 4
        
        push [bx+si];xi
        
        sub si, 2
        
        push [bx+si];yi  
        
        
        add si, 6
        mov ax, [bx+si];msbi   

        push bx
        mov bx, [bp+4]
        mov [bx], ax
        mov ax, bx 
        pop bx
        push ax
        
        sub si, 2   
        mov ax, [bx+si];lsbi  

        push bx  
        mov bx, [bp+2]
        mov [bx], ax
        mov ax, bx 
        pop bx
        push ax

        call move_single_missle   
        
        add sp, 4 
        
        pop ax

        add sp, 2  
        
        
        sub si, 4
        
        mov [bx+si], ax;yi  
        
        mov dl, 200
        xor dh, dh
        add ax, 3 
        cmp ax, dx
        jbe in_bounds
            xor ax, ax
            mov [bx+si], ax
            add si, 2
            mov [bx+si], ax
            sub si, 2

            push bx

            mov bx, [bp+4]
            mov [bx], ax
            mov bx, [bp+2]
            mov [bx], ax
                  
            mov bx, [bp+6]
            mov ax, [bx]
            sub ax, 1
            mov [bx], ax
            pop bx
        in_bounds:
        add si, 6 
        
        mov ax, missles_speed_MSB    
        mov [bx+si], ax
        
        sub si, 2 
        mov ax, missles_speed_LSB    
        mov [bx+si], ax
                          
        add si, 4
    loop check_movement
    endmulti_move:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret    
move_multi_missles endp
                        
search_win_condition proc 
    ;so to win we hgave 2 condtions
    ;x_enemy<=xmissle<=xenemy+4
    ;and 
    ;y_missle-2<=yenemy<=ymissle
    ;to make it more easay we can do
    ;x_enemy<=xmissle<=x_enemy+4->0<=xmissle-x_enemy<=4
    ;sinces its unsigned sub we can only keep the high limit since the low is 0<= so now we only have
    ;xmissle-x_enemy<=4
    ;with the same logic the second becomes
    ;y_missle<=yenemy<=ymissle+2-> 0<=yenemy-y_missle<=2 ->
    ;yenemy-y_missle<=2
    
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov cx, max_missles
    
    xor si, si
    lea bx, missles_array
    search_loop: 
    mov ax, [bx+si]
    add si, 2
    
    or ax, [bx+si]
    
    ;if x == y == 0 then its not valid since its an empty space of memory
    cmp ax, 0
    je unsatisfied  
    
    sub si, 2
    
    
    mov dx, [bx+si]
    mov ax, enemy_y;we take it as constant 
    add si, 2
    
    sub ax, dx
    
    cmp ax, 2
    ja unsatisfied
    
    mov ax, [bx+si]
    mov dx, enemy_x;we take it as constant 
    
    sub ax, dx 
    
    cmp ax, 9
    jbe game_over
    
    unsatisfied:
    add si, 6
    
    loop search_loop 
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax  
    ret
search_win_condition endp                            
code ends 
end start
