# CPET-561 — Embedded Systems Design I (Spring 2025)

Hands-on labs, incremental IP builds, and a multi-mode real-time audio demo for the **CPET-561 Embedded Systems Design I** course at RIT.  
Everything targets the **Intel/Altera DE1-SoC** board (Cyclone V 5CSEMA5F31C6 FPGA + dual-core ARM) and is developed with **Quartus Prime 18.1, Platform Designer/Qsys, and Nios II SBT**. 

---

## Table of Contents
1. [Hardware](#hardware)  
2. [Software / Toolchain](#software--toolchain)  
3. [Repo Layout](#repo-layout)  
4. [Lab Summaries](#lab-summaries)  
5. [Demo Summaries](#demo-summaries)  
6. [Building & Programming](#building--programming)  
7. [Contributing](#contributing)  

---

## Hardware
| Part | Purpose |
|------|---------|
| **DE1-SoC board** (Cyclone V FPGA + HPS) | Central development platform |
| **24-bit Audio CODEC** + on-board MIC / 3.5 mm line-in/out | Real-time audio capture & playback |
| **HiTec HS-311 Servo** | PWM-controlled actuator for Labs 4-5 |
| **User I/O** (SW\[9:0], KEY\[3:0], HEX Displays, LEDs) | Interface for polling/interrupt exercises |

---

## Software / Toolchain
| Tool | Version | Notes |
|------|---------|-------|
| **Quartus Prime Lite** | 18.1 | Synthesis, pin-planning, and device programming |
| **Platform Designer / Qsys** | 18.1 | Avalon-MM system construction |
| **ModelSim-Intel Edition** | 10.5b | VHDL simulation & test-benches |
| **Nios II SBT (Eclipse)** | 21.1 | C/C++ BSP generation, ELF download |
| **Python + Excel** | — | FIR-filter coefficient verification (Labs 8-9) |

---

## Repo Layout
```bash
CPET-561/
├── Arbitration_Demo/         # Two-part mailbox & bus-arbiter project
├── Assembly_Demo/            # Nios II assembly language walkthrough
├── Audio_Demo/               # SDRAM-to-CODEC audio playback example
├── DE1_SoC_Lab1/             # Intro: VHDL LED blink & SW→LED mapping
├── DE1_SoC_Lab2/             # Assembly I/O lab (HEX0 counter)
├── DE1_SoC_Lab3/             # Polling vs. IRQs; 1 Hz timer LEDs
├── DE1_SoC_Lab4/             # PWM servo-controller IP (angle sweep)
├── DE1_SoC_Lab5/             # C firmware driving Lab 4 servo IP
├── DE1_SoC_Lab6/             # 16 KB inferred RAM Avalon slave
├── DE1_SoC_Lab7/             # Byte-enable RAM (4 × 4 KB × 8)
├── DE1_SoC_Lab8/             # 17-tap LPF/HPF FIR cores in VHDL
├── DE1_SoC_Lab9/             # Audio FIR IP + .wav stream test
├── DE1_SoC_Lab10/            # Five-mode real-time audio effects demo
├── Signal Tap Demo/          # On-chip logic-analyzer (Signal Tap) tutorial
├── TimeQuest_Demo/           # Timing constraints & slack analysis demo
├── custom_component_demo/    # 8-word Avalon-MM slave with IRQ trigger
├── int_demo/                 # 1-second interval-timer interrupt example
├── DE1_SoC.qsf               # Board-wide pin assignments for Cyclone V
└── README.md                 # Course overview, build notes, lab/demo index
```
---

## Lab Summaries
| # | Title | One-liner |
|---|-------|-----------|
| **1** | Intro to DE1-SoC | Blink LED in VHDL; map SW → LED pipeline to learn Quartus pin flow |
| **2** | Assembly I/O | KEY1-controlled up/down counter on HEX0 in pure Nios II assembly |
| **3** | I/O & Interrupts | Compare polling vs. edge-captured IRQs; 100 ms timer blinks LEDs |
| **4** | Servo Controller IP | Custom VHDL core generates 50 Hz PWM sweep (45°–135°) with IRQ |
| **5** | Servo Controller SW | C drivers/ISRs write min/max angle regs & update seven-segment display |
| **6** | Embedded Memory IP | 16 KB inferred RAM, Avalon slave, continuous RAM-confidence test |
| **7** | Byte-Enable RAM | 4 × 4 KB × 8 RAM banks with write-byte-enable; byte/half-word testing suite |
| **8** | Digital FIR Filters | 17-tap low-pass & high-pass FIR in DSP blocks; ModelSim test-bench plots |
| **9** | Audio Filter IP | Custom FIR IP wrapped for Qsys; Nios program streams .wav through LPF/HPF |
| **10** | Fun with Audio | Five runtime modes: passthrough, LPF, HPF, record/playback, *student concept* echo/effect |

---

## Demo Summaries
| # | Title | Key idea / skills shown |
|---|-------|-------------------------|
| 1 | Custom Component IP | Design a Qsys-ready Avalon-MM slave that stores eight 32-bit words; switches pick an address, LEDs echo the data, and an IRQ fires on invalid (>7) addresses |
| 2 | Signal Tap Logic Analyzer | Live-probe internal Avalon writes & interrupts in the custom-IP system; configure triggers, widen sample depth, and correlate with C break-points |
| 3 | Audio Demo | Stream a `.wav` from SDRAM through the audio core to the on-board CODEC; covers I²C config, 48 kHz ISR pacing, and oscilloscope verification |
| 4 | TimeQuest (Demo 7) | Constrain and analyze a 16-bit adder: inspect failing paths at 1 ns default, add 20 ns SDC, re-compile, and compare new slack *Fmax* |
| 5 | Bus Arbitration P1 | Avalon-to-External Bus Bridge driving a 2 KB × 16 SRAM; C test fills RAM, then flashes LEDs on read-back error detection |
| 6 | Bus Arbitration P2 | Dual Nios II masters share SRAM via two bridges + VHDL round-robin arbiter; “chat-room” mailbox demo validates concurrent access |
| 7 | Interval-Timer Interrupt | Register a 1 Hz timer ISR in C that clears the IRQ flag and bumps an LED counter—shows priority swapping and BSP constants |
| 8 | Assembly-Language Suite | Three hand-written Nios II ASM programs: max-of-array, decimal digit split, and live SW → LED echo; Eclipse disassembly debugging |

---

## Building & Programming
1. **Clone**
   ```bash
   git clone https://github.com/JRSumner1/CPET-561.git
   cd CPET-561
   ```
2. Choose a lab or demo folder and open the Quartus project.
3. Generate HDL in Platform Designer (nios_system → Generate).
4. Compile & Program
   * Run Quartus compilation, then use the Programmer to load *.sof.
   * In Nios II SBT build the matching *.elf, then Run → Hardware.
5. Verification
   * ModelSim test benches live in each lab’s sim/ directory.
   * Labs 8-10 export CSVs you can plot in Excel.   

---

## Contributing
Jonathan Sumner – JRSumner1
