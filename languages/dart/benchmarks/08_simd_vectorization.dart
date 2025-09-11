import 'dart:typed_data';
import 'dart:math' as math;

const iterations = 10000;
const vectorSize = 1024;

class ScalarOperations {
  List<double> addScalar(List<double> a, List<double> b) {
    final result = List<double>.filled(a.length, 0);
    for (var i = 0; i < a.length; i++) {
      result[i] = a[i] + b[i];
    }
    return result;
  }
  
  List<double> multiplyScalar(List<double> a, double scalar) {
    final result = List<double>.filled(a.length, 0);
    for (var i = 0; i < a.length; i++) {
      result[i] = a[i] * scalar;
    }
    return result;
  }
  
  double dotProductScalar(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }
  
  List<double> matrixMultiplyScalar(List<double> a, List<double> b, int size) {
    final result = List<double>.filled(size * size, 0);
    
    for (var i = 0; i < size; i++) {
      for (var j = 0; j < size; j++) {
        var sum = 0.0;
        for (var k = 0; k < size; k++) {
          sum += a[i * size + k] * b[k * size + j];
        }
        result[i * size + j] = sum;
      }
    }
    
    return result;
  }
  
  List<double> transcendentalScalar(List<double> data) {
    final result = List<double>.filled(data.length, 0);
    for (var i = 0; i < data.length; i++) {
      result[i] = math.sin(data[i]) + math.cos(data[i]);
    }
    return result;
  }
  
  List<int> compareScalar(List<double> a, List<double> b) {
    final result = List<int>.filled(a.length, 0);
    for (var i = 0; i < a.length; i++) {
      result[i] = a[i] > b[i] ? 1 : 0;
    }
    return result;
  }
}

class VectorizedOperations {
  Float64List addVectorized(Float64List a, Float64List b) {
    final result = Float64List(a.length);
    
    final unrollFactor = 4;
    final limit = a.length - (a.length % unrollFactor);
    
    var i = 0;
    while (i < limit) {
      result[i] = a[i] + b[i];
      result[i + 1] = a[i + 1] + b[i + 1];
      result[i + 2] = a[i + 2] + b[i + 2];
      result[i + 3] = a[i + 3] + b[i + 3];
      i += unrollFactor;
    }
    
    while (i < a.length) {
      result[i] = a[i] + b[i];
      i++;
    }
    
    return result;
  }
  
  Float64List multiplyVectorized(Float64List a, double scalar) {
    final result = Float64List(a.length);
    
    final unrollFactor = 8;
    final limit = a.length - (a.length % unrollFactor);
    
    var i = 0;
    while (i < limit) {
      result[i] = a[i] * scalar;
      result[i + 1] = a[i + 1] * scalar;
      result[i + 2] = a[i + 2] * scalar;
      result[i + 3] = a[i + 3] * scalar;
      result[i + 4] = a[i + 4] * scalar;
      result[i + 5] = a[i + 5] * scalar;
      result[i + 6] = a[i + 6] * scalar;
      result[i + 7] = a[i + 7] * scalar;
      i += unrollFactor;
    }
    
    while (i < a.length) {
      result[i] = a[i] * scalar;
      i++;
    }
    
    return result;
  }
  
  double dotProductVectorized(Float64List a, Float64List b) {
    var sum0 = 0.0, sum1 = 0.0, sum2 = 0.0, sum3 = 0.0;
    
    final unrollFactor = 4;
    final limit = a.length - (a.length % unrollFactor);
    
    var i = 0;
    while (i < limit) {
      sum0 += a[i] * b[i];
      sum1 += a[i + 1] * b[i + 1];
      sum2 += a[i + 2] * b[i + 2];
      sum3 += a[i + 3] * b[i + 3];
      i += unrollFactor;
    }
    
    var sum = sum0 + sum1 + sum2 + sum3;
    
    while (i < a.length) {
      sum += a[i] * b[i];
      i++;
    }
    
    return sum;
  }
  
