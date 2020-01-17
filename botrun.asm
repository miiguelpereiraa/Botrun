STACK SEGMENT PARA STACK
	DB 64 DUP ('STACK')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	; Localização do ficheiro lab.txt
    labltxt	    db	'.\lab.txt', 0

	; Localização do ficheiro conteudo.txt
	conttxt		db	'.\conteudo.txt', 0

	; Conteudo File Handle
	cfhandle 	dw 	?

	; Lab File Handle
	lfhandle 	dw	?

	; Buffer de auxilio para a leitura do ficheiro
    fileLine	db  80 dup(' '), '$'
	; Número de bytes usado no buffer
	lineSize	db	0
	
	;Coordenada Y inicial do robot
	YROBOT 		DW 	0
	;Coordenada X inicial do robot
	XROBOT 		DW 	0
	
	;Coordenada Y da meta
	YEXIT 		DW 	0	
	;Coordenada X da meta
	XEXIT 		DW 	0	
	
	;Array de paredes
	WALLS 		DW 	400 dup(' ')
	;Número de linhas presente do array walls
	NWALLS 		DB 	0
	
	;Array de monstros
	MONSTERS 	DW 	50 DUP(0)
	;Número de monstros 
	NMONSTERS 	DB 	0
	
	;Array de moedas
	COINS 	DW 	20 dup(0)
	;Número de moedas
	NCOINS 	DB 	0
	
	;Score do jogador
	SCORE DB 0
	
	;Variáveis auxiliares
	INFO1 DB "BotRun$"
	INFO2 DB "Controls$"
	INFO3 DB "i - up$"
	INFO4 DB "k - down$"
	INFO5 DB "j - left$"
	INFO6 DB "l - right$"
	INFO7 DB "SCORE$"


DATA ENDS

CODE SEGMENT PARA 'CODE'

MAIN PROC FAR
	; Inicialização
	ASSUME CS:CODE, DS:DATA, SS:STACK, ES:DATA
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

	;Importa dos dados do ficheiro conteudo.txt
	LEA DX, conttxt
	CALL OPENFILE
	MOV cfhandle, AX
	CALL LOADCONT
	MOV BX, cfhandle
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
	
	;Desenhar os monstros
	LEA SI,MONSTERS	;Array de monstros
	XOR CX,CX				;CX a zero
	MOV CL,NMONSTERS	;Número de monstros no array
	CALL DRAWMONSTERS		;Desenhar os monstros
	
	;Desenha as moedas de jogo
	LEA SI,COINS			;Array de paredes
	XOR CX,CX				;CX a zero
	MOV CL,NCOINS		;Número de linhas no array de paredes
	CALL DRAWCOINS
	
	;Desenha o quadrado da meta
	XOR AX,AX					;Coloca AX a 0
	MOV AL,2						;Cor verde
	MOV DX,YEXIT			;Valor Y inicial
	MOV CX,XEXIT			;Valor X inicial
	MOV BX,9					;Comprimento
	CALL DRAWSQUARE		;Desenha quadrado
	
	;Desenha o quadrado do robot
	XOR AX,AX					;Coloca AX a 0
	MOV AL,5						;Cor magenta
	MOV DX,YROBOT			;Valor Y inicial
	MOV CX,XROBOT			;Valor X inicial
	MOV BX,9					;Comprimento
	CALL DRAWSQUARE		;Desenha quadrado
	
	CALL DISPLAYINFO
	
RECHECK:	
	CALL CHECKEY			;Verifica se foi pressionada uma tecla
	CMP  AL,0
	JE RECHECK						;Se não foi pressionada nenhuma tecla, volta a verificar
	CMP AL,'q'					;Se foi pressionado q, sai do jogo
	JE EXITGAME
	
	CALL KEYPRESSED		;Toma acção de acordo com tecla pressionada
	CMP BL,99
	JE WAITEXIT
	JMP RECHECK					;Verifica novamente se alguma tecla foi pressionada

