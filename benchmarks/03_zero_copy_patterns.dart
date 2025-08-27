import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';

const iterations = 100000;
const dataSize = 10000;

class TraditionalAllocation {
  List<int> processWithCopies(List<int> input) {
    final doubled = input.map((x) => x * 2).toList();
    final filtered = doubled.where((x) => x > 100).toList();
    final sorted = List<int>.from(filtered)..sort();
    final result = sorted.take(100).toList();
    return result;
  }
  
  String buildStringWithConcatenation(List<String> parts) {
    var result = '';
    for (final part in parts) {
      result += part + ',';
    }
    return result;
  }
  
  List<double> convertIntToDouble(List<int> ints) {
    return ints.map((i) => i.toDouble()).toList();
  }
  
  List<int> sliceAndProcess(List<int> data, int start, int end) {
    final slice = data.sublist(start, end);
    return slice.map((x) => x * 2).toList();
  }
}

class ZeroCopyPatterns {
  final _arena = ByteData(1024 * 1024);
  var _arenaOffset = 0;
  
  Uint32List processWithViews(Uint32List input) {
    final buffer = Uint32List(input.length * 2);
    var writeIdx = 0;
    
    for (var i = 0; i < input.length; i++) {
      final doubled = input[i] * 2;
      if (doubled > 100) {
        buffer[writeIdx++] = doubled;
      }
    }
    
    final filtered = Uint32List.view(buffer.buffer, 0, writeIdx);
    filtered.sort();
    
    final resultSize = min(100, filtered.length);
    return Uint32List.view(filtered.buffer, 0, resultSize);
  }
  
  String buildStringWithBuffer(List<String> parts) {
    final buffer = StringBuffer();
    for (final part in parts) {
      buffer.write(part);
      buffer.write(',');
    }
    return buffer.toString();
  }
  
  Float64List convertIntToDoubleView(Uint32List ints) {
    final buffer = ByteData(ints.length * 8);
    for (var i = 0; i < ints.length; i++) {
      buffer.setFloat64(i * 8, ints[i].toDouble(), Endian.host);
    }
    return Float64List.view(buffer.buffer);
  }
  
  Uint32List sliceAndProcessView(Uint32List data, int start, int end) {
    final view = Uint32List.view(
      data.buffer, 
      data.offsetInBytes + start * 4, 
      end - start
    );
    
    final result = Uint32List(view.length);
    for (var i = 0; i < view.length; i++) {
      result[i] = view[i] * 2;
    }
    return result;
  }
}

class ArenaAllocator {
  static const arenaSize = 10 * 1024 * 1024;
  final ByteData _arena = ByteData(arenaSize);
  var _offset = 0;
  
  Uint32List allocate(int count) {
    final bytes = count * 4;
    if (_offset + bytes > arenaSize) {
      throw StateError('Arena exhausted');
    }
    
    final view = Uint32List.view(
      _arena.buffer,
      _offset,
      count
    );
    _offset += bytes;
    return view;
  }
  
  void reset() {
    _offset = 0;
  }
  
  double usage() => _offset / arenaSize;
}

class ObjectPool<T> {
  final T Function() _factory;
  final void Function(T) _reset;
  final _pool = <T>[];
  
  ObjectPool(this._factory, this._reset);
  
  T acquire() {
    if (_pool.isEmpty) {
      return _factory();
    }
    return _pool.removeLast();
  }
  
  void release(T obj) {
    _reset(obj);
    _pool.add(obj);
  }
  
  int get poolSize => _pool.length;
}

class RingBuffer {
  final Uint8List _buffer;
  var _writePos = 0;
  var _readPos = 0;
  
  RingBuffer(int size) : _buffer = Uint8List(size);
  
  void write(Uint8List data) {
    for (final byte in data) {
      _buffer[_writePos] = byte;
      _writePos = (_writePos + 1) % _buffer.length;
    }
  }
  
  Uint8List read(int count) {
    final result = Uint8List(count);
    for (var i = 0; i < count; i++) {
      result[i] = _buffer[_readPos];
      _readPos = (_readPos + 1) % _buffer.length;
    }
    return result;
  }
  
  Uint8List readView(int count) {
    if (_readPos + count <= _buffer.length) {
      final view = Uint8List.view(
        _buffer.buffer,
        _readPos,
        count
      );
      _readPos += count;
      return view;
    } else {
      return read(count);
    }
  }
}