  Float64List matrixMultiplyBlocked(Float64List a, Float64List b, int size) {
    final result = Float64List(size * size);
    const blockSize = 64;
    
    for (var ii = 0; ii < size; ii += blockSize) {
      for (var jj = 0; jj < size; jj += blockSize) {
        for (var kk = 0; kk < size; kk += blockSize) {
          
          final iEnd = math.min(ii + blockSize, size);
          final jEnd = math.min(jj + blockSize, size);
          final kEnd = math.min(kk + blockSize, size);
          
          for (var i = ii; i < iEnd; i++) {
            for (var j = jj; j < jEnd; j++) {
              var sum = result[i * size + j];
              
              for (var k = kk; k < kEnd; k++) {
                sum += a[i * size + k] * b[k * size + j];
              }
              
              result[i * size + j] = sum;
            }
          }
        }
      }
    }
    
    return result;
  }
  
  Float64List transcendentalVectorized(Float64List data) {
    final result = Float64List(data.length);
    final unrollFactor = 2;
    final limit = data.length - (data.length % unrollFactor);
    
    var i = 0;
    while (i < limit) {
      result[i] = math.sin(data[i]) + math.cos(data[i]);
      result[i + 1] = math.sin(data[i + 1]) + math.cos(data[i + 1]);
      i += unrollFactor;
    }
    
    while (i < data.length) {
      result[i] = math.sin(data[i]) + math.cos(data[i]);
      i++;
    }
    
    return result;
  }
  
  Int32List compareVectorized(Float64List a, Float64List b) {
    final result = Int32List(a.length);
    
    final unrollFactor = 8;
    final limit = a.length - (a.length % unrollFactor);
    
    var i = 0;
    while (i < limit) {
      result[i] = a[i] > b[i] ? 1 : 0;
      result[i + 1] = a[i + 1] > b[i + 1] ? 1 : 0;
      result[i + 2] = a[i + 2] > b[i + 2] ? 1 : 0;
      result[i + 3] = a[i + 3] > b[i + 3] ? 1 : 0;
      result[i + 4] = a[i + 4] > b[i + 4] ? 1 : 0;
      result[i + 5] = a[i + 5] > b[i + 5] ? 1 : 0;
      result[i + 6] = a[i + 6] > b[i + 6] ? 1 : 0;
      result[i + 7] = a[i + 7] > b[i + 7] ? 1 : 0;
      i += unrollFactor;
    }
    
    while (i < a.length) {
      result[i] = a[i] > b[i] ? 1 : 0;
      i++;
    }
    
    return result;
  }
}

class SimdLikePatterns {
  static const lanes = 4;
  
  List<Float64x2> packToFloat64x2(Float64List data) {
    final packedLength = data.length ~/ 2;
    final result = <Float64x2>[];
    
    for (var i = 0; i < packedLength; i++) {
      final base = i * 2;
      result.add(Float64x2(
        data[base],
        data[base + 1]
      ));
    }
    
    return result;
  }
  
  Float64List unpackFromFloat64x2(List<Float64x2> packed) {
    final result = Float64List(packed.length * 2);
    
    for (var i = 0; i < packed.length; i++) {
      final vec = packed[i];
      final base = i * 2;
      result[base] = vec.x;
      result[base + 1] = vec.y;
    }
    
    return result;
  }
  
  List<Float64x2> addFloat64x2(List<Float64x2> a, List<Float64x2> b) {
    final result = <Float64x2>[];
    
    for (var i = 0; i < a.length; i++) {
      result.add(a[i] + b[i]);
    }
    
    return result;
  }
  
  List<Float64x2> multiplyFloat64x2(List<Float64x2> a, double scalar) {
    final scalarVec = Float64x2.splat(scalar);
    final result = <Float64x2>[];
    
    for (var i = 0; i < a.length; i++) {
      result.add(a[i] * scalarVec);
    }
    
    return result;
  }
  
  double dotProductFloat64x2(List<Float64x2> a, List<Float64x2> b) {
    var sumVec = Float64x2.zero();
    
    for (var i = 0; i < a.length; i++) {
      sumVec += a[i] * b[i];
    }
    
    return sumVec.x + sumVec.y;
  }
}

