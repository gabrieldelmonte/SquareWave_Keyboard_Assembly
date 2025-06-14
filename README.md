# SquareWave Keyboard in Assembly (ELTD13A Final Project)

This repository contains the source code (written in ARM Assembly) for a digital square-wave musical keyboard developed as the final project for the **Microcontroller Laboratory (ELTD13A)** course at UNIFEI, Federal University of Itajubá.


## Objective

To design and implement a musical keyboard system capable of:

- Generating **musical notes** using square waves;
- Switching between two **musical octaves**;
- Adjusting the **timbre** by modifying the duty cycle of the PWM;
- Implementing a **bending/sliding** effect using a potentiometer;
- Displaying real-time information on an **LCD display**;
- Including a bonus **custom function** triggered by a special button.


## Authors

| Name								| Registry number	|
|-----------------------------------|-------------------|
| Gabriel Del Monte Schiavi Noda	| 2022014552		|
| Gabrielle Gomes Almeida			| 2022002758		|
| Mirela Vitoria Domiciano   		| 2022004930		|


## Functionality overview

| Component         | Function                                                                |
|-------------------|-------------------------------------------------------------------------|
| **SW1 / SW2**     | Select active octave (Octave 1 or Octave 2)                             |
| **SW3 / SW4**     | Adjust timbre (+5% / -5%) by modifying PWM duty cycle                   |
| **SW5 to SW11**   | Play musical notes from the selected octave                             |
| **SW12**          | Toggle between system status and a custom credits screen                |
| **Potentiometer** | Apply sliding effect between current and next musical note (pitch bend) |
| **LCD Display**   | Show current octave and timbre or alternate credits screen              |


## Technical specifications

- **Language:** ARM Assembly
- **Platform:** STM32F103 (ARM Cortex-M3)
- **Peripherals Used:**
  - GPIO (Button inputs, LCD)
  - ADC (Analog read from potentiometer)
  - TIM3 (PWM signal generation)
  - LCD 16x2 (4-bit mode)
- **Audio Output:** Square wave signal modulated by timers and PWM
- **Note Mapping:** Based on pre-calculated PSC values for two octaves


## Code structure

The code is modular and organized into multiple subroutines, such as:

- `sub_identify_key`: Detect pressed keys
- `sub_read_potentiometer`: Read ADC values
- `sub_convert_pot_value`: Normalize potentiometer value to percentage
- `sub_calculate_effect`: Apply frequency sliding effect
- `sub_update_lcd`: Display system information
- `sub_toggle_button12`: Toggle between UI modes
- `sub_lcd_init`, `sub_lcd_command`, `sub_lcd_data`: LCD management
- Initialization routines for GPIO, ADC, Timers


## Note Frequency Table

| Note | Octave 1 (Hz) | Octave 2 (Hz) |
|------|----------------|----------------|
| C    | 261.63         | 523.26         |
| C#   | 277.18         | 554.36         |
| D    | 293.66         | 587.32         |
| D#   | 311.13         | 622.26         |
| E    | 329.63         | 659.26         |
| F    | 349.23         | 698.46         |
| F#   | 369.99         | 739.98         |
| G    | 391.99         | 783.98         |
| G#   | 415.30         | 830.60         |
| A    | 440.00         | 880.00         |
| A#   | 466.16         | 932.32         |
| B    | 493.88         | 987.76         |


## Building and Flashing

This project can be compiled and flashed using:

**Keil uVision:** [Keil uVision](https://www.keil.com/)

Ensure proper wiring of the LCD, switches, and potentiometer according to your development board's GPIO configuration.


## Extra feature

The **SW12** key allows switching between two LCD modes:
- Status mode (shows timbre and octave)
- Credits mode (displays team nicknames and course code)


## 📜 License

This project is for educational purposes only. You are free to use, study, and modify it, provided that proper credit is given to the original authors.

---
