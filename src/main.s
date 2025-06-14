; Trabalho final - ELTD13A
; Discentes
	; Gabriel Del Monte Schiavi Noda - 2022014552
	; Gabrielle Gomes Almeida 		 - 2022002758
	; Mirela Vitoria Domiciano		 - 2022004930
; -----------------------------------------------


; As sub-rotinas para o funcionamento do programa
; estao dispostas na seguinte ordem:
; sub_identifica_tecla
; sub_leitura_potenciometro
; sub_conversao_potenciometro
; sub_calcula_efeito
; sub_atualiza_lcd
; sub_atualiza_oitava_1
; sub_atualiza_oitava_2
; sub_toggle_botao12
; sub_aumenta_valor_timbre
; sub_abaixa_valor_timbre
; sub_mostra_timbre
; sub_mostra_botao12
; delay
; sub_lcd_init
; sub_lcd_command
; sub_lcd_data
; sub_habilita_rcc_gpios
; sub_configuracao_inicial_lcd
; sub_configura_potenciometro
; sub_configura_timer


; Equates

; Registros para configuracao
JTAG_GPIO   EQU 0x02000000
AFIO_HAB    EQU 0x0100
LCD_EN      EQU 0x1000
LCD_RS      EQU 0x8000

TIM2_BASE   EQU 0x40000000
TIM3_BASE	EQU	0x40000400
TIM_CR1     EQU 0x00
TIM_SR      EQU 0x10
TIM_CCMR1   EQU 0x18
TIM_CCMR2	EQU 0x1C
TIM_CCER    EQU 0x20
TIM_CNT     EQU 0x24
TIM_PSC     EQU 0x28
TIM_ARR     EQU 0x2C
TIM_CCR1	EQU 0x34
TIM_CCR3	EQU	0x3C

AFIO_MAPR 	EQU 0x40010004

GPIOA_BASE  EQU 0x40010800
GPIOB_BASE  EQU 0x40010C00
GPIOC_BASE  EQU 0x40011000
GPIO_CRL    EQU 0x00
GPIO_CRH    EQU 0x04
GPIO_IDR    EQU 0x08
GPIO_ODR    EQU 0x0C
GPIO_BSRR   EQU 0x10
GPIO_BRR    EQU 0x14

RCC_BASE    EQU 0x40021000
RCC_APB2ENR EQU 0x18
RCC_APB1ENR EQU 0x1C

ADC1_BASE   EQU 0x40012400
ADC_SR      EQU 0x00
ADC_CR2     EQU 0x08
ADC_SMPR2	EQU 0x10
ADC_SQR3    EQU 0x34
ADC_DR      EQU 0x4C


; Codigo principal
	export __main

;	Switches
;	-, 1, 2 , 3, 4 , 5, 6, 7 , 8, 9 , 10, 11, 12 - Index 
;	0, 5, 13, 6, 14, 7, 8, 15, 9, 16, 10, 17, 11 - SW
; 	-, C, C#, D, D#, E, F, F#, G, G#, A , A#, B	 - Nota

	area psc_oitava1, data, readonly
	dcd	 0, 2751, 2597, 2451, 2313, 2183, 2061, 1945, 1836, 1733, 1635, 1544, 1457, 1379
;		 -, C   , C#  , D	, D#  , E   , F   , F#  , G   , G#  , A   , A#  , B	  , AUX

	area psc_oitava2, data, readonly
	dcd  0, 1375, 1298, 1225, 1156, 1091, 1030, 972, 917, 866, 817, 771, 728, 689
;	     -, C   , C#  , D	, D#  , E   , F   , F# , G  , G# , A  , A# , B  , AUX


	area dados_programa, data, readwrite
oitava_selecionada	 	 space 4
valor_botao12			 space 4
index_selecionado		 space 4
botao_selecionado	 	 space 4
valor_potenciometro		 space 4


	area trabalho, code, readonly
