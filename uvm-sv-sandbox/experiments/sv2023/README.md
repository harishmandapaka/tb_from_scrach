# SystemVerilog 2023 experiments

One small, self-contained file per IEEE 1800-2023 feature. Each file has a top module
called `exp_top`, needs no UVM, and prints one line starting with `PASS:` or `FAIL:`.

Run all of them and get a table of what your simulator accepts:

```bash
bash scripts/try_sv2023.sh -s verilator       # or -s xsim
bash scripts/try_sv2023.sh -s xsim array_map  # just one file
```

| File | Feature | What the file checks |
|---|---|---|
| `triple_quoted_string.sv` | `"""..."""` string literals | equals the same text written with `\"` and `\n` |
| `ifdef_expression.sv` | `` `ifdef (A && !B) `` and `` `ifdef (B \|\| A) `` | the right branches are compiled |
| `array_map.sv` | `map()` array method | `{1,2,3}` becomes `{2,3,4}` and `{10,20,30}` |
| `class_final.sv` | `class :final` | a final class builds and runs |
| `method_override_qualifiers.sv` | `:initial`, `:extends`, `:final` on methods | virtual dispatch still returns the leaf result |
| `constructor_default_args.sv` | `new(default, ...)` and `super.new(default)` | base-class fields are set through the forwarded arguments |
| `constraint_override_qualifiers.sv` | `:initial`, `:extends`, `:final` on constraints | solutions follow the overriding constraint |
| `rand_real.sv` | `rand real` | random values stay inside the constraint |
| `dist_default.sv` | `default :/ weight` inside `dist` | values that are not listed also appear |
| `soft_packed_union.sv` | `union soft` | writing the 8-bit member keeps the upper bits |
| `type_this.sv` | `type(this)` | a singleton built with `type(this)` returns one handle |
| `stacktrace.sv` | `$stacktrace` | compiles and runs (the output format is tool-specific) |
| `covergroup_extends.sv` | `covergroup extends` | compiles and runs, adds a coverpoint and a cross |

## Checking that the tool enforces the new rules

`class_final.sv`, `method_override_qualifiers.sv` and `constraint_override_qualifiers.sv`
contain an illegal block guarded by the define `SHOW_ERRORS`:

```bash
bash scripts/try_sv2023.sh -s verilator -d SHOW_ERRORS class_final method_override_qualifiers constraint_override_qualifiers
```

With `SHOW_ERRORS`, a compile error is the correct result for those three files.

## Sources

* IEEE Std 1800-2023, free PDF through the IEEE GET program:
  https://ieeexplore.ieee.org/browse/standards/get-program/page
* K. Shinozuka, "A Subjective Review on IEEE Std 1800-2023", DVCon Japan tutorial:
  https://dvcon-proceedings.org/wp-content/uploads/Tutorial6-A-Subjective-Review-on-IEEE-Std-1800-2023.pdf

The examples here were written for this repository; tool support for these features is
still uneven, which is exactly what the survey script is for.
