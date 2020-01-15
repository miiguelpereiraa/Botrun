STACK SEGMENT PARA STACK
	DB 64 DUP ('STACK')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	; Conteudo File Handle
	cfhandle 	dw 	?

	; Lab File Handle
	lfhandle 	dw	?

	; Buffer de auxilio para a leitura do ficheiro
    fileLine	db  80 dup(' '), '$'
	; Número de bytes usado no buffer
	lineSize	db	0
	
	;######################preenchimento "manual" temporário######################
	;Coordenada Y inicial do robot
	YROBOT DW 94
	;Coordenada X inicial do robot
	XROBOT DW 5
	
	;Coordenada Y da meta
	YEND DW 84	
	;Coordenada X da meta
	XEND DW 225	
	
	;Array de paredes
	WALLS DW 'h',0,0,239,'h',199,0,239,'v',0,0,199,'v',0,239,199,'h',1,0,239,'h',198,0,239,'v',0,1,199,'v',0,238,199,'h',87,30,60,'h',112,30,60
				DW 'h',30,30,190,'h',169,30,210,'h',50,60,80,'h',70,60,60,'v',50,140,40,'v',70,120,42,'v',30,30,57,'v',112,30,57,'h',142,60,60,'h',79,140,40
				DW 'h',112,120,40,'v',112,160,57,'h',127,180,40,'v',30,180,97,'h',99,200,39,'v',69,200,30,'v',30,220,39,'v',0,120,15,'v',15,160,15,'h',0,0,0
				DW 'h',88,30,60,'h',113,30,60,'h',31,30,190,'h',170,30,210,'h',51,60,80,'h',71,60,60,'v',50,141,40,'v',70,121,42,'v',30,31,57,'v',112,31,57
				DW 'h',143,60,60,'h',80,140,40,'h',113,120,40,'v',112,161,57,'h',128,180,40,'v',30,181,97,'h',100,200,39,'v',69,201,30,'v',30,221,39,'v',0,121,15,'v',15,161,15
	;Número de linhas presente do array walls
	NWALLS DB 51
	
	;Array de monstros
	;MONSTERS DW 'm',36,150,1.00,'h','m',70,40,2.85,'v','m',100,165,3.25,'v','m',125,95,3.60,'h','m',155,130,1.35,'v'
	;Número de monstros 
	NMONSTERS DB 5
	
	;Array de moedas
	COINS DW '$',38,82,'$',57,37,'$',76,82,'$',76,127,'$',96,52,'$',96,97,'$',102,184,'$',157,212,'$',157,147
	;Número de moedas
	NCOINS DB 9


DATA ENDS

CODE SEGMENT PARA 'CODE'

MAIN PROC FAR
	; Inicialização
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
	PUSH DS
	SUB AX, AX
	PUSH AX
	MOV AX, DATA
	MOV DS, AX
	MOV ES, AX
	
	;Definição do modo gráfico de 320x200, 256 cores
	MOV AH,00H	;Prepara para definir o modo gráfico
	MOV AL,13H		;Modo gráfico 320x200, 256 cores
	INT 10H			;invoca a interrupção 10h da BIOS

	;Desenhar as paredes
	LEA SI,WALLS			;Array de paredes
	XOR CX,CX				;CX a zero
	MOV CL,NWALLS		;Número de linhas no array de paredes
	CALL DRAWALLS		;Desenhar as paredes
	
	XOR AX,AX					;Coloca AX a 0
	MOV AL,4						;Cor vermelha
	MOV DX,YROBOT			;Valor Y inicial
	MOV CX,XROBOT			;Valor X inicial
	MOV BX,9					;Comprimento
	CALL DRAWSQUARE		;Desenha quadrado
	
	; MOV AH,00H	;Definir modo texto
	; MOV AL,02H
	; INT 10H
	
	; Retornar a execução para o SO
	RET
MAIN ENDP	

; Abre um determinado ficheiro
; INPUT: 
;		- DX: Ficheiro a abrir
; OUTPUT:
;		- AX: Handle do ficheiro
OPENFILE PROC NEAR
	MOV AH, 3DH			; Ler do ficheiro
	MOV AL, 00h			; Modo de leitura
	INT 21H

    RET
OPENFILE ENDP

; Carrega o labirinto do ficheiro para a memória
LOADLAB PROC NEAR
LOADLAB ENDP

; Carrega o conteudo do ficheiro para a memória
LOADCONT PROC NEAR
LOADCONT ENDP

