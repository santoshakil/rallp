import 'dart:typed_data';
import 'dart:math';
import 'dart:collection';

const iterations = 100000;
const allocSize = 1024;

class TraditionalAllocation {
  final _allocations = <List<int>>[];
  
  void allocateAndDeallocate() {
    for (var i = 0; i < 100; i++) {
      _allocations.add(List<int>.filled(allocSize, 0));
    }
    
    for (var i = 0; i < 50; i++) {
      _allocations[i * 2] = List<int>.filled(allocSize, 1);
    }
    
    _allocations.clear();
  }
  
  List<ByteBuffer> fragmentedAllocation() {
    final buffers = <ByteBuffer>[];
    final rng = Random();
    
    for (var i = 0; i < 1000; i++) {
      final size = rng.nextInt(4096) + 64;
      buffers.add(Uint8List(size).buffer);
    }
    
    return buffers;
  }
}

class SlabAllocator {
  static const slabSize = 64;
  static const slabsPerClass = 32;
  
  final _slabClasses = <int, _SlabClass>{};
  
  Uint8List allocate(int size) {
    final slabClass = _getSlabClass(size);
    return slabClass.allocate();
  }
  
  void deallocate(Uint8List memory) {
    final size = memory.length;
    final slabClass = _getSlabClass(size);
    slabClass.deallocate(memory);
  }
  
  _SlabClass _getSlabClass(int size) {
    final classSize = _roundUpToSlabSize(size);
    return _slabClasses.putIfAbsent(
      classSize,
      () => _SlabClass(classSize),
    );
  }
  
  int _roundUpToSlabSize(int size) {
    return ((size + slabSize - 1) ~/ slabSize) * slabSize;
  }
  
  void reset() {
    _slabClasses.clear();
  }
  
  Map<String, num> getStats() {
    var totalAllocated = 0;
    var totalFree = 0;
    
    _slabClasses.forEach((size, slab) {
      totalAllocated += slab._allocated.length * size;
      totalFree += slab._free.length * size;
    });
    
    return {
      'allocated': totalAllocated,
      'free': totalFree,
      'fragmentation': totalFree / (totalAllocated + totalFree) * 100,
    };
  }
}

class _SlabClass {
  final int size;
  final _free = Queue<Uint8List>();
  final _allocated = <Uint8List>{};
  
  _SlabClass(this.size);
  
  Uint8List allocate() {
    if (_free.isNotEmpty) {
      final buffer = _free.removeFirst();
      _allocated.add(buffer);
      return buffer;
    }
    
    final buffer = Uint8List(size);
    _allocated.add(buffer);
    return buffer;
  }
  
  void deallocate(Uint8List buffer) {
    if (_allocated.remove(buffer)) {
      buffer.fillRange(0, buffer.length, 0);
      _free.add(buffer);
    }
  }
}

class BuddyAllocator {
  static const minBlockSize = 64;
  static const maxBlockSize = 65536;
  
  final ByteData _memory;
  final _freeBlocks = <int, Set<int>>{};
  final _allocatedBlocks = <int, int>{};
  var _totalAllocated = 0;
  
  BuddyAllocator() : _memory = ByteData(maxBlockSize) {
    _freeBlocks[maxBlockSize] = {0};
  }
  
  Uint8List? allocate(int size) {
    final blockSize = _nextPowerOfTwo(max(size, minBlockSize));
    
    if (blockSize > maxBlockSize) return null;
    
    final offset = _findFreeBlock(blockSize);
    if (offset == null) return null;
    
    _allocatedBlocks[offset] = blockSize;
    _totalAllocated += blockSize;
    
    return Uint8List.view(_memory.buffer, offset, size);
  }
  
  void deallocate(Uint8List memory) {
    final offset = memory.offsetInBytes;
    final blockSize = _allocatedBlocks.remove(offset);
    
    if (blockSize != null) {
      _totalAllocated -= blockSize;
      _mergeBuddy(offset, blockSize);
    }
  }
  
  int? _findFreeBlock(int size) {
    var currentSize = size;
    
    while (currentSize <= maxBlockSize) {
      final blocks = _freeBlocks[currentSize];
      
      if (blocks != null && blocks.isNotEmpty) {
        final offset = blocks.first;
        blocks.remove(offset);
        
        while (currentSize > size) {
          currentSize ~/= 2;
          final buddyOffset = offset + currentSize;
          _freeBlocks.putIfAbsent(currentSize, () => {}).add(buddyOffset);
        }
        
        return offset;
      }
      
      currentSize *= 2;
    }
    
    return null;
  }
  
  void _mergeBuddy(int offset, int size) {
    final buddyOffset = _getBuddy(offset, size);
    final blocks = _freeBlocks[size];
    
    if (blocks != null && blocks.contains(buddyOffset)) {
      blocks.remove(buddyOffset);
      final mergedOffset = min(offset, buddyOffset);
      
      if (size * 2 <= maxBlockSize) {
        _mergeBuddy(mergedOffset, size * 2);
      } else {
        _freeBlocks.putIfAbsent(size * 2, () => {}).add(mergedOffset);
      }
    } else {
      _freeBlocks.putIfAbsent(size, () => {}).add(offset);
    }
  }
  
