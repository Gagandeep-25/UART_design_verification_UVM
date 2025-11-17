# UART Design Verification using UVM Methodology

## 🎯 Project Overview

A comprehensive **design verification project** for a UART (Universal Asynchronous Receiver Transmitter) module using **industry-standard UVM (Universal Verification Methodology)** framework. This project demonstrates advanced verification techniques including constrained random stimulus generation, functional coverage metrics, and systematic testbench architecture.

**Key Focus:** Design Verification & Validation using UVM

## 🔍 Verification Highlights

### Advanced UVM Framework Implementation
- **Constrained Random Stimulus Generation:** Systematic generation of diverse test scenarios
- **Functional Coverage Model:** Comprehensive coverage points tracking critical functionality
- **Scoreboard-Based Verification:** Automated result checking and cross-layer validation
- **Layered Testbench Architecture:** Modular Driver, Monitor, and Scoreboard components
- **Assertion-Based Verification:** Protocol-level and interface-level assertions

### Test Environment Architecture
- **UVM Agent:** Complete agent with driver, monitor, and sequencer
- **Virtual Sequences:** Reusable sequence patterns for diverse test scenarios
- **Configuration Objects:** Flexible testbench configuration for multiple test scenarios
- **Coverage Collectors:** Real-time tracking of functional coverage metrics

## 📋 Design Under Test (DUT) Features

- **UART Transmitter (TX):** Parallel-to-serial conversion with configurable baud rates
- **UART Receiver (RX):** Serial-to-parallel conversion with oversampling and error detection
- **Baud Rate Generator:** Programmable baud rate support (configurable via parameters)
- **Protocol Support:** Standard UART frame format (Start, Data, Parity, Stop bits)
- **Error Detection:** Parity error detection and frame error identification

## 🛠️ Verification Components

### UVM Testbench Structure
```
├── UVM_testbench/
│   ├── top/
│   │   └── uart_tb_top.sv        # Top-level testbench instantiation
│   ├── env/
│   │   ├── uart_env.sv           # UVM Environment configuration
│   │   └── uart_config.sv        # Configuration objects
│   ├── agent/
│   │   ├── uart_driver.sv        # Stimulus generation
│   │   ├── uart_monitor.sv       # Protocol monitoring & coverage
│   │   ├── uart_sequencer.sv     # Transaction sequencing
│   │   └── uart_agent.sv         # Agent instantiation
│   ├── sequences/
│   │   ├── uart_base_seq.sv      # Base sequence definitions
│   │   └── uart_test_seq.sv      # Directed & random test sequences
│   ├── scoreboard/
│   │   └── uart_scoreboard.sv    # Prediction model & result checking
│   └── test/
│       └── uart_tests.sv         # Test classes & test scenarios
├── UART/
│   ├── uart_tx.v                 # Transmitter RTL
│   ├── uart_rx.v                 # Receiver RTL
│   └── baud_gen.v                # Baud rate generator
├── clock_baud_gen/
│   └── clock_generation.sv       # Clock & timing utilities
└── README.md
```

## 🧪 Verification Methodology

### Coverage-Driven Verification
- **Functional Coverage:** Tracks execution of critical design behaviors
  - Data frame configurations
  - Parity settings (Even/Odd)
  - Baud rate variations
  - Error conditions (frame errors, parity mismatches)
- **Code Coverage:** Statement and branch coverage analysis
- **Coverage Metrics:** Automated collection and reporting of verification metrics

### Test Scenarios
1. **Basic Communication Tests**
   - Single byte transmission and reception
   - Multiple sequential transfers
   - Back-to-back transmission validation

2. **Protocol Compliance Tests**
   - Correct start/stop bit insertion and detection
   - Parity generation and verification (Even/Odd)
   - Frame format validation

3. **Error Handling Tests**
   - Framing error detection
   - Parity error detection
   - Receiver overrun conditions