WAITEXIT:
	CALL CHECKEY
	CMP AL,'q'
	JNE WAITEXIT
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
	CMP DL, 2EH				; Comparar DL com . (2EH)
	JE PN_END				; Se DL for igual ao . (2EH) então saltar fora
	CMP DL, 0DH				; Comparar DL com CR (0DH)
	JE PN_END				; Se DL for igual ao CR (0DH) então saltar fora
	INC SI					; Incrementar SI
	SUB DL, 30H				; Subtrair 30H de DL para obter o valor real
	PUSH BX
	PUSH DX					; Guardar o valor real na stack (porque MUL utiliza o DX)
	MOV BX, 0AH				; Guardar 10 (em decimal) em BX
	MUL BX					; Multiplicar AX por BX (multiplicar AX por 10)
	POP DX					; Restaurar o valor de DX
	POP BX
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
	MOV BX, lfhandle
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

; Inicializa YROBOT e XROBOT com os dados do fileLine
; INOUT:
;		- fileLine: Buffer de onde importar os dados
;		- SI: Indice para o buffer
; OUTPUT:
; 		- YROBOT: Coordenada Y
;		- XROBOT: Coordenada X
PROCESSPLAYER PROC NEAR
	INC SI						; Avançar com SI para o primeiro digito da coordenada Y
	INC SI
	; Processar a coordenada Y e guardar em YROBOT
	MOV BX, cfhandle
	CALL PROCESSNUMBER
	MOV YROBOT, AX

	INC SI						; Avançar com SI para o primeiro digito da coordenada X

	; Processar a coordenada X e guardar em XROBOT
	MOV BX, cfhandle
	CALL PROCESSNUMBER
	MOV XROBOT, AX

	RET
PROCESSPLAYER ENDP

; Inicializa YEXIT e XEXIT com os dados do fileLine
; INOUT:
;		- fileLine: Buffer de onde importar os dados
;		- SI: Indice para o buffer
; OUTPUT:
; 		- YEXIT: Coordenada Y
;		- XEXIT: Coordenada X
PROCESSEXIT PROC NEAR
	INC SI
	INC SI
	MOV BX, cfhandle
	CALL PROCESSNUMBER
	MOV YEXIT, AX
	INC SI
	MOV BX, cfhandle
	CALL PROCESSNUMBER
	MOV XEXIT, AX
	RET
PROCESSEXIT ENDP

; Inicializa as coordenadas X e Y das moedas (com os dados do fileLine) e coloca-as no array de moedas
; INPUT:
;		- fileLine: Buffer de onde importar os dados
;		- SI: Indice para o buffer
; 		- NCOINS: Número de moedas
PROCESSCOIN PROC NEAR
	INC SI
	INC SI
	
	; Definiar a linha da moeda
	MOV BX, cfhandle
	CALL PROCESSNUMBER

	MOV BX, 00H
	MOV BL, NCOINS
	SHL BX, 1
	SHL BX, 1

	MOV COINS[BX + 0], AX
	INC SI

	; Definiar a coluna da moeda
	MOV BX, cfhandle
	CALL PROCESSNUMBER
	
	MOV BX, 00H
	MOV BL, NCOINS
	SHL BX, 1
	SHL BX, 1
	
	MOV COINS[BX + 2], AX

	; Incrementar o número de moedas
	INC NCOINS
	RET
PROCESSCOIN ENDP

PROCESSMONSTER PROC NEAR
	INC SI
	INC SI

	; Definir a linha do monstro
	MOV BX, cfhandle
	CALL PROCESSNUMBER
	
	PUSH AX
	MOV AX, 00H
	MOV AL, NMONSTERS
	MOV BX, 05H
	MUL BX
	MOV BX, AX
	SHL BX, 1
	POP AX
	
	MOV MONSTERS[BX + 0], AX
	INC SI
	
	; Definir a coluna do monstro
	MOV BX, cfhandle
	CALL PROCESSNUMBER
	
	PUSH AX
	MOV AX, 00H
	MOV AL, NMONSTERS
	MOV BX, 05H
	MUL BX
	MOV BX, AX
	SHL BX, 1
	POP AX

	MOV MONSTERS[BX + 2], AX
	INC SI

	MOV BX, cfhandle
	CALL PROCESSNUMBER
	INC SI
	PUSH AX
	MOV BX, cfhandle
	CALL PROCESSNUMBER
	INC SI

	MOV CX, AX
	MOV BX, 64H
	POP AX
	MUL BX
	ADD AX, CX
	
	PUSH AX
	MOV AX, 00H
	MOV AL, NMONSTERS
	MOV BX, 05H
	MUL BX
	MOV BX, AX
	SHL BX, 1
	POP AX

	MOV MONSTERS[BX + 6], AX

	MOV AX, SI					; Guardar o valor de SI em AX
	CMP AL, lineSize			; Comparar AL com lineSize
	JL PM_1						; Se AL for inferior a lineSize então saltar para LL_2
	MOV BX, cfhandle			; Guardar em BX o handle do ficheiro de lab.txt
	CALL READLINE				; Voltar a preenhcer o buffer (lineSize)
	MOV SI, 00H					; Reiniciar o indice do buffer (lineSize)
