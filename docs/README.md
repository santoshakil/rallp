# Research Documentation

## Findings Overview

This directory contains detailed analysis of applying Rust patterns to high-level languages.

### Core Findings

1. **[Allocation Patterns](01_allocation_patterns.md)** - 2.4x performance improvement
   - Buffer reuse eliminates GC pressure
   - In-place operations avoid temporaries
   - Single-pass algorithms reduce iterations

2. **[Cache Locality](02_cache_locality.md)** - 38% performance improvement
   - Column-oriented storage beats objects
   - CPU cache effects matter in all languages
   - Memory layout impacts even GC languages

3. **[Ownership Overhead](03_ownership_overhead.md)** - 66% overhead penalty
   - Runtime ownership tracking hurts performance
   - GC already provides memory safety
   - Ownership patterns only help API design

4. **[Concurrency Overhead](04_concurrency_overhead.md)** - 4-6x slower than single-threaded!
   - Isolate communication dominates performance
   - Parallelization often hurts for <1MB data
   - Worker pools only reduce overhead by 33%

5. **[Zero-Copy Patterns](05_zero_copy_patterns.md)** - Up to 15x performance gains!
   - Type punning provides 15x speedup
   - View slicing is 7x faster
   - Object pooling eliminates GC pressure

6. **[Async Patterns](06_async_patterns.md)** - Up to 14x faster async operations!
   - Microtask scheduling is 14x faster
   - Buffered streams provide 5x speedup
   - Lazy futures are 1.5x faster

### Summary Statistics

| Optimization | Performance Gain | Complexity | When to Use |
|-------------|------------------|------------|-------------|
| Type punning | 15x | Low | Binary data parsing |
| Microtask scheduling | 14x | Low | CPU-bound async work |
| View slicing | 7x | Low | Array segments |
| Buffered streams | 5x | Low | Stream processing |
| StringBuffer | 3.7x | Low | String building |
| Batched concurrency | 3.2x | Medium | Parallel operations |
| Object pooling | 2.7x | Medium | Temporary objects |
| Buffer reuse | 2.4x | Low | Hot paths |
| Lazy futures | 1.57x | Low | Avoiding scheduling |
| Cache locality | 1.38x | Medium | Large datasets |
| Arena allocation | 1.21x | Medium | Many small allocs |
| Ownership patterns | 0.66x (slower) | High | Never for performance |
| Isolate parallelism | 0.25x (4x slower!) | High | Only for >1MB data |

### Key Takeaway

**Allocation discipline > Ownership rules**

Focus on:
- Reducing allocations
- Improving cache usage
- Processing in-place

Avoid:
- Runtime ownership tracking
- Unnecessary copying
- Complex ownership models

## Reading Order

For best understanding:
1. Start with [Allocation Patterns](01_allocation_patterns.md) - biggest impact
2. Then [Cache Locality](02_cache_locality.md) - hardware fundamentals
3. Finally [Ownership Overhead](03_ownership_overhead.md) - what not to do

## Reproducibility

All findings based on benchmarks in `/benchmarks/`
- Platform: Darwin 25.0.0
- Test size: 1,000,000 iterations
- List size: 1,000 elements

Run yourself: `dart benchmarks/01_allocation_patterns.dart`