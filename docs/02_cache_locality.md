# Finding #2: Cache Locality Impacts GC Languages

## Summary
Column-oriented data storage improves performance by 38% in Dart, demonstrating that CPU cache effects matter even in garbage-collected languages.

## Benchmark Results

| Data Layout | Access Time | Improvement |
|-------------|------------|-------------|
| Array of arrays | 1053μs | baseline |
| Column-oriented | 653μs | 38% faster |

## The Discovery

Traditional object-oriented design often creates poor cache locality:
```dart
// Poor locality - objects scattered in memory
List<Point> points = [
  Point(x: 1, y: 2),
  Point(x: 3, y: 4),
  Point(x: 5, y: 6),
];

// Good locality - related data contiguous
class Points {
  List<int> x = [1, 3, 5];
  List<int> y = [2, 4, 6];
}
```

## Why It Matters

### CPU Cache Behavior
1. **Cache lines**: CPUs load 64-byte chunks
2. **Spatial locality**: Accessing nearby data is fast
3. **Prefetching**: CPUs predict sequential access

### In Practice
When summing all X coordinates:
- **Objects**: Load entire Point objects (x, y, maybe padding)
- **Columns**: Load only X values (better cache utilization)

## Test Implementation

```dart
// Test setup
const size = 100000;

// Poor cache locality
final scattered = List.generate(size, (i) => [i, i * 2, i * 3]);

// Good cache locality
final packed = {
  'col1': List<int>.filled(size, 0),
  'col2': List<int>.filled(size, 0),
  'col3': List<int>.filled(size, 0),
};

// Accessing first column
// Scattered: Jumps through memory
// Packed: Sequential memory access
```

## Real-World Applications

### Good Candidates for Column Storage
1. **Time series data**: Timestamps, values separate
2. **Particle systems**: Position, velocity, mass columns
3. **Data processing**: CSV/table operations
4. **Graphics**: Vertex buffers

### When Objects Are Better
1. **Complex operations**: Need all fields together
2. **Small datasets**: Cache effects minimal
3. **Polymorphic behavior**: Methods on objects
4. **Domain modeling**: Clarity over performance

## Memory Layout Visualization

```
// Array of Objects (AoS)
[x1,y1,z1] [x2,y2,z2] [x3,y3,z3] ...
    ↓          ↓          ↓
  64 bytes   64 bytes   64 bytes (cache lines)

// Structure of Arrays (SoA)
[x1,x2,x3,x4,x5,x6,x7,x8,...] (all X values)
[y1,y2,y3,y4,y5,y6,y7,y8,...] (all Y values)
    ↓
  Sequential access = better prefetching
```

## Performance Guidelines

### Use Column Storage When
- Processing large datasets
- Accessing subset of fields
- Performing bulk operations
- Memory bandwidth limited

### Implementation Tips
```dart
class ColumnStore<T> {
  final Map<String, List<T>> columns = {};
  
  void addColumn(String name, List<T> data) {
    columns[name] = data;
  }
  
  List<T> getColumn(String name) => columns[name]!;
  
  // Bulk operations on columns
  void mapColumn(String name, T Function(T) fn) {
    final col = columns[name]!;
    for (var i = 0; i < col.length; i++) {
      col[i] = fn(col[i]);
    }
  }
}
```

## Measured Impact

For 100,000 elements, accessing single field:
- Traditional objects: 1053μs
- Column storage: 653μs
- **Cache improvement: 38%**

## Conclusion

Cache-friendly data layouts significantly impact performance even in high-level languages. The CPU doesn't care about your language's abstraction level - it cares about memory access patterns.