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
	YROBOT 		DW 	94
	;Coordenada X inicial do robot
	XROBOT 		DW 	5
	
	;Coordenada Y da meta
	YEND 		DW 	84	
	;Coordenada X da meta
	XEND 		DW 	225	
	
	;Array de paredes
	WALLS 		DW 	400 dup(' ')
	;Número de linhas presente do array walls
	NWALLS 		DB 	0
	
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

; Lê 80 bytes de um ficheiro para o buffer
; INPUT:
;		- BX: Handle do ficheiro
; OUTPUT:
;		- fileLine: Buffer para onde se escreveu o contúdo lido do ficheiro
;		- lineSize: Número de bytes lidos
READLINE PROC NEAR
    MOV AH, 3FH	        ; Operação de leitura do ficheiro
    MOV CX, 80          ; Indicar que é para ler 80 bytes
    LEA DX, fileLine  	; Indicar o buffer de destino
    INT 21h

	MOV lineSize, AL	; Guardar o número de bytes lidos

	RET
READLINE ENDP

; Processa 3 caracteres e converte-os para número
; INPUT:
;		- SI: Indice do fileLine onde se encontra o número
;		- fileLine: Do qual buffer ler o número
;		- lineSize: Tamanho do buffer
;		- lfhandle: Handle do ficheiro lab.txt
; OUTPUT:
;		- AX: Número convertido
;		- SI: Ultimo indice utilizado +1
PROCESSNUMBER PROC NEAR
	MOV AX, 00H				; AX é utilizado como acumulador
	MOV CX, 03H				; CX indica o número de caracteres processados

PN_1:
	; Verificar se o buffer foi totalmente lido (se SI >= lineSize então todo o buffer foi lido)
	; e se foi lido então voltar a ler mais 80 bytes do ficheiro e reiniciar o indice de leitura (SI)
	PUSH AX					; Guardar o valor de AX
	MOV AX, SI				; Guardar o valor de SI em AX
	CMP AL, lineSize		; Comparar AL com lineSize
	JL PN_2					; Se AL for inferior a lineSize então saltar para PN_2
	PUSH CX					; Guardar o valor de CX
	MOV BX, lfhandle		; Guardar em BX o handle do ficheiro de lab.txt
	CALL READLINE			; Voltar a preenhcer o buffer (lineSize)
	POP CX					; Restaurar o valor de CX
	MOV SI, 00H				; Reiniciar o indice do buffer (lineSize)
PN_2:
	POP AX					; Restaurar o valor de AX
	MOV DX, 00H				; Limpar DX
	MOV DL, fileLine[SI]	; Ler do buffer para DL
	; Se DL for espaço (20H) ou CR (0Dh) então sair do procedimento
	CMP DL, 20H				; Comparar DL com espaço (20H)
	JE PN_END				; Se DL for igual ao espaço (20H) então saltar fora
	CMP DL, 0DH				; Comparar DL com CR (0DH)
	JE PN_END				; Se DL for igual ao CR (0DH) então saltar fora
	INC SI					; Incrementar SI
	SUB DL, 30H				; Subtrair 30H de DL para obter o valor real
	PUSH DX					; Guardar o valor real na stack (porque MUL utiliza o DX)
	MOV BX, 0AH				; Guardar 10 (em decimal) em BX
	MUL BX					; Multiplicar AX por BX (multiplicar AX por 10)
	POP DX					; Restaurar o valor de DX
	ADD AX, DX				; Somar DX ao AX (operação completa: AX = AX * 10 + DX)
	LOOP PN_1				; Voltar a processar outro digito caso necessário
PN_END:
	RET
PROCESSNUMBER ENDP

; Carrega o labirinto do ficheiro para a memória
LOADLAB PROC NEAR
	MOV BX, lfhandle			; Guardar o handle do ficheiro de lab.txt em BX
	CALL READLINE				; Preenhcer o buffer (fileLine) com o conteúdo do ficheiro lab.txt
	MOV BX, 00H					; Limpar o valor de BX, BX é usado como indice para o array de WALLS
	MOV SI, 00H					; Limpar o valor de SI, SI é usado como indice para o buffer (fileLine)
