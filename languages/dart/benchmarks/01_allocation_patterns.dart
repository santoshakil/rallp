import 'dart:math';

const iterations = 1000000;
const listSize = 1000;

class DartStyle {
  List<int> data = [];
  
  void traditionalDartPattern() {
    for (var i = 0; i < listSize; i++) {
      data.add(Random().nextInt(100));
    }
    
    for (var i = 0; i < data.length; i++) {
      data[i] = data[i] * 2;
    }
    
    var filtered = data.where((x) => x > 50).toList();
    
    var sum = 0;
    for (var val in filtered) {
      sum += val;
    }
    
    var mapped = filtered.map((x) => x * 3).toList();
    
    data = mapped;
  }
}

class RustStyle {
  List<int>? _data;
  final _buffer = List<int>.filled(listSize * 2, 0);
  var _bufferLen = 0;
  
  void rustInspiredPattern() {
    _bufferLen = 0;
    final rng = Random();
    for (var i = 0; i < listSize; i++) {
      _buffer[i] = rng.nextInt(100);
    }
    _bufferLen = listSize;
    
    for (var i = 0; i < _bufferLen; i++) {
      _buffer[i] = _buffer[i] * 2;
    }
    
    var writeIdx = 0;
    for (var i = 0; i < _bufferLen; i++) {
      if (_buffer[i] > 50) {
        _buffer[writeIdx++] = _buffer[i];
      }
    }
    _bufferLen = writeIdx;
    
    var sum = 0;
    for (var i = 0; i < _bufferLen; i++) {
      sum += _buffer[i];
    }
    
    for (var i = 0; i < _bufferLen; i++) {
      _buffer[i] = _buffer[i] * 3;
    }
    
    _data = List<int>.generate(_bufferLen, (i) => _buffer[i]);
  }
}

class OwnershipStyle {
  List<int> processWithOwnership(List<int> data) {
    final owned = List<int>.from(data);
    
    for (var i = 0; i < owned.length; i++) {
      owned[i] = owned[i] * 2;
    }
    
    final filtered = <int>[];
    for (final val in owned) {
      if (val > 50) filtered.add(val);
    }
    
    var sum = 0;
    for (final val in filtered) {
      sum += val;
    }
    
    final result = List<int>.filled(filtered.length, 0);
    for (var i = 0; i < filtered.length; i++) {
      result[i] = filtered[i] * 3;
    }
    
    return result;
  }
  
  void run() {
    var data = List.generate(listSize, (_) => Random().nextInt(100));
    data = processWithOwnership(data);
  }
}

class ImmutableStyle {
  List<int> transform(List<int> input) => 
    List.unmodifiable(input.map((x) => x * 2));
  
  List<int> filter(List<int> input) => 
    List.unmodifiable(input.where((x) => x > 50));
  
  int sum(List<int> input) {
    var total = 0;
    for (final val in input) total += val;
    return total;
  }
  
  List<int> scale(List<int> input) => 
    List.unmodifiable(input.map((x) => x * 3));
  
  void run() {
    final initial = List<int>.unmodifiable(
      List.generate(listSize, (_) => Random().nextInt(100))
    );
    final doubled = transform(initial);
    final filtered = filter(doubled);
    final total = sum(filtered);
    final scaled = scale(filtered);
  }
}

void benchmark(String name, void Function() fn) {
  final sw = Stopwatch()..start();
  
  for (var i = 0; i < iterations; i++) {
    fn();
  }
  
  sw.stop();
  print('$name: ${sw.elapsedMilliseconds}ms '
        '(${(sw.elapsedMicroseconds / iterations).toStringAsFixed(2)}μs per op)');
}

