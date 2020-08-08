COD SEGMENT
ASSUME CS:COD, DS:COD, ES:COD, SS:COD
ORG 100h

INCLUDE "Macro.asm"

MAIN PROC NEAR

;-----------------------------------------------------------------------------
;                                       JOGO                                 -
;----------------------------------------------------------------------------- 

;------------------------------------
;       CONFIGURACAO/INSTRUCAO      -
;------------------------------------
lb_inicio:
        
;Configuracao da Tela   
MOV AH,00h  ; Ajusta o Modo de Video
MOV AL,02h  ; Modo Texto   
INT 10h     ; 80x25, 16 cores, 8 paginas


;Cria palavra Chopit

MOV AH,09h
MOV DH,00h
LEA DX, str_chopit
INT 21h 

;Espera Tecla Enter (No Menu de Instrucoes)   
lb_enter1:
    MOV AH,01h
    INT 21h
    CMP AL,0Dh
    JNE lb_enter1            
    mcr_limpaTela


;Cria menu de Instrucoes
lb_menuInst:
    MOV AH,09h
    MOV DH,00h
    LEA DX, str_menuInst
    INT 21h 

;Espera Tecla Enter (No Menu de Instrucoes)   
lb_enter:
    MOV AH,01h
    INT 21h
    CMP AL,0Dh
    JNE lb_enter            
    mcr_limpaTela



;------------------------------------
;           NIVEL (1/2/3)           -
;------------------------------------
lb_nivel:
    mcr_vetor_moscas  
    
    ;Cria os fundos  
    CALL prc_fundo 
    CALL prc_fundo_madeira
    
    ;Verifica o nivel atul
    CMP NIVEL,1h
    JE lb_nivel1 
    CMP NIVEL,2h
    JE lb_nivel2
    CMP NIVEL,3h
    JE lb_nivel3
    JMP lb_finaliza_jogo 

lb_nivel1:
       MOV DELAY_AUX,10000d   
       MOV NVP,01h
       CALL prc_gera_nivel        
       JMP lb_fundo       
lb_nivel2:                  
       MOV DELAY_AUX,5000d
       MOV NVP,02h
       CALL prc_gera_nivel        
       JMP lb_fundo
lb_nivel3:                  
       MOV DELAY_AUX,2200d
       MOV NVP,03h
       CALL prc_gera_nivel        
       JMP lb_fundo
lb_finaliza_jogo:       
       CALL prc_parabens
       INT 20H
             
;------------------------------------
;              CENARIO              -
;------------------------------------
lb_fundo:
    ;Print das moscas (Menu)   
    CALL prc_escrever_mosca     
    mrc_moscas
    mcr_dc 18h 0Fh ' ' 0FH 01h       
   
    ;Print do Nivel (Menu) 
    CALL prc_escrever_nivel 
    
    MOV DL,1Bh
    MOV BL,06h
    MOV AL,0Fh 
    MOV CL,NIVEL

lb_cnivel:    
    PUSHA
    mcr_dc 18h DL AL BL 01h
    POPA 
    INC DL
LOOP lb_cnivel
    
    ;Carrega Moscas (Cenario)
    mcr_carrega_moscas
    
    ;Desenha Personagem (Cenario)
    MOV SI,0h
    JMP lb_desenhaPersonagem

;------------------------------------
;          INICIA JOGO              -
;------------------------------------
;Inicia Jogo
lb_IniciarJogo:
    ;Informa se Alguma Tecla Esta Pressionada    
    MOV AH,01h
    INT 16h 
    
    ;Tecla Pressionada (Cima|Baixo|Esquerda|Direita)               
    JNZ lb_teclaPress    
    JMP lb_continuaIniciarJogo
    
lb_continuaIniciarJogo:    
;Movimenta os carros (Quando a tecla nao esta pressionada)
lb_carros: 
    mcr_movimentaCarro    
;Desenha o Personagem na Tela   
lb_desenhaPersonagem:    
    PUSHA    
    mcr_dc pos_x pos_y Personagem 4Fh 1h   
    POPA     

    JMP lb_IniciarJogo   