__main

	bl	sub_habilita_rcc_gpios
	bl	sub_configuracao_inicial_lcd
	bl	sub_configura_potenciometro
	bl	sub_configura_timer

	; Inicializando os valores na memoria
	; para garantir que a leitura nao ira
	; receber "lixo"
	mov r0, #0x1
	ldr r1, =oitava_selecionada
	mov r0, #0x0
	str r0, [r1]
	ldr r1, =valor_botao12
	str r0, [r1]
	ldr r1, =index_selecionado
	str r0, [r1]
	ldr r1, =botao_selecionado
	str r0, [r1]
	ldr r1, =valor_potenciometro
	str r0, [r1]

	; Resetando o valor dos registradores de uso geral
	mov r0,  #0x0
	mov r1,  #0x0
	mov r2,  #0x0
	mov r3,  #0x0
	mov r4,  #0x0
	mov r5,  #0x0
	mov r6,  #0x0
	mov r7,  #0x0
	mov r8,  #0x0
	mov r9,  #0x0
	mov r10, #0x0
	mov r11, #0x0
	mov r12, #0x0

    bl  sub_lcd_init
	bl  delay
    bl  sub_atualiza_lcd
	bl  delay

; Loop infinito para o programa
lp
	bl	sub_identifica_tecla
	bl	sub_leitura_potenciometro
	bl	sub_conversao_potenciometro
	bl	sub_calcula_efeito

    b  lp
	LTORG


; Sub-rotinas para o programa