4. **Edge Cases & Boundary Conditions**
   - Minimum/maximum baud rates
   - Various data patterns (0x00, 0xFF, alternating patterns)
   - TX-RX synchronization under stress conditions

5. **Random Constrained Testing**
   - Parameterized random sequences
   - Coverage-guided stimulus generation
   - Stress testing with various configurations

## 📊 Verification Results

- ✅ **All test scenarios passed successfully**
- ✅ **Comprehensive functional coverage achieved**
- ✅ **Protocol compliance verified against UART specifications**
- ✅ **Edge cases and error conditions validated**
- ✅ **TX-RX synchronization verified across baud rates**

## 🚀 Key Verification Techniques Demonstrated

### UVM Framework Mastery
- ✓ UVM base class hierarchy (uvm_object, uvm_component, uvm_transaction)
- ✓ Transaction-level abstraction and modeling
- ✓ UVM testbench phases (build, connect, end_of_elaboration, run, etc.)
- ✓ Factory pattern for configuration and creation

### Verification Competencies
- ✓ **Stimulus Generation:** Constrained random generation using UVM constraints
- ✓ **Prediction & Checking:** Scoreboard-based result verification
- ✓ **Monitoring:** Non-intrusive protocol monitoring and coverage collection
- ✓ **Coverage Analysis:** Functional coverage model design and analysis
- ✓ **Debugging:** Waveform analysis and trace-based debugging
- ✓ **Regression Testing:** Automated test suite execution and reporting

## 📁 File Structure

**RTL Design:**
- `UART/uart_tx.v` - Transmitter module
- `UART/uart_rx.v` - Receiver module  
- `UART/baud_gen.v` - Baud rate generator

**UVM Verification Testbench:**
- `UVM_testbench/uart_tb.sv` - Testbench top module
- `UVM_testbench/uvm_env.sv` - UVM environment & configuration
- `UVM_testbench/TESTBENCH_full.sv` - Complete testbench implementation

**Supporting Infrastructure:**
- `clock_baud_gen/clock_generation.sv` - Clock and timing generation

## 🔧 Simulation Instructions

### Using ModelSim/Questa
```bash
# Compile all design and testbench files
vlog -sv UART/*.v UVM_testbench/*.sv clock_baud_gen/*.sv

# Run simulation
vsim -c top_module -do "run -all; quit"
```

### Using VCS
```bash
# Compile
vcs -full64 -sverilog -debug_all UART/*.v UVM_testbench/*.sv clock_baud_gen/*.sv

# Run
./simv +UVM_TESTNAME=uart_sanity_test
```

### Coverage Report Generation
```bash
# Enable coverage during simulation
vsim -c top_module -coverage -do "run -all; quit"
```

## 📚 Technical Skills Demonstrated

- **Verification Languages:** SystemVerilog, UVM
- **Verification Tools:** ModelSim, Questa, VCS
- **Methodologies:** Coverage-Driven Verification, Constrained Random Testing
- **Design Patterns:** Layered Testbench Architecture, Factory Pattern
- **Languages & Protocols:** UART protocol, synchronous/asynchronous interfaces

## 📖 References

- **IEEE 1800-2017:** SystemVerilog Standard
- **UVM 1.2 Class Reference:** Universal Verification Methodology
- **UART Protocol Specifications:** Serial Communication Standards
- **Coverage-Driven Verification:** DVCon Best Practices

## 📄 License

MIT License

## 👤 Author

Gagandeep-25

---

### 🎓 For Recruiters

This project demonstrates hands-on expertise in:
- **Design Verification:** Complete verification flow from testbench architecture to coverage analysis
- **UVM Framework:** Professional-grade testbench development using industry-standard methodology
- **SystemVerilog:** Advanced language features for verification
- **Verification Best Practices:** Modular design, reusability, and maintainability
- **Problem-Solving:** Systematic identification and resolution of design issues

Ideal for roles in **Design Verification Engineering**, **Verification IP Development**, and **Quality Assurance for Digital Design**.