;Tecla de Movimentacao Pressionada
lb_teclaPress: 
    ;Movimenta os Carros (Quando a tecla esta pressionada)     
    mcr_movimentaCarro
  
    ;Movimento do Personagem
    MOV AH,00h
    INT 16h 
    
    PUSHA
    ;mcr_tocasom 2500d 1500d
    POPA 
    
    
    ;Compara para Saber qual Tecla foi Pressionada
    CMP AH,48h                            
    JE lb_mjogador_cima
    
    CMP AH, 50h
    JE lb_mjogador_baixo
    
    CMP AH, 4Bh
    JE lb_mjogador_esquerda
    
    CMP AH, 4Dh
    JE lb_mjogador_direita
    
    CMP AL, 1Bh
    JE lb_esc     
  
    ;Retoma o Jogo    
    JMP lb_IniciarJogo

lb_esc:
    mcr_limpaTela
    INT 20h 
    
;Label para Movimento
lb_mjogador_cima:
    CMP pos_x,01h
    JE lb_verf_ganhou
     
    CALL prc_piso  
    PUSHA
    mcr_dc pos_x pos_y 0B2h cor_piso 1h
    POPA
    CMP pos_x,8h
    JE lb_vida    
lb_volta:  
    DEC pos_x 
    JMP lb_continua
lb_vida: 
    PUSHA
    mcr_verf_pos pos_y 1h
    POPA 
    JMP lb_dm_vida
    
lb_mjogador_baixo:
       
    CMP pos_x,17h
    JE lb_continua 
    CALL prc_piso
    mcr_dc pos_x pos_y 0B2h cor_piso 1h    
    INC pos_x 
    JMP lb_continua

 
lb_mjogador_direita:    
    CMP pos_y,4Fh
    JE lb_continua   
    
    MOV CL,1h
    MOV AL,0h
        
    INC pos_y 
    CMP pos_x,8h    
    JB lb_vd   
    JMP lb_vt

lb_mjogador_esquerda:    
    CMP pos_y,00h
    JE lb_continua     
     
    MOV CL,2h
    MOV AL,0h
    
    DEC pos_y 
    CMP pos_x,8h    
    JB lb_vd     
    JMP lb_vt    

;Madeira/Agua (Para pintar onde o personagem anda)
lb_vt:    
    CMP CL,1h
    JE lb_dec
lb_inc:
    INC pos_y 
    JMP ln_sg
lb_dec:
    DEC pos_y

ln_sg:    
    CMP AL,0h
    JE lb_call    
    MOV cor_piso,06h   
    JMP lb_ncall
lb_call:     
    CALL prc_piso_horizontal    
lb_ncall:     
    PUSHA  
    mcr_dc pos_x pos_y 0B2h cor_piso 1h 
    POPA
    
    CMP CL,1h
    JE lb_inc2

lb_dec2:
    DEC pos_y
    JMP ln_sg2    
lb_inc2:
    INC pos_y
ln_sg2:          
    JMP lb_continua 
    
lb_vd:
    MOV AL,1h    
                        
    PUSHA        
    mcr_verf_pos pos_y 2h
    POPA
    
    CMP CL,1h
    JE lb_dec3 
    
lb_inc3:
    INC pos_y 
    JMP ln_sg3
lb_dec3:
    DEC pos_y
ln_sg3:  

    MOV cor_piso,06h 
    JMP lb_dm_vida

lb_dm_vida:  
    
    PUSHA  
    mcr_dc pos_x pos_y 0B2h cor_piso 1h     
    mcr_vida 
    POPA       
                     
lb_continua:
    PUSHA    
    mcr_dc pos_x pos_y Personagem 4Fh 1h   
    POPA     
    
    PUSHA
    MOV SI,00h 
    MOV CL,09d  

lb_volta_mosca:    
    CALL prc_moscas    
    INC SI
LOOP lb_volta_mosca
     
    POPA    
    JMP lb_IniciarJogo                     

lb_verf_ganhou:
    
    MOV AL,QNTDMOSCAS   
    CMP MOSCAS,AL
    JE lb_quase_ganhou
    JMP lb_IniciarJogo
    
lb_quase_ganhou:  
    MOV AL,RESULTADO          
    CMP pos_ponte_atual,AL
    
    JE lb_prox_nivel
    JMP lb_IniciarJogo
    
lb_prox_nivel:
    INC NIVEL
    MOV AL,MOSCAS   
    ADD MOSCAST,AL
    MOV MOSCAS,0H 
    mcr_limpaTela 
    
    MOV SI,0d 
    
    MOV pos_y,28h
    MOV pos_x,17h 
    
    JMP lb_nivel      
                