LL_1:
	; Verificar se o buffer foi totalmente lido (se SI >= lineSize então todo o buffer foi lido)
	; e se foi lido então voltar a ler mais 80 bytes do ficheiro e reiniciar o indice de leitura (SI).
	; Se lineSize for igual a zero significa que n há mais conteudo para ler do ficheir lab.txt então
	; é necessário sair do procedimento
	MOV AX, SI					; Guardar o valor de SI em AX
	CMP AL, lineSize			; Comparar AL com lineSize
	JL LL_2						; Se AL for inferior a lineSize então saltar para LL_2
	PUSH BX						; Guardar o valor de BX
	MOV BX, lfhandle			; Guardar em BX o handle do ficheiro de lab.txt
	CALL READLINE				; Voltar a preenhcer o buffer (lineSize)
	POP BX						; Restaurar o valor de BX
	MOV SI, 00H					; Reiniciar o indice do buffer (lineSize)
	CMP lineSize, 00H			; Comparar lineSize com 0
	JE LL_END					; Se forem iguais então saltar fora
LL_2:
	INC NWALLS					; Incrementar o NWALLS
	MOV AX, 00H					; Limpar AX
	MOV AL, fileLine[SI]		; Copiar um byte para AX
	INC SI						; Incrementar o indice do buffer 2x para colocar o indice
	INC SI						; a apontar para um número do buffer (fileLine)
	MOV WALLS[BX], AX			; Mover o byte do AX para o array WALLS (o valor que indica se a parede é vertical ou horizontal)
	ADD BX, 02H					; Avançar com o indice BX em dois bytes
	MOV CX, 03H					; Mover 03H para CX (porque são 3 números a processar por parede: linha, coluna e o tamanho)
LL_3:
	PUSH BX						; Guardar o valor de BX
	PUSH CX						; Guardar o valor de CX
	CALL PROCESSNUMBER			; Processar um número do buffer (fileLine)
	POP CX						; Restaurar o valor de CX
	POP BX						; Restaurar o valor de BX
	MOV WALLS[BX], AX			; Guardar o número processado no array WALLS
	ADD BX, 02H					; Anvaçar com o indice BX em dois bytes
	INC SI						; Incrementar SI
	LOOP LL_3					; Processar mais números caso haja
LL_4:
	; Verificar se o buffer foi totalmente lido (se SI >= lineSize então todo o buffer foi lido)
	; e se foi lido então voltar a ler mais 80 bytes do ficheiro e reiniciar o indice de leitura (SI).
	; Se lineSize for igual a zero significa que n há mais conteudo para ler do ficheir lab.txt então
	; é necessário sair do procedimento
	MOV AX, SI
	CMP AL, lineSize
	JL LL_5
	PUSH BX
	MOV BX, lfhandle
	CALL READLINE
	POP BX
	MOV SI, 00H
	CMP lineSize, 00H
	JE LL_END
LL_5:
	MOV AX, 00H
	MOV AL, fileLine[SI]
	INC SI
	CMP AL, 0AH
	JE LL_1
	JMP	LL_4
LL_END:
	RET
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
	CALL LVERTICAL			;Desenha linha vertical da esquerda
	POP BX						;Retira comprimento da pilha
	POP CX						;Retira valor X inicial da pilha
	POP DX						;Retira valor Y inicial da pilha
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	PUSH BX						;Guarda comprimento
	ADD CX,9						;Adiciona 9 ao valor X
	CALL LVERTICAL			;Desenha linha vertical da direita
	POP BX						;Retira comprimento da pilha
	POP CX						;Retira valor X inicial da pilha
	POP DX						;Retira valor Y inicial da pilha
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	PUSH BX						;Guarda comprimento
	MOV AH,BL					;Contador para desenhar as linhas horizontais de preenchimento do quadrado = comprimento + 1
	INC AH							;Incrementa AH para desenhar a última linha do quadrado
STARTDS:
	PUSH AX						;Guarda contador de linhas horizontais na pilha
	CMP AH,0						;Verifica se o quadrado está preenchido
	JE ENDDS
	CALL LHORIZONTAL		;Desenha linha superior do quadrado
	POP AX						;Retira contador de linha horizontais da pilha
	POP BX						;Retira comprimento da pilha
	POP CX						;Retira valor X inicial da pilha
	POP DX						;Retira valor Y inicial da pilha
	INC DX							;Incrementa valor Y
	DEC AH						;Decrementa contador 
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	PUSH BX						;Guarda comprimento na pilha
	JMP STARTDS

ENDDS:
	POP AX						;Retirar valores desnecessários da pilha
	POP AX
	POP AX
	POP AX
	RET
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