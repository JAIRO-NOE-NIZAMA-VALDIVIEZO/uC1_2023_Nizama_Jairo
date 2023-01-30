;--------------------------------------------------------------
; @file:		Ejercicio2_Nizama_Jairo.s
; @brief:		El siguiente programa consiste que al momento de presionar el botón de la placa (RA3) la cual será una interrupción 
;                       de baja prioridad tendrá que  ejecutar una secuencia de encendido y apagado de leds en el puerto C cuyo retardo
;                       será de 250ms. La secuencia se detiene cuando se presione otro pulsador externo conectado  en el pin RB4 (INT1) la cual
;                       será interrupción de alta prioridad o hasta que el número de repeticiones sea 5.Otro pulsador externo conectado al RF2(INT2) 
;                       la cual es una interrupción de alta prioridad tiene que reiniciar toda la secuencia y apagar los leds.Y finalmente,
;                       mientras no se active ninguna interrupción, el programa principal, realice un toggle del led de la placa cada 500 ms.                      
; @date:		30/01/2023
; @author:		Jairo Noe Nizama Valdiviezo
; @Version and program:	MPLAB X IDE v6.00
;------------------------------------------------------------------
PROCESSOR 18F57Q84
#include "Bit_Config.inc"   /*config statements should precede project file includes.*/
#include <xc.inc>
    
PSECT resetVect,class=CODE,reloc=2
resetVect:
    goto Main
    
PSECT udata_acs
contador1:  DS 1	    
contador2:  DS 1
offset:	    DS 1
offset1:    DS 1
counter:    DS 1
conteo_5:   DS 1 
       
PSECT ISRVectLowPriority,class=CODE,reloc=2
ISRVectLowPriority:
    BTFSS   PIR1,0,0	; ¿Se ha producido la INT0?
    GOTO    INT0_FINAL
INT0:
    BCF	    PIR1,0,0	; limpiamos el flag de INT0
    GOTO    INICIO_SECUENCIA
INT0_FINAL:
    RETFIE

PSECT ISRVectHighPriority,class=CODE,reloc=2
ISRVectHighPriority:
    BTFSS   PIR10,0,0	; ¿Se ha producido la INT2?
    GOTO    HighPriority_STOP
INT2:
    BCF	    PIR10,0,0	; limpiamos el flag de INT2
    GOTO    Exit
FIN_INT2:
    RETFIE

    
PSECT CODE    
Main:
    CALL    Config_OSC,1
    CALL    Config_Port,1
    CALL    Config_PPS,1
    CALL    Config_INT0_INT1_INT2,1
    
interrupciones_inactivas:
   BTFSC   PIR10,0,0	     ;¿Se ha producido la INT2?
   GOTO	   ISRVectHighPriority
   BTG	   LATF,3,0          ;toggle Led
   CALL    Delay_250ms,1
   CALL    Delay_250ms,1
   BTG	   LATF,3,0
   CALL    Delay_250ms,1
   CALL    Delay_250ms,1
   goto	   interrupciones_inactivas

Loop:
    BANKSEL PCLATU
    MOVLW   low highword(Table)
    MOVWF   PCLATU,1
    MOVLW   high(Table)
    MOVWF   PCLATH,1
    RLNCF   offset,0,0
    CALL    Table
    MOVWF   LATC,0
    CALL    Delay_250ms,1
    DECFSZ  counter,1,0
    GOTO    Next_Seq
    
Verificar_conteo:
    DECFSZ  conteo_5,1,0
    GOTO    Reload
    Goto    INT0_FINAL
Next_Seq:
    INCF    offset,1,0
    GOTO    Loop
  
INICIO_SECUENCIA:
    MOVLW   0x05	
    MOVWF   conteo_5,0	;Se repetirá la secuecia 5 veces
    MOVLW   0x00	
    MOVWF   offset,0	    
Reload:
    MOVLW   0x0A	
    MOVWF   counter,0	; carga del contador con el numero de offsets
    MOVLW   0x00	
    MOVWF   offset,0	; definimos el valor del offset inicial
    GOTO    Loop  
    
HighPriority_STOP:
    BTFSS   PIR6,0,0	; ¿Se ha producido la INT1?
    GOTO    FIN_INT2
    GOTO    interrupciones_inactivas

Table:
    ADDWF   PCL,1,0
    RETLW   10000001B	; offset: 0 -> se enciende los leds ubicados en RC0 y RC7
    RETLW   01000010B	; offset: 1 -> se enciende los leds ubicados en RC1 y RC6
    RETLW   00100100B	; offset: 2 -> se enciende los leds ubicados en RC2 y RC5
    RETLW   00011000B	; offset: 3 -> se enciende los leds ubicados en RC3 y RC4
    RETLW   00000000B	; offset: 4 -> se apagan todos los leds
    RETLW   00011000B	; offset: 5 -> se enciende los leds ubicados en RC3 y RC4
    RETLW   00100100B	; offset: 6 -> se enciende los leds ubicados en RC2 y RC5
    RETLW   01000010B	; offset: 7 -> se enciende los leds ubicados en RC1 y RC6
    RETLW   10000001B	; offset: 8 -> se enciende los leds ubicados en RC0 y RC7
    RETLW   00000000B	; offset: 9 -> se apagan todos los leds

