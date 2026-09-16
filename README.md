# Acoustic Environment Simulator

A simulation framework for generating large-scale underwater acoustic datasets using the KRAKEN normal-mode propagation model.

The Acoustic Environment Simulator was developed to produce realistic synthetic datasets for machine learning applications in underwater acoustics, including source localization, geoacoustic inversion, and passive acoustic monitoring. The simulator generates thousands of randomized acoustic environments by varying environmental parameters such as sound-speed profiles, sediment properties, source geometry, and ambient noise before simulating acoustic propagation with KRAKEN.

The resulting datasets can be exported for downstream deep learning workflows or post-processed into machine learning formats such as HDF5 or Zarr.

---

## Features

- Large-scale randomized acoustic environment simulation
- Built on the KRAKEN normal-mode propagation model
- Configurable ocean and seabed parameters
- Realistic water-column sound speed variability
- Ambient noise injection with configurable SNR
- Parallel simulation of large datasets
- Automatic saving of simulation outputs
- Python utilities for post-processing and dataset conversion

---

## Repository Structure

```
acoustic-environment-simulator/
├── KRAKEN/
│   KRAKEN acoustic propagation model and documentation
│
├── simulators/
│   MATLAB simulation engines
│   ├── RI_simulator.m
│   └── RI_dense_SSP_simulator.m
│
├── utils/
│   MATLAB helper functions
│
├── python/
│   Python utilities
│   ├── post_process.py
│   ├── h5_to_zarr.py
│   └── utils/
│
├── run_RI_simulator.m
├── run_RI_dense_SSP_simulator.m
└── config_global.yaml
```

---

## Installation

### Requirements

The simulator requires

- MATLAB
- KRAKEN
- Parallel Computing Toolbox (recommended)

Python utilities additionally require

- NumPy
- h5py
- zarr

---

## Running Simulations

Two simulation drivers are included.

### Standard simulator

```matlab
run_RI_simulator.m
```

Generates randomized underwater acoustic environments using parameterized water-column and seabed models.

### Dense sound-speed profile simulator

```matlab
run_RI_dense_SSP_simulator.m
```

Uses dense water-column sound speed profiles generated from measured variability using a Karhunen–Loève Expansion (KLE).

---

## Environmental Parameters

Each simulation randomly samples environmental properties from user-defined ranges.

Examples include

### Water column

- sound speed
- sound-speed profile
- water depth

### Sediment

- sound speed
- attenuation
- layer thickness

### Basement

- sound speed
- attenuation

### Source geometry

- source depth
- source range

### Noise

- ambient noise
- signal-to-noise ratio
- random signal timing

Sampling ranges are specified directly within the simulation scripts.

---

## Sound Speed Profile Generation

Two approaches are supported.

### Parameterized profiles

The standard simulator generates sound-speed profiles using a small number of control points defining the water-column structure.

### Dense profiles

The dense SSP simulator generates physically realistic sound-speed profiles using a Karhunen–Loève Expansion (KLE) derived from observed CTD measurements.

This allows simulated environments to capture realistic oceanographic variability while maintaining statistical consistency with measured data.

---

## Configuration

Global data locations are defined in

```
config_global.yaml
```

The configuration specifies paths for

- simulation output
- ambient noise datasets
- CTD measurements

allowing the same code to run on both local and remote systems.

Simulation parameters such as

- frequency range
- environmental parameter ranges
- SNR
- parallel workers
- output chunk size

are configured within the MATLAB driver scripts.

---

## Output

Simulation results are saved as HDF5 datasets for downstream processing.

Python utilities are provided to

- post-process simulation outputs
- split datasets
- convert HDF5 datasets into Zarr format

making the generated data suitable for machine learning pipelines.

---

## Python Utilities

The `python/` directory contains helper scripts for preparing simulated datasets after generation.

Included utilities support

- dataset post-processing
- HDF5 to Zarr conversion
- dataset splitting

---

## Applications

The simulator was designed to support machine learning research in underwater acoustics, including

- source localization
- geoacoustic inversion
- underwater acoustic classification
- domain adaptation
- uncertainty quantification
- passive acoustic monitoring

Although originally developed for these applications, the generated datasets may be useful for any study requiring large numbers of acoustically realistic underwater environments.

---

## Citation

If you use this simulator in your research, please cite the following.

```bibtex
@software{goldwater2026acousticsimulator,
  author       = {Mark Goldwater},
  title        = {Acoustic Environment Simulator},
  year         = {2026},
  publisher    = {GitHub},
  url          = {https://github.com/whoi-mars/acoustic-environment-simulator},
  note         = {Version accessed Month Day, Year}
}
```
---

## License

See the `LICENSE` file for licensing information.
