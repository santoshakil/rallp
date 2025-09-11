import 'dart:typed_data';
import 'dart:math' as math;

const iterations = 100000;
const dataSize = 1000;

class StandardCode {
  int simpleFunction(int x) {
    return x * 2 + 1;
  }
  
  int recursiveFunction(int n) {
    if (n <= 1) return n;
    return recursiveFunction(n - 1) + recursiveFunction(n - 2);
  }
  
  List<int> allocatingFunction() {
    final result = <int>[];
    for (var i = 0; i < 100; i++) {
      result.add(i * 2);
    }
    return result;
  }
  
  int polymorphicCall(Object obj) {
    if (obj is int) {
      return obj * 2;
    } else if (obj is double) {
      return obj.toInt() * 2;
    } else if (obj is String) {
      return int.tryParse(obj) ?? 0;
    }
    return 0;
  }
}

class InlinedCode {
  @pragma('vm:prefer-inline')
  int inlinedFunction(int x) {
    return x * 2 + 1;
  }
  
  @pragma('vm:never-inline')
  int neverInlinedFunction(int x) {
    return x * 2 + 1;
  }
  
  @pragma('vm:prefer-inline')
  int hotPath(int x) {
    return x * 2;
  }
  
  @pragma('vm:never-inline')
  int coldPath(int x) {
    var result = x;
    for (var i = 0; i < 100; i++) {
      result = (result * 31) ^ i;
    }
    return result;
  }
}

class ExactTypes {
  @pragma('vm:exact-result-type', int)
  int exactIntReturn(int x) {
    return x * 2;
  }
  
  int dynamicReturn(int x) {
    return x * 2;
  }
  
  @pragma('vm:exact-result-type', List<int>)
  List<int> exactListReturn() {
    return [1, 2, 3, 4, 5];
  }
  
  List<int> dynamicListReturn() {
    return [1, 2, 3, 4, 5];
  }
}

class EntryPoints {
  @pragma('vm:entry-point')
  void entryPointMethod() {
    var sum = 0;
    for (var i = 0; i < 100; i++) {
      sum += i;
    }
  }
  
  void regularMethod() {
    var sum = 0;
    for (var i = 0; i < 100; i++) {
      sum += i;
    }
  }
  
  @pragma('vm:entry-point', 'get')
  int get entryPointGetter => 42;
  
  int get regularGetter => 42;
  
  @pragma('vm:entry-point', 'set')
  set entryPointSetter(int value) {
    final _ = value * 2;
  }
  
  set regularSetter(int value) {
    final _ = value * 2;
  }
}

final class FinalClass {
  final int value;
  
  FinalClass(this.value);
  
  int compute() {
    return value * 2;
  }
}

class RegularClass {
  final int value;
  
  RegularClass(this.value);
  
  int compute() {
    return value * 2;
  }
}

class ConstOptimizations {
  static const constValue = 42;
  static final finalValue = 42;
  static int staticValue = 42;
  
  int useConst() {
    return constValue * 2;
  }
  
  int useFinal() {
    return finalValue * 2;
  }
  
  int useStatic() {
    return staticValue * 2;
  }
  
  int useConstList() {
    const list = [1, 2, 3, 4, 5];
    var sum = 0;
    for (final v in list) {
      sum += v;
    }
    return sum;
  }
  
  int useDynamicList() {
    final list = [1, 2, 3, 4, 5];
    var sum = 0;
    for (final v in list) {
      sum += v;
    }
    return sum;
  }
}

class TypedDataOptimizations {
  int sumList(List<int> data) {
    var sum = 0;
    for (final v in data) {
      sum += v;
    }
    return sum;
  }
  
  int sumInt32List(Int32List data) {
    var sum = 0;
    for (final v in data) {
      sum += v;
    }
    return sum;
  }
  
  int sumWithTypeCheck(List<int> data) {
    if (data is Int32List) {
      return _sumInt32ListFast(data);
    }
    return sumList(data);
  }
  
  @pragma('vm:prefer-inline')
  int _sumInt32ListFast(Int32List data) {
    var sum = 0;
    for (var i = 0; i < data.length; i++) {
      sum += data[i];
    }
    return sum;
  }
}

class NonNullableOptimizations {
  int processNullable(int? value) {
    if (value != null) {
      return value * 2;
    }
    return 0;
  }
  
  int processNonNullable(int value) {
    return value * 2;
  }
  
  int processWithBang(int? value) {
    return value! * 2;
  }
  
  int processWithDefault(int? value) {
    return (value ?? 0) * 2;
  }
}

class AssertOptimizations {
  int withAssert(int x) {
    assert(x >= 0);
    assert(x < 1000000);
    return x * 2;
  }
  
  int withoutAssert(int x) {
    return x * 2;
  }
  
