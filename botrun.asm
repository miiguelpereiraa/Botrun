STACK SEGMENT PARA STACK
	DB 64 DUP ('STACK')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	; Localização do ficheiro lab.txt
    labltxt	    db	'.\lab.txt', 0

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
	;MONSTERS DW 36,150,1.00,'h',70,40,2.85,'v',100,165,3.25,'v',125,95,3.60,'h',155,130,1.35,'v'
	;Número de monstros 
	NMONSTERS DB 5
	
	;Array de moedas
	COINS DW 38,82,57,37,76,82,76,127,96,52,96,97,102,184,157,212,157,147
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
	
	;Importa dos dados do ficheiro lab.txt
	LEA DX, labltxt
	CALL OPENFILE
	MOV lfhandle, AX
	CALL LOADLAB
	MOV BX, lfhandle
	CALL CLOSEFILE

	;Definição do modo gráfico de 320x200, 256 cores
	MOV AH,00H	;Prepara para definir o modo gráfico
	MOV AL,13H		;Modo gráfico 320x200, 256 cores
	INT 10H			;invoca a interrupção 10h da BIOS

	;Desenhar as paredes
	LEA SI,WALLS			;Array de paredes
	XOR CX,CX				;CX a zero
	MOV CL,NWALLS		;Número de linhas no array de paredes
	CALL DRAWALLS		;Desenhar as paredes
	
	;Desenha as moedas de jogo
	LEA SI,COINS			;Array de paredes
	XOR CX,CX				;CX a zero
	MOV CL,NCOINS		;Número de linhas no array de paredes
	CALL DRAWCOINS
	
	;Desenha o quadrado do robot
	XOR AX,AX					;Coloca AX a 0
	MOV AL,4						;Cor vermelha
	MOV DX,YROBOT			;Valor Y inicial
	MOV CX,XROBOT			;Valor X inicial
	MOV BX,9					;Comprimento
	CALL DRAWSQUARE		;Desenha quadrado
	
DRAW:	
	CALL CHECKEY			;Verifica se foi pressionada uma tecla
	CMP  AL,0
	JE DRAW						;Se não foi pressionada nenhuma tecla, volta a verificar
	
	CMP AL,'q'
	JE EXITGAME
	
	CALL KEYPRESSED		;Toma acção de acordo com tecla pressionada
	
	JE DRAW
	
EXITGAME:	
	MOV AH,00H	;Definir modo texto
	MOV AL,02H
	INT 10H
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
	MOV AX, SI					; Guardar o valor de SI em AX
	CMP AL, lineSize			; Comparar AL com lineSize
	JL LL_5						; Se AL for inferior a lineSize então saltar para LL_2
	PUSH BX						; Guardar o valor de BX
	MOV BX, lfhandle			; Guardar em BX o handle do ficheiro de lab.txt
	CALL READLINE				; Voltar a preenhcer o buffer (lineSize)
	POP BX						; Restaurar o valor de BX
	MOV SI, 00H					; Reiniciar o indice do buffer (lineSize)
	CMP lineSize, 00H			; Comparar lineSize com 0
	JE LL_END					; Se forem iguais então saltar fora
LL_5:
	; Incrementar SI até que SI aponte para o valor depois de 0AH (LF)
	MOV AX, 00H				; Limpar AX
	MOV AL, fileLine[SI]	; Copiar o byte do buffer (fileLine) no indice SI para AX
	INC SI					; Incrementar SI
	; Se AX for diferente de LF (0AH) então voltar a repetir desde LL_5
	CMP AL, 0AH				; Comparar AL com LF (0AH)
	JE LL_1					; Se forem iguals, então saltar para LL_1 (começar a processar uma nova parede)
	JMP	LL_4				; Saltar para LL_5
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