MAIN ENDP    

;-----------------------------------------------------------------------------
;                                 VARIAVEIS                                  -
;-----------------------------------------------------------------------------   

;Variaveis Constantes    
Personagem EQU 04h 
Carro EQU 0B2h
Madeira EQU 0B2h

moscas_nivel1 EQU 3d   ;ate 7
moscas_nivel2 EQU 6d   ;ate 14
moscas_nivel3 EQU 9d   ;ate 21 

;Variaveis de posicao (Carro)
pos_car_x DB 12h   
pos_car_y DB -01d 

;Variaveis de posicao (Personagem)
pos_y db 28h
pos_x db 17h

pos_ponte_atual DB 0
RESULTADO DB 0

;Variaveis de cor
cor_fundo DB 0Ah 
cor_piso DB 00h

;Variaveis de caracter
caracter_fundo EQU 0B2h 

;Variaveis de Controle
qntdBlocos DW 80d
coracao DB 03h,03h,03h
vida DB 3d
cont DB 00h 

INICIAL DB 020H
FINAL DW 04CH 

DELAY     DW 0FFFFh ;delay p os carros
DELAY_AUX DW 0FFFFh
 
MOSCAS DB 0h 
MOSCAST DB 0h
NIVEL DB 1h
QNTDMOSCAS DB 0 
NVP DB 0h

;vetores/string
pos_carros_x DB 0Ah,0Ah,0Ah,0Dh,0Dh,0Dh,12h,12h,12h,15h,15h,15h 
pos_carros_y DB 02h,13h,35h,06h,1Ch,43h,07h,1Bh,39h,07h,25h,44h 
 
pos_moedas_x DB 8h,9h,10h,13h,14,16h,0Eh,8h,9h,10h,13h,14,16h,0Eh,8h,9h,10h,13h,14,16h,0Eh
pos_moedas_y DB 17h,28h,07h,0Ah,25h,0Fh,2Dh,,46h,32h,41h,1Bh,20h,25h,29h,02h,40h,11h,28h,45h,13h,4Bh
pos_moedas_aux DB 17h,28h,07h,0Ah,25h,0Fh,2Dh,,46h,32h,41h,1Bh,20h,25h,29h,02h,40h,11h,28h,45h,13h,4Bh

                                        
NA1 DB "37+42 34+62 16+53 91-14 Resultado: 69 3$"
NA2 DB "44+40 71+12 91-59 81+04 Resultado: 83 2$" 
NA3 DB "81+01 46+02 71-33 51+14 Resultado: 65 4$" 
NA4 DB "91-51 95+02 91-33 31+14 Resultado: 40 1$" 
NA5 DB "01+31 01-02 01+33 41-40 Resultado: -1 2$" 
                                                                                                    
NB1 DB "4X*7X X*8+X 4X+3X 6X*1X Resultado: 7X 3$"
NB2 DB "08*05 41*02 91-33 78*14 Resultado: 40 1$" 
NB3 DB "42/02 48*02 01+9X 91*04 Resultado: 96 2$" 
NB4 DB "41*01 31*02 01*33 01*14 Resultado: 62 2$" 
NB5 DB "88/04 41+02 45*07 30*03 Resultado: 90 4$"                                                               

NC1 DB "3/2+2 5/2-2 4*2/2 int 5 Resultado: 04 3$"
NC2 DB "48/24 4/2-2 3/4+3 56/08 Resultado: 07 4$" 
NC3 DB "90-91 dZ/dZ 9/3+6 01+14 Resultado: 01 1$" 
NC4 DB "1X-1X 2X+5X int 3 dY/dY Resultado: 01 4$" 
NC5 DB "3X*3X 9X/03 int X dX/dX Resultado: 3X 2$" 


;-----------------------------------------------------------------------------
;         MENU ( CHOPIT | INICIAL | GAME OVER | VITORIA)                     -
;-----------------------------------------------------------------------------  


