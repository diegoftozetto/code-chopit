

;-----------------------------------------------------------------------------
;                              MACRO PARA DESENHO                            -
;-----------------------------------------------------------------------------
mcr_dc MACRO PX PY CRC COR TAM 
    
MOV DH, PX ; linha
MOV DL, PY
MOV AH,02h ; move o cursor
INT 10h  
    
MOV BL, COR 
MOV AL, CRC 
MOV AH, 09h ; imprime caracter na pos do cursor
MOV CX, TAM   
INT 10h
   
mrc_dc ENDM                

;-----------------------------------------------------------------------------
;                              MACRO DESENHAR MADEIRA                        -
;-----------------------------------------------------------------------------
mrc_fundo_letra_madeira MACRO NV 
local lb_printf1 lb_printf lb_print_fim
MOV cor_fundo,0Fh
LEA DX,NV
MOV SI,DX 

ADD SI,38d  
MOV AL,[SI]
SUB AL,30h
MOV RESULTADO,AL


LEA DX,NV
MOV SI,DX 

ADD SI,23d
MOV AH,00h  
MOV CL,15d

lb_printf1:
    PUSHA
    mcr_dc 00h AH [SI] cor_fundo 01h 
    POPA

    INC SI
    
    INC AH
LOOP lb_printf1 
    
LEA DX,NV
MOV SI,DX

MOV AH,12h
       
MOV CL,20d 
MOV AL,00H 

lb_printf:
    PUSHA
    mcr_dc 00h AH [SI] cor_fundo 01h 
    POPA

    INC SI
    
    INC AL  
    INC AH
    CMP AL,04h
JBE lb_print_fim
MOV AL,00H 
INC SI
ADD AH,0Bh
lb_print_fim:

LOOP lb_printf    

   
Mrc_fundo_letra_madeira ENDM


;-----------------------------------------------------------------------------
;                              MACRO  MOSCA                                  -
;-----------------------------------------------------------------------------

;print moscas
mcr_carrega_moscas MACRO
local lb_c1 lb_cl2 lb_cl3 lb_vmosca
CMP NIVEL,1h
   JE lb_cl1 
   CMP NIVEL,2h
   JE lb_cl2
   CMP NIVEL,3h
   JE lb_cl3

lb_cl1:
   MOV CL,moscas_nivel1    
   JMP lb_vmosca
lb_cl2:
   MOV CL,moscas_nivel2
   JMP lb_vmosca
lb_cl3:
   MOV CL,moscas_nivel3

lb_vmosca:
MOV QNTDMOSCAS,CL
MOV SI,0h
        
lb_r: 
    PUSHA 
    CALL prc_print_moscas
    POPA     
    INC SI
    LOOP lb_r    

mcr_carrega_moscas ENDM

;Carrega a posy (aleatorio) no vetor da da mosca
mcr_vetor_moscas MACRO 
local lb_cl7  lb_cl14 lb_cl21    

CMP NIVEL,1h
JE lb_cl7 
CMP NIVEL,2h
JE lb_cl14
CMP NIVEL,3h
JE lb_cl21

lb_cl7:
    MOV CL,moscas_nivel1
    JMP lb_vmosca
lb_cl14:
    MOV CL,moscas_nivel2
    JMP lb_vmosca
lb_cl21:
    MOV CL,moscas_nivel3 
   
    MOV SI,00h 
lb_vmosca:   
    PUSHA
    ;mcr_aleatorio 7H 37H 
    ;MOV pos_moedas_y[SI],DL
    MOV AL,pos_moedas_aux[SI]
    MOV pos_moedas_y[SI],AL
    POPA 
     
    INC SI 
    LOOP lb_vmosca
mcr_vetor_moscas ENDM


;Carrega a pontuacao mosca (numero)
mrc_moscas MACRO
MOV DL,0Eh 
MOV BL,0FH
PUSHA
mcr_dc 18h DL 0B2H 00H 01h
POPA      
     
MOV AL,MOSCAS
ADD MOSCAST,AL
ADD AL,30h
    
PUSHA
mcr_dc 18h DL AL BL 01h
POPA    
mrc_moscas ENDM