; Toma as acções necessárias, caso uma tecla tenha sido pressionada
; INPUT:
;	- AL - ASCII da tecla pressionada
KEYPRESSED PROC NEAR

	XOR AH,AH

	CMP AL,'i'			;Se foi pressionada a tecla 'i', movimento para cima
	JE GOUP
	CMP AL,'k'		;Se foi pressionada a tecla 'k', movimento para baixo
	JE GODOWN
	CMP AL,'j'			;Se foi pressionada a tecla 'j', movimento para a esquerda
	JE GOLEFT
	CMP AL,'l'			;Se foi pressionada a tecla 'l', movimento para a direita
	JE GORIGHT
	CMP AL,'s'		;Se foi pressionada a tecla 's', guarda screenshot do jogo
	CMP AL,'p'		;Se foi pressionada a tecla 'p', o jogo pára
	RET					;Se não foi pressionada nenhuma tecla válida, sai sem efectuar qualquer acção
	
GOUP:
	;Verificar se há colisão com monstro, parede ou moeda
	CALL ROBOTUP
	
	RET
GODOWN:
	;Verificar se há colisão com monstro, parede ou moeda
	CALL ROBOTDOWN
	
	RET
GOLEFT:
	;Verificar se há colisão com monstro, parede ou moeda
	CALL ROBOTLEFT

	RET
GORIGHT:
	;Verificar se há colisão com monstro, parede ou moeda
	CALL ROBOTRIGHT

	RET
KEYPRESSED ENDP

; Move o robot para cima
ROBOTUP PROC NEAR

	XOR AH,AH					;Garante AH a 0
	;Desenha linha preta horizontal em baixo 
	MOV AL,0						;Cor preta
	MOV DX,YROBOT			;Valor Y inicial
	ADD DX,8						;Y + 8 para eliminar a linha inferior do quadrado
	MOV CX,XROBOT			;Valor X inicial
	MOV BX,9					;Comprimento
	CALL LHORIZONTAL
	
	DEC YROBOT				;Decrementa Y do robot

	;Desenha linha vermelha horizontal em cima
	MOV AL,4						;Cor vermelha
	MOV DX,YROBOT			;Valor Y inicial
	MOV CX,XROBOT			;Valor X inicial
	MOV BX,9					;Comprimento
	CALL LHORIZONTAL
	
	RET
ROBOTUP ENDP

; Move o robot para baixo
ROBOTDOWN PROC NEAR

	XOR AH,AH
	;Desenha linha preta horizontal em cima 
	MOV AL,0						;Cor preta
	MOV DX,YROBOT			;Valor Y inicial
	MOV CX,XROBOT			;Valor X inicial
	MOV BX,9					;Comprimento
	CALL LHORIZONTAL
	
	INC YROBOT				;Incrementa Y do robot
	
	;Desenha linha vermelha horizontal em baixo
	MOV AL,4						;Cor vermelha
	MOV DX,YROBOT			;Valor Y inicial
	ADD DX,8						;Y + 8 para desenhar a linha inferior do quadrado
	MOV CX,XROBOT			;Valor X inicial
	MOV BX,9					;Comprimento
	CALL LHORIZONTAL
	
	RET
ROBOTDOWN ENDP

; Move o robot para a esquerda
ROBOTLEFT PROC NEAR

	XOR AH,AH
	;Desenha linha preta vertical à direita 
	MOV AL,0						;Cor preta
	MOV DX,YROBOT			;Valor Y inicial
	MOV CX,XROBOT			;Valor X inicial
	ADD CX,8						;X + 8 para eliminar a linha da direita do quadrado 
	MOV BX,9					;Comprimento
	CALL LVERTICAL
	
	DEC XROBOT				;Decrementa X do robot
	
	;Desenha linha vermelha vertical à esquerda
	MOV AL,4						;Cor vermelha
	MOV DX,YROBOT			;Valor Y inicial
	MOV CX,XROBOT			;Valor X inicial
	MOV BX,9					;Comprimento
	CALL LVERTICAL
	
	RET
ROBOTLEFT ENDP

