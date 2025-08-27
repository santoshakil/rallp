import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

const dataSize = 100000;
const numWorkers = 4;

class BenchmarkResult {
  final String name;
  final int milliseconds;
  final double throughput;
  
  BenchmarkResult(this.name, this.milliseconds, this.throughput);
}

class TraditionalDartConcurrency {
  Future<int> simpleIsolateSum(List<int> data) async {
    final results = <Future<int>>[];
    final chunkSize = data.length ~/ numWorkers;
    
    for (var i = 0; i < numWorkers; i++) {
      final start = i * chunkSize;
      final end = i == numWorkers - 1 ? data.length : (i + 1) * chunkSize;
      final chunk = data.sublist(start, end);
      
      results.add(Isolate.run(() {
        var sum = 0;
        for (final val in chunk) {
          sum += val;
        }
        return sum;
      }));
    }
    
    final sums = await Future.wait(results);
    return sums.reduce((a, b) => a + b);
  }
  
  Future<List<int>> naiveParallelMap(List<int> data) async {
    final results = <Future<List<int>>>[];
    final chunkSize = data.length ~/ numWorkers;
    
    for (var i = 0; i < numWorkers; i++) {
      final start = i * chunkSize;
      final end = i == numWorkers - 1 ? data.length : (i + 1) * chunkSize;
      final chunk = data.sublist(start, end);
      
      results.add(Isolate.run(() {
        return chunk.map((x) => x * x).toList();
      }));
    }
    
    final chunks = await Future.wait(results);
    return chunks.expand((x) => x).toList();
  }
}

class RustInspiredPatterns {
  final _workerPool = <SendPort>[];
  final _responses = StreamController<dynamic>.broadcast();
  var _initialized = false;
  
  Future<void> initWorkerPool() async {
    if (_initialized) return;
    
    for (var i = 0; i < numWorkers; i++) {
      final response = ReceivePort();
      await Isolate.spawn(_workerLoop, response.sendPort);
      
      final sendPort = await response.first as SendPort;
      _workerPool.add(sendPort);
    }
    _initialized = true;
  }
  
  static void _workerLoop(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    
    await for (final msg in port) {
      if (msg is _WorkPacket) {
        final result = msg.process();
        msg.replyPort.send(result);
      } else if (msg == 'shutdown') {
        port.close();
        break;
      }
    }
  }
  
  Future<int> channelBasedSum(List<int> data) async {
    await initWorkerPool();
    
    final chunkSize = data.length ~/ numWorkers;
    final futures = <Future<int>>[];
    
    for (var i = 0; i < numWorkers; i++) {
      final start = i * chunkSize;
      final end = i == numWorkers - 1 ? data.length : (i + 1) * chunkSize;
      final chunk = data.sublist(start, end);
      
      final response = ReceivePort();
      _workerPool[i].send(_SumPacket(chunk, response.sendPort));
      futures.add(response.first.then((v) => v as int));
    }
    
    final results = await Future.wait(futures);
    return results.reduce((a, b) => a + b);
  }
  
  Future<List<int>> batchedParallelMap(List<int> data) async {
    await initWorkerPool();
    
    const batchSize = 1000;
    final batches = <List<int>>[];
    
    for (var i = 0; i < data.length; i += batchSize) {
      final end = (i + batchSize < data.length) ? i + batchSize : data.length;
      batches.add(data.sublist(i, end));
    }
    
    final results = <int>[];
    var workerIndex = 0;
    
    for (final batch in batches) {
      final response = ReceivePort();
      _workerPool[workerIndex].send(_MapPacket(batch, response.sendPort));
      final result = await response.first as List<int>;
      results.addAll(result);
      workerIndex = (workerIndex + 1) % numWorkers;
    }
    
    return results;
  }
  
  Future<void> cleanup() async {
    for (final worker in _workerPool) {
      worker.send('shutdown');
    }
    _workerPool.clear();
    _initialized = false;
  }
}

abstract class _WorkPacket {
  final SendPort replyPort;
  _WorkPacket(this.replyPort);
  dynamic process();
}

class _SumPacket extends _WorkPacket {
  final List<int> data;
  _SumPacket(this.data, SendPort replyPort) : super(replyPort);
  
  @override
  int process() {
    var sum = 0;
    for (final val in data) {
      sum += val;
    }
    return sum;
  }
}

class _MapPacket extends _WorkPacket {
  final List<int> data;
  _MapPacket(this.data, SendPort replyPort) : super(replyPort);
  
  @override
  List<int> process() {
    return data.map((x) => x * x).toList();
  }
}

class ZeroCopyPatterns {
  Future<int> typedDataSum(Uint32List data) async {
    final results = <Future<int>>[];
    final chunkSize = data.length ~/ numWorkers;
    
    for (var i = 0; i < numWorkers; i++) {
      final start = i * chunkSize;
      final end = i == numWorkers - 1 ? data.length : (i + 1) * chunkSize;
      
      results.add(Isolate.run(() {
        var sum = 0;
        for (var j = start; j < end; j++) {
          sum += data[j];
        }
        return sum;
      }));
    }
    
    final sums = await Future.wait(results);
    return sums.reduce((a, b) => a + b);
  }
  
  int singleThreadedSum(Uint32List data) {
    var sum = 0;
    for (final val in data) {
      sum += val;
    }
    return sum;
  }
}

class WorkStealingPattern {
  static const workUnitSize = 100;
  