void memoryPressureTest() {
  print('\n=== Memory Pressure Test ===');
  
  final dartObjs = <DartStyle>[];
  final rustObjs = <RustStyle>[];
  
  print('Creating 10000 objects...');
  
  var sw = Stopwatch()..start();
  for (var i = 0; i < 10000; i++) {
    final obj = DartStyle();
    obj.traditionalDartPattern();
    dartObjs.add(obj);
  }
  print('Dart style: ${sw.elapsedMilliseconds}ms');
  
  sw = Stopwatch()..start();
  for (var i = 0; i < 10000; i++) {
    final obj = RustStyle();
    obj.rustInspiredPattern();
    rustObjs.add(obj);
  }
  print('Rust style: ${sw.elapsedMilliseconds}ms');
}

void concurrentModificationTest() {
  print('\n=== Concurrent Modification Patterns ===');
  
  print('Dart allows shared mutable state:');
  final sharedList = [1, 2, 3, 4, 5];
  final results = <int>[];
  
  for (var i = 0; i < sharedList.length; i++) {
    sharedList[i] *= 2;
    if (i < 3) {
      results.add(sharedList[i]);
    }
  }
  print('  Shared list modified in-place: $sharedList');
  print('  Results collected during mutation: $results');
  
  print('\nRust-style single owner:');
  var ownedList = [1, 2, 3, 4, 5];
  final collector = <int>[];
  
  ownedList = ownedList.map((x) => x * 2).toList();
  
  for (var i = 0; i < 3 && i < ownedList.length; i++) {
    collector.add(ownedList[i]);
  }
  print('  List transformed to new owner: $ownedList');
  print('  Results collected after transformation: $collector');
}

void cacheLocalityTest() {
  print('\n=== Cache Locality Test ===');
  
  const size = 100000;
  
  final scattered = List.generate(size, (i) => [i, i * 2, i * 3]);
  
  final packed = {
    'col1': List<int>.filled(size, 0),
    'col2': List<int>.filled(size, 0),
    'col3': List<int>.filled(size, 0),
  };
  for (var i = 0; i < size; i++) {
    packed['col1']![i] = i;
    packed['col2']![i] = i * 2;
    packed['col3']![i] = i * 3;
  }
  
  var sw = Stopwatch()..start();
  var sum = 0;
  for (var i = 0; i < size; i++) {
    sum += scattered[i][0];
  }
  final scatteredTime = sw.elapsedMicroseconds;
  
  sw = Stopwatch()..start();
  sum = 0;
  final col = packed['col1']!;
  for (var i = 0; i < size; i++) {
    sum += col[i];
  }
  final packedTime = sw.elapsedMicroseconds;
  
  print('Array of arrays access: ${scatteredTime}μs');
  print('Column-oriented access: ${packedTime}μs');
  print('Improvement: ${((scatteredTime - packedTime) / scatteredTime * 100).toStringAsFixed(1)}%');
}

void main() {
  print('=== Dart Performance: Traditional vs Rust-Inspired Patterns ===\n');
  print('List size: $listSize, Iterations: $iterations\n');
  
  print('Warming up JIT...');
  for (var i = 0; i < 1000; i++) {
    DartStyle().traditionalDartPattern();
    RustStyle().rustInspiredPattern();
    OwnershipStyle().run();
    ImmutableStyle().run();
  }
  
  print('\n=== Main Benchmarks ===');
  benchmark('Traditional Dart (mutable, allocating)', 
    () => DartStyle().traditionalDartPattern());
  
  benchmark('Rust-inspired (reused buffers, in-place)', 
    () => RustStyle().rustInspiredPattern());
  
  benchmark('Ownership-style (explicit transfer)', 
    () => OwnershipStyle().run());
  
  benchmark('Immutable functional style', 
    () => ImmutableStyle().run());
  
  memoryPressureTest();
  concurrentModificationTest();
  cacheLocalityTest();
  
  print('\n=== Analysis ===');
  print('• Rust-style buffer reuse reduces allocations significantly');
  print('• In-place mutations avoid intermediate collections');
  print('• Cache locality matters even in managed languages');
  print('• Ownership clarity helps reasoning but adds overhead in GC languages');
  print('• Dart\'s GC handles memory differently than Rust\'s ownership');
}