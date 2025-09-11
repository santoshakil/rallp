import 'dart:typed_data';
import 'dart:math' as math;

const iterations = 10000;
const dataSize = 10000;

class UnpredictableBranches {
  int sumWithRandomBranches(List<int> data) {
    var sum = 0;
    for (final value in data) {
      if (value > 128) {
        sum += value;
      }
    }
    return sum;
  }
  
  int processWithManyBranches(List<int> data) {
    var result = 0;
    for (final value in data) {
      if (value < 25) {
        result += value * 2;
      } else if (value < 50) {
        result += value * 3;
      } else if (value < 75) {
        result += value * 4;
      } else if (value < 100) {
        result += value * 5;
      } else if (value < 125) {
        result += value * 6;
      } else if (value < 150) {
        result += value * 7;
      } else if (value < 175) {
        result += value * 8;
      } else if (value < 200) {
        result += value * 9;
      } else {
        result += value * 10;
      }
    }
    return result;
  }
  
  List<int> filterWithBranches(List<int> data) {
    final result = <int>[];
    for (final value in data) {
      if (value % 2 == 0) {
        result.add(value);
      }
    }
    return result;
  }
  
  int nestedConditionals(List<int> data) {
    var count = 0;
    for (final value in data) {
      if (value > 50) {
        if (value < 150) {
          if (value % 2 == 0) {
            count++;
          }
        }
      }
    }
    return count;
  }
}

class PredictableBranches {
  int sumWithSortedBranches(List<int> sortedData) {
    var sum = 0;
    for (final value in sortedData) {
      if (value > 128) {
        sum += value;
      }
    }
    return sum;
  }
  
  int processWithLookupTable(List<int> data) {
    final multipliers = [2, 3, 4, 5, 6, 7, 8, 9, 10, 10];
    var result = 0;
    
    for (final value in data) {
      final index = math.min(value ~/ 25, 9);
      result += value * multipliers[index];
    }
    return result;
  }
  
  List<int> filterBranchless(List<int> data) {
    final result = <int>[];
    for (final value in data) {
      final isEven = 1 - (value & 1);
      if (isEven == 1) {
        result.add(value);
      }
    }
    return result;
  }
  
  int flattenedConditionals(List<int> data) {
    var count = 0;
    for (final value in data) {
      final inRange = value > 50 && value < 150;
      final isEven = (value & 1) == 0;
      count += (inRange && isEven) ? 1 : 0;
    }
    return count;
  }
}

class BranchlessPatterns {
  int conditionalMove(List<int> data) {
    var sum = 0;
    for (final value in data) {
      final addValue = value > 128 ? value : 0;
      sum += addValue;
    }
    return sum;
  }
  
  int minMaxBranchless(int a, int b) {
    final diff = a - b;
    final sign = (diff >> 31) & 1;
    return a - sign * diff;
  }
  
  int absBranchless(int value) {
    final mask = value >> 31;
    return (value + mask) ^ mask;
  }
  
  List<int> selectBranchless(List<int> data, bool condition) {
    final result = <int>[];
    final multiplier = condition ? 1 : 0;
    
    for (final value in data) {
      final selected = value * multiplier;
      if (selected != 0) {
        result.add(selected);
      }
    }
    return result;
  }
  
  int countBranchless(List<int> data, int threshold) {
    var count = 0;
    for (final value in data) {
      count += (value > threshold) ? 1 : 0;
    }
    return count;
  }
}

class LikelyUnlikelyPatterns {
  int processWithLikelyPath(List<int> data) {
    var sum = 0;
    for (final value in data) {
      if (value < 1000000) {
        sum += value;
      } else {
        sum += value * 2;
      }
    }
    return sum;
  }
  
  int? processWithUnlikelyError(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    
    var sum = 0;
    for (final value in data) {
      sum += value;
    }
    return sum;
  }
  
  int hotColdPaths(List<int> data) {
    var result = 0;
    
    for (final value in data) {
      result += _hotPath(value);
      
      if (value == 999999) {
        result += _coldPath(value);
      }
    }
    
    return result;
  }
  
  int _hotPath(int value) {
    return value * 2;
  }
  
  int _coldPath(int value) {
    var result = value;
    for (var i = 0; i < 100; i++) {
      result = (result * 31) ^ i;
    }
    return result;
  }
}

class JumpTablePatterns {
  int switchStatement(List<int> data) {
    var result = 0;
    
    for (final value in data) {
      switch (value % 10) {
        case 0:
          result += value * 2;
          break;
        case 1:
          result += value * 3;
          break;
        case 2:
          result += value * 4;
          break;
        case 3:
          result += value * 5;
          break;
        case 4:
          result += value * 6;
          break;
        case 5:
          result += value * 7;
          break;
        case 6:
          result += value * 8;
          break;
        case 7:
          result += value * 9;
          break;
        case 8:
          result += value * 10;
          break;
        case 9:
          result += value * 11;
          break;
        default:
          result += value;
      }
    }
    
    return result;
  }
  
