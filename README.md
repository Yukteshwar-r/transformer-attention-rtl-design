# Transformer Attention RTL Design

A high-performance SystemVerilog implementation of the Scaled Dot-Product Attention mechanism, a core component of Transformer models. This project realizes the complete hardware path from input embeddings and weight matrices to the final attention scores, optimized for ASIC synthesis.

## 🛠 Features
* Matrix Computation Engine: RTL for calculating Query (Q), Key (K), and Value (V) matrices.
* Scaled Dot-Product Logic: Implementation of the score matrix (S = QK^T) and scaled attention (Z = S * V).
* SRAM Interface: Memory controller handling 1-cycle delays and Read-After-Write (RAW) hazard management.
* Handshake Protocol: Robust dut_valid and dut_ready signaling for synchronized data transfer with the test fixture.
* ASIC Synthesis: Logic synthesis optimized for a 5ns clock period and efficient area utilization.

## 🚀 Getting Started

### Environment Setup
Initialize the tool environment (Modelsim and Synopsys) using the provided script:

source setup.sh

### Simulation & Functional Verification
To compile the RTL and run the evaluation suite:

cd run
make build
make eval

Simulation results are generated in run/logs/output.log, while final verification status is located in run/logs/RESULTS.log.

### Logic Synthesis
To synthesize the design and generate timing/area reports:

cd synthesis
make all CLOCK_PER=5

## 📂 Repository Structure
* inputs/ - Contains .dat files for SRAM initialization (Input, Weight, and Expected Results).
* rtl/ - SystemVerilog source files including the core dut.sv and common header files.
* run/ - Simulation directory containing the Makefile and execution logs.
* scripts/ - Utility scripts for data generation or verification.
* synthesis/ - Synopsys Design Compiler environment and synthesis reports.
* testbench/ - Contains tb_top and behavioral SRAM models.

## ⚙️ Hardware Specifications
* Algorithm: Scaled Dot-Product Attention 
* Data Path: 32-bit SRAM-based word access
* Clock Period: 5ns (Synthesized target)
* Area: 9155.1879 um2 (Approximately 8615 logic cells)