;-----------------------------------------------------------------------------
;                                  MACRO POSICAO                             -
;----------------------------------------------------------------------------- 
mcr_verf_pos MACRO posv x

local lb_mr17 lb_mr27 lb_mr37 lb_perde_vida lb_1 lb_2 lb_3 lb_teste 


    MOV AL,x
    CMP posv,11h
    JBE  lb_perde_vida 
    CMP posv,47h
    JAE  lb_perde_vida 
    CMP posv,17h
    JAE  lb_mr17
    MOV pos_ponte_atual,1h
    JMP  lb_teste

lb_mr17:
    CMP posv,21h
    JBE lb_perde_vida
    CMP posv,27h
    JAE lb_mr27
     MOV pos_ponte_atual,2h
    JMP lb_teste

lb_mr27: 
    CMP posv,31h
    JBE lb_perde_vida
    CMP posv,37h
    JAE lb_mr37
    MOV pos_ponte_atual,3h
    JMP lb_teste


lb_mr37:
    CMP posv,41h
    JBE lb_perde_vida 
    MOV pos_ponte_atual,4h

lb_teste:    
    CMP AL,1h
    JE lb_1 
    CMP AL,2h
    JE lb_2 

lb_1:
    JMP lb_volta

lb_2:    
    JMP lb_vt
     
    
lb_perde_vida:   
mcr_verf_pos ENDM       
    
;-----------------------------------------------------------------------------
;                                  MACRO VIDA                                -
;----------------------------------------------------------------------------- 
mcr_vida MACRO

local lb_game_over lb_sair 

DEC vida

CMP vida,00h
JE lb_game_over

MOV pos_y, 28h
MOV pos_x, 17h 

PUSHA   
CALL prc_vida                   
POPA

JMP lb_sair
lb_game_over:
CALL prc_gameOver
INT 20H

lb_sair:  
mcr_vida ENDM 


;-----------------------------------------------------------------------------
;                                  MACRO MOVIMENTA CARRO                     -
;----------------------------------------------------------------------------- 
mcr_movimentaCarro MACRO
local lb_r, lb_limpar, lb_sair      

MOV CL,3d 
 
lb_r:    
    PUSHA
    call prc_colisao
    POPA
    
 
    PUSHA 
    CALL prc_carro
    POPA     
    INC SI
LOOP lb_r
    

CMP SI,12d
JE lb_limpar
JMP lb_sair

lb_limpar:
    MOV SI,0d
    
lb_sair:
mcr_movimentaCarro ENDM

;-----------------------------------------------------------------------------
;                                  MACRO LIMPA TELA                          -
;----------------------------------------------------------------------------- 
mcr_limpaTela MACRO
MOV AH,6
MOV AL,0
MOV BH,7
MOV CX,0
MOV DL,79
MOV DH,25
INT 10H
MOV AH,2
MOV BH,0
MOV DH,0
MOV DL,0
INT 10H
mcr_limpaTela ENDM  


;-----------------------------------------------------------------------------
;                              MACRO GERA ALEATORIO                          -
;-----------------------------------------------------------------------------
mcr_aleatorio MACRO INICIO FIM
local RANDSTART  
                 
RANDSTART:
   MOV AH, 00h  
   INT 1AH     

   MOV  AX, DX
   XOR  DX, DX
   MOV  CX, FIM    
   DIV  CX       
   
   MOV BL,INICIO
      
   CMP BL,DL
   JGE RANDSTART     
mcr_aleatorio ENDM 

;-----------------------------------------------------------------------------
;                                  MACRO TOCA SOM                            -
;-----------------------------------------------------------------------------

mcr_tocasom MACRO nota tempo
local pausa1 pausa2

mov al,182         
out 43h, al        
mov ax, nota       
                                
out 42h, al        
mov al, ah         
out 42h, al 
in al, 61h        
                                
or al, 00000011b   
out 61h, al        
mov bx, 25         
pausa1:
    mov cx,tempo
pausa2:
    dec cx
    jne pausa2
    dec bx
    jne pausa1
    in  al, 61h        
                               
    and al, 11111100b  
    out 61h, al  
mcr_tocasom ENDM