PM_1:
	MOV AX, 00H
	MOV AL, fileLine[SI]
	INC SI
	
	PUSH AX
	MOV AX, 00H
	MOV AL, NMONSTERS
	MOV BX, 05H
	MUL BX
	MOV BX, AX
	SHL BX, 1
	POP AX

	MOV MONSTERS[BX + 4], AX
	INC NMONSTERS

	RET
PROCESSMONSTER ENDP

; Carrega o conteudo do ficheiro para a memória
LOADCONT PROC NEAR
	MOV BX, cfhandle
	CALL READLINE
	MOV SI, 00H
LC_1:
	MOV AX, SI
	CMP AL, lineSize
	JL LC_2
	MOV BX, cfhandle
	CALL READLINE
	CMP lineSize, 00H
	JE LC_END
LC_2:
	MOV AX, 00H
	MOV AL, fileLine[SI]
	CMP AL, 'r'
	JE PROCESS_PLAYER
	CMP AL, 'f'
	JE PROCESS_EXIT
	CMP AL, '$'
	JE PROCESS_COIN
	CMP AL, 'm'
	JE PROCESS_MONSTER
	JMP END_PROCESS
PROCESS_PLAYER:
	CALL PROCESSPLAYER
	JMP END_PROCESS
PROCESS_EXIT:
	CALL PROCESSEXIT
	JMP END_PROCESS
PROCESS_COIN:
	CALL PROCESSCOIN
	JMP END_PROCESS
PROCESS_MONSTER:
	CALL PROCESSMONSTER
END_PROCESS:
	; Verificar se o buffer foi totalmente lido (se SI >= lineSize então todo o buffer foi lido)
	; e se foi lido então voltar a ler mais 80 bytes do ficheiro e reiniciar o indice de leitura (SI).
	; Se lineSize for igual a zero significa que n há mais conteudo para ler do ficheir lab.txt então
	; é necessário sair do procedimento
	MOV AX, SI					; Guardar o valor de SI em AX
	CMP AL, lineSize			; Comparar AL com lineSize
	JL LC_3						; Se AL for inferior a lineSize então saltar para LL_2
	MOV BX, lfhandle			; Guardar em BX o handle do ficheiro de lab.txt
	CALL READLINE				; Voltar a preenhcer o buffer (lineSize)
	MOV SI, 00H					; Reiniciar o indice do buffer (lineSize)
	CMP lineSize, 00H			; Comparar lineSize com 0
	JE LC_END					; Se forem iguais então saltar fora
LC_3:
	; Incrementar SI até que SI aponte para o valor depois de 0AH (LF)
	MOV AX, 00H				; Limpar AX
	MOV AL, fileLine[SI]	; Copiar o byte do buffer (fileLine) no indice SI para AX
	INC SI					; Incrementar SI
	; Se AX for diferente de LF (0AH) então voltar a repetir desde LL_5
	CMP AL, 0AH				; Comparar AL com LF (0AH)
	JE LC_1					; Se forem iguals, então saltar para LL_1 (começar a processar uma nova parede)
	JMP	END_PROCESS				; Saltar para LL_5
LC_END:
	RET
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

	XOR AH,AH						;Garante AH a 0
	MOV DX,YROBOT				;Obtém o valor Y do robot actual
	MOV CX,XROBOT				;Obtém o valor X do robot actual

	CMP AL,'i'			;Se foi pressionada a tecla 'i', movimento para cima
	JE GOUP
	CMP AL,'k'		;Se foi pressionada a tecla 'k', movimento para baixo
	JE GODOWN
	CMP AL,'j'			;Se foi pressionada a tecla 'j', movimento para a esquerda
	JE GOLEFT
	CMP AL,'l'			;Se foi pressionada a tecla 'l', movimento para a direita
	JE GORIGHT
	CMP AL,'s'		;Se foi pressionada a tecla 's', guarda screenshot do jogo
	JE SCRSHOT
	CMP AL,'p'		;Se foi pressionada a tecla 'p', o jogo pára
	JE STOPGAME
	RET					;Se não foi pressionada nenhuma tecla válida, sai sem efectuar qualquer acção
	