str_chopit dw '  ',0ah,0dh
dw ' ',0ah,0dh
dw ' ########### #        # ########### ######### ## ###########',0ah,0dh
dw ' #           #        # #         # #       # ##      ##    ',0ah,0dh                                        
dw ' #           #        # #         # #       #         ##    ',0ah,0dh
dw ' #           #        # #         # #       # ##      ##    ',0ah,0dh
dw ' #           #        # #         # #       # ##      ##    ',0ah,0dh
dw ' #           #        # #         # #       # ##      ##    ',0ah,0dh          
dw ' #           #        # #         # ######### ##      ##    ',0ah,0dh        
dw ' #           #        # #         # #         ##      ##    ',0ah,0dh
dw ' #           ########## #         # #         ##      ##    ',0ah,0dh  
dw ' #           #        # #         # #         ##      ##    ',0ah,0dh
dw ' #           #        # #         # #         ##      ##    ',0ah,0dh
dw ' #           #        # #         # #         ##      ##    ',0ah,0dh
dw ' #           #        # #         # #         ##      ##    ',0ah,0dh
dw ' #           #        # #         # #         ##      ##    ',0ah,0dh
dw ' ########### #        # ########### #         ##      ##    ',0ah,0dh
dw '$',0ah,0dh


str_menuInst dw '  ',0ah,0dh
dw ' ',0ah,0dh
dw '      ---------------------------------------------------------------',0ah,0dh
dw '     |                                                               |',0ah,0dh                                        
dw '     |                      CHOPIT - INSTRUCOES                      |',0ah,0dh
dw '     |                                                               |',0ah,0dh
dw '     |---------------------------------------------------------------|',0ah,0dh
dw '     |                                                               |',0ah,0dh          
dw '     |     Use as teclas:           ^                                |',0ah,0dh        
dw '     |                              |                                |',0ah,0dh
dw '     |                            <- ->                              |',0ah,0dh  
dw '     |                              |                                |',0ah,0dh
dw '     |                              v                                |',0ah,0dh 
dw '     |                                                               |',0ah,0dh
dw '     | *Objetivo: Pegue as moscas e leve o sapo ao local seguro,que  |',0ah,0dh
dw '     |                      corresponde a soma correta.              |',0ah,0dh
dw '     |                                                               |',0ah,0dh
dw '     |                   Pressione ENTER para jogar                  |',0ah,0dh
dw '      --------------------------------------------------------------- ',0ah,0dh
dw '$',0ah,0dh

                                                                    
game_over_str dw '  ',0ah,0dh  
dw '                 _______________________________________ ',0ah,0dh
dw '                |                                       |',0ah,0dh
dw '                |   Voce Perdeu!! Chopit Morreu  :<     |',0ah,0dh
dw '                |---------------------------------------|',0ah,0dh
dw '                |  * * * * * * * * * * * * * * * * * *  |',0ah,0dh
dw '                |_______________________________________|',0ah,0dh
dw '                                                         ',0ah,0dh 
dw '                                                         $',0ah,0dh 

parabens_str dw '  ',0ah,0dh  
dw '                 _______________________________________ ',0ah,0dh
dw '                |                                       |',0ah,0dh
dw '                |   Parabens!! Voce salvou Chopit :>    |',0ah,0dh
dw '                |---------------------------------------|',0ah,0dh
dw '                |  *       Moscas: 18 pontos          * |',0ah,0dh
dw '                |_______________________________________|',0ah,0dh
dw '                                                         ',0ah,0dh 
dw '                                                         $',0ah,0dh

COD ENDS
          

;-----------------------------------------------------------------------------
;                              GAME OVER/ VITORIA                            -
;-----------------------------------------------------------------------------  

;Perdeu
prc_gameOver PROC 
PUSHA
;mcr_tocasom 2500d 10000d
POPA 
   
PUSHA
;mcr_tocasom 4000d 12000d
POPA 
  
PUSHA
;mcr_tocasom 6000d 15000d
POPA 
  
PUSHA
;mcr_tocasom 10000d 20000d
POPA                               

mcr_limpaTela
    
MOV AH,09h
MOV DH,00h
LEA DX, game_over_str
INT 21h
  
lb_enter2:
    MOV AH,01h
    INT 21h
    CMP AL,0Dh
    JNE lb_enter2    
    
RET
prc_gameOver ENDP

;Ganhou
prc_parabens PROC    
PUSHA
mcr_limpatela
POPA
    
PUSHA
;mcr_tocasom 3619d 10000d
POPA 
   
