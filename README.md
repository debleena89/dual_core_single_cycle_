# Folder Structure

```sh
.
├── Dual_core_2_ways_single_cycle.v ........ DUT
├── explorer.ebv ........................... Configuration exported from online BRISC-V explorer
├── instructions1.dat ...................... hex instruction file currently being loaded by TB
├── instructions2.dat ...................... sample instruction file containing different instructions for testing
└── tb_Dual_core_2_ways_single_cycle.v ..... TB
```

# Usage Instructions

1. Set the path name to instructions file in TB (tb_Dual_core_2_ways_single_cycle.v)
2. Run simulation on the TB.
