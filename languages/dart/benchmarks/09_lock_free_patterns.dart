import 'dart:collection';
import 'dart:math' as math;

const iterations = 100000;
const dataSize = 1000;

class TraditionalLocking {
  final _data = <int>[];
  final _lock = Object();
  
  void add(int value) {
    _data.add(value);
  }
  
  int? remove() {
    if (_data.isEmpty) return null;
    return _data.removeAt(0);
  }
  
  int get length => _data.length;
  
  bool compareAndSwap(int index, int expected, int newValue) {
    if (index >= _data.length) return false;
    
    if (_data[index] == expected) {
      _data[index] = newValue;
      return true;
    }
    return false;
  }
}

class AtomicCounter {
  int _value = 0;
  
  int get value => _value;
  
  void increment() {
    _value++;
  }
  
  void add(int delta) {
    _value += delta;
  }
  
  int getAndIncrement() {
    final old = _value;
    _value++;
    return old;
  }
  
  int incrementAndGet() {
    _value++;
    return _value;
  }
  
  bool compareAndSet(int expected, int newValue) {
    if (_value == expected) {
      _value = newValue;
      return true;
    }
    return false;
  }
}

class SpinLock {
  bool _locked = false;
  int _spinCount = 0;
  
  bool tryAcquire() {
    if (!_locked) {
      _locked = true;
      return true;
    }
    return false;
  }
  
  void acquire() {
    while (_locked) {
      _spinCount++;
    }
    _locked = true;
  }
  
  void release() {
    _locked = false;
  }
  
  T withLock<T>(T Function() operation) {
    acquire();
    try {
      return operation();
    } finally {
      release();
    }
  }
  
  int get totalSpins => _spinCount;
}

class LockFreeQueue<T> {
  final _items = <T>[];
  int _head = 0;
  int _tail = 0;
  
  void enqueue(T item) {
    _items.add(item);
    _tail++;
  }
  
  T? dequeue() {
    if (_head >= _tail) return null;
    
    if (_head < _items.length) {
      final item = _items[_head];
      _head++;
      
      if (_head > 100 && _head > _items.length ~/ 2) {
        _items.removeRange(0, _head);
        _tail -= _head;
        _head = 0;
      }
      
      return item;
    }
    return null;
  }
  
  bool get isEmpty => _head >= _tail;
  int get length => _tail - _head;
}

class MPSCQueue<T> {
  final _producers = <List<T>>[];
  final _consumer = <T>[];
  int _consumerIndex = 0;
  
  void produce(T item, int producerId) {
    while (_producers.length <= producerId) {
      _producers.add(<T>[]);
    }
    _producers[producerId].add(item);
  }
  
  T? consume() {
    if (_consumerIndex < _consumer.length) {
      return _consumer[_consumerIndex++];
    }
    
    _consumer.clear();
    _consumerIndex = 0;
    
    for (final producer in _producers) {
      _consumer.addAll(producer);
      producer.clear();
    }
    
    if (_consumer.isEmpty) return null;
    
    return _consumer[_consumerIndex++];
  }
  
  int get approximateLength {
    var total = _consumer.length - _consumerIndex;
    for (final producer in _producers) {
      total += producer.length;
    }
    return total;
  }
}

class SeqLock {
  int _sequence = 0;
  var _data = 0;
  
  int read() {
    int seq1 = 0;
    int seq2 = 0;
    int data = 0;
    
    do {
      seq1 = _sequence;
      if (seq1 % 2 == 1) continue;
      
      data = _data;
      
      seq2 = _sequence;
    } while (seq1 != seq2);
    
    return data;
  }
  
  void write(int value) {
    _sequence++;
    
    _data = value;
    
    _sequence++;
  }
}

class RCU<T> {
  T? _current;
  T? _old;
  bool _inGracePeriod = false;
  
  T? read() => _current;
  
  void update(T newValue) {
    if (_inGracePeriod) {
      _old = null;
    }
    
    _old = _current;
    _current = newValue;
    _inGracePeriod = true;
    
    Future.microtask(() {
      _old = null;
      _inGracePeriod = false;
    });
  }
  
  void synchronize() {
    while (_inGracePeriod) {}
  }
}

class HazardPointer<T> {
  final _hazardList = <T>[];
  final _retiredList = <T>[];
  
  void acquire(T obj) {
    _hazardList.add(obj);
  }
  
  void release(T obj) {
    _hazardList.remove(obj);
  }
  
