# VHDL Hardware Module: Sequence Filler with Credibility Values

Hardware component described in **VHDL**, developed as an individual project for the **Digital Logic Design** course (Reti Logiche, final project) at **Politecnico di Milano**.

## The problem

The module receives a sequence of K integers (0–255) stored in memory, where `0` is not a real value but means "missing data". It has to:

- replace every `0` with the **last valid value** read before it;
- write, right after each value, a **credibility value C**: 31 for a valid number, decreased by one for each consecutive missing value, never going below 0.

Example (value, credibility):

```
Input:  (12,–) (0,–) (0,–) (7,–) (0,–)
Output: (12,31) (12,30) (12,29) (7,31) (7,30)
```

## Design

The component (`project_reti_logiche`) interfaces with an external memory that reads or writes one 8-bit word per clock cycle.

| Signal | Direction | Description |
|---|---|---|
| `i_clk`, `i_rst` | in | Clock and asynchronous reset |
| `i_start` | in | Starts the processing |
| `i_add` (16 bit) | in | Address of the first element of the sequence |
| `i_k` (10 bit) | in | Number of elements in the sequence |
| `o_done` | out | Signals that processing is complete |
| `o_mem_addr`, `o_mem_data`, `i_mem_data`, `o_mem_we`, `o_mem_en` | in/out | Memory interface |

The behaviour is implemented as a **finite state machine with 9 states** in a single synchronous process:

```
IDLE → WAIT_R_D → READ → EVALUATE ─┬─(value = 0)→ WAIT_W_D → WRITE_D ─┐
                   │               └─(value ≠ 0)───────────────────────┴→ WAIT_W_C → WRITE_C → WAIT_R_D
                   └─(sequence finished)→ DONE → IDLE
```

When a value is valid, the machine skips the unnecessary rewrite of the same value and writes only its credibility, saving memory accesses. Execution time grows linearly with the length of the sequence.

## Verification

The design is synthesisable and passes all tests in **behavioural, post-synthesis functional and post-synthesis timing** simulation with Xilinx Vivado. Besides the reference testbench (`project_tb.vhd`), the following corner cases were tested:

- asynchronous reset at any point during processing;
- sequence starting with `0` (credibility must be 0);
- more than 31 consecutive missing values (credibility must stay at 0);
- two different sequences processed one after the other without a reset.

## Files

| File | Content |
|---|---|
| `10702465.vhd` | VHDL source of the component |
| `project_tb.vhd` | Testbench |
| `10702465.pdf` | Project report (in Italian) |

## Author

**Riccardo Zonno**, Computer Engineering, Politecnico di Milano