; Move o robot para a direita
ROBOTRIGHT PROC NEAR

	XOR AH,AH
	;Desenha linha preta vertical à esquerda
	MOV AL,0						;Cor preta
	MOV DX,YROBOT			;Valor Y inicial
	MOV CX,XROBOT			;Valor X inicial
	MOV BX,9					;Comprimento
	CALL LVERTICAL
	
	INC XROBOT				;Incrementa X do robot
	
	;Desenha linha vermelha vertical à direita
	MOV AL,4						;Cor vermelha
	MOV DX,YROBOT			;Valor Y inicial
	MOV CX,XROBOT			;Valor X inicial
	ADD CX,8						;X + 8 para desenhar a linha da direita do quadrado 
	MOV BX,9					;Comprimento
	CALL LVERTICAL
	
	RET
ROBOTRIGHT ENDP

; Verifica, de forma não bloqueante, se foi pressionada uma tecla do teclado
; OUTPUT:
;	- AL : ASCII da tecla pressionada
CHECKEY PROC NEAR
	XOR AL,AL	;AL a zero - Se uma tecla for pressionada, será onde ficará guardada a mesma
	MOV AH,01	;Permite verificar se existe alguma tecla no buffer do teclado (Significa que uma tecla foi pressionada)
	INT 16H		;Interrução 16h - Keyboard I/O Service
	JZ ENDCK		;Se Zero Flag = 1, buffer vazio (Não foi pressionada nenhuma tecla)
	MOV AH,0	;Coloca ASCII code da tecla pressionada em AL e limpa o buffer do teclado
	INT 16H
	
ENDCK:
	RET

CHECKEY ENDP

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

	MOV AH,BL					;Contador para desenhar as linhas horizontais de preenchimento do quadrado
STARTDS:
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	PUSH BX						;Guarda comprimento
	PUSH AX						;Guarda contador de linhas horizontais na pilha + cor dos pixeis
	CMP AH,0						;Verifica se o quadrado está preenchido
	JE ENDDS
	CALL LHORIZONTAL		;Desenha linha superior do quadrado
	POP AX						;Retira contador de linha horizontais da pilha
	POP BX						;Retira comprimento da pilha
	POP CX						;Retira valor X inicial da pilha
	POP DX						;Retira valor Y inicial da pilha
	INC DX							;Incrementa valor Y
	DEC AH						;Decrementa contador 
	JMP STARTDS

ENDDS:
	POP AX						;Retirar valores desnecessários da pilha
	POP AX
	POP AX
	POP AX
	RET
DRAWSQUARE ENDP

;Desenha as moedas de jogo
;INPUT:
;	- SI: ARRAY de moedas
;	- CX: Número de moedas no array
DRAWCOINS PROC NEAR

STARTDC:
		CMP CX,0			;Verifica se todas as linhas foram desenhadas
		JE ENDDC
		PUSH CX			;Guarda o valor de CX na pilha
		MOV DX,[SI]	;Valor Y inicial
		ADD SI,2			
		MOV CX,[SI]	;Valor X inicial
		ADD SI,2
		PUSH CX			;Guarda valor X inicial na pilha
		PUSH DX			;Guarda valor Y inicial na pilha
		CALL DRAWCIRCLE
		POP DX			;Retira valor Y inicial da pilha
		POP CX			;Retira valor X inicial da pilha
		MOV AL,6			;Define a cor castanha para o quadrado interior da moeda
		ADD DX,2			;Adiciona 2 ao valor Y inicial para quadrado ficar no interior da moeda
		ADD CX,2			;Adiciona 2 ao valor X inicial para quadrado ficar no interior da moeda
		MOV BX,5		;Comprimento do quadrado = 5
		CALL DRAWSQUARE
		POP CX			;Obtém novamente o valor de CX
		DEC CX			;Decrementa o número de moedas a desenhar
		JMP STARTDC
		
ENDDC:
		RET
DRAWCOINS ENDP

