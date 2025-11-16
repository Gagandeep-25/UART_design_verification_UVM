# UART Design and Verification

## Overview

This repository contains the design and verification of a **Universal Asynchronous Receiver Transmitter (UART)** using RTL and SystemVerilog. The project covers both the transmitter and receiver modules, implemented in Verilog/SystemVerilog, and verified using a UVM/testbench methodology.

## Features

- UART **Transmitter** and **Receiver RTL**
- **Baud Rate Generator**
- **Parity Handling:** Even/Odd parity support
- **Configurable Data Frame:** 8-bit data, start/stop bit, parity bit
- **SystemVerilog/UVM testbench** for functional coverage and random verification
- **Simulation Results** (waveforms/documentation)

## Architecture

- **Transmitter**
    - Parallel-to-Serial Data
    - Start, Parity, Stop Bit insertion
    - FSM for state management
- **Receiver**
    - Serial-to-Parallel Data conversion
    - Start, Parity, Stop Bit detection
    - FSM with oversampling and error checking
- **Baud Rate Generator**
    - Generates clock enables for accurate baud timing

## File Structure

```
├── UART/
│   ├── uart_tx.v
│   ├── uart_rx.v
│   ├── baud_gen.v
├── UVM_testbench/
│   ├── uart_tb.sv
│   ├── uvm_env.sv
├── clock_baud_gen/
│   ├── clock_generation.sv
├── README.md
```

## Simulation

To run the testbench and view results, use your preferred EDA tools (ModelSim, Questa, VCS, etc.).

Example:
```sh
vlog UART/*.v UVM_testbench/*.sv
vsim uart_tb
```

## Verification Methodology

- Used **constrained random stimulus** and **functional coverage** in UVM.
- Checked edge cases: framing errors, parity mismatch, overrun errors.
- Verified transmitter and receiver synchronization.
- Tested various baud rates and data configurations.

## Results

- All test cases passed successfully
- Comprehensive functional coverage of transmit and receive operations
- Verified protocol compliance with UART standard specifications

## Key Verification Components

- **Driver:** Sends stimulus to DUT
- **Monitor:** Observes DUT outputs
- **Scoreboard:** Compares expected vs actual results
- **Coverage:** Tracks functional coverage metrics

## References

- UART Protocol Documentation
- SystemVerilog UVM Class Reference
- IEEE 1800-2017 Standard

## License

MIT License

## Author

Gagandeep-25