  int withRangeCheck(int x) {
    if (x < 0 || x >= 1000000) {
      throw RangeError('Out of range');
    }
    return x * 2;
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
  print('$name: ${sw.elapsedMilliseconds}ms (${perOp.toStringAsFixed(3)}μs per op)');
}

void inliningBenchmarks() {
  print('\n=== Inlining Pragmas ===');
  
  final standard = StandardCode();
  final inlined = InlinedCode();
  
  benchmark('Standard function', () {
    standard.simpleFunction(42);
  }, iterations * 10);
  
  benchmark('Prefer inline', () {
    inlined.inlinedFunction(42);
  }, iterations * 10);
  
  benchmark('Never inline', () {
    inlined.neverInlinedFunction(42);
  }, iterations * 10);
  
  benchmark('Hot path (inlined)', () {
    inlined.hotPath(42);
  }, iterations * 10);
  
  benchmark('Cold path (not inlined)', () {
    inlined.coldPath(42);
  }, iterations);
}

void exactTypeBenchmarks() {
  print('\n=== Exact Type Pragmas ===');
  
  final exact = ExactTypes();
  
  benchmark('Dynamic int return', () {
    exact.dynamicReturn(42);
  }, iterations * 10);
  
  benchmark('Exact int return', () {
    exact.exactIntReturn(42);
  }, iterations * 10);
  
  benchmark('Dynamic list return', () {
    exact.dynamicListReturn();
  }, iterations);
  
  benchmark('Exact list return', () {
    exact.exactListReturn();
  }, iterations);
}

void finalClassBenchmarks() {
  print('\n=== Final Class Optimization ===');
  
  final finalObj = FinalClass(42);
  final regularObj = RegularClass(42);
  
  benchmark('Regular class method', () {
    regularObj.compute();
  }, iterations * 10);
  
  benchmark('Final class method', () {
    finalObj.compute();
  }, iterations * 10);
}

void constOptimizationBenchmarks() {
  print('\n=== Const Optimizations ===');
  
  final constOpt = ConstOptimizations();
  
  benchmark('Use const value', () {
    constOpt.useConst();
  }, iterations * 10);
  
  benchmark('Use final value', () {
    constOpt.useFinal();
  }, iterations * 10);
  
  benchmark('Use static value', () {
    constOpt.useStatic();
  }, iterations * 10);
  
  benchmark('Use const list', () {
    constOpt.useConstList();
  }, iterations);
  
  benchmark('Use dynamic list', () {
    constOpt.useDynamicList();
  }, iterations);
}

void typedDataBenchmarks() {
  print('\n=== TypedData Optimizations ===');
  
  final typed = TypedDataOptimizations();
  final list = List.generate(dataSize, (i) => i);
  final int32List = Int32List.fromList(list);
  
  benchmark('Sum regular list', () {
    typed.sumList(list);
  }, iterations);
  
  benchmark('Sum Int32List', () {
    typed.sumInt32List(int32List);
  }, iterations);
  
  benchmark('Sum with type check', () {
    typed.sumWithTypeCheck(int32List);
  }, iterations);
}

void nullabilityBenchmarks() {
  print('\n=== Nullability Optimizations ===');
  
  final nullable = NonNullableOptimizations();
  const value = 42;
  const int? nullableValue = 42;
  
  benchmark('Process nullable', () {
    nullable.processNullable(nullableValue);
  }, iterations * 10);
  
  benchmark('Process non-nullable', () {
    nullable.processNonNullable(value);
  }, iterations * 10);
  
  benchmark('Process with bang (!)', () {
    nullable.processWithBang(nullableValue);
  }, iterations * 10);
  
  benchmark('Process with default (??)', () {
    nullable.processWithDefault(nullableValue);
  }, iterations * 10);
}

void assertBenchmarks() {
  print('\n=== Assert Optimizations ===');
  print('Note: Run with --enable-asserts to see assert impact\n');
  
  final asserts = AssertOptimizations();
  
  benchmark('Without assert', () {
    asserts.withoutAssert(42);
  }, iterations * 10);
  
  benchmark('With assert', () {
    asserts.withAssert(42);
  }, iterations * 10);
  
  benchmark('With range check', () {
    asserts.withRangeCheck(42);
  }, iterations * 10);
}

void polymorphismBenchmarks() {
  print('\n=== Polymorphism Optimizations ===');
  
  final standard = StandardCode();
  final intValue = 42;
  final doubleValue = 42.0;
  final stringValue = '42';
  
  benchmark('Monomorphic (int only)', () {
    standard.polymorphicCall(intValue);
  }, iterations * 10);
  
  benchmark('Polymorphic (mixed types)', () {
    standard.polymorphicCall(intValue);
    standard.polymorphicCall(doubleValue);
    standard.polymorphicCall(stringValue);
  }, iterations * 10 ~/ 3);
}

void main() {
  print('=== Compiler Hints and Pragma Patterns ===');
  print('Testing Dart VM optimization pragmas\n');
  
  print('Note: These pragmas primarily affect AOT compilation.');
  print('Run with: dart compile exe <file> for best results.\n');
  
  inliningBenchmarks();
  exactTypeBenchmarks();
  finalClassBenchmarks();
  constOptimizationBenchmarks();
  typedDataBenchmarks();
  nullabilityBenchmarks();
  assertBenchmarks();
  polymorphismBenchmarks();
  
  print('\n=== Analysis ===');
  print('• @pragma("vm:prefer-inline") hints for hot path inlining');
  print('• @pragma("vm:never-inline") prevents cold path inlining');
  print('• @pragma("vm:exact-result-type") enables type optimizations');
  print('• final classes allow devirtualization');
  print('• const values are compile-time optimized');
  print('• TypedData provides better performance than List<int>');
  print('• Non-nullable types avoid null checks');
  print('• Monomorphic calls are faster than polymorphic');
}