  void retire(T obj) {
    _retiredList.add(obj);
    _tryReclaim();
  }
  
  void _tryReclaim() {
    final toReclaim = <T>[];
    
    for (final retired in _retiredList) {
      if (!_hazardList.contains(retired)) {
        toReclaim.add(retired);
      }
    }
    
    for (final obj in toReclaim) {
      _retiredList.remove(obj);
    }
  }
  
  int get retiredCount => _retiredList.length;
}

class WaitFreeCounter {
  final _counters = List<int>.filled(64, 0);
  
  void increment(int threadId) {
    final index = threadId % _counters.length;
    _counters[index]++;
  }
  
  int get value {
    var sum = 0;
    for (final count in _counters) {
      sum += count;
    }
    return sum;
  }
  
  void reset() {
    for (var i = 0; i < _counters.length; i++) {
      _counters[i] = 0;
    }
  }
}

class VersionedData<T> {
  int _version = 0;
  T _data;
  
  VersionedData(this._data);
  
  (T, int) read() {
    return (_data, _version);
  }
  
  bool compareAndSwap(T expected, T newValue, int expectedVersion) {
    if (_version == expectedVersion && _data == expected) {
      _data = newValue;
      _version++;
      return true;
    }
    return false;
  }
  
  void write(T value) {
    _data = value;
    _version++;
  }
  
  int get version => _version;
}

class COWList<T> {
  List<T> _data;
  
  COWList(List<T> initial) : _data = List.from(initial);
  
  List<T> read() => _data;
  
  void add(T item) {
    final newList = List<T>.from(_data);
    newList.add(item);
    _data = newList;
  }
  
  void remove(T item) {
    final newList = List<T>.from(_data);
    newList.remove(item);
    _data = newList;
  }
  
  void update(int index, T value) {
    final newList = List<T>.from(_data);
    newList[index] = value;
    _data = newList;
  }
  