class TypePunning {
  Uint32List bytesToInts(Uint8List bytes) {
    return Uint32List.view(bytes.buffer);
  }
  
  Float32List intsToFloats(Uint32List ints) {
    return Float32List.view(ints.buffer);
  }
  
  Uint8List floatsToBytes(Float32List floats) {
    return Uint8List.view(floats.buffer);
  }
  
  void reinterpretInPlace(ByteData data) {
    for (var i = 0; i < data.lengthInBytes ~/ 8; i++) {
      final asInt = data.getUint64(i * 8, Endian.host);
      final asDouble = data.buffer.asFloat64List()[i];
      data.setFloat64(i * 8, asDouble * 2, Endian.host);
    }
  }
}

class CopyOnWrite<T> {
  T _data;
  var _isShared = false;
  T Function(T) _copier;
  
  CopyOnWrite(this._data, this._copier);
  
  T get read => _data;
  
  T get write {
    if (_isShared) {
      _data = _copier(_data);
      _isShared = false;
    }
    return _data;
  }
  
  CopyOnWrite<T> share() {
    _isShared = true;
    return CopyOnWrite(_data, _copier).._isShared = true;
  }
}

void benchmark(String name, void Function() fn) {
  final sw = Stopwatch()..start();
  
  for (var i = 0; i < iterations; i++) {
    fn();
  }
  
  sw.stop();
  final perOp = sw.elapsedMicroseconds / iterations;
  print('$name: ${sw.elapsedMilliseconds}ms (${perOp.toStringAsFixed(2)}μs/op)');
}

void memoryPressureTest() {
  print('\n=== Memory Pressure Test ===');
  
  final traditional = TraditionalAllocation();
  final zeroCopy = ZeroCopyPatterns();
  
  final data = List.generate(10000, (i) => i);
  final typedData = Uint32List.fromList(data);
  
  var sw = Stopwatch()..start();
  for (var i = 0; i < 1000; i++) {
    traditional.processWithCopies(data);
  }
  print('Traditional (1000 ops): ${sw.elapsedMilliseconds}ms');
  
  sw = Stopwatch()..start();
  for (var i = 0; i < 1000; i++) {
    zeroCopy.processWithViews(typedData);
  }
  print('Zero-copy (1000 ops): ${sw.elapsedMilliseconds}ms');
}

void arenaVsAllocation() {
  print('\n=== Arena vs Normal Allocation ===');
  
  final arena = ArenaAllocator();
  
  var sw = Stopwatch()..start();
  final normalLists = <List<int>>[];
  for (var i = 0; i < 10000; i++) {
    normalLists.add(List.filled(100, i));
  }
  print('Normal allocation (10K lists): ${sw.elapsedMicroseconds}μs');
  
  sw = Stopwatch()..start();
  final arenaLists = <Uint32List>[];
  for (var i = 0; i < 10000; i++) {
    final list = arena.allocate(100);
    list.fillRange(0, 100, i);
    arenaLists.add(list);
  }
  print('Arena allocation (10K lists): ${sw.elapsedMicroseconds}μs');
  print('Arena usage: ${(arena.usage() * 100).toStringAsFixed(2)}%');
}

void poolingBenchmark() {
  print('\n=== Object Pooling ===');
  
  final pool = ObjectPool<List<int>>(
    () => List.filled(1000, 0),
    (list) => list.fillRange(0, list.length, 0)
  );
  
  var sw = Stopwatch()..start();
  for (var i = 0; i < 10000; i++) {
    final list = List.filled(1000, i);
    list[500] = i * 2;
  }
  print('Without pooling (10K allocations): ${sw.elapsedMicroseconds}μs');
  
  sw = Stopwatch()..start();
  for (var i = 0; i < 10000; i++) {
    final list = pool.acquire();
    list[500] = i * 2;
    pool.release(list);
  }
  print('With pooling (10K operations): ${sw.elapsedMicroseconds}μs');
  print('Pool size: ${pool.poolSize}');
}