PUSHA
;mcr_tocasom 4560d 12000d
POPA 
   
PUSHA
;mcr_tocasom 3043d 15000d
POPA 
   
PUSHA
; mcr_tocasom 2873d 20000d
POPA                  
    
PUSHA
;mcr_tocasom 5423d 10000d
POPA 
    
PUSHA
;mcr_tocasom 3416d 12000d
POPA 
   
PUSHA
;mcr_tocasom 3224d 15000d
POPA 
    
MOV AH,09h
MOV DH,00h
LEA DX, parabens_str
INT 21h

lb_enter3:
    MOV AH,01h
    INT 21h
    CMP AL,0Dh
    JNE lb_enter3 
    
RET
prc_parabens ENDP 


;-----------------------------------------------------------------------------
;                                        MOSCAS                              -
;----------------------------------------------------------------------------- 

;Ecreve moscas na tela
prc_print_moscas PROC
MOV cor_fundo,0Fh 
            
PUSHA
mcr_dc pos_moedas_x[SI] pos_moedas_y[SI] 2Ah cor_fundo 01h 
POPA 

RET     
prc_print_moscas ENDP

;Verifica colisao com mosca
prc_moscas PROC 
    
    MOV AL,pos_x
    CMP pos_moedas_x[SI], AL
    JE lb_posym
    JMP lb_desenha
lb_posym:
     MOV AL,pos_y
    CMP pos_moedas_y[SI], AL
    JE lb_contm
    JMP lb_desenha
lb_contm:
    INC MOSCAS    
    MOV pos_moedas_y[SI],-01d    
    mrc_moscas  
lb_desenha:
  
        
RET    
prc_moscas ENDP

;Escreve mosca no menu inferior
prc_escrever_mosca PROC
mcr_dc 18h 06h ' ' 0FH 01h
mcr_dc 18h 07h 'M' 0FH 01h    
mcr_dc 18h 08h 'o' 0FH 01h
mcr_dc 18h 09h 's' 0FH 01h
mcr_dc 18h 0Ah 'c' 0FH 01h
mcr_dc 18h 0Bh 'a' 0FH 01h  
mcr_dc 18h 0Ch 's' 0FH 01h 
mcr_dc 18h 0Dh ':' 0FH 01h    

RET
prc_escrever_mosca ENDP


;-----------------------------------------------------------------------------
;                                     CARROS                                 -
;-----------------------------------------------------------------------------

;Cria carros nas posicoes dos vetores                                                                          
prc_carro PROC 

    MOV AL,pos_carros_y[SI]
    PUSHA       
    mcr_dc pos_carros_x[SI] AL 0B2h 07h 3h 
    POPA
    INC AL                      
    PUSHA
    mcr_dc pos_carros_x[SI] AL 0B2h 03h 3h 
    
   ; call prc_delay
    
    POPA
    MOV pos_carros_y[SI],AL
   
    CMP pos_carros_y[SI],4Dh
    JE lb_ajuste 
    
    JMP lb_fim_prc_carro        

lb_ajuste: 
    
    PUSHA
    mcr_dc pos_carros_x[SI] pos_carros_y[SI] 0B2h 07h 3h
    POPA     
    MOV pos_carros_y[SI],00h 
   

lb_fim_prc_carro:        
    RET 
    
prc_carro ENDP


;Colisao do personagem com o carro
prc_colisao PROC    
   
MOV AL,pos_carros_y[SI]
CMP pos_y,AL
JE estay
  
INC AL
 
CMP pos_y,AL
JE estay
    
INC AL
  
CMP pos_y,AL
JE estay
  
INC AL
   
CMP pos_y,AL
JE estay
    
    
JMP prc_colisao_fim
   
estay:
    MOV AL,pos_carros_x[SI]
    CMP pos_x,AL
    JE vem
    JMP prc_colisao_fim
   
vem:
    mcr_vida     
prc_colisao_fim:    
    RET
prc_colisao ENDP
                
;-----------------------------------------------------------------------------
;                                       PISO (FUNDO)                         -
;----------------------------------------------------------------------------- 

;Cria fundo de madeira
prc_fundo_madeira PROC NEAR 

MOV AL,12h

lb_limpar:
    MOV AH,00h 
    MOV cor_fundo,0Ah

