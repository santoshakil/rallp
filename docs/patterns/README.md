# Rust Patterns for Performance

This directory contains pattern documentation that applies across all programming languages.

## Core Patterns

### 1. [Allocation Patterns](allocation.md)
- Buffer reuse strategies
- Memory pooling techniques
- Arena allocation
- **Expected gains**: 2-3x performance improvement

### 2. [Zero-Copy Patterns](zero_copy.md)
- Type punning and reinterpretation
- View-based processing
- Copy-on-write strategies
- **Expected gains**: Up to 15x for specific operations

### 3. [Cache Locality](cache_locality.md)
- Data structure layout optimization
- Column-oriented vs row-oriented storage
- Hot/cold data separation
- **Expected gains**: 30-40% improvement

### 4. [Async Patterns](async.md)
- Lazy evaluation strategies
- Stream buffering and batching
- Scheduling optimizations
- **Expected gains**: 5-14x for async operations

### 5. [Concurrency Patterns](concurrency.md)
- When NOT to parallelize
- Worker pool designs
- Message passing overhead
- **Warning**: Often slower than single-threaded!

### 6. [Ownership Patterns](ownership.md)
- Why ownership doesn't translate to GC languages
- Alternative safety patterns
- When clarity beats performance
- **Warning**: Usually adds overhead in GC languages

## Pattern Applicability Matrix

| Pattern | Dart | Python | JavaScript | Go | Java | C# |
|---------|------|--------|------------|-----|------|----|
| Buffer Reuse | ✅ 2.4x | 🔄 | 🔄 | 🔄 | 🔄 | 🔄 |
| Zero-Copy | ✅ 15x | 🔄 | 🔄 | 🔄 | 🔄 | 🔄 |
| Cache Locality | ✅ 1.38x | 🔄 | 🔄 | 🔄 | 🔄 | 🔄 |
| Async Optimization | ✅ 14x | 🔄 | 🔄 | 🔄 | 🔄 | 🔄 |
| Concurrency | ❌ 4x slower | 🔄 | 🔄 | 🔄 | 🔄 | 🔄 |

Legend:
- ✅ Tested and verified with performance gains
- ❌ Tested and found to be counterproductive
- 🔄 Pending research

## How to Read These Patterns

1. **Start with the theory** - Understand why the pattern works in Rust
2. **Check language applicability** - See if your language supports the pattern
3. **Review benchmarks** - Look at actual performance data
4. **Apply selectively** - Use only where profiling shows bottlenecks

## Contributing

To add results for a new language:
1. Implement the benchmark suite in your language
2. Run the standardized tests
3. Document findings in `languages/<your-language>/README.md`
4. Update the applicability matrix above