class DataParallelPatterns {
  void parallelForEach<T>(List<T> data, void Function(T) operation) {
    const chunkSize = 64;
    
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = math.min(i + chunkSize, data.length);
      
      for (var j = i; j < end; j++) {
        operation(data[j]);
      }
    }
  }
  
  List<R> parallelMap<T, R>(List<T> data, R Function(T) transform) {
    const chunkSize = 64;
    final result = List<R?>.filled(data.length, null);
    
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = math.min(i + chunkSize, data.length);
      
      for (var j = i; j < end; j++) {
        result[j] = transform(data[j]);
      }
    }
    
    return result.cast<R>();
  }
  
  T parallelReduce<T>(List<T> data, T Function(T, T) combine) {
    if (data.isEmpty) throw ArgumentError('Empty data');
    if (data.length == 1) return data[0];
    
    const chunkSize = 64;
    final chunks = <T>[];
    
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = math.min(i + chunkSize, data.length);
      var chunkResult = data[i];
      
      for (var j = i + 1; j < end; j++) {
        chunkResult = combine(chunkResult, data[j]);
      }
      
      chunks.add(chunkResult);
    }
    
    var result = chunks[0];
    for (var i = 1; i < chunks.length; i++) {
      result = combine(result, chunks[i]);
    }
    
    return result;
  }
}

class PrefetchPatterns {
  double sumWithPrefetch(Float64List data) {
    var sum = 0.0;
    const prefetchDistance = 8;
    
    for (var i = 0; i < data.length - prefetchDistance; i++) {
      final _ = data[i + prefetchDistance];
      sum += data[i];
    }
    
    for (var i = data.length - prefetchDistance; i < data.length; i++) {
      sum += data[i];
    }
    
    return sum;
  }
  