  int functionTable(List<int> data) {
    final operations = [
      (int x) => x * 2,
      (int x) => x * 3,
      (int x) => x * 4,
      (int x) => x * 5,
      (int x) => x * 6,
      (int x) => x * 7,
      (int x) => x * 8,
      (int x) => x * 9,
      (int x) => x * 10,
      (int x) => x * 11,
    ];
    
    var result = 0;
    for (final value in data) {
      final index = value % 10;
      result += operations[index](value);
    }
    return result;
  }
  
  int directTable(List<int> data) {
    const multipliers = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    
    var result = 0;
    for (final value in data) {
      final index = value % 10;
      result += value * multipliers[index];
    }
    return result;
  }
}

class LoopPatterns {
  int unrolledLoop(List<int> data) {
    var sum = 0;
    final limit = data.length - (data.length % 8);
    
    var i = 0;
    while (i < limit) {
      sum += data[i] > 128 ? data[i] : 0;
      sum += data[i + 1] > 128 ? data[i + 1] : 0;
      sum += data[i + 2] > 128 ? data[i + 2] : 0;
      sum += data[i + 3] > 128 ? data[i + 3] : 0;
      sum += data[i + 4] > 128 ? data[i + 4] : 0;
      sum += data[i + 5] > 128 ? data[i + 5] : 0;
      sum += data[i + 6] > 128 ? data[i + 6] : 0;
      sum += data[i + 7] > 128 ? data[i + 7] : 0;
      i += 8;
    }
    
    while (i < data.length) {
      sum += data[i] > 128 ? data[i] : 0;
      i++;
    }
    
    return sum;
  }
  
  int tiledLoop(List<int> data) {
    const tileSize = 64;
    var sum = 0;
    
    for (var tile = 0; tile < data.length; tile += tileSize) {
      final tileEnd = math.min(tile + tileSize, data.length);
      
      for (var i = tile; i < tileEnd; i++) {
        if (data[i] > 128) {
          sum += data[i];
        }
      }
    }
    
    return sum;
  }
  
  int sentinelLoop(List<int> dataWithSentinel) {
    var sum = 0;
    var i = 0;
    
    while (dataWithSentinel[i] != -1) {
      if (dataWithSentinel[i] > 128) {
        sum += dataWithSentinel[i];
      }
      i++;
    }
    
    return sum;
  }
}

class SpeculativeExecution {
  int speculativeCompute(List<int> data) {
    var sum = 0;
    
    for (final value in data) {
      final result1 = value * 2;
      final result2 = value * 3;
      
      sum += value > 128 ? result2 : result1;
    }
    
    return sum;
  }
  
  int eagerEvaluation(List<int> data) {
    var sum = 0;
    
    for (final value in data) {
      final expensive = _expensiveComputation(value);
      final cheap = value * 2;
      
      sum += value > 500 ? expensive : cheap;
    }
    
    return sum;
  }
  
  int lazyEvaluation(List<int> data) {
    var sum = 0;
    
    for (final value in data) {
      if (value > 500) {
        sum += _expensiveComputation(value);
      } else {
        sum += value * 2;
      }
    }
    
    return sum;
  }
  
  int _expensiveComputation(int value) {
    var result = value;
    for (var i = 0; i < 10; i++) {
      result = (result * 31) % 1000000;
    }
    return result;
  }
}

void benchmark(String name, void Function() fn, int iterations) {
  for (var i = 0; i < 100; i++) {
    fn();
  }
  
  final sw = Stopwatch()..start();
  
  for (var i = 0; i < iterations; i++) {
    fn();
  }
  
  sw.stop();
  final perOp = sw.elapsedMicroseconds / iterations;
  print('$name: ${sw.elapsedMilliseconds}ms (${perOp.toStringAsFixed(2)}μs per op)');
}

void sortedVsUnsortedBenchmarks() {
  print('\n=== Sorted vs Unsorted Data ===');
  
  final rng = math.Random(42);
  final unsorted = List.generate(dataSize, (_) => rng.nextInt(256));
  final sorted = List<int>.from(unsorted)..sort();
  
  final unpredictable = UnpredictableBranches();
  final predictable = PredictableBranches();
  
  benchmark('Unsorted data branches', () {
    unpredictable.sumWithRandomBranches(unsorted);
  }, iterations);
  
  benchmark('Sorted data branches', () {
    predictable.sumWithSortedBranches(sorted);
  }, iterations);
  
  final branchless = BranchlessPatterns();
  
  benchmark('Branchless (conditional move)', () {
    branchless.conditionalMove(unsorted);
  }, iterations);
}