GOUP:
	;Verificar se há colisão com monstro, parede ou moeda
	;Verifica se vai colidir com uma parede
	DEC DX							;Decrementa valor Y para verificação de colisão
	CALL WALLCOLLISION
	CMP BL,1							;Se BL = 1, há colisão, não pode avançar
	JE ENDKP
	
	CALL COLLISIONCOINS

	CALL ROBOTUP
	
	MOV DX,YROBOT				;Obtém o valor Y do robot actual
	MOV CX,XROBOT				;Obtém o valor X do robot actual
	DEC DX
	CALL ENDGAME
	
	
	RET
GODOWN:
	;Verificar se há colisão com monstro, parede ou moeda
	;Verifica se vai colidir com uma parede
	INC DX							;Incrementa valor Y para verificação de colisão
	CALL WALLCOLLISION
	CMP BL,1							;Se BL = 1, há colisão, não pode avançar
	JE ENDKP
	
	CALL COLLISIONCOINS
	
	CALL ROBOTDOWN
	
	MOV DX,YROBOT				;Obtém o valor Y do robot actual
	MOV CX,XROBOT				;Obtém o valor X do robot actual
	INC DX
	CALL ENDGAME
	
	RET
GOLEFT:
	;Verificar se há colisão com monstro, parede ou moeda
	;Verifica se vai colidir com uma parede
	DEC CX							;Decrementa valor X para verificação de colisão
	CALL WALLCOLLISION
	CMP BL,1							;Se BL = 1, há colisão, não pode avançar
	JE ENDKP
	
	CALL COLLISIONCOINS
	
	CALL ROBOTLEFT
	
	MOV DX,YROBOT				;Obtém o valor Y do robot actual
	MOV CX,XROBOT				;Obtém o valor X do robot actual
	DEC CX
	CALL ENDGAME

	RET
GORIGHT:
	;Verificar se há colisão com monstro, parede ou moeda
	;Verifica se vai colidir com uma parede
	INC CX							;Incrementa valor X para verificação de colisão
	CALL WALLCOLLISION
	CMP BL,1							;Se BL = 1, há colisão, não pode avançar
	JE ENDKP
	
	CALL COLLISIONCOINS
	
	CALL ROBOTRIGHT
	
	MOV DX,YROBOT				;Obtém o valor Y do robot actual
	MOV CX,XROBOT				;Obtém o valor X do robot actual
	INC CX	
	CALL ENDGAME
	
	RET
SCRSHOT:
STOPGAME:
	MOV BL,99
ENDKP:
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

	;Desenha linha magenta horizontal em cima
	MOV AL,5						;Cor magenta
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
	
	;Desenha linha magenta horizontal em baixo
	MOV AL,5						;Cor magenta
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
	
	;Desenha linha magenta vertical à esquerda
	MOV AL,5						;Cor magenta
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
	
	;Desenha linha magenta vertical à direita
	MOV AL,5						;Cor magenta
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
	MOV AH,00	;Coloca ASCII code da tecla pressionada em AL e limpa o buffer do teclado
	INT 16H
	
ENDCK:
	RET

CHECKEY ENDP

