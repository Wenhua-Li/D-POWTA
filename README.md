# D-POWTA: Dynamic Phase-Ordered Weapon Target Assignment

<div align="center">

![MATLAB](https://img.shields.io/badge/MATLAB-R2020b+-orange) ![License](https://img.shields.io/badge/License-MIT-blue) ![Research](https://img.shields.io/badge/Research-Optimization-green)

**An Evolutionary Algorithm for Dynamic Weapon-Target Assignment with Knowledge Guidance**

</div>

---

## Overview

**D-POWTA** addresses the *Dynamic Phase-Ordered Weapon Target Assignment* problem, a challenging multi-stage combinatorial optimization problem in air defense systems. This repository contains the implementation of **KG-DREA** (Knowledge-Guided Differential Evolution Algorithm), along with benchmark instances and comparison algorithms.

### Key Features

- **Multi-phase optimization**: Handles sequential decision-making across multiple time phases
- **Knowledge-guided evolution**: Incorporates domain knowledge to accelerate convergence
- **Robustness evaluation**: Uses RMI (Robustness Measure Index) for solution reliability assessment
- **Constraint handling**: Preprocessing and repair mechanisms for complex military operation constraints
- **Comprehensive benchmarks**: 10 test instances with varying complexity

---

## Problem Description

The Weapon Target Assignment (WTA) problem is a classic optimization problem in military operations research. The dynamic variant (D-POWTA) considers:

```
                    ┌─────────────────────────────────────┐
  Targets ────────► │  Phase 1  →  Phase 2  →  ...  →  Phase T  │
                    └─────────────────────────────────────┘
                          ↓            ↓                      ↓
                     Weapons       Weapons               Weapons
                     Allocated     Allocated             Allocated
```

**Key Constraints**:
- Radar detection probability thresholds
- Weapon engagement envelopes (range, reaction time)
- Limited ammunition per weapon platform
- Strike window timing constraints

---

## Algorithm: KG-DREA

The Knowledge-Guided Differential Evolution Algorithm (KG-DREA) combines:

1. **Differential Evolution** base operators (mutation, crossover, selection)
2. **Knowledge Base** tracking successful allocation patterns
3. **Niche Preservation** via Hamming distance sharing
4. **RMI-based Selection** for robustness

```
┌──────────────────────────────────────────────────────────────┐
│                    KG-DREA Framework                         │
├──────────────────────────────────────────────────────────────┤
│  for each phase t = 1 to T:                                 │
│    ├── Constraint Preprocessing (A_jt construction)         │
│    ├── Knowledge-Guided Population Initialization            │
│    ├── while g < G_max:                                     │
│    │   ├── Knowledge-Guided Mutation & Crossover             │
│    │   ├── Niche-based Environmental Selection              │
│    │   └── Update fitness history                           │
│    ├── ε-Approximate Solution Set Construction              │
│    ├── RMI Evaluation & Best Solution Selection              │
│    └── Knowledge Base Update                                 │
└──────────────────────────────────────────────────────────────┘
```

### Key Parameters

| Parameter | Default | Description |
|-----------|--------|-------------|
| `N` | 100 | Population size |
| `G_max` | 100 | Maximum generations |
| `δ` | 3 | Niche radius |
| `p_crossover` | 0.8 | Crossover probability |
| `p_mut` | 0.1 | Mutation probability |
| `p_guided` | 0.7 | Knowledge guidance probability |
| `S` | 50 | RMI Monte Carlo samples |

---

## Project Structure

```
D-POWTA/
├── _core/                      # Core algorithm modules
│   ├── generate_instances.m    # Instance generator
│   ├── solve_kgdrea.m          # KG-DREA solver
│   ├── constraint_preprocess.m # Constraint preprocessing
│   ├── encoding_decode.m       # TC-FCE encoding
│   ├── knowledge_manager.m     # Knowledge base
│   └── rmi_evaluator.m         # Robustness evaluation
├── _operators/                 # Evolutionary operators
│   ├── crossover.m             # Uniform crossover
│   ├── mutation.m              # Knowledge-guided mutation
│   ├── repair_constraints.m    # Constraint repair
│   └── niche_selection.m       # Niche selection
├── _visualization/             # Visualization tools
│   ├── plot_instance.m         # Instance scene plotting
│   ├── plot_allocation.m      # Allocation visualization
│   ├── plot_convergence.m     # Convergence curves
│   └── plot_robustness.m      # Robustness metrics
├── _utils/                     # Utility functions
│   ├── load_instance.m        # Instance loader
│   └── compute_distance.m     # Distance calculations
├── instances/                  # Test instances (I1.mat - I10.mat)
├── results/                    # Output results
├── competitor algorithms/      # Comparison algorithms (GA, HA, LKEA)
├── main.m                     # Main entry point
├── demo.m                     # Quick demo script
└── run_all_instances.m        # Batch runner
```

---

## Quick Start

### 1. Solve Specific Instance

```matlab
TestInstanceNum = 1;  % Change to 1-10 for different instances
main
```

### 2. Compare Algorithms

```matlab
cd 'competitor algorithms'
HA % Run HA
GA % Run GA
LKEA % Run LKEA
run_all_instances  % Run KG-DREA on all instances
```

### 3. Run all instances

```matlab
run_all_instances  % Run KG-DREA on all instances
```

---

## Test Instances

The benchmark suite includes 10 instances with increasing complexity:

| Instance | Targets | Weapons | Radars | Phases | Complexity |
|----------|---------|---------|--------|--------|------------|
| I1 | 5 | 4 | 3 | 2 | ★☆☆☆☆ |
| I2 | 6 | 5 | 4 | 3 | ★★☆☆☆ |
| I3 | 8 | 6 | 4 | 4 | ★★☆☆☆ |
| I4 | 10 | 6 | 5 | 5 | ★★★☆☆ |
| I5 | 12 | 8 | 6 | 8 | ★★★☆☆ |
| I6 | 15 | 8 | 6 | 5 | ★★★★☆ |
| I7 | 18 | 10 | 8 | 10 | ★★★★☆ |
| I8 | 20 | 10 | 8 | 6 | ★★★★★ |
| I9 | 25 | 12 | 8 | 8 | ★★★★★ |
| I10 | 30 | 12 | 10 | 10 | ★★★★★ |

---

## Results Visualization

### Instance Scene
![I1 Instance](results/I1_instance.png) ![I1 Instance](results/I2_instance.png)

### Convergence Curves
![I1 Convergence](results/I9_convergence.png)

### Allocation Visualization
![I1 Phase 1 Allocation](results/I2_phase1_allocation.png) ![I1 Phase 2 Allocation](results/I2_phase2_allocation.png)

### Robustness Analysis
![I1 Robustness](results/I10_robustness.png)

### Performance Comparison
![Performance](results/I1_performance.png)

---

## Competitor Algorithms

For benchmarking, this repository also includes three competitor algorithms:

| Algorithm | Description | Reference |
|-----------|-------------|-----------|
| **GA** | Genetic Algorithm with standard operators | Classical baseline |
| **HA** | Heuristic Algorithm with greedy strategies | Rule-based approach |
| **LKEA** | Local Knowledge Evolutionary Algorithm | Similar knowledge-guided approach |

---

## Data Structure

### Instance Structure

```matlab
instance = struct(
    'name',           % Instance name (e.g., 'I1')
    'n',              % Total number of targets
    'm',              % Number of weapon platforms
    'L',              % Number of radars
    'T_total',        % Total number of phases

    % Weapon parameters
    'weapon_x',       % Weapon X coordinates
    'weapon_y',       % Weapon Y coordinates
    'R_max',          % Maximum engagement range
    'tau_react',      % Reaction time
    'ammo',           % Ammunition capacity

    % Radar parameters
    'radar_x',        % Radar X coordinates
    'R_radar',        % Detection range
    'lambda',         % Radar performance parameter

    % Target parameters
    'targets',        % Array of target structures

    % Precomputed matrices
    'P_ij',           % Kill probability matrix
    'eta_j',          % MRFDQI detection quality index
    'd_ij'            % Weapon-target distance
);
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- Special thanks to the research group for valuable discussions
- Instance generation methodology based on related research in the field

---

<div align="center">

**If this project helps your research, please give it a ⭐**

</div>