Config_OSC:
    ;Configuracion del Oscilador Interno a una frecuencia de 4MHz
    BANKSEL OSCCON1
    MOVLW   0x60    ;seleccionamos el bloque del osc interno(HFINTOSC) con DIV=1
    MOVWF   OSCCON1,1 
    MOVLW   0x02    ;seleccionamos una frecuencia de Clock = 4MHz
    MOVWF   OSCFRQ,1
    RETURN
   
Config_Port:	
    ;Config Led
    BANKSEL PORTF
    CLRF    PORTF,1	
    BSF	    LATF,3,1
    BSF	    LATF,2,1
    CLRF    ANSELF,1	
    BCF	    TRISF,3,1
    BCF	    TRISF,2,1
    
    ;Config User Button
    BANKSEL PORTA
    CLRF    PORTA,1	
    CLRF    ANSELA,1	
    BSF	    TRISA,3,1	
    BSF	    WPUA,3,1
    
    ;Config Ext Button1
    BANKSEL PORTB
    CLRF    PORTB,1	
    CLRF    ANSELB,1	
    BSF	    TRISB,4,1	
    BSF	    WPUB,4,1
    
    ;Config Ext Button2
    BANKSEL PORTF
    CLRF    PORTF,1	
    CLRF    ANSELF,1	
    BSF	    TRISF,2,1	
    BSF	    WPUB,2,1
    
    ;Config PORTC
    BANKSEL PORTC
    CLRF    PORTC,1	
    CLRF    LATC,1	
    CLRF    ANSELC,1	
    CLRF    TRISC,1
    RETURN
    
Config_PPS:
    ;Config INT0
    BANKSEL INT0PPS
    MOVLW   0x03          ;Elejimos el PORTA<3>
    MOVWF   INT0PPS,1	  ; INT0 --> RA3
    
    ;Config INT1
    BANKSEL INT1PPS
    MOVLW   0x0C         ;Elejimos el PORTB<4>
    MOVWF   INT1PPS,1	 ; INT1 --> RB4
    
    ;Config INT2
    BANKSEL INT2PPS
    MOVLW   0x2A         ;Elejimos el PORTF<2>  
    MOVWF   INT2PPS,1    ; INT2 --> RF2
    RETURN   
;   Secuencia para configurar interrupcion:
;    1. Definir prioridades
;    2. Configurar interrupcion
;    3. Limpiar el flag
;    4. Habilitar la interrupcion
;    5. Habilitar las interrupciones globales
Config_INT0_INT1_INT2:
    
    ;Configuracion de prioridades
    BSF	INTCON0,5,0 ; INTCON0<IPEN> = 1 -- Habilitamos las prioridades
    BANKSEL IPR1
    BCF	IPR1,0,1    ; IPR1<INT0IP> = 0 --  INT0 de baja prioridad
    BANKSEL IPR6
    BSF	IPR6,0,1    ; IPR6<INT1IP> = 1 --  INT1 de alta prioridad
    BANKSEL IPR10
    BSF	IPR10,0,1   ; IPR10<INT2IP> = 1 -- INT2 de alta prioridad
    
    ;Configuración de INT0
    BCF	INTCON0,0,0 ; INTCON0<INT0EDG> = 0 -- INT0 por flanco de bajada
    BCF	PIR1,0,0    ; PIR1<INT0IF> = 0 -- limpiamos el flag de interrupcion
    BSF	PIE1,0,0    ; PIE1<INT0IE> = 1 -- habilitamos la interrupcion ext0
    
    ;Configuración de INT1
    BCF	INTCON0,1,0 ; INTCON0<INT1EDG> = 0 -- INT1 por flanco de bajada
    BCF	PIR6,0,0    ; PIR6<INT1IF> = 0 -- limpiamos el flag de interrupcion
    BSF	PIE6,0,0    ; PIE6<INT1IE> = 1 -- habilitamos la interrupcion ext1
    
    ;Configuración de INT2
    BCF	INTCON0,2,0 ; INTCON0<INT1EDG> = 0 -- INT2 por flanco de bajada
    BCF	PIR10,0,0    ; PIR10<INT2IF> = 0 -- limpiamos el flag de interrupcion
    BSF	PIE10,0,0    ; PIE10<INT2IE> = 1 -- habilitamos la interrupcion ext2
    
    ;Habilitacion de interrupciones
    BSF	INTCON0,7,0 ; INTCON0<GIE/GIEH> = 1 -- habilitamos las interrupciones de forma global y de alta prioridad
    BSF	INTCON0,6,0 ; INTCON0<GIEL> = 1 -- habilitamos las interrupciones de baja prioridad
    RETURN
    
;retado de 250ms       
Delay_250ms:		    ; 2Tcy -- Call
    MOVLW   250		    ; 1Tcy -- k2
    MOVWF   contador2,0	    ; 1Tcy
; T = (6 + 4k)us	    1Tcy = 1us
Ext_Loop:		    
    MOVLW   249		    ; 1Tcy -- k1
    MOVWF   contador1,0	    ; 1Tcy
Int_Loop:
    NOP			    ; k1*Tcy
    DECFSZ  contador1,1,0   ; (k1-1)+ 3Tcy
    GOTO    Int_Loop	    ; (k1-1)*2Tcy
    DECFSZ  contador2,1,0
    GOTO    Ext_Loop
    RETURN		    ; 2Tcy
   
Exit:     
End resetVect