;Verifica se existe uma colisão do robot com uma parede
; INPUT:
;	- DX: Valor Y do canto superior esquerdo do robot actualizado
;	- CX: Valor X do canto superior esquerdo do robot actualizado
; OUTPUT:
;	- DX: Valor Y no qual foi detectada a colisão
;	- CX: Valor X no qual foi detectada a colisão
;	- BL: Se BL = 1, colisão
WALLCOLLISION PROC NEAR
	
	XOR AL,AL		;Garante AL a zero
	XOR BX,BX		;Garante BH a 0 para a cor do pixel ser verificada na primeira display page e BL = 0 para verificação de colisão
	PUSH DX			;Guarda valor Y na pilha
	PUSH CX			;Guarda valor X na pilha
	MOV AH,13		;Verifica a cor do pixel no canto superior esquerdo
	INT 10H
	CMP AL,1			;Se AL = 1 significa que o pixel é azul, vai haver colisão.
	JE COLLISION
	POP CX			;Retira valor X da pilha
	POP DX			;Retira valor Y da pilha
	PUSH DX			;Guarda valor Y na pilha
	PUSH CX			;Guarda valor X na pilha
	ADD CX,8
	MOV AH,13		;Verifica a cor do pixel no canto superior direito
	INT 10H
	CMP AL,1			;Se AL = 1 significa que o pixel é azul, vai haver colisão.
	JE COLLISION
	POP CX			;Retira valor X da pilha
	POP DX			;Retira valor Y da pilha
	PUSH DX			;Guarda valor Y na pilha
	PUSH CX			;Guarda valor X na pilha
	ADD DX,8
	MOV AH,13		;Verifica a cor do pixel no canto inferior esquerdo
	INT 10H
	CMP AL,1			;Se AL = 1 significa que o pixel é azul, vai haver colisão.
	JE COLLISION
	POP CX			;Retira valor X da pilha
	POP DX			;Retira valor Y da pilha
	ADD CX,8
	ADD DX,8
	MOV AH,13		;Verifica a cor do pixel no canto inferior direito
	INT 10H
	CMP AL,1			;Se AL = 1 significa que o pixel é azul, vai haver colisão.
	JE COLLISION2
	RET					;Não há colisão
	
	
COLLISION:	
	POP CX			;Retira valores desnecessários da pilha
	POP CX
COLLISION2:
	MOV BL,1
	RET
WALLCOLLISION ENDP

; Verificar se o robot chegou à linha da meta
; INPUT:
;	- DX: Valor Y do canto superior esquerdo do robot actualizado
;	- CX: Valor X do canto superior esquerdo do robot actualizado
; OUTPUT:
;	- BL: Se BL = 99, terminou
ENDGAME PROC NEAR

	XOR AL,AL		;Garante AL a zero
	XOR BX,BX		;Garante BH a 0 para a cor do pixel ser verificada na primeira display page e BL = 0 para verificação de colisão
	PUSH DX			;Guarda valor Y na pilha
	PUSH CX			;Guarda valor X na pilha
	MOV AH,13		;Verifica a cor do pixel no canto superior esquerdo
	INT 10H
	CMP AL,2			;Se AL = 2 significa que o pixel é verde
	JE COLLISIONED	
	CMP AL,4			;Se AL = 4 significa que o pixel é vermelho
	JE COLLISIONED
	POP CX			;Retira valor X da pilha
	POP DX			;Retira valor Y da pilha
	PUSH DX			;Guarda valor Y na pilha
	PUSH CX			;Guarda valor X na pilha
	ADD CX,8
	MOV AH,13		;Verifica a cor do pixel no canto superior direito
	INT 10H
	CMP AL,2			;Se AL = 2 significa que o pixel é verde
	JE COLLISIONED	
	CMP AL,4			;Se AL = 4 significa que o pixel é vermelho
	JE COLLISIONED
	POP CX			;Retira valor X da pilha
	POP DX			;Retira valor Y da pilha
	PUSH DX			;Guarda valor Y na pilha
	PUSH CX			;Guarda valor X na pilha
	ADD DX,8
	MOV AH,13		;Verifica a cor do pixel no canto inferior esquerdo
	INT 10H
	CMP AL,2			;Se AL = 2 significa que o pixel é verde
	JE COLLISIONED	
	CMP AL,4			;Se AL = 4 significa que o pixel é vermelho
	JE COLLISIONED
	POP CX			;Retira valor X da pilha
	POP DX			;Retira valor Y da pilha
	ADD CX,8
	ADD DX,8
	MOV AH,13		;Verifica a cor do pixel no canto inferior direito
	INT 10H
	CMP AL,2			;Se AL = 2 significa que o pixel é verde
	JE COLLISIONED	
	CMP AL,4			;Se AL = 4 significa que o pixel é vermelho
	JE COLLISIONED2
	RET					;Não chegou à meta
	
	
COLLISIONED:	
	POP CX			;Retira valores desnecessários da pilha
	POP CX
COLLISIONED2:
	MOV BL,99
	RET
	
ENDGAME ENDP

COLLISIONCOINS PROC NEAR
	MOV CX, 00H
	MOV CL, NCOINS