  int _getBuddy(int offset, int size) {
    return offset ^ size;
  }
  
  int _nextPowerOfTwo(int n) {
    n--;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    return n + 1;
  }
  
  double get fragmentation {
    final totalFree = _freeBlocks.entries
        .fold<int>(0, (sum, e) => sum + e.key * e.value.length);
    return totalFree / maxBlockSize * 100;
  }
}

class ThreadLocalPool {
  static const poolSize = 16;
  static const objectSize = 256;
  
  final _localPools = <int, List<Uint8List>>{};
  
  Uint8List allocate(int threadId) {
    final pool = _localPools.putIfAbsent(threadId, () => []);
    
    if (pool.isNotEmpty) {
      return pool.removeLast();
    }
    
    return Uint8List(objectSize);
  }
  
  void deallocate(int threadId, Uint8List object) {
    final pool = _localPools.putIfAbsent(threadId, () => []);
    
    if (pool.length < poolSize) {
      object.fillRange(0, object.length, 0);
      pool.add(object);
    }
  }
  
  int getTotalPooled() {
    return _localPools.values.fold(0, (sum, pool) => sum + pool.length);
  }
}

class StackAllocator {
  final ByteData _stack;
  var _top = 0;
  final _marks = <int>[];
  
  StackAllocator(int size) : _stack = ByteData(size);
  
  Uint8List? allocate(int size) {
    if (_top + size > _stack.lengthInBytes) {
      return null;
    }
    
    final result = Uint8List.view(_stack.buffer, _top, size);
    _top += size;
    return result;
  }
  
  void push() {
    _marks.add(_top);
  }
  
  void pop() {
    if (_marks.isNotEmpty) {
      _top = _marks.removeLast();
    }
  }
  
  void reset() {
    _top = 0;
    _marks.clear();
  }
  
  double get utilization => _top / _stack.lengthInBytes * 100;
}

class GenerationalPool {
  static const youngGenSize = 1024 * 1024;
  static const oldGenSize = 4 * 1024 * 1024;
  static const survivorThreshold = 3;
  
  final _youngGen = ByteData(youngGenSize);
  final _oldGen = ByteData(oldGenSize);
  var _youngTop = 0;
  var _oldTop = 0;
  
  final _allocations = <_Allocation>[];
  
  Uint8List allocate(int size) {
    if (_youngTop + size <= youngGenSize) {
      final result = Uint8List.view(_youngGen.buffer, _youngTop, size);
      _allocations.add(_Allocation(result, 0));
      _youngTop += size;
      return result;
    }
    
    _minorGC();
    
    if (_youngTop + size <= youngGenSize) {
      final result = Uint8List.view(_youngGen.buffer, _youngTop, size);
      _allocations.add(_Allocation(result, 0));
      _youngTop += size;
      return result;
    }
    
    if (_oldTop + size <= oldGenSize) {
      final result = Uint8List.view(_oldGen.buffer, _oldTop, size);
      _allocations.add(_Allocation(result, survivorThreshold));
      _oldTop += size;
      return result;
    }
    
    throw StateError('Out of memory');
  }
  
  void _minorGC() {
    final survivors = <_Allocation>[];
    
    for (final alloc in _allocations) {
      alloc.age++;
      
      if (alloc.age >= survivorThreshold) {
        if (_oldTop + alloc.data.length <= oldGenSize) {
          final newData = Uint8List.view(_oldGen.buffer, _oldTop, alloc.data.length);
          newData.setAll(0, alloc.data);
          _oldTop += alloc.data.length;
          survivors.add(_Allocation(newData, alloc.age));
        }
      } else {
        survivors.add(alloc);
      }
    }
    
    _youngTop = 0;
    _allocations.clear();
    _allocations.addAll(survivors);
  }
  
  Map<String, double> getStats() {
    return {
      'youngUtilization': _youngTop / youngGenSize * 100,
      'oldUtilization': _oldTop / oldGenSize * 100,
      'totalAllocations': _allocations.length.toDouble(),
    };
  }
}

class _Allocation {
  final Uint8List data;
  int age;
  
  _Allocation(this.data, this.age);
}

void benchmark(String name, void Function() fn, int iterations) {
  print('\nWarming up $name...');
  for (var i = 0; i < 100; i++) {
    fn();
  }
  
  print('Benchmarking $name...');
  final sw = Stopwatch()..start();
  
  for (var i = 0; i < iterations; i++) {
    fn();
  }
  
  sw.stop();
  final perOp = sw.elapsedMicroseconds / iterations;
  print('  Time: ${sw.elapsedMilliseconds}ms (${perOp.toStringAsFixed(2)}μs per op)');
}

