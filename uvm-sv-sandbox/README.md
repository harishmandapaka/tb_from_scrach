# uvm-sv-sandbox

A very small UVM and SystemVerilog testbench for trying UVM and new SystemVerilog
(IEEE 1800-2023) syntax on **free simulators**. Everything here is public: the code was
written from scratch against the public IEEE 1800 (SystemVerilog) and IEEE 1800.2 (UVM)
standards, and no third-party code is stored in the repository.

- **DUT:** a registered 8-bit adder (`rtl/adder.sv`). `a`, `b` and `in_valid` go in;
  `sum` (9 bits, keeps the carry) and `out_valid` come out one clock later. No ready signal.
- **Testbench:** one agent (sequencer, driver, monitor), a scoreboard with a reference
  model, an environment and two tests.
- **Self-checking:** every run ends with `RESULT: PASS` or `RESULT: FAIL`. The regression
  also builds a deliberately broken DUT to prove that the scoreboard catches bugs.

## Layout

```text
uvm-sv-sandbox/
├── rtl/adder.sv                DUT (define INJECT_BUG for a broken version)
├── tb/
│   ├── add_if.sv               interface: the only link to the DUT pins
│   ├── add_pkg.sv              UVM classes: item, sequences, sequencer, driver,
│   │                           monitor, agent, scoreboard, env, tests
│   └── tb_top.sv               clock, reset, DUT, interface, run_test()
├── experiments/sv2023/         one small file per IEEE 1800-2023 feature
├── scripts/
│   ├── setup.sh                downloads the public UVM library; can build Verilator
│   ├── run.sh                  builds and runs one test, then prints PASS/FAIL
│   ├── regress.sh              2 tests that must pass + 1 bug that must be caught
│   ├── check_log.sh            decides PASS/FAIL from a log
│   ├── try_sv2023.sh           which 2023 features does my simulator accept?
│   └── make_playground.sh      2-file version for EDA Playground
├── .github/workflows/ci.yml    runs the regression on Verilator for every push
├── Makefile                    short names for the scripts (make help)
└── LICENSE, NOTICE, README.md
```

## Free simulators