CC_1:
	MOV BX, 00H
	MOV BL, NCOINS
	SUB BX, CX
	SHL BX, 1
	SHL BX, 1

	PUSH CX
	PUSH BX

	MOV AX, COINS[BX + 0]
	MOV BX, COINS[BX + 2]
	CALL CHECKCOINCOLLISION
	POP BX
	POP CX

	CMP AX, 01H
	JE CC_2
	LOOP CC_1
	JMP CC_END
CC_2:
	CALL REMOVECOIN
CC_END:
	RET
COLLISIONCOINS ENDP

REMOVECOIN PROC NEAR
	PUSH BX			;Indice da moeda a remover

	XOR AX,AX					;Coloca AX a 0
	MOV AL, 0					;Cor preta
	MOV DX, COINS[BX + 0]	;Coordenada Y da moeda a remover
	MOV CX, COINS[BX + 2]	;Coordenada X da moeda a remover
	MOV BX,9					;Comprimento
	CALL DRAWSQUARE				;Desenha quadrado preto

	DEC NCOINS				;decrementar numero de moedas
	MOV BX, 00h				;Vai buscar o indice da última moeda
	MOV BL, NCOINS
	SHL BX, 1
	SHL BX, 1
	
	MOV DX, COINS[BX + 0]	;Guardar Y da moeda que fui buscar
	MOV CX, COINS[BX + 2]	;Guardar X da moeda que fui buscar

	POP BX							;Buscar indice da moeda a remover a pilha
	MOV COINS[BX + 0], DX	;Colocar Y da ultima moeda do array no inicio do array
	MOV COINS[BX + 2], CX	;Colocar X da ultima moeda do array no inicio do array
	INC SCORE						;Incrementa score
	;Actualizar score no ecra
	MOV DH,16
	MOV DL,31
	CALL MOVECURS
	MOV AH,2
	MOV DL,30H
	ADD DL,SCORE
	INT 21H
	RET
REMOVECOIN ENDP

;INPUT
; AX - Y do monstro
; BX - X do monstro
CHECKCOINCOLLISION PROC NEAR
	MOV CX, YROBOT
	ADD CX, 09H
	MOV DX, XROBOT
	ADD DX, 09H

	CMP CX, AX
	JL CCC_END
	CMP DX, BX
	JL CCC_END

	ADD AX, 09H
	ADD BX, 09H
	MOV CX, YROBOT
	MOV DX, XROBOT

	CMP AX, CX
	JL CCC_END
	CMP BX, DX
	JL CCC_END
	MOV AX, 01H
	JMP CCC_END
	MOV AX, 00H
CCC_END:
	RET
CHECKCOINCOLLISION ENDP

; Verifica se num dado comprimento vertical, existe a cor castanha, sinal de existencia de uma moeda
; e devolve a coordenada Y inicial da moeda detectada 
; INPUT
;	- DX: Valor Y inicial a verificar
;	- CX: Valor X inicial a verificar
;	- BL: Comprimento a verificar
; OUTPUT
;	- BL: Se BL = 1, foi detectada uma moeda
;	- DX: Valor Y inicial da moeda detectada
COLORVERT PROC NEAR
		XOR BH,BH		;Garante BH a 0 para a cor do pixel ser verificada na primeira display page
VERIFBROWN:			;Verifica para baixo se existe um pixel castanho
		CMP BL,0			;Confirma se verificou o comprimento completo
		JLE FIMCV
		MOV AH,13		;Verifica a cor do pixel
		INT 10H
		CMP AL,6			;Se AL = 6, existe a cor castanha
		JE VERIFYELLOW
		DEC BL				;Decrementa comprimento
		INC DX				;Incrementa Y
		JMP VERIFBROWN
	
VERIFYELLOW:			;Verifica para cima quando existe um pixel amarelo, para devolver a coordenada Y correcta da moeda
		DEC DX			;Decrementa Y
		MOV AH,13		;Verifica a cor do pixel
		INT 10H
		CMP AL,14			;Se AL = 14, existe a cor amarela
		JE COLLISIONCV
		JMP VERIFYELLOW

COLLISIONCV:
		MOV BL,1			;Confirma que foi detectada uma moeda
		DEC DX			;Valor Y inicial da moeda detectada
		RET

