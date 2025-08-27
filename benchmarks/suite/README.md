# Cross-Language Benchmark Suite

## Overview

This directory contains standardized benchmark definitions that should be implemented in each language for fair comparison.

## Benchmark Categories

### 1. Allocation Patterns
- **Buffer Reuse**: Pre-allocate vs allocate-per-operation
- **Object Pooling**: Pool vs create-new
- **Arena Allocation**: Arena vs individual allocations
- **In-place Operations**: Mutate vs copy

### 2. Zero-Copy Patterns
- **Type Punning**: Reinterpret vs convert
- **View Slicing**: View vs copy
- **String Building**: Builder vs concatenation
- **Memory Views**: Zero-copy vs allocation

### 3. Cache Locality
- **Row vs Column**: Array-of-structs vs struct-of-arrays
- **Hot-Cold Split**: Separate frequently accessed data
- **Sequential Access**: Linear vs random access
- **Data Packing**: Minimize padding

### 4. Async Patterns
- **Future Creation**: Lazy vs eager
- **Stream Processing**: Buffered vs unbuffered
- **Concurrency**: Batched vs unlimited
- **Scheduling**: Immediate vs deferred

### 5. Concurrency Patterns
- **Work Distribution**: Single vs parallel
- **Worker Pools**: Reused vs created
- **Message Passing**: Overhead measurement
- **Synchronization**: Lock-free vs locked

## Implementation Requirements

Each language implementation MUST:

1. **Measure Time**: Use high-resolution timers
2. **Measure Memory**: Track allocations if possible
3. **Warm Up**: Run warm-up iterations before measuring
4. **Statistical Validity**: Run enough iterations for stable results
5. **Fair Comparison**: Same algorithm, different implementation

## Standard Metrics

### Required Measurements
- **Operations per second**
- **Time per operation (μs)**
- **Memory allocated (bytes)**
- **GC pressure (if applicable)**

### Optional Measurements
- **Cache misses**
- **CPU cycles**
- **Context switches**
- **Page faults**

## Benchmark Template

```pseudocode
benchmark_name: "allocation/buffer_reuse"
iterations: 100000
warmup_iterations: 1000

setup:
  - Create test data
  - Initialize resources

traditional_approach:
  for i in iterations:
    result = allocate_and_process(data)
    
rust_inspired_approach:
  buffer = preallocate(max_size)
  for i in iterations:
    result = process_with_buffer(data, buffer)

measure:
  - Time difference
  - Memory difference
  - Throughput difference
  
report:
  - Speedup factor
  - Memory savings
  - Practical implications
```

## Data Sizes

Standard data sizes for consistency:

- **Small**: 100 elements
- **Medium**: 10,000 elements
- **Large**: 1,000,000 elements
- **Huge**: 100,000,000 elements

## Output Format

```json
{
  "benchmark": "allocation/buffer_reuse",
  "language": "dart",
  "version": "3.0.0",
  "platform": "darwin_arm64",
  "results": {
    "traditional": {
      "ops_per_sec": 1000000,
      "time_per_op_us": 1.0,
      "memory_bytes": 1024
    },
    "rust_inspired": {
      "ops_per_sec": 2400000,
      "time_per_op_us": 0.42,
      "memory_bytes": 512
    },
    "improvement": {
      "speedup": 2.4,
      "memory_reduction": 0.5
    }
  }
}
```

## How to Add a New Language

1. Create `languages/<lang>/benchmarks/`
2. Implement each benchmark category
3. Follow the standard template
4. Output results in JSON format
5. Update the main comparison matrix
6. Document language-specific findings

## Validation

Before accepting results:
1. Verify algorithm equivalence
2. Check statistical significance
3. Confirm platform details
4. Validate measurement methodology
5. Ensure reproducibility