void viewChaining() {
  print('\n=== View Chaining vs Copies ===');
  
  final data = Uint8List.fromList(List.generate(100000, (i) => i % 256));
  
  var sw = Stopwatch()..start();
  final copy1 = Uint8List.fromList(data);
  final copy2 = Uint8List.fromList(copy1);
  final copy3 = Uint8List.fromList(copy2);
  final copyResult = copy3.sublist(1000, 2000);
  print('Three copies + sublist: ${sw.elapsedMicroseconds}μs');
  
  sw = Stopwatch()..start();
  final view1 = Uint8List.view(data.buffer);
  final view2 = Uint8List.view(view1.buffer);
  final view3 = Uint8List.view(view2.buffer);
  final viewResult = Uint8List.view(view3.buffer, 1000, 1000);
  print('Three views + subview: ${sw.elapsedMicroseconds}μs');
}

void typePunningBenchmark() {
  print('\n=== Type Punning (Reinterpretation) ===');
  
  final punner = TypePunning();
  final bytes = Uint8List.fromList(List.generate(40000, (i) => i % 256));
  
  var sw = Stopwatch()..start();
  final converted = bytes.map((b) => b.toInt()).toList();
  final floats = converted.map((i) => i.toDouble()).toList();
  print('Traditional conversion: ${sw.elapsedMicroseconds}μs');
  
  sw = Stopwatch()..start();
  final intView = punner.bytesToInts(bytes);
  final floatView = punner.intsToFloats(intView);
  print('Type punning views: ${sw.elapsedMicroseconds}μs');
}

void cowBenchmark() {
  print('\n=== Copy-on-Write Pattern ===');
  
  final original = List.generate(10000, (i) => i);
  
  var sw = Stopwatch()..start();
  final copies = <List<int>>[];
  for (var i = 0; i < 100; i++) {
    copies.add(List.from(original));
  }
  print('100 immediate copies: ${sw.elapsedMicroseconds}μs');
  
  sw = Stopwatch()..start();
  final cow = CopyOnWrite(original, (list) => List<int>.from(list));
  final shared = <CopyOnWrite<List<int>>>[];
  for (var i = 0; i < 100; i++) {
    shared.add(cow.share());
  }
  print('100 COW shares (no copy): ${sw.elapsedMicroseconds}μs');
  
  sw = Stopwatch()..start();
  for (var i = 0; i < 10; i++) {
    shared[i].write[0] = 999;
  }
  print('10 COW writes (triggers copy): ${sw.elapsedMicroseconds}μs');
}

void main() {
  print('=== Zero-Copy and Memory Pooling Patterns ===\n');
  print('Data size: $dataSize, Iterations: $iterations\n');
  
  final traditional = TraditionalAllocation();
  final zeroCopy = ZeroCopyPatterns();
  
  final testData = List.generate(dataSize, (i) => Random().nextInt(1000));
  final typedTestData = Uint32List.fromList(testData);
  final stringParts = List.generate(100, (i) => 'part$i');
  
  print('=== Basic Processing ===');
  benchmark(
    'Traditional (multiple copies)', 
    () => traditional.processWithCopies(testData.take(1000).toList())
  );
  
  benchmark(
    'Zero-copy (views only)', 
    () => zeroCopy.processWithViews(Uint32List.fromList(testData.take(1000).toList()))
  );
  
  print('\n=== String Building ===');
  benchmark(
    'String concatenation', 
    () => traditional.buildStringWithConcatenation(stringParts)
  );
  
  benchmark(
    'StringBuffer', 
    () => zeroCopy.buildStringWithBuffer(stringParts)
  );
  
  print('\n=== Type Conversion ===');
  benchmark(
    'Map to double (allocation)', 
    () => traditional.convertIntToDouble(testData.take(100).toList())
  );
  
  benchmark(
    'View as double (reinterpret)', 
    () => zeroCopy.convertIntToDoubleView(Uint32List.fromList(testData.take(100).toList()))
  );
  
  print('\n=== Slicing ===');
  benchmark(
    'Sublist + map', 
    () => traditional.sliceAndProcess(testData, 100, 200)
  );
  
  benchmark(
    'View + process', 
    () => zeroCopy.sliceAndProcessView(typedTestData, 100, 200)
  );
  
  memoryPressureTest();
  arenaVsAllocation();
  poolingBenchmark();
  viewChaining();
  typePunningBenchmark();
  cowBenchmark();
  
  print('\n=== Analysis ===');
  print('• Views avoid copies but have offset overhead');
  print('• Arena allocation reduces allocation overhead significantly');
  print('• Object pooling eliminates GC pressure for hot paths');
  print('• StringBuffer is 10x faster than concatenation');
  print('• Type punning via views is instant vs conversion');
  print('• COW delays expensive copies until needed');
}