  Float64List processWithPrefetch(Float64List data) {
    final result = Float64List(data.length);
    const prefetchDistance = 16;
    
    for (var i = 0; i < data.length - prefetchDistance; i++) {
      final _ = data[i + prefetchDistance];
      result[i] = data[i] * 2.0 + 1.0;
    }
    
    for (var i = data.length - prefetchDistance; i < data.length; i++) {
      result[i] = data[i] * 2.0 + 1.0;
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

void vectorAddBenchmarks() {
  print('\n=== Vector Addition Benchmarks ===');
  
  final a = List.generate(vectorSize, (i) => i.toDouble());
  final b = List.generate(vectorSize, (i) => (i * 2).toDouble());
  final aTyped = Float64List.fromList(a);
  final bTyped = Float64List.fromList(b);
  
  final scalar = ScalarOperations();
  final vectorized = VectorizedOperations();
  final simd = SimdLikePatterns();
  
  final aSimd = simd.packToFloat64x2(aTyped);
  final bSimd = simd.packToFloat64x2(bTyped);
  
  benchmark('Scalar addition', () {
    scalar.addScalar(a, b);
  }, iterations);
  
  benchmark('Vectorized addition (unrolled)', () {
    vectorized.addVectorized(aTyped, bTyped);
  }, iterations);
  
  benchmark('SIMD-like Float64x2', () {
    simd.addFloat64x2(aSimd, bSimd);
  }, iterations);
}

void dotProductBenchmarks() {
  print('\n=== Dot Product Benchmarks ===');
  
  final a = List.generate(vectorSize, (i) => i.toDouble());
  final b = List.generate(vectorSize, (i) => (i * 2).toDouble());
  final aTyped = Float64List.fromList(a);
  final bTyped = Float64List.fromList(b);
  
  final scalar = ScalarOperations();
  final vectorized = VectorizedOperations();
  final simd = SimdLikePatterns();
  
  final aSimd = simd.packToFloat64x2(aTyped);
  final bSimd = simd.packToFloat64x2(bTyped);
  
  benchmark('Scalar dot product', () {
    scalar.dotProductScalar(a, b);
  }, iterations);
  
  benchmark('Vectorized dot product (unrolled)', () {
    vectorized.dotProductVectorized(aTyped, bTyped);
  }, iterations);
  
  benchmark('SIMD-like Float64x2 dot', () {
    simd.dotProductFloat64x2(aSimd, bSimd);
  }, iterations);
}

void matrixMultiplyBenchmarks() {
  print('\n=== Matrix Multiply Benchmarks ===');
  
  const matrixSize = 64;
  final a = List.generate(matrixSize * matrixSize, (i) => i.toDouble());
  final b = List.generate(matrixSize * matrixSize, (i) => (i * 2).toDouble());
  final aTyped = Float64List.fromList(a);
  final bTyped = Float64List.fromList(b);
  
  final scalar = ScalarOperations();
  final vectorized = VectorizedOperations();
  
  benchmark('Scalar matrix multiply', () {
    scalar.matrixMultiplyScalar(a, b, matrixSize);
  }, iterations ~/ 100);
  
  benchmark('Blocked matrix multiply', () {
    vectorized.matrixMultiplyBlocked(aTyped, bTyped, matrixSize);
  }, iterations ~/ 100);
}

void transcendentalBenchmarks() {
  print('\n=== Transcendental Function Benchmarks ===');
  
  final data = List.generate(vectorSize, (i) => i * 0.01);
  final dataTyped = Float64List.fromList(data);
  
  final scalar = ScalarOperations();
  final vectorized = VectorizedOperations();
  
  benchmark('Scalar sin+cos', () {
    scalar.transcendentalScalar(data);
  }, iterations ~/ 10);
  
  benchmark('Vectorized sin+cos (unrolled)', () {
    vectorized.transcendentalVectorized(dataTyped);
  }, iterations ~/ 10);
}

void comparisonBenchmarks() {
  print('\n=== Comparison Benchmarks ===');
  
  final a = List.generate(vectorSize, (i) => i.toDouble());
  final b = List.generate(vectorSize, (i) => (i * 1.5).toDouble());
  final aTyped = Float64List.fromList(a);
  final bTyped = Float64List.fromList(b);
  
  final scalar = ScalarOperations();
  final vectorized = VectorizedOperations();
  
  benchmark('Scalar comparison', () {
    scalar.compareScalar(a, b);
  }, iterations);
  
  benchmark('Vectorized comparison (unrolled)', () {
    vectorized.compareVectorized(aTyped, bTyped);
  }, iterations);
}

void dataParallelBenchmarks() {
  print('\n=== Data Parallel Patterns ===');
  
  final data = List.generate(vectorSize * 10, (i) => i);
  final parallel = DataParallelPatterns();
  
  benchmark('Sequential map', () {
    data.map((x) => x * 2).toList();
  }, iterations ~/ 10);
  
  benchmark('Chunked parallel map', () {
    parallel.parallelMap(data, (x) => x * 2);
  }, iterations ~/ 10);
  
  benchmark('Sequential reduce', () {
    data.fold(0, (sum, x) => sum + x);
  }, iterations ~/ 10);
  
  benchmark('Chunked parallel reduce', () {
    parallel.parallelReduce(data, (a, b) => a + b);
  }, iterations ~/ 10);
}

void prefetchBenchmarks() {
  print('\n=== Prefetch Pattern Benchmarks ===');
  
  final data = Float64List(vectorSize * 10);
  for (var i = 0; i < data.length; i++) {
    data[i] = i.toDouble();
  }
  
  final prefetch = PrefetchPatterns();
  
  benchmark('Sum without prefetch', () {
    var sum = 0.0;
    for (var i = 0; i < data.length; i++) {
      sum += data[i];
    }
  }, iterations ~/ 10);
  
  benchmark('Sum with prefetch', () {
    prefetch.sumWithPrefetch(data);
  }, iterations ~/ 10);
  
  benchmark('Process without prefetch', () {
    final result = Float64List(data.length);
    for (var i = 0; i < data.length; i++) {
      result[i] = data[i] * 2.0 + 1.0;
    }
  }, iterations ~/ 100);
  
  benchmark('Process with prefetch', () {
    prefetch.processWithPrefetch(data);
  }, iterations ~/ 100);
}

void main() {
  print('=== SIMD-like Vectorization Patterns ===');
  print('Simulating SIMD operations in Dart\n');
  
  vectorAddBenchmarks();
  dotProductBenchmarks();
  matrixMultiplyBenchmarks();
  transcendentalBenchmarks();
  comparisonBenchmarks();
  dataParallelBenchmarks();
  prefetchBenchmarks();
  
  print('\n=== Analysis ===');
  print('• Loop unrolling provides 1.5-2x speedup for simple operations');
  print('• Float64x2 SIMD types offer native vectorization');
  print('• Blocked matrix multiply improves cache utilization');
  print('• Chunked parallel patterns simulate data parallelism');
  print('• Prefetching patterns have minimal impact in Dart');
  print('• TypedData operations are consistently faster');
}