  int get length => _data.length;
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

void atomicOperationBenchmarks() {
  print('\n=== Atomic Operation Benchmarks ===');
  
  final traditional = TraditionalLocking();
  final atomic = AtomicCounter();
  
  for (var i = 0; i < dataSize; i++) {
    traditional.add(i);
  }
  
  benchmark('Traditional increment', () {
    traditional.add(1);
  }, iterations);
  
  benchmark('Atomic increment', () {
    atomic.increment();
  }, iterations);
  
  benchmark('Atomic get-and-increment', () {
    atomic.getAndIncrement();
  }, iterations);
  
  benchmark('Traditional CAS', () {
    traditional.compareAndSwap(0, 0, 1);
  }, iterations);
  
  benchmark('Atomic CAS', () {
    atomic.compareAndSet(atomic.value, atomic.value + 1);
  }, iterations);
}

void queueBenchmarks() {
  print('\n=== Queue Benchmarks ===');
  
  final traditional = Queue<int>();
  final lockFree = LockFreeQueue<int>();
  final mpsc = MPSCQueue<int>();
  
  benchmark('Traditional queue add', () {
    traditional.add(42);
  }, iterations);
  
  benchmark('Lock-free queue enqueue', () {
    lockFree.enqueue(42);
  }, iterations);
  
  benchmark('MPSC queue produce', () {
    mpsc.produce(42, 0);
  }, iterations);
  
  for (var i = 0; i < dataSize; i++) {
    traditional.add(i);
    lockFree.enqueue(i);
    mpsc.produce(i, 0);
  }
  
  benchmark('Traditional queue remove', () {
    if (traditional.isNotEmpty) traditional.removeFirst();
  }, iterations);
  
  benchmark('Lock-free queue dequeue', () {
    lockFree.dequeue();
  }, iterations);
  
  benchmark('MPSC queue consume', () {
    mpsc.consume();
  }, iterations);
}

void lockBenchmarks() {
  print('\n=== Lock Benchmarks ===');
  
  final spinLock = SpinLock();
  final seqLock = SeqLock();
  var counter = 0;
  
  benchmark('Uncontended increment', () {
    counter++;
  }, iterations);
  
  benchmark('SpinLock protected increment', () {
    spinLock.withLock(() {
      counter++;
      return counter;
    });
  }, iterations);
  
  benchmark('SeqLock write', () {
    seqLock.write(counter++);
  }, iterations);
  
  benchmark('SeqLock read', () {
    seqLock.read();
  }, iterations);
  
  print('Total spins: ${spinLock.totalSpins}');
}

void rcuBenchmarks() {
  print('\n=== RCU (Read-Copy-Update) Benchmarks ===');
  
  final rcu = RCU<List<int>>();
  final traditional = <int>[1, 2, 3, 4, 5];
  
  rcu.update([1, 2, 3, 4, 5]);
  
  benchmark('Traditional list read', () {
    final _ = traditional[0];
  }, iterations);
  
  benchmark('RCU read', () {
    final _ = rcu.read();
  }, iterations);
  
  benchmark('Traditional list update', () {
    traditional[0] = traditional[0] + 1;
  }, iterations);
  
  benchmark('RCU update', () {
    final current = rcu.read() ?? [];
    final newList = List<int>.from(current);
    if (newList.isNotEmpty) newList[0]++;
    rcu.update(newList);
  }, iterations ~/ 100);
}

void waitFreeBenchmarks() {
  print('\n=== Wait-Free Benchmarks ===');
  
  final traditional = AtomicCounter();
  final waitFree = WaitFreeCounter();
  
  benchmark('Traditional counter increment', () {
    traditional.increment();
  }, iterations);
  
  benchmark('Wait-free counter increment', () {
    waitFree.increment(0);
  }, iterations);
  
  benchmark('Traditional counter read', () {
    final _ = traditional.value;
  }, iterations);
  
  benchmark('Wait-free counter read', () {
    final _ = waitFree.value;
  }, iterations);
}

void versionedDataBenchmarks() {
  print('\n=== Versioned Data Benchmarks ===');
  
  final versioned = VersionedData<int>(0);
  var simpleData = 0;
  var simpleVersion = 0;
  
  benchmark('Simple read', () {
    final _ = simpleData;
  }, iterations);
  
  benchmark('Versioned read', () {
    final _ = versioned.read();
  }, iterations);
  
  benchmark('Simple write', () {
    simpleData = simpleData + 1;
    simpleVersion++;
  }, iterations);
  
  benchmark('Versioned write', () {
    versioned.write(versioned.read().$1 + 1);
  }, iterations);
  
  benchmark('Versioned CAS', () {
    final (data, version) = versioned.read();
    versioned.compareAndSwap(data, data + 1, version);
  }, iterations);
}

void cowListBenchmarks() {
  print('\n=== Copy-on-Write List Benchmarks ===');
  
  final traditional = List<int>.generate(dataSize, (i) => i);
  final cow = COWList<int>(List.generate(dataSize, (i) => i));
  
  benchmark('Traditional list read', () {
    final _ = traditional[dataSize ~/ 2];
  }, iterations);
  
  benchmark('COW list read', () {
    final _ = cow.read()[dataSize ~/ 2];
  }, iterations);
  
  benchmark('Traditional list update', () {
    traditional[0] = traditional[0] + 1;
  }, iterations);
  
  benchmark('COW list update', () {
    cow.update(0, cow.read()[0] + 1);
  }, iterations ~/ 100);
  
  benchmark('Traditional list add', () {
    traditional.add(42);
  }, iterations);
  
  benchmark('COW list add', () {
    cow.add(42);
  }, iterations ~/ 100);
}

void hazardPointerBenchmarks() {
  print('\n=== Hazard Pointer Benchmarks ===');
  
  final hazard = HazardPointer<int>();
  
  benchmark('Hazard pointer acquire', () {
    hazard.acquire(42);
  }, iterations);
  
  benchmark('Hazard pointer release', () {
    hazard.acquire(42);
    hazard.release(42);
  }, iterations);
  
  benchmark('Hazard pointer retire', () {
    hazard.retire(42);
  }, iterations ~/ 10);
  
  print('Retired count: ${hazard.retiredCount}');
}

void main() {
  print('=== Lock-Free Data Structure Patterns ===');
  print('Simulating lock-free patterns inspired by Rust\n');
  
  atomicOperationBenchmarks();
  queueBenchmarks();
  lockBenchmarks();
  rcuBenchmarks();
  waitFreeBenchmarks();
  versionedDataBenchmarks();
  cowListBenchmarks();
  hazardPointerBenchmarks();
  
  print('\n=== Analysis ===');
  print('• Atomic operations avoid lock overhead for simple updates');
  print('• Lock-free queues eliminate contention for producer-consumer');
  print('• SeqLocks optimize read-heavy workloads');
  print('• RCU enables wait-free reads with delayed reclamation');
  print('• Wait-free counters scale linearly with threads');
  print('• COW provides safe concurrent reads with consistent snapshots');
  print('• Versioned data enables optimistic concurrency control');
}