; Esta sub-rotina ira realizar a identificacao
; da tecla pressionada por meio de rotacoes
; sucessivas, para que, caso alguma tecla seja
; pressionada, realizar a alteracao no index
; da tecla pressionada para que seja possivel
; realizar o tratamento necessario para cada
; tecla, como por exemplo alterar o valor do timbre
; e alem disso, caso nenhuma tecla esteja pressionada,
; o buzzer sera desligado para nao emitir nenhum som
sub_identifica_tecla
	push {lr, r1, r2, r3, r9, r12}

	ldr  r1,   =index_selecionado
	ldr  r2,   =botao_selecionado
	mov  r12,  #0x0

	; Switches da GPIOA
	ldr	 r3,   =GPIOA_BASE
	ldr	 r9,   [r3, #GPIO_IDR]

	; SW14: PA07
	lsls  r9,  #25
	orrcc r12, #4
	strcc r12, [r1]
	orrcc r12, #14
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla

	; SW09: PA04
	lsls  r9,  #3
	orrcc r12, #8
	strcc r12, [r1]
	orrcc r12, #9
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla

	; SW08: PA03
	lsls  r9,  #1
	orrcc r12, #6
	strcc r12, [r1]
	orrcc r12, #8
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla

	; Switches da GPIOB
	ldr	r3,    =GPIOB_BASE
	ldr	r9,    [r3, #GPIO_IDR]

	; SW04: PB15
    lsls  r9,  #17
	blcc  sub_aumenta_valor_timbre
	bcc.w nenhuma_tecla_sonora_pressionada

	; SW03: PB14
    lsls  r9,  #1
	blcc  sub_abaixa_valor_timbre
	bcc.w nenhuma_tecla_sonora_pressionada

	; SW02: PB13
    lsls  r9,  #1
	blcc  sub_atualiza_oitava_2
	bcc.w nenhuma_tecla_sonora_pressionada

	; SW01: PB12
    lsls  r9,  #1
	blcc  sub_atualiza_oitava_1
	bcc.w nenhuma_tecla_sonora_pressionada

	; SW12: PB11
    lsls  r9,  #1
	blcc  sub_toggle_botao12
	bcc.w nenhuma_tecla_sonora_pressionada

	; SW13: PB10
    lsls  r9,  #1
	orrcc r12, #2
	strcc r12, [r1]
	orrcc r12, #13
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla

	; SW11: PB09
    lsls  r9,  #1
	orrcc r12, #12
	strcc r12, [r1]
	orrcc r12, #11
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla

	; SW10: PB08
    lsls  r9,  #1
	orrcc r12, #10
	strcc r12, [r1]
	orrcc r12, #10
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla

	; SW05: PB05
    lsls  r9,  #3
	orrcc r12, #1
	strcc r12, [r1]
	orrcc r12, #5
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla

	; SW06: PB04
    lsls  r9,  #1
	orrcc r12, #3
	strcc r12, [r1]
	orrcc r12, #6
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla

	; SW07: PB03
    lsls  r9,  #1
	orrcc r12, #5
	strcc r12, [r1]
	orrcc r12, #7
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla


	; Switches da GPIOC
	ldr	  r3,  =GPIOC_BASE
	ldr	  r9,  [r3, #GPIO_IDR]

	; SW15: PC15
    lsls  r9,  #17
	orrcc r12, #7
	strcc r12, [r1]
	orrcc r12, #15
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla

	; SW16: PC14
    lsls  r9,  #1
	orrcc r12, #9
	strcc r12, [r1]
	orrcc r12, #16
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla

	; SW17: PC13
    lsls  r9,  #1
	orrcc r12, #11
	strcc r12, [r1]
	orrcc r12, #17
	strcc r12, [r2]
    bcc.w fim_sub_identifica_tecla

nenhuma_tecla_sonora_pressionada
	; Nenhuma tecla sonora pressionada, portanto...
	mov	  r12, #0x0
	; Indice 0
	str  r12, [r1]
	; Nenhum botao apertado
	str  r12, [r2]
	; Desligando o buzzer
	ldr	  r3,  =TIM3_BASE
	str	  r12, [r3, #TIM_CCER]

fim_sub_identifica_tecla
	nop

	pop	  {r12, r9, r3, r2, r1, lr}
	bx	  lr
	LTORG


; Esta sub-rotina ira realizar a leitura adequada
; do potenciometro, esperando o tempo de
; estabilizacao do sinal apos a inicializacao do
; ADC
sub_leitura_potenciometro
	push {lr, r0, r2, r3, r9, r12}

	ldr	 r3,  =ADC1_BASE
	ldr  r9,  [r3, #ADC_CR2]
	orr  r9,  #0x1
	str  r9,  [r3, #ADC_CR2]
	
	bl	 delay

espera_conversao
	ldr  r9,  [r3, #ADC_SR]
	and  r12, r9, #0x2
	cmp  r12, #0x2

	bne  espera_conversao
	ldr  r0,  [r3, #ADC_DR]

	ldr	 r2, =valor_potenciometro
	str	 r0, [r2]

	pop  {r12, r9, r3, r2, r0, lr}
	bx   lr
	LTORG


; Esta sub-rotina ira realizar a conversao do
; potenciometro em valor nominal para porcentagem
; para que seja possivel realizar a mudanca de
; nota pois a alteracao sera de acordo com a
; seguinte formula:
; Novo_PSC = PSC_Atual - (PSC_Proximo) * Valor_Potenciometro / Maximo_Potenciometro
sub_conversao_potenciometro
	push {lr, r0, r2, r3}

	ldr	 r2, =valor_potenciometro
	ldr	 r0, [r2]

	; Encontrando a porcentagem
	mov  r3, #100
	mul  r0, r3
	; Em relacao ao maximo (12 bits: 4095)
	mov  r3, #4095
	udiv r0, r3

	str	 r0, [r2]

	pop  {r3, r2, r0, lr}
	bx	 lr
	LTORG


; Esta sub-rotina ira calcular e produzir o efeito
; causado pela mudanca no valor do potenciometro
; enquanto as teclas sao pressionadas
sub_calcula_efeito
	push {lr, r0, r1, r2, r3, r4, r6, r9, r12}

	mov  r12, #0x0

	; Caso nenhuma tecla esteja selecionada,
	; vai para o fim da sub-rotina desligando
	; o buzzer
	ldr	 r1,  =index_selecionado
	ldr	 r2,  [r1]
	cmp  r2,  #0x0
	beq	 fim_sub_calcula_efeito

	; Define a tabela de PSC usadas
	ldr	 r1,  =oitava_selecionada
	ldr	 r9,  [r1]
	cmp  r9,  #0x2
	beq  oitava_2_selecionada_efeito
	ldr  r9,  =psc_oitava1
	b	 encontra_psc

oitava_2_selecionada_efeito
	ldr  r9,  =psc_oitava2

encontra_psc
	; Pegando o valor do potenciometro da memoria
	ldr	 r4, =valor_potenciometro
	ldr	 r0, [r4]

	; Valor atual para PSC
	ldr  r3,  [r9, r2, lsl #2]

	; Proximo valor para PSC
	add	 r2,  #0x1
	ldr  r12, [r9, r2, lsl #2]

	; Calcula a diferenca entre os dois
	sub	 r12, r3, r12
	; Multiplica a diferenca por 100 (porcentagem)
	mov	 r6,  #100
	mul	 r0,  r12
	; Divide por 100
	udiv r0,  r6

	; Determinando o efeito no PSC para chegar para a proxima nota
	sub  r2,  #0x1
	ldr	 r12, [r9, r2, lsl #2]

	; Novo valor para o PSC
	sub  r12, r0
	ldr	 r9,  =TIM3_BASE
	str	 r12, [r9, #TIM_PSC]

fim_sub_calcula_efeito
	; Habilita o buzzer caso alguma tecla esteja pressionada
	; Valor para caso nenhuma tecla esteja pressionada
	mov  r12, #0x0

	; Confere se alguma tecla esta pressionada
	ldr	 r1,  =index_selecionado
	ldr	 r2,  [r1]

	cmp  r2,  #0x0
	beq	 nenhuma_tecla_pressionada

	; Caso alguma tecla esta pressionada, liga o buzzer
	mov  r12, #0x100

nenhuma_tecla_pressionada
	ldr	 r9,  =TIM3_BASE
	str	 r12, [r9, #TIM_CCER]

	; Inicia a contagem
	mov	 r12, #0x1
	str	 r12, [r9, #TIM_CR1]

	pop  {r12, r9, r6, r4, r3, r2, r1, r0, lr}
	bx 	 lr
	LTORG



; Sub-rotinas auxiliares para o programa

; Esta sub-rotina ira atualizar o LCD de acordo
; com as informacoes atuais do sistema, apresentando
; ao usuario as informacoes de timbre e oitava
; selecionados
sub_atualiza_lcd
	push {lr, r2, r4, r9}

    mov  r4, #0x01
    bl   sub_lcd_command

    mov  r4, #'T'
    bl   sub_lcd_data
    mov  r4, #':'
    bl   sub_lcd_data

    bl   sub_mostra_timbre

	mov  r4, #' '
    bl   sub_lcd_data

    mov  r4, #'8'
    bl   sub_lcd_data
    mov  r4, #':'
    bl   sub_lcd_data

	ldr	 r2, =oitava_selecionada
	ldr	 r9, [r2]

	cmp  r9, #0x2
	beq  oitava_2_selecionada
	mov	 r4, #'1'
	bl	 sub_lcd_data
	b	 fim_sub_rotina_att_lcd

oitava_2_selecionada
	mov	 r4, #'2'
	bl	 sub_lcd_data

fim_sub_rotina_att_lcd
	nop

	pop  {r9, r4, r2, lr}
    bx 	 lr
    LTORG


; Esta sub-rotina ira definir, em memoria, que
; a oitava a ser utilizada durante a execucao
; do programa sera a primeira
sub_atualiza_oitava_1
	push {lr, r2, r9}

	ldr	 r2, =oitava_selecionada
	mov	 r9, #0x1
	str  r9, [r2]

    bl   sub_atualiza_lcd

	pop  {r9, r2, lr}
    bx   lr
    LTORG


; Esta sub-rotina ira definir, em memoria, que
; a oitava a ser utilizada durante a execucao
; do programa sera a segunda
sub_atualiza_oitava_2
	push {lr, r2, r9}

	ldr	 r2, =oitava_selecionada
	mov	 r9, #0x2
	str  r9, [r2]

	bl   sub_atualiza_lcd

	pop  {r9, r2, lr}
    bx   lr
    LTORG


; Esta sub-rotina ira alternar a funcao do SW12,
; para caso o valor em memoria seja igual a 1
; a sub-rotina sub_mostra_botao12 seja chamada
; enquanto sendo 0, a sub_atualiza_lcd sera
; chamada para mostrar os dados atuais do sistema
sub_toggle_botao12
	push {lr, r3, r9}

	ldr	 r3, =valor_botao12
	ldr  r9, [r3]
	eor  r9, #0x1
	str  r9, [r3]

	ands r9, #0x1

	beq	 botao12_zero
    bl   sub_mostra_botao12
	b	 fim_sub

botao12_zero
	bl	 sub_atualiza_lcd

fim_sub
	nop
	
	pop  {r9, r3, lr}
    bx   lr
    LTORG


; Esta sub-rotina ira aumentar o valor atual do
; timbre em 5 pct ate o limite estabelecido em 40,
; tendo em vista que um valor maior que este
; podera resultar em problemas durante a execucao
; do programa
sub_aumenta_valor_timbre
	push  {lr, r3, r9}

	; Carregando o valor atual de CCR3
    ldr   r3,  =TIM3_BASE
    ldr   r9,  [r3, #TIM_CCR3]

	; Somando 5 para aumentar o valor do timbre
    cmp   r9,  #39
    addle r9,  #5
    str   r9,  [r3, #TIM_CCR3]
    bl    sub_atualiza_lcd

	pop	  {r9, r3, lr}
    bx    lr
    LTORG


; Esta sub-rotina ira reduzir o valor atual do
; timbre em 5 pct ate o limite estabelecido em 5,
; tendo em vista que um valor menor que este
; podera resultar em problemas durante a execucao
; do programa
sub_abaixa_valor_timbre
	push  {lr, r3, r9, r12}

	; Carregando o valor atual de CCR3
    ldr   r3, =TIM3_BASE
    ldr   r9, [r3, #TIM_CCR3]

	; Subtraindo 5 para reduzir o valor do timbre
    cmp   r9, #6
    subge r9, #5
    str   r9, [r3, #TIM_CCR3]
    bl    sub_atualiza_lcd

	pop   {r12, r9, r3, lr}
    bx    lr
    LTORG


; Esta sub-rotina ira mostrar no LCD o valor
; do timbre atual, separando o valor da dezena
; e da unidade para mostrar cada dado separadamente
sub_mostra_timbre
	push {lr, r3, r4, r9, r12}

	mov	 r12, #10

	; Carregando o valor atual de CCR1
    ldr  r3, =TIM3_BASE
    ldr  r9, [r3, #TIM_CCR3]

	; Extraindo a dezena
	udiv r4, r9, r12
	add	 r4, #'0'
	bl	 sub_lcd_data
	; Extaindo a unidade
	sub	 r4, #'0'
	mls	 r4, r4, r12, r9
	add	 r4, #'0'
	bl	 sub_lcd_data
	
	pop	 {r12, r9, r4, r3, lr}
	bx	 lr
	LTORG


; Esta sub-rotina ira mostrar no LCD os "apelidos"
; de cada integrante do grupo, alem de mostrar tambem
; o curso de graduacao dos tres integrantes
sub_mostra_botao12
	push {lr, r4}

    mov  r4, #0x01
    bl   sub_lcd_command

	mov	 r4, #'G'
	bl	 sub_lcd_data
	mov	 r4, #'A'
	bl	 sub_lcd_data
	mov	 r4, #'B'
	bl	 sub_lcd_data
	mov	 r4, #' '
	bl	 sub_lcd_data

	mov	 r4, #'G'
	bl	 sub_lcd_data
	mov	 r4, #'A'
	bl	 sub_lcd_data
	mov	 r4, #'V'
	bl	 sub_lcd_data
	mov	 r4, #' '
	bl	 sub_lcd_data

	mov	 r4, #'M'
	bl	 sub_lcd_data
	mov	 r4, #'I'
	bl	 sub_lcd_data
	mov	 r4, #'R'
	bl	 sub_lcd_data
	mov	 r4, #' '
	bl	 sub_lcd_data

	mov	 r4, #'E'
	bl	 sub_lcd_data
	mov	 r4, #'C'
	bl	 sub_lcd_data
	mov	 r4, #'O'
	bl	 sub_lcd_data

	pop  {r4, lr}
	bx 	 lr
	LTORG



; Sub-rotinas de uso geral

; Delay
; Esta sub-rotina ira gerar um delay para garantir
; o funcionamento correto dos perifericos, como por
; exemplo o potenciometro e o LCD
delay
    push {lr, r3, r9}
	ldr  r3, =1
d_L1
	ldr  r9, =100000
d_L2
	subs r9, r9, #1
	bne  d_L2
	subs r3, r3, #1
	bne  d_L1
    pop  {r3, r9, lr}
	bx	  lr
    LTORG


; LCD
; Esta sub-rotina ira garantir a inicializacao
; correta para o LCD, enviando os comandos para
; inicializar as linhas e definir o modo de
; operacao, por exemplo
sub_lcd_init
	push {lr, r4}

	mov  r4, #0x33
	bl   sub_lcd_command
	mov  r4, #0x32
	bl   sub_lcd_command
	mov  r4, #0x20
	bl   sub_lcd_command
	mov  r4, #0x0E
	bl   sub_lcd_command
	mov  r4, #0x01
	bl   sub_lcd_command
	bl   delay
	mov  r4, #0x06
	bl   sub_lcd_command

	pop  {r4, lr}
	bx   lr
    LTORG

; Esta sub-rotina ira enviar os dados para o LCD
; na forma de comandos, como por exemplo para limpar
; o LCD de forma geral ou para alterar o cursor de
; local
sub_lcd_command
	push {lr, r4, r5, r7, r8, r9, r10, r11}

	and  r5,  r4,  #0xF0
	lsr  r5,  r5,  #4
	and  r7,  r5,  #0x08
	lsl  r10, r7,  #8
	and  r7,  r5,  #0x04
	lsl  r7,  r7,  #3
	orr  r10, r10, r7
	and  r7,  r5,  #0x02
	lsl  r7,  r7,  #5
	orr  r10, r10, r7
	and  r7,  r5,  #0x01
	lsl  r7,  r7,  #8
	orr  r10, r10, r7
	ldr  r11, =LCD_RS
	bic  r10, r10, r11
	bic  r10, r10, #LCD_EN
	ldr  r8,  =GPIOA_BASE
	add  r8,  r8,  #GPIO_ODR
	str  r10, [r8]
	bl   delay
	orr  r10, r10, #LCD_EN
	str  r10, [r8]
	bl   delay
	bic  r10, r10, #LCD_EN
	str  r10, [r8]
	bl   delay
	and  r5,  r4,  #0x0F
	and  r7,  r5,  #0x08
	lsl  r10, r7,  #8
	and  r7,  r5,  #0x04
	lsl  r7,  r7,  #3
	orr  r10, r10, r7
	and  r7,  r5,  #0x02
	lsl  r7,  r7,  #5
	orr  r10, r10, r7
	and  r7,  r5,  #0x01
	lsl  r7,  r7,  #8
	orr  r10, r10, r7
	ldr  r11, =LCD_RS
	bic  r6,  r6,  r11
	bic  r10, r10, #LCD_EN
	ldr  r8,  =GPIOA_BASE
	add  r8,  r8,  #GPIO_ODR
	str  r10, [r8]
	bl   delay
	bic  r10, r10, r11
	str  r10, [r8]
	bl   delay
	orr  r10, r10, #LCD_EN
	str  r10, [r8]
	bl   delay
	bic  r10, r10, #LCD_EN
	str  r10, [r8]
	bl   delay

	pop  {r11, r10, r9, r8, r7, r5, r4, lr}
	bx   lr
	LTORG

; Esta sub-rotina ira enviar os dados para o LCD
; na forma de 'chars' para que seja o valor
; enviado seja mostrado na posicao atual do cursor
; e apos o envio, o cursor eh alterado de forma
; automatica para a proxima posicao
sub_lcd_data
	push {lr, r4, r5, r7, r8, r10, r11}

	and  r5,  r4,  #0xF0
	lsr  r5,  r5,  #4
	and  r7,  r5,  #0x08
	lsl  r10, r7,  #8
	and  r7,  r5,  #0x04
	lsl  r7,  r7,  #3
	orr  r10, r10, r7
	and  r7,  r5,  #0x02
	lsl  r7,  r7,  #5
	orr  r10, r10, r7
	and  r7,  r5,  #0x01
	lsl  r7,  r7,  #8
	orr  r10, r10, r7
	ldr  r11, =LCD_RS
	orr  r10, r10, r11
	bic  r10, r10, #LCD_EN
	ldr  r8,  =GPIOA_BASE
	add  r8,  r8,  #GPIO_ODR
	str  r10, [r8]
	bl   delay
	orr  r10, r10, #LCD_EN
	str  r10, [r8]
	bl   delay
	bic  r10, r10, #LCD_EN
	str  r10, [r8]
	bl   delay
	and  r5,  r4,  #0x0F
	and  r7,  r5,  #0x08
	lsl  r10, r7,  #8
	and  r7,  r5,  #0x04
	lsl  r7,  r7,  #3
	orr  r10, r10, r7
	and  r7,  r5,  #0x02
	lsl  r7,  r7,  #5
	orr  r10, r10, r7
	and  r7,  r5,  #0x01
	lsl  r7,  r7,  #8
	orr  r10, r10, r7
	orr  r10, r10, r11
	bic  r6,  r6,  #LCD_EN
	ldr  r8,  =GPIOA_BASE
	add  r8,  r8,  #GPIO_ODR
	str  r10, [r8]
	bl   delay
	orr  r10, r10, #LCD_EN
	str  r10, [r8]
	bl   delay
	bic  r10, r10, #LCD_EN
	str  r10, [r8]
	bl   delay

	pop  {r11, r10, r8, r7, r5, r4, lr}
	bx   lr
	LTORG



; Sub-rotinas de inicializacao

; RCC e GPIOS
; Nesta subrotina serao habilitados os clocks
; do RCC e das GPIOs necessarias para o funcionamento
; do projeto
sub_habilita_rcc_gpios
	push {lr, r0, r1, r2}

	; RCC:
	ldr  r0, =RCC_BASE
	; Habilitando AFIO, IOPA, IOPB, IOPC e ADC1
	ldr  r1, [r0, #RCC_APB2ENR]
	mov  r2, #0x21D
	orr  r1, r2
	mov  r2, #0x0
	str  r1, [r0, #RCC_APB2ENR]
	; Habilitando TIM3
	ldr  r1, [r0, #RCC_APB1ENR]
	eor  r1, #0x2
	str  r1, [r0, #RCC_APB1ENR]

	; Configurando GPIOA
	ldr  r0, =GPIOA_BASE
	ldr  r1, =0x43344333
	str  r1, [r0, #GPIO_CRL]
	ldr  r1, =0x34433443
	str  r1, [r0, #GPIO_CRH]

	; Configurando GPIOB
	ldr  r0, =GPIOB_BASE
	ldr	 r1, =0x4444444B
	str  r1, [r0, #GPIO_CRL]
	ldr  r1, =0x44444444
	str  r1, [r0, #GPIO_CRH]

	; Configurando GPIOC
	ldr  r0, =GPIOC_BASE
	ldr  r1, =0x44444444
	str  r1, [r0, #GPIO_CRL]
	str  r1, [r0, #GPIO_CRH]

	pop  {r2, r1, r0, lr}
	bx	 lr
	LTORG


; LCD
; Nesta sub-rotina sera realizada a configuracao
; inicial para o LCD
sub_configuracao_inicial_lcd
	push {lr, r0, r1}

	; Configuracao inicial para LCD
    ldr  r1, =AFIO_MAPR 
    ldr  r0, =JTAG_GPIO
    str  r0, [r1]

	pop	 {r1, r0, lr}
	bx	 lr
	LTORG


; Potenciometro
; Nesta sub-rotina sera realizada a configuracao
; para o funcionamento do potenciometro
sub_configura_potenciometro
	push {lr, r0, r1}

	; Configurando o potenciometro
	ldr  r0, =ADC1_BASE
	; Habilitando o ADC1
	ldr  r1, [r0, #ADC_CR2]
	orr  r1, #0x1
	str	 r1, [r0, #ADC_CR2]

	; Habilitando o canal 9 para PB1
	mov  r1, #0x9
	str	 r1, [r0, #ADC_SQR3]

	; Define o tempo de amostragem padrao
	mov  r1, #0x0
	str  r1, [r0, #ADC_SMPR2]
	bl	 delay

	pop  {r1, r0, lr}
	bx	 lr
	LTORG


; Timer
; Nesta sub-rotina sera realizada a configuracao
; para o funcionamento do TIMER3, utilizando
; tambem os registros ARR, CCMR, CCR3 e CR1 para
; configurar corretamente
sub_configura_timer
	push {lr, r3, r9}

	ldr	 r3, =RCC_BASE
	ldr  r9, [r3, #RCC_APB1ENR]
	orr	 r9, #0x2
	str  r9, [r3, #RCC_APB1ENR]

    ldr  r3, =TIM3_BASE
    mov  r9, #99
    str  r9, [r3, #TIM_ARR]

    mov  r9, #0x68
    str  r9, [r3, #TIM_CCMR2]

    mov  r9, #10
    str  r9, [r3, #TIM_CCR3]

    mov  r9, #0x1
    str  r9, [r3, #TIM_CR1]

	pop  {r9, r3, lr}
    bx   lr
    LTORG





	end