lb_print:   
    PUSHA
    mcr_dc AH AL caracter_fundo cor_fundo 05h 
    POPA 

    MOV cor_fundo,06h 

    INC AH
    CMP AH,07h
JBE lb_print
             
    ADD AL,10H 
    CMP AL,50h
    JBE lb_limpar

    RET    
prc_fundo_madeira ENDP

;Cria outros fundos
prc_fundo PROC NEAR 

MOV qntdBlocos,80D
MOV cor_fundo,0Ah
 
MOV AH,00h
MOV BL, 01h

lb_limpa: 
MOV AL,00h 

PUSHA
mcr_dc AH AL caracter_fundo cor_fundo qntdBlocos 
POPA    

CMP AH,06h
JBE CASO1

CMP AH,07h
JE  CASO2

CMP AH,16h 
JBE CASO3

CMP AH,17h
JE  CASO2   
 
JMP CASO4   
     
CASO1:
    INC AH      
    MOV cor_fundo,01h  
    JMP lb_limpa 
      
CASO2:
    INC AH      
    MOV cor_fundo,0Fh  
    JMP lb_limpa 
    
CASO3:
    INC AH      
    MOV cor_fundo,07h  
    JMP lb_limpa  

CASO4:  
    MOV AH,10h
    MOV AL,04h
    MOV CX,02d
    MOV cor_fundo,0Eh  
    MOV qntdBlocos,20h 
lb_faixa:
    PUSHA
    mcr_dc AH AL caracter_fundo cor_fundo qntdBlocos 
    POPA 
    
    ADD AL,27h
    LOOP lb_faixa

CASO5:  
    PUSHA
    CALL prc_vida
    POPA    
   
    JMP DEFAULT 

DEFAULT:
    JMP RESUME             
    
RESUME:   

RET   
prc_fundo ENDP  

;-----------------------------------------------------------------------------
;                                   VERIFICACAO DE PISO                      -
;----------------------------------------------------------------------------- 

;Horizontal
prc_piso_horizontal PROC

CMP pos_x,08h  
JE lb_branco1
CMP pos_x,10h
JE lb_ver1
JMP lb_cinza1     

lb_ver1:
    CMP pos_y,04h
    JB lb_cinza1
    CMP pos_y,4Ah
    JA lb_cinza1
    CMP pos_y,23h
    JA lb_verf    
    JMP lb_amarelo1 
    
lb_verf1:
    CMP pos_y,2Bh
    JB lb_cinza1
    JMP lb_amarelo1

lb_branco1:
    MOV cor_piso,0Fh
    JMP lb_fim_piso1 
    
lb_cinza1:
    MOV cor_piso,07h
    JMP lb_fim_piso1
lb_amarelo1:
    MOV cor_piso,0Eh
    JMP lb_fim_piso1     

lb_fim_piso1:

RET
    
prc_piso_horizontal ENDP


;Vertical
prc_piso PROC
    
CMP pos_x,00h
JE lb_verde 
CMP pos_x,08h
JB lb_marrom
CMP pos_x,08h  
JE lb_branco
CMP pos_x,10h
JE lb_ver
CMP pos_x,17h
JBE lb_cinza 
CMP pos_x,18h
JE lb_branco 
     
lb_ver:
    CMP pos_y,04h
    JB lb_cinza
    CMP pos_y,4Ah
    JA lb_cinza
    CMP pos_y,23h
    JA lb_verf    
    JMP lb_amarelo
    
lb_verf:
    CMP pos_y,2Bh
    JB lb_cinza
    JMP lb_amarelo 

lb_verde:
    MOV cor_piso,0Ah
    JMP lb_fim_piso

lb_branco:
    MOV cor_piso,0Fh
    JMP lb_fim_piso 
    
lb_cinza:
    MOV cor_piso,07h
    JMP lb_fim_piso 
lb_marrom:
    MOV cor_piso,06h
    JMP lb_fim_piso
lb_amarelo:
    MOV cor_piso,0Eh
    JMP lb_fim_piso     

lb_fim_piso:

RET    
prc_piso ENDP

;-----------------------------------------------------------------------------
;                                       VIDA                                 -
;----------------------------------------------------------------------------- 
prc_vida PROC    
    MOV BL,0CH 
    MOV DI,01h
    MOV DL,00h 
    MOV CL,03h
    
    lb_repeticaol: 
    PUSHA
    mcr_dc 18h DL 0B2H 0FH 01h
    POPA          
    inc DL
    LOOP lb_repeticaol 
    
    MOV CL,vida
    MOV DL,00h  
    MOV DI,01h
