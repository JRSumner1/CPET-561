# CPET-561 — Embedded Systems Design I (Spring 2025)

Hands-on labs, incremental IP builds, and a multi-mode real-time audio demo for the **CPET-561 Embedded Systems Design I** course at RIT.  
Everything targets the **Intel/Altera DE1-SoC** board (Cyclone V 5CSEMA5F31C6 FPGA + dual-core ARM) and is developed with **Quartus Prime 18.1, Platform Designer/Qsys, and Nios II SBT**. :contentReference[oaicite:0]{index=0}&#8203;:contentReference[oaicite:1]{index=1}  

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
| **DE1-SoC board** (Cyclone V FPGA + HPS) | Central development platform :contentReference[oaicite:2]{index=2}&#8203;:contentReference[oaicite:3]{index=3} |
| **24-bit Audio CODEC** + on-board MIC / 3.5 mm line-in/out | Real-time audio capture & playback :contentReference[oaicite:4]{index=4}&#8203;:contentReference[oaicite:5]{index=5} |
| **HiTec HS-311 Servo** | PWM-controlled actuator for Labs 4-5 :contentReference[oaicite:6]{index=6}&#8203;:contentReference[oaicite:7]{index=7} |
| **User I/O** (SW\[9:0], KEY\[3:0], HEX Displays, LEDs) | Interface for polling/interrupt exercises :contentReference[oaicite:8]{index=8}&#8203;:contentReference[oaicite:9]{index=9} |

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
CPET-561/                        # Top-level project root
│   ├── lab01_intro_leds/        # VHDL “hello world” — blink LED & SW→LED mapping
│   ├── lab02_assembly_io/       # Nios II assembly programs and HEX0 counter
│   ├── lab03_interrupts/        # Poll vs. IRQ; 1 Hz timer toggles LEDs
│   ├── lab04_servo_ip/          # Custom PWM servo-controller IP (45°–135° sweep)
│   ├── lab05_servo_sw/          # C firmware that drives Lab 4 IP and displays angles
│   ├── lab06_ram_ip/            # 16 KB inferred RAM Avalon-MM slave + confidence test
│   ├── lab07_ram_be/            # Byte-enable RAM variant (4 × 4 KB × 8) + byte/half tests
│   ├── lab08_fir_filters/       # 17-tap LPF / HPF FIR cores, ModelSim TB + Excel plots
│   ├── lab09_audio_filter/      # FIR IP in Platform Designer; stream .wav through LPF/HPF
│   └── lab10_fun_with_audio/    # 5-mode real-time audio demo (pass, LPF, HPF, record, echo)
│   ├── demo01_custom_ip/        # 8-word register block with IRQ on invalid address
│   ├── demo02_signaltap/        # Signal Tap setup, trigger config, live debug tips
│   ├── demo03_audio_playback/   # Play .wav from SDRAM via audio core
│   ├── demo04_timequest/        # Adder timing analysis & SDC constraint walk-through
│   ├── demo05_bus_arb_p1/       # Avalon-to-External Bus bridge + SRAM controller
│   ├── demo06_bus_arb_p2/       # Dual-master mailbox with round-robin arbiter
├── demo07_timer_irq/        # 1 s interval-timer ISR toggling LEDs
└── demo08_assembly/         # Step-through of Nios II assembly in Eclipse
│
└── README.md                    # Course overview, lab & demo summaries, build notes
```
---

## Lab Summaries
| # | Title | One-liner |
|---|-------|-----------|
| **1** | Intro to DE1-SoC | Blink LED in VHDL; map SW → LED pipeline to learn Quartus pin flow :contentReference[oaicite:10]{index=10}&#8203;:contentReference[oaicite:11]{index=11} |
| **2** | Assembly I/O | KEY1-controlled up/down counter on HEX0 in pure Nios II assembly :contentReference[oaicite:12]{index=12}&#8203;:contentReference[oaicite:13]{index=13} |
| **3** | I/O & Interrupts | Compare polling vs. edge-captured IRQs; 100 ms timer blinks LEDs :contentReference[oaicite:14]{index=14}&#8203;:contentReference[oaicite:15]{index=15} |
| **4** | Servo Controller IP | Custom VHDL core generates 50 Hz PWM sweep (45°–135°) with IRQ :contentReference[oaicite:16]{index=16}&#8203;:contentReference[oaicite:17]{index=17} |
| **5** | Servo Controller SW | C drivers/ISRs write min/max angle regs & update seven-segment display :contentReference[oaicite:18]{index=18}&#8203;:contentReference[oaicite:19]{index=19} |
| **6** | Embedded Memory IP | 16 KB inferred RAM, Avalon slave, continuous RAM-confidence test :contentReference[oaicite:20]{index=20}&#8203;:contentReference[oaicite:21]{index=21} |
| **7** | Byte-Enable RAM | 4 × 4 KB × 8 RAM banks with write-byte-enable; byte/half-word testing suite :contentReference[oaicite:22]{index=22}&#8203;:contentReference[oaicite:23]{index=23} |
| **8** | Digital FIR Filters | 17-tap low-pass & high-pass FIR in DSP blocks; ModelSim test-bench plots :contentReference[oaicite:24]{index=24}&#8203;:contentReference[oaicite:25]{index=25} |
| **9** | Audio Filter IP | Custom FIR IP wrapped for Qsys; Nios program streams .wav through LPF/HPF :contentReference[oaicite:26]{index=26}&#8203;:contentReference[oaicite:27]{index=27} |
| **10** | Fun with Audio | Five runtime modes: passthrough, LPF, HPF, record/playback, *student concept* echo/effect :contentReference[oaicite:28]{index=28}&#8203;:contentReference[oaicite:29]{index=29} |

---

## Demo Summaries
| # | Title | Key idea / skills shown |
|---|-------|-------------------------|
| 1 | Custom Component IP | Design a Qsys-ready Avalon-MM slave that stores eight 32-bit words; switches pick an address, LEDs echo the data, and an IRQ fires on invalid (>7) addresses |
| 2 | Signal Tap Logic Analyzer | Live-probe internal Avalon writes & interrupts in the custom-IP system; configure triggers, widen sample depth, and correlate with C break-points |
| 3 | Audio Demo | Stream a `.wav` from SDRAM through the audio core to the on-board CODEC; covers I²C config, 48 kHz ISR pacing, and oscilloscope verification |
| 4 | TimeQuest (Demo 7) | Constrain and analyze a 16-bit adder: inspect failing paths at 1 ns default, add 20 ns SDC, re-compile, and compare new slack/F<sub>max</sub> :contentReference[oaicite:36]{index=36}&#8203;:contentReference[oaicite:37]{index=37} |
| 5 | Bus Arbitration P1 | Avalon-to-External Bus Bridge driving a 2 KB × 16 SRAM; C test fills RAM, then flashes LEDs on read-back error detection :contentReference[oaicite:38]{index=38}&#8203;:contentReference[oaicite:39]{index=39} |
| 6 | Bus Arbitration P2 | Dual Nios II masters share SRAM via two bridges + VHDL round-robin arbiter; “chat-room” mailbox demo validates concurrent access :contentReference[oaicite:40]{index=40}&#8203;:contentReference[oaicite:41]{index=41} |
| 7 | Interval-Timer Interrupt | Register a 1 Hz timer ISR in C that clears the IRQ flag and bumps an LED counter—shows priority swapping and BSP constants :contentReference[oaicite:42]{index=42}&#8203;:contentReference[oaicite:43]{index=43} |
| 8 | Assembly-Language Suite | Three hand-written Nios II ASM programs: max-of-array, decimal digit split, and live SW → LED echo; Eclipse disassembly debugging :contentReference[oaicite:44]{index=44}&#8203;:contentReference[oaicite:45]{index=45} |

---

## Building & Programming
1. **Clone**  
   ```bash
   git clone https://github.com/JRSumner1/CPET-561.git
   cd CPET-561