| Simulator | Cost | UVM | Runs on |
|---|---|---|---|
| [Verilator](https://github.com/verilator/verilator) | Open source | Accellera IEEE 1800.2-2020.3.1, compiled from source | Linux, macOS, Windows (WSL) |
| [Vivado simulator (xsim)](https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Universal-Verification-Methodology-UVM-Support) | Included in the free Vivado ML Standard Edition | UVM 1.2, precompiled | Linux (WSL on Windows) |
| [EDA Playground](https://www.edaplayground.com) | Free account | UVM 1.1d, 1.2, IEEE 1800.2-2017 | Web browser |

Verilator could compile the unmodified Accellera UVM library only from late 2025
([Antmicro, October 2025](https://antmicro.com/blog/2025/10/support-for-upstream-uvm-2017-in-verilator)),
so distribution packages are usually too old; `make verilator-build` builds the latest one.
At that time Verilator only parsed covergroups (no functional coverage), which is why this
testbench has none; `make try-sv2023` shows what your build accepts.

## Quick start

### Verilator (open source)

```bash
# 1. Build tools (Ubuntu, Debian or WSL; use your package manager elsewhere)
sudo apt-get install -y git autoconf make g++ perl python3 bison flex libfl-dev help2man z3
# 2. One time: build the latest Verilator into third_party/ and download UVM
make verilator-build
# 3. Run
make regress SIM=verilator
```

### Vivado simulator

```bash
source <Vivado install folder>/settings64.sh    # puts xvlog, xelab and xsim on PATH
make regress SIM=xsim
```

No setup step is needed: xsim ships with a precompiled UVM 1.2.

### EDA Playground (nothing to install)

```bash
make playground        # or: bash scripts/make_playground.sh
```

Then paste the two files it writes, as the script explains.

A good regression ends like this:

```text
Regression summary (simulator: verilator, seed: 1)
  PASS  add_test
  PASS  add_corner_test
  PASS  deliberate DUT bug is caught
ALL PASSED
```

## Everyday commands

| Command | What it does |
|---|---|
| `make run TEST=add_corner_test SEED=7` | one test, one seed (default simulator: Verilator) |
| `make run SIM=xsim VERBOSITY=UVM_HIGH` | more messages; the driver prints every item at `UVM_HIGH` |
| `make run BUG=1` | builds the broken DUT; counts as PASS only if the scoreboard catches it |
| `make run WAVES=1` | also writes `build/<sim>/clean_waves/waves.vcd` |
| `make regress SIM=xsim` | `add_test`, `add_corner_test` and the bug check |
| `make try-sv2023 SIM=verilator` | which SystemVerilog 2023 features the simulator accepts |
| `make clean` | deletes `build/` |

No `make`? Every target is a script, for example
`bash scripts/run.sh -s xsim -t add_corner_test -r 7`. Add `-h` to any script for its
options. Logs are in `build/logs/`.

## How PASS/FAIL is decided

`scripts/check_log.sh` reads the log. A normal run passes only when:

1. the test printed `*** TEST PASSED ***` (the test checks the UVM error count in its report phase),
2. the UVM report summary shows `UVM_ERROR : 0` and `UVM_FATAL : 0`, and
3. the log shows that the requested test is the one that ran.

A `BUG=1` run passes only when the test printed `*** TEST FAILED ***` with at least one `UVM_ERROR`.

## The testbench

```text
 add_seq / add_corner_seq
          |
   add_sequencer --> add_driver --> add_if --> adder (DUT)
                                      |
                                 add_monitor
                                  |       |
                               in_ap    out_ap
                                  \       /
                                add_scoreboard   (reference model: a + b, compared in order)

 add_env holds the agent and the scoreboard; add_test and add_corner_test build add_env.
```

| Class | Role |
|---|---|
| `add_item` | one addition: random `a` and `b`; the monitor fills in `sum` |
| `add_seq` | 20 random items; `pick()` decides how each item is randomized |
| `add_corner_seq` | overrides `pick()` to use only 0, 1, 127 or 128, and 255 |
| `add_driver` | drives one item for one clock with `in_valid` high, then one idle clock |
| `add_monitor` | sends accepted inputs and produced results to the scoreboard |
| `add_scoreboard` | predicts `a + b` for each input and compares results in order; also flags unexpected and missing results |
| `add_test` | runs `add_seq`; prints `TEST PASSED` or `TEST FAILED` from the UVM error count |
| `add_corner_test` | same flow, but a factory type override swaps in `add_corner_seq` |

## Try SystemVerilog 2023 features

```bash
make try-sv2023 SIM=verilator          # or: bash scripts/try_sv2023.sh -s verilator
```

This builds each file in `experiments/sv2023/` on its own and prints one line per feature:
`works`, `compiles, wrong result`, `compiles, no result line` or `not accepted`.
See [experiments/sv2023/README.md](experiments/sv2023/README.md) for the list of features,
and for `-d SHOW_ERRORS`, which checks that the tool enforces the new `:final`, `:initial`
and `:extends` rules.

## Try another UVM version

- Verilator compiles UVM from source, so you choose the version:
  `UVM_VER=1800.2-2017-1.0 bash scripts/setup.sh --force-uvm` (default: 1800.2-2020.3.1).
- APIs that Accellera proposes for the next IEEE 1800.2 are tagged `@uvm-contrib` in the
  source: `grep -rn "@uvm-contrib" third_party/uvm/src`. They are not in the standard yet,
  so code that uses them may not work with other UVM libraries.
- xsim always uses its built-in UVM 1.2; EDA Playground lets you pick the library.
- The testbench uses only UVM calls found in both UVM 1.2 and IEEE 1800.2, so it runs on all of them.

## Add your own test

1. In `tb/add_pkg.sv`, extend `add_seq` and override `pick()` (copy `add_corner_seq`).
2. Extend `add_test` and, in `build_phase`, call
   `add_seq::type_id::set_type_override(<your_seq>::get_type());` before
   `super.build_phase(phase);` (copy `add_corner_test`).
3. Run it with `make run TEST=<your_test>`, then add a `step` line for it in `scripts/regress.sh`.

## Other simulators

Compile these files in this order with the simulator's UVM library:
`rtl/adder.sv tb/add_if.sv tb/add_pkg.sv tb/tb_top.sv`. The top module is `tb_top`.
Choose the test with `+UVM_TESTNAME=add_test` or `+UVM_TESTNAME=add_corner_test`, and
define `INJECT_BUG` for the broken DUT. Then judge the log with
`bash scripts/check_log.sh <log> pass add_test`.

The Questa-Altera FPGA Starter Edition is another no-cost option (it needs a free license
from Altera). Check that your edition supports class-based SystemVerilog and UVM before
relying on it.

## Continuous integration

`.github/workflows/ci.yml` runs on every push and pull request on GitHub. It installs the
build tools, builds Verilator (cached per Verilator commit, so not every run rebuilds it),
downloads UVM, runs `scripts/regress.sh -s verilator`, runs the 2023 feature survey for
information, and keeps the logs as a downloadable artifact.

## Publish it to your own Git repository

```bash
cd uvm-sv-sandbox
chmod +x scripts/*.sh                 # only needed if the unzip tool dropped the execute bits
git init -b main
git add .
git commit -m "UVM and SystemVerilog sandbox"
git remote add origin <your-repository-url>
git push -u origin main
```

`build/` and `third_party/` are git-ignored, so downloads and build outputs are never
committed. Before you make the repository public, run `make regress` on every simulator
you mention.

## Troubleshooting

| Message | Fix |
|---|---|
| `UVM sources not found` | `make setup` |
| `'verilator' is not on PATH` | `make verilator-build`, or put your own recent Verilator on PATH |
| Verilator errors inside `uvm_pkg.sv` | Verilator is too old for UVM. `verilator --version` shows the version; `make verilator-build` builds the latest |
| `randomize() failed` on Verilator | install `z3` (Verilator uses it to solve constraints), then rebuild with `make verilator-build` |
| `'xvlog' is not on PATH` | `source <Vivado install folder>/settings64.sh` |
| `$'\r': command not found` | the scripts got Windows line endings: `sed -i 's/\r$//' scripts/*.sh` |
| `expected test 'add_corner_test' to run` | the simulator ignored `+UVM_TESTNAME`; check the run command in `scripts/run.sh` |

## Sources

- IEEE 1800-2023 (SystemVerilog), free through the IEEE GET program:
  https://ieeexplore.ieee.org/browse/standards/get-program/page
- Accellera UVM reference library (IEEE 1800.2): https://github.com/accellera-official/uvm-core
  (the setup script downloads the release tarball from https://www.accellera.org/images/downloads/standards/uvm/)
- Verilator with UVM: https://github.com/antmicro/verilator-uvm-example
- Vivado simulator UVM support (UG900):
  https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Universal-Verification-Methodology-UVM-Support
- SystemVerilog 2023 feature examples (DVCon Japan tutorial):
  https://dvcon-proceedings.org/wp-content/uploads/Tutorial6-A-Subjective-Review-on-IEEE-Std-1800-2023.pdf

## License

Apache-2.0: see [LICENSE](LICENSE) and [NOTICE](NOTICE). Downloads in `third_party/` keep
their own licenses.