void branchEliminationBenchmarks() {
  print('\n=== Branch Elimination ===');
  
  final rng = math.Random(42);
  final data = List.generate(dataSize, (_) => rng.nextInt(256));
  
  final branchy = UnpredictableBranches();
  final branchless = PredictableBranches();
  
  benchmark('Many if-else branches', () {
    branchy.processWithManyBranches(data);
  }, iterations);
  
  benchmark('Lookup table', () {
    branchless.processWithLookupTable(data);
  }, iterations);
  
  benchmark('Nested conditionals', () {
    branchy.nestedConditionals(data);
  }, iterations);
  
  benchmark('Flattened conditionals', () {
    branchless.flattenedConditionals(data);
  }, iterations);
}

void jumpTableBenchmarks() {
  print('\n=== Jump Table Patterns ===');
  
  final rng = math.Random(42);
  final data = List.generate(dataSize, (_) => rng.nextInt(256));
  
  final jumpTable = JumpTablePatterns();
  
  benchmark('Switch statement', () {
    jumpTable.switchStatement(data);
  }, iterations);
  
  benchmark('Function table', () {
    jumpTable.functionTable(data);
  }, iterations);
  
  benchmark('Direct lookup table', () {
    jumpTable.directTable(data);
  }, iterations);
}

void loopOptimizationBenchmarks() {
  print('\n=== Loop Optimization ===');
  
  final rng = math.Random(42);
  final data = List.generate(dataSize, (_) => rng.nextInt(256));
  final dataWithSentinel = [...data, -1];
  
  final loops = LoopPatterns();
  final basic = UnpredictableBranches();
  
  benchmark('Basic loop', () {
    basic.sumWithRandomBranches(data);
  }, iterations);
  
  benchmark('Unrolled loop (8x)', () {
    loops.unrolledLoop(data);
  }, iterations);
  
  benchmark('Tiled loop', () {
    loops.tiledLoop(data);
  }, iterations);
  
  benchmark('Sentinel loop', () {
    loops.sentinelLoop(dataWithSentinel);
  }, iterations);
}

void speculativeBenchmarks() {
  print('\n=== Speculative Execution ===');
  
  final rng = math.Random(42);
  final data = List.generate(dataSize ~/ 10, (_) => rng.nextInt(1000));
  
  final speculative = SpeculativeExecution();
  
  benchmark('Speculative compute both', () {
    speculative.speculativeCompute(data);
  }, iterations);
  
  benchmark('Eager evaluation', () {
    speculative.eagerEvaluation(data);
  }, iterations);
  
  benchmark('Lazy evaluation', () {
    speculative.lazyEvaluation(data);
  }, iterations);
}

void likelyUnlikelyBenchmarks() {
  print('\n=== Likely/Unlikely Paths ===');
  
  final rng = math.Random(42);
  final data = List.generate(dataSize, (_) => rng.nextInt(1000));
  
  final patterns = LikelyUnlikelyPatterns();
  
  benchmark('Likely path (99.9%)', () {
    patterns.processWithLikelyPath(data);
  }, iterations);
  
  benchmark('Unlikely error check', () {
    patterns.processWithUnlikelyError(data);
  }, iterations);
  
  benchmark('Hot/cold paths', () {
    patterns.hotColdPaths(data);
  }, iterations);
}

void branchlessTechniquesBenchmarks() {
  print('\n=== Branchless Techniques ===');
  
  final rng = math.Random(42);
  final data = List.generate(dataSize, (_) => rng.nextInt(256));
  
  final branchless = BranchlessPatterns();
  
  benchmark('Min/max branchless', () {
    for (var i = 0; i < data.length - 1; i++) {
      branchless.minMaxBranchless(data[i], data[i + 1]);
    }
  }, iterations);
  
  benchmark('Abs branchless', () {
    for (final value in data) {
      branchless.absBranchless(value - 128);
    }
  }, iterations);
  
  benchmark('Count branchless', () {
    branchless.countBranchless(data, 128);
  }, iterations);
}

void main() {
  print('=== Branch Prediction Optimization Patterns ===');
  print('Exploring CPU branch prediction in Dart\n');
  
  sortedVsUnsortedBenchmarks();
  branchEliminationBenchmarks();
  jumpTableBenchmarks();
  loopOptimizationBenchmarks();
  speculativeBenchmarks();
  likelyUnlikelyBenchmarks();
  branchlessTechniquesBenchmarks();
  
  print('\n=== Analysis ===');
  print('• Sorted data improves branch prediction dramatically');
  print('• Lookup tables eliminate branch mispredictions');
  print('• Loop unrolling reduces branch overhead');
  print('• Branchless techniques avoid misprediction penalties');
  print('• Speculative execution can hide branch latency');
  print('• Hot/cold path separation improves I-cache usage');
}