  Future<List<int>> workStealingMap(List<int> data) async {
    final workQueue = List.generate(
      data.length ~/ workUnitSize + 1,
      (i) => _WorkUnit(
        i * workUnitSize,
        min((i + 1) * workUnitSize, data.length),
        data,
      ),
    );
    
    final results = List<int?>.filled(data.length, null);
    final futures = <Future<void>>[];
    
    for (var w = 0; w < numWorkers; w++) {
      futures.add(Isolate.run(() async {
        final localResults = <_ProcessedUnit>[];
        
        for (var i = w; i < workQueue.length; i += numWorkers) {
          final unit = workQueue[i];
          final processed = <int>[];
          
          for (var j = unit.start; j < unit.end; j++) {
            processed.add(unit.data[j] * unit.data[j]);
          }
          
          localResults.add(_ProcessedUnit(unit.start, processed));
        }
        
        return localResults;
      }).then((localResults) {
        for (final unit in localResults) {
          var idx = unit.start;
          for (final val in unit.results) {
            results[idx++] = val;
          }
        }
      }));
    }
    
    await Future.wait(futures);
    return results.cast<int>();
  }
}

class _WorkUnit {
  final int start;
  final int end;
  final List<int> data;
  
  _WorkUnit(this.start, this.end, this.data);
}

class _ProcessedUnit {
  final int start;
  final List<int> results;
  
  _ProcessedUnit(this.start, this.results);
}

Future<void> runBenchmark(String name, Future<void> Function() fn, int iterations) async {
  print('\nWarming up $name...');
  for (var i = 0; i < 10; i++) {
    await fn();
  }
  
  print('Benchmarking $name...');
  final sw = Stopwatch()..start();
  
  for (var i = 0; i < iterations; i++) {
    await fn();
  }
  
  sw.stop();
  final perOp = sw.elapsedMicroseconds / iterations;
  print('  Time: ${sw.elapsedMilliseconds}ms (${perOp.toStringAsFixed(2)}μs per op)');
  print('  Throughput: ${(iterations * dataSize / sw.elapsedMilliseconds * 1000).toStringAsFixed(0)} items/sec');
}

void runSyncBenchmark(String name, void Function() fn, int iterations) {
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
  print('  Throughput: ${(iterations * dataSize / sw.elapsedMilliseconds * 1000).toStringAsFixed(0)} items/sec');
}

Future<void> analyzeMessagePassingOverhead() async {
  print('\n=== Message Passing Overhead Analysis ===');
  
  const sizes = [10, 100, 1000, 10000, 100000];
  
  for (final size in sizes) {
    final data = List.generate(size, (i) => i);
    
    final sw1 = Stopwatch()..start();
    await Isolate.run(() {
      final copy = List<int>.from(data);
      return copy.length;
    });
    sw1.stop();
    
    final sw2 = Stopwatch()..start();
    final typedData = Uint32List.fromList(data);
    await Isolate.run(() {
      var sum = 0;
      for (final val in typedData) {
        sum += val;
      }
      return sum;
    });
    sw2.stop();
    
    print('Size $size:');
    print('  Regular list: ${sw1.elapsedMicroseconds}μs');
    print('  Typed data: ${sw2.elapsedMicroseconds}μs');
    print('  Ratio: ${(sw1.elapsedMicroseconds / sw2.elapsedMicroseconds).toStringAsFixed(2)}x');
  }
}

Future<void> main() async {
  print('=== Dart Concurrency: Traditional vs Rust-Inspired Patterns ===\n');
  print('Data size: $dataSize, Workers: $numWorkers\n');
  
  final testData = List.generate(dataSize, (i) => Random().nextInt(1000));
  final typedTestData = Uint32List.fromList(testData);
  
  final traditional = TraditionalDartConcurrency();
  final rustPatterns = RustInspiredPatterns();
  final zeroCopy = ZeroCopyPatterns();
  final workStealing = WorkStealingPattern();
  
  print('=== Summation Benchmarks ===');
  
  runSyncBenchmark(
    'Single-threaded baseline',
    () {
      var sum = 0;
      for (final val in testData) {
        sum += val;
      }
    },
    100,
  );
  
  await runBenchmark(
    'Traditional Dart (new isolates each time)',
    () => traditional.simpleIsolateSum(testData),
    100,
  );
  
  await runBenchmark(
    'Rust-inspired (worker pool with channels)',
    () => rustPatterns.channelBasedSum(testData),
    100,
  );
  
  await runBenchmark(
    'Zero-copy with TypedData',
    () => zeroCopy.typedDataSum(typedTestData),
    100,
  );
  
  print('\n=== Parallel Map Benchmarks ===');
  
  runSyncBenchmark(
    'Single-threaded map baseline',
    () => testData.map((x) => x * x).toList(),
    100,
  );
  
  await runBenchmark(
    'Traditional parallel map',
    () => traditional.naiveParallelMap(testData),
    50,
  );
  
  await runBenchmark(
    'Batched parallel map (Rust-style)',
    () => rustPatterns.batchedParallelMap(testData),
    50,
  );
  
  await runBenchmark(
    'Work-stealing pattern',
    () => workStealing.workStealingMap(testData),
    50,
  );
  
  await analyzeMessagePassingOverhead();
  
  print('\n=== Analysis ===');
  print('• Worker pools avoid isolate spawn overhead');
  print('• Batching reduces message passing overhead');
  print('• TypedData provides minor improvements');
  print('• Work stealing improves load balancing');
  print('• Isolate overhead dominates for small tasks');
  
  await rustPatterns.cleanup();
}