;Desenha um circulo de cor amarela 
;INPUT:
;	- DX: Valor Y inicial do quadrado onde o circulo está contido
;	- CX: Valor X inicial do quadrado onde o circulo está contido
DRAWCIRCLE PROC NEAR

	MOV AL,14					;Define a cor dos pixeis amarela
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	ADD CX,3						;Adiciona 3 à coordenada X
	MOV BX,3					;Define o comprimento de 3
	CALL LHORIZONTAL
	POP CX						;Retira o valor X inicial da pilha
	POP DX						;Retira o valor Y inicial da pilha
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	ADD DX,1						;Adiciona 1 à coordenada Y
	ADD CX,2						;Adiciona 2 à coordenada X
	MOV BX,5					;Define o comprimento de 5
	CALL LHORIZONTAL
	POP CX						;Retira o valor X inicial da pilha
	POP DX						;Retira o valor Y inicial da pilha
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	ADD DX,2						;Adiciona 2 à coordenada Y
	ADD CX,1						;Adiciona 1 à coordenada X
	MOV BX,7					;Define o comprimento de 7
	CALL LHORIZONTAL
	POP CX						;Retira o valor X inicial da pilha
	POP DX						;Retira o valor Y inicial da pilha
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	ADD DX,3						;Adiciona 3 à coordenada Y
	MOV BX,9					;Define o comprimento de 9
	CALL LHORIZONTAL
	POP CX						;Retira o valor X inicial da pilha
	POP DX						;Retira o valor Y inicial da pilha
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	ADD DX,4						;Adiciona 4 à coordenada Y
	MOV BX,9					;Define o comprimento de 9
	CALL LHORIZONTAL
	POP CX						;Retira o valor X inicial da pilha
	POP DX						;Retira o valor Y inicial da pilha
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	ADD DX,5						;Adiciona 5 à coordenada Y
	MOV BX,9					;Define o comprimento de 9
	CALL LHORIZONTAL
	POP CX						;Retira o valor X inicial da pilha
	POP DX						;Retira o valor Y inicial da pilha
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	ADD DX,6						;Adiciona 6 à coordenada Y
	ADD CX,1						;Adiciona 1 à coordenada X
	MOV BX,7					;Define o comprimento de 7
	CALL LHORIZONTAL
	POP CX						;Retira o valor X inicial da pilha
	POP DX						;Retira o valor Y inicial da pilha
	PUSH DX						;Guarda valor Y inicial na pilha
	PUSH CX						;Guarda valor X inicial na pilha
	ADD DX,7						;Adiciona 1 à coordenada Y
	ADD CX,2						;Adiciona 2 à coordenada X
	MOV BX,5					;Define o comprimento de 5
	CALL LHORIZONTAL
	POP CX						;Retira o valor X inicial da pilha
	POP DX						;Retira o valor Y inicial da pilha
	ADD DX,8						;Adiciona 1 à coordenada Y
	ADD CX,3						;Adiciona 3 à coordenada X
	MOV BX,3					;Define o comprimento de 3
	CALL LHORIZONTAL
	

DRAWCIRCLE ENDP

;Desenha uma horizontal com ponto inicial (X,Y) e comprimento Z
;INPUT:
;	- AL: Cor dos pixeis a desenhar
;	- DX: Valor Y inicial
;	- CX: Valor X inicial
;	- BL: Comprimento da linha
LHORIZONTAL PROC NEAR
		XOR BH,BH		;Garante BH a zero, para que seja desenhado sempre na primeira display page
STARTLH:	
		CMP BX,0			;Verifica se desenhou a reta completa
		JLE FIMLH
		MOV AH,12		;Função para desenhar um pixel
		INT 10H			;Interrupção 10h da BIOS
		DEC BL			;Decrementa comprimento
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
;	- BL: Comprimento da linha
LVERTICAL PROC NEAR
		XOR BH,BH		;Garante BH a zero, para que seja desenhado sempre na primeira display page
		; INC BL				;Corrige problema com o desenho do pixel inferior direito
STARTLV:
		CMP BX,0			;Verifica se desenhou a reta completa
		JLE FIMLV
		MOV AH,12		;Função para desenhar um pixel
		INT 10H			;Interrupção 10h da BIOS
		DEC BL			;Decrementa comprimento
		INC DX				;Incrementa Y
		JMP STARTLV
	
FIMLV:	
		RET
LVERTICAL ENDP

CODE ENDS

END