lb_repeticao:  
    MOV AL,coracao[DI] 
    INC DI
    PUSHA
    mcr_dc 18h DL AL BL 01h
    POPA 
    INC DL
    LOOP lb_repeticao     

RET
prc_vida ENDP 

;-----------------------------------------------------------------------------
;                                       NIVEL                                -
;----------------------------------------------------------------------------- 
prc_escrever_nivel PROC
    
    mcr_dc 18h 14h ' ' 0FH 01h
    mcr_dc 18h 15h 'N' 0FH 01h    
    mcr_dc 18h 16h 'i' 0FH 01h
    mcr_dc 18h 17h 'v' 0FH 01h
    mcr_dc 18h 18h 'e' 0FH 01h
    mcr_dc 18h 19h 'l' 0FH 01h 
    mcr_dc 18h 1Ah ':' 0FH 01h
    mcr_dc 18h 1Ch ' ' 0FH 01h 
    mcr_dc 18h 1Dh ' ' 0FH 01h
    mcr_dc 18h 1Eh ' ' 0FH 01h
    mcr_dc 18h 1Fh ' ' 0FH 01h     

RET
prc_escrever_nivel ENDP    


prc_gera_nivel PROC

mcr_aleatorio 1h 0Ah

MOV AL,NVP

CMP DL,02h
JBE N1P 
CMP DL,04h
JBE N2P
CMP DL,06h
JBE N3P
CMP DL,08h
JBE N4P
CMP DL,0Ah
JBE N5P

N1P:
CMP AL,1h
JE lb_nvA1
CMP AL,2h
JE lb_nvB1
CMP AL,3h
JE lb_nvC1

lb_nvA1:
   mrc_fundo_letra_madeira NA1
   JMP FIM  
lb_nvB1:
   mrc_fundo_letra_madeira NB1
   JMP FIM   
lb_nvC1:
   mrc_fundo_letra_madeira NC1
   JMP FIM 

N2P:

CMP AL,1h
JE lb_nvA2
CMP AL,2h
JE lb_nvB2
CMP AL,3h
JE lb_nvC2

lb_nvA2:
   mrc_fundo_letra_madeira NA2
   JMP FIM   
lb_nvB2:
   mrc_fundo_letra_madeira NB2
   JMP FIM
lb_nvC2:
   mrc_fundo_letra_madeira NC2
   JMP FIM
N3P:
CMP AL,1h
JE lb_nvA3
CMP AL,2h
JE lb_nvB3
CMP AL,3h
JE lb_nvC3

lb_nvA3:
   mrc_fundo_letra_madeira NA3
   JMP FIM   
lb_nvB3:
   mrc_fundo_letra_madeira NB3 
   JMP FIM
lb_nvC3:
   mrc_fundo_letra_madeira NC3
   JMP FIM
N4P:
CMP AL,1h
JE lb_nvA4
CMP AL,2h
JE lb_nvB4
CMP AL,3h
JE lb_nvC4

lb_nvA4:
   mrc_fundo_letra_madeira NA4
   JMP FIM   
lb_nvB4:
   mrc_fundo_letra_madeira NB4
   JMP FIM
lb_nvC4:
   mrc_fundo_letra_madeira NC4
   JMP FIM
N5P:

CMP AL,1h
JE lb_nvA5
CMP AL,2h
JE lb_nvB5
CMP AL,3h
JE lb_nvC5

lb_nvA5:
   mrc_fundo_letra_madeira NA5 
   JMP FIM  
lb_nvB5:
   mrc_fundo_letra_madeira NB5
   JMP FIM
lb_nvC5:
   mrc_fundo_letra_madeira NC5 

FIM:
RET    
prc_gera_nivel ENDP

;-----------------------------------------------------------------------------
;                                       DELAY                                -
;----------------------------------------------------------------------------- 
prc_delay PROC
    
    MOV AX,DELAY_AUX
    MOV DELAY,AX

    decdelay:
    
    DEC DELAY
    JZ  fim_delay

    JMP decdelay    

    fim_delay:
    RET
    
prc_delay ENDP

END MAIN 