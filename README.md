# fuel-brute
CRC32 Brute Force Solver For FUEL

<sup>This repository is a relative of the main [FMTK repository](https://github.com/widberg/fmtk).</sup>

## Notice

This project is a reverse engineering playground for crc32 algorithms more than it is a set of tools. I have taken a break from working on this to investigate meta data available in FUEL's DPC archive format. Hopefully this investigation can help uncover hints about the directory structure and lead to a "strength in numbers" solution.

Calculating a crc32 collision from a target hash is trivial; calculating the original target string used to generate the target hash with only the target hash is impossible. For this project to be useful to you, you will need to divise a system of scoring your confidence in the potential target strings. Gather as much context as possible and minimize the possibility space. Smaller dictionary is better. Fewer wildcards in the pattern is better. The prefix and suffix are free irregardless of length. Best of luck.

## Files

The general flow of running the system is:

1. Generate your dictionary and hash files
2. Run either cpu or cuda
3. Coagulate the result
4. Hand verify the target string collisions

### dictc

Generate a dictionary file from a text document.

A dictionary file contains information about legal sequences of characters that may appear in a target string.

### hashc

Generate hash file from a text document.

A hash file contains information about target crc32s.

### coagulate

Transpose the output from cpu or cuda back into a human readable text format.

### cpu

Cpu middle end.

### cuda

Cuda middle end.

## Optimizations

Optimizations used in the system:

* Prefix addition
* Suffix subtraction
* Dictionary
* Table driven

## Getting Started

### Prerequisites

* CMake
* Cuda
* OpenCL

### Checkout

```sh
git clone https://github.com/widberg/fuel-brute.git
cd fuel-brute
```

### Build

```sh
mkdir build
cd build
cmake ..
cmake --build .
```