; Fecha um determinado ficheiro
; INPUT:
;		- BX: Handle do ficheiro
CLOSEFILE PROC NEAR
    MOV AH, 3EH         ; Fechar o ficheiro
    INT 21H

	RET
CLOSEFILE ENDP

;Desenha as paredes de jogo
;INPUT:
;	- SI: ARRAY de paredes
;	- CX: Número de linhas no array
DRAWALLS PROC NEAR

STARTDW:
		CMP CX,0			;Verifica se todas as linhas foram desenhadas
		JE ENDDW
		MOV DX,[SI]		;Letra para verificação da orientação da linha (Horizontal/Vertical)
		CMP DX,'h'		;Verifica se é para desenhar uma linha horizontal
		JE LH
		PUSH CX			;Guarda o valor de CX na pilha
		ADD SI,2			;Avança posição do ponteiro
		MOV AL,1			;Cor azul
		MOV DX,[SI]	;Valor Y inicial
		ADD SI,2			
		MOV CX,[SI]	;Valor X inicial
		ADD SI,2
		MOV BX,[SI]		;Comprimento da linha
		ADD SI,2
		CALL LVERTICAL
		POP CX			;Obtém novamente o valor de CX
		DEC CX
		JMP STARTDW
		
		
	LH:						;Desenhar linha horizontal
		PUSH CX			;Guarda o valor de CX na pilha
		ADD SI,2			;Avança posição do ponteiro
		MOV AL,1			;Cor azul
		MOV DX,[SI]	;Valor Y inicial
		ADD SI,2			
		MOV CX,[SI]	;Valor X inicial
		ADD SI,2
		MOV BX,[SI]		;Comprimento da linha
		ADD SI,2
		CALL LHORIZONTAL
		POP CX			;Obtém novamente o valor de CX
		DEC CX
		JMP STARTDW
		
ENDDW:
		RET
DRAWALLS ENDP

;Desenha um quadrado
;INPUT:
;	- AL: Cor dos pixeis a desenhar
;	- DX: Valor Y inicial
;	- CX: Valor X inicial
;	- BX: Comprimento da linha
DRAWSQUARE PROC NEAR

	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	PUSH BX						;Guarda comprimento
	CALL LHORIZONTAL		;Desenha linha superior do quadrado
	POP BX						;Retira comprimento da pilha
	POP CX						;Retira valor X inicial da pilha
	PUSH CX						;Guarda valor X inicial na pilha
	PUSH BX						;Guarda comprimento na pilha
	CALL LVERTICAL			;Desenha linha da esquerda do quadrado
	POP BX						;Retira comprimento da pilha
	POP CX						;Retira valor X inicial da pilha
	POP DX						;Retira valor Y inicial da pilha
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	PUSH BX						;Guarda comprimento
	ADD CX,9						;Adiciona 9 ao valor X
	CALL LVERTICAL			;Desenha linha da direita do quadrado
	POP BX						;Retira comprimento da pilha
	POP CX						;Retira valor X inicial da pilha
	POP DX						;Retira valor Y inicial da pilha
	ADD DX,9						;Aciciona 9 ao valor Y
	CALL LHORIZONTAL
	
DRAWSQUARE ENDP

;Desenha uma horizontal com ponto inicial (X,Y) e comprimento Z
;INPUT:
;	- AL: Cor dos pixeis a desenhar
;	- DX: Valor Y inicial
;	- CX: Valor X inicial
;	- BX: Comprimento da linha
LHORIZONTAL PROC NEAR

STARTLH:	
		CMP BX,0			;Verifica se desenhou a reta completa
		JLE FIMLH
		MOV AH,12		;Função para desenhar um pixel
		INT 10H			;Interrupção 10h da BIOS
		DEC BX			;Decrementa comprimento
		INC CX				;Incrementa X
		JMP STARTLH
FIMLH:			
		RET
LHORIZONTAL ENDP

;Desenha uma vertical com ponto inicial (X,Y) e comprimento Z
;INPUT:
;	- AL: Cor dos pixeis a desenhar
;	- DX: Valor Y inicial
;	- CX: Valor X inicial
;	- BX: Comprimento da linha
LVERTICAL PROC NEAR
		INC BX				;Corrige problema com o desenho do pixel inferior direito dos quadrados
STARTLV:
		CMP BX,0			;Verifica se desenhou a reta completa
		JLE FIMLV
		MOV AH,12		;Função para desenhar um pixel
		INT 10H			;Interrupção 10h da BIOS
		DEC BX			;Decrementa comprimento
		INC DX				;Incrementa Y
		JMP STARTLV
	
FIMLV:	
		RET
LVERTICAL ENDP

CODE ENDS

END