FIMCV:	
		MOV BL,0			;Não foi detectada uma moeda
		RET
		
COLORVERT ENDP

; Verifica se num dado comprimento horizontal, existe a cor castanha, sinal de existencia de uma moeda
; e devolve a coordenada X inicial da moeda detectada 
; INPUT
;	- DX: Valor Y inicial a verificar
;	- CX: Valor X inicial a verificar
;	- BL: Comprimento a verificar
; OUTPUT
;	- BL: Se BL = 1, foi detectada uma moeda
;	- CX: Valor X inicial da moeda detectada
COLORHORIZ PROC NEAR
		XOR BH,BH		;Garante BH a 0 para a cor do pixel ser verificada na primeira display page
VERIFBROWNH:			;Verifica para a direita se existe um pixel castanho
		CMP BL,0			;Confirma se verificou o comprimento completo
		JLE FIMCH
		MOV AH,13		;Verifica a cor do pixel
		INT 10H
		CMP AL,6			;Se AL = 6, existe a cor castanha
		JE VERIFYELLOWH
		DEC BL			;Decrementa comprimento
		INC CX				;Incrementa X
		JMP VERIFBROWNH
	
VERIFYELLOWH:			;Verifica para a esquerda quando existe um pixel amarelo, para devolver a coordenada X correcta da moeda
		DEC CX			;Decrementa X
		MOV AH,13		;Verifica a cor do pixel
		INT 10H
		CMP AL,14			;Se AL = 14, existe a cor amarela
		JE COLLISIONCH
		JMP VERIFYELLOWH

COLLISIONCH:
		MOV BL,1			;Confirma que foi detectada uma moeda
		DEC CX			;Valor X inicial da moeda detectada
		RET

FIMCH:	
		MOV BL,0			;Não foi detectada uma moeda
		RET
		
COLORHORIZ ENDP

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

;Desenha os monstros de jogo
;INPUT:
;	- SI: ARRAY de monstros
;	- CX: Número de monstros no array
DRAWMONSTERS PROC NEAR

STARTDM:
		CMP CX,0			;Verifica se todos os monstros foram desenhados
		JE ENDDM
		PUSH CX			;Guarda o valor de CX na pilha
		MOV AL,4			;Cor vermelha
		MOV DX,[SI]	;Valor Y inicial
		ADD SI,2			
		MOV CX,[SI]	;Valor X inicial
		ADD SI,8
		MOV BX,9
		CALL DRAWSQUARE
		POP CX			;Obtém novamente o valor de CX
		DEC CX
		JMP STARTDM
		
ENDDM:
		RET
DRAWMONSTERS ENDP

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

;Display de informação
DISPLAYINFO PROC NEAR
	;botrun
	MOV DH,1
	MOV DL,32
	CALL MOVECURS
	MOV AH,9
	LEA DX,INFO1
	INT 21H
	
	;controls
	MOV DH,4
	MOV DL,31
	CALL MOVECURS
	MOV AH,9
	LEA DX,INFO2
	INT 21H
	
	;up
	MOV DH,6
	MOV DL,31
	CALL MOVECURS
	MOV AH,9
	LEA DX,INFO3
	INT 21H
	
	;down
	MOV DH,8
	MOV DL,31
	CALL MOVECURS
	MOV AH,9
	LEA DX,INFO4
	INT 21H
	
	;left
	MOV DH,10
	MOV DL,31
	CALL MOVECURS
	MOV AH,9
	LEA DX,INFO5
	INT 21H
	
	;right
	MOV DH,12
	MOV DL,31
	CALL MOVECURS
	MOV AH,9
	LEA DX,INFO6
	INT 21H
	
	;score
	MOV DH,14
	MOV DL,31
	CALL MOVECURS
	MOV AH,9
	LEA DX,INFO7
	INT 21H
	
	;score inicial
	MOV DH,16
	MOV DL,31
	CALL MOVECURS
	MOV AH,2
	MOV DL,30H
	ADD DL,SCORE
	INT 21H
	
	RET
DISPLAYINFO ENDP

; Move o cursor para a posição desejada
; INPUT:
;	- DH - linha do cursor 
;	- DL - coluna do cursor 
MOVECURS proc
    MOV BH, 0   ;display page
    MOV AH, 2
    INT 10H
    RET
MOVECURS endp

CODE ENDS

END