void compareFragmentation() {
  print('\n=== Fragmentation Analysis ===');
  
  final traditional = TraditionalAllocation();
  final slab = SlabAllocator();
  final buddy = BuddyAllocator();
  
  final rng = Random();
  
  print('\nAllocating random sized chunks...');
  
  final traditionalBuffers = traditional.fragmentedAllocation();
  print('Traditional: ${traditionalBuffers.length} allocations');
  
  final slabBuffers = <Uint8List>[];
  for (var i = 0; i < 1000; i++) {
    final size = rng.nextInt(256) + 32;
    slabBuffers.add(slab.allocate(size));
  }
  
  for (var i = 0; i < 500; i++) {
    slab.deallocate(slabBuffers[i * 2]);
  }
  
  final slabStats = slab.getStats();
  print('Slab allocator:');
  print('  Allocated: ${slabStats['allocated']} bytes');
  print('  Free: ${slabStats['free']} bytes');
  print('  Fragmentation: ${slabStats['fragmentation']?.toStringAsFixed(2)}%');
  
  final buddyBuffers = <Uint8List?>[];
  for (var i = 0; i < 100; i++) {
    final size = rng.nextInt(1024) + 64;
    buddyBuffers.add(buddy.allocate(size));
  }
  
  for (var i = 0; i < 50; i++) {
    final buffer = buddyBuffers[i * 2];
    if (buffer != null) {
      buddy.deallocate(buffer);
    }
  }
  
  print('Buddy allocator:');
  print('  Fragmentation: ${buddy.fragmentation.toStringAsFixed(2)}%');
}

void threadLocalSimulation() {
  print('\n=== Thread-Local Pool Simulation ===');
  
  final pool = ThreadLocalPool();
  
  void simulateThread(int threadId) {
    final allocations = <Uint8List>[];
    
    for (var i = 0; i < 100; i++) {
      allocations.add(pool.allocate(threadId));
    }
    
    for (final alloc in allocations) {
      pool.deallocate(threadId, alloc);
    }
  }
  
  for (var thread = 0; thread < 4; thread++) {
    simulateThread(thread);
  }
  
  print('Total pooled objects: ${pool.getTotalPooled()}');
}

void generationalGCSimulation() {
  print('\n=== Generational Pool Simulation ===');
  
  final gen = GenerationalPool();
  
  final longLived = <Uint8List>[];
  final shortLived = <Uint8List>[];
  
  for (var generation = 0; generation < 5; generation++) {
    print('\nGeneration $generation:');
    
    for (var i = 0; i < 100; i++) {
      shortLived.add(gen.allocate(1024));
    }
    
    if (generation % 2 == 0) {
      for (var i = 0; i < 10; i++) {
        longLived.add(gen.allocate(4096));
      }
    }
    
    shortLived.clear();
    
    final stats = gen.getStats();
    print('  Young gen: ${stats['youngUtilization']?.toStringAsFixed(2)}%');
    print('  Old gen: ${stats['oldUtilization']?.toStringAsFixed(2)}%');
    print('  Total allocations: ${stats['totalAllocations']?.toInt()}');
  }
}

void main() {
  print('=== Advanced Memory Pooling Patterns ===');
  print('Comparing Rust-inspired memory management strategies\n');
  
  final traditional = TraditionalAllocation();
  final slab = SlabAllocator();
  final buddy = BuddyAllocator();
  final stack = StackAllocator(1024 * 1024);
  
  print('=== Allocation Speed Benchmarks ===');
  
  benchmark('Traditional allocation', () {
    traditional.allocateAndDeallocate();
  }, iterations);
  
  benchmark('Slab allocator', () {
    final buffers = <Uint8List>[];
    for (var i = 0; i < 100; i++) {
      buffers.add(slab.allocate(allocSize));
    }
    for (final buffer in buffers) {
      slab.deallocate(buffer);
    }
  }, iterations);
  
  benchmark('Buddy allocator', () {
    final buffers = <Uint8List?>[];
    for (var i = 0; i < 100; i++) {
      buffers.add(buddy.allocate(allocSize));
    }
    for (final buffer in buffers) {
      if (buffer != null) buddy.deallocate(buffer);
    }
  }, iterations);
  
  benchmark('Stack allocator', () {
    stack.reset();
    for (var i = 0; i < 100; i++) {
      stack.allocate(allocSize);
    }
  }, iterations);
  
  compareFragmentation();
  threadLocalSimulation();
  generationalGCSimulation();
  
  print('\n=== Analysis ===');
  print('• Slab allocator reduces fragmentation for fixed-size allocations');
  print('• Buddy allocator handles variable sizes with O(log n) complexity');
  print('• Stack allocator is fastest but limited to LIFO patterns');
  print('• Thread-local pools eliminate contention in concurrent scenarios');
  print('• Generational pools optimize for short-lived object patterns');
  print('• Traditional allocation relies on GC, causing unpredictable pauses');
}