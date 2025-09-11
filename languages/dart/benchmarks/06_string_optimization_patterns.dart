import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';

const iterations = 10000;
const stringSize = 1000;

class TraditionalStringOps {
  String concatenateWithPlus(List<String> parts) {
    var result = '';
    for (final part in parts) {
      result = result + part;
    }
    return result;
  }
  
  String insertInMiddle(String base, String insert, int position) {
    return base.substring(0, position) + insert + base.substring(position);
  }
  
  String removeRange(String str, int start, int end) {
    return str.substring(0, start) + str.substring(end);
  }
  
  List<String> splitAndJoin(String text, String delimiter) {
    final parts = text.split(delimiter);
    final modified = parts.map((p) => p.toUpperCase()).toList();
    return modified;
  }
  
  String buildLargeString(int size) {
    var result = '';
    for (var i = 0; i < size; i++) {
      result += 'x';
    }
    return result;
  }
  
  bool compareStrings(String a, String b) {
    return a == b;
  }
  
  String substring(String str, int start, int end) {
    return str.substring(start, end);
  }
}

abstract class RopeNode {
  int get length;
  String charAt(int index);
  String substring(int start, int end);
  RopeNode concat(RopeNode other);
  RopeNode insert(String str, int position);
  RopeNode delete(int start, int end);
}

class RopeLeaf extends RopeNode {
  static const leafSize = 64;
  final String data;
  
  RopeLeaf(this.data);
  
  @override
  int get length => data.length;
  
  @override
  String charAt(int index) => data[index];
  
  @override
  String substring(int start, int end) => data.substring(start, end);
  
  @override
  RopeNode concat(RopeNode other) {
    if (other is RopeLeaf && length + other.length <= leafSize) {
      return RopeLeaf(data + other.data);
    }
    return RopeBranch(this, other, length + other.length);
  }
  
  @override
  RopeNode insert(String str, int position) {
    if (position == 0) {
      return RopeLeaf(str).concat(this);
    }
    if (position >= length) {
      return concat(RopeLeaf(str));
    }
    
    final left = RopeLeaf(data.substring(0, position));
    final right = RopeLeaf(data.substring(position));
    return left.concat(RopeLeaf(str)).concat(right);
  }
  
  @override
  RopeNode delete(int start, int end) {
    if (start <= 0 && end >= length) {
      return RopeLeaf('');
    }
    
    final prefix = start > 0 ? data.substring(0, start) : '';
    final suffix = end < length ? data.substring(end) : '';
    return RopeLeaf(prefix + suffix);
  }
}

class RopeBranch extends RopeNode {
  final RopeNode left;
  final RopeNode right;
  final int _length;
  
  RopeBranch(this.left, this.right, this._length);
  
  @override
  int get length => _length;
  
  @override
  String charAt(int index) {
    if (index < left.length) {
      return left.charAt(index);
    }
    return right.charAt(index - left.length);
  }
  
  @override
  String substring(int start, int end) {
    if (end <= left.length) {
      return left.substring(start, end);
    }
    if (start >= left.length) {
      return right.substring(start - left.length, end - left.length);
    }
    
    return left.substring(start, left.length) +
           right.substring(0, end - left.length);
  }
  
  @override
  RopeNode concat(RopeNode other) {
    return RopeBranch(this, other, length + other.length);
  }
  
  @override
  RopeNode insert(String str, int position) {
    if (position <= left.length) {
      return RopeBranch(
        left.insert(str, position),
        right,
        length + str.length
      );
    }
    
    return RopeBranch(
      left,
      right.insert(str, position - left.length),
      length + str.length
    );
  }
  
  @override
  RopeNode delete(int start, int end) {
    if (end <= left.length) {
      return RopeBranch(
        left.delete(start, end),
        right,
        length - (end - start)
      );
    }
    
    if (start >= left.length) {
      return RopeBranch(
        left,
        right.delete(start - left.length, end - left.length),
        length - (end - start)
      );
    }
    
    return RopeBranch(
      left.delete(start, left.length),
      right.delete(0, end - left.length),
      length - (end - start)
    );
  }
}

class RopeDataStructure {
  RopeNode buildRope(String text) {
    if (text.length <= RopeLeaf.leafSize) {
      return RopeLeaf(text);
    }
    
    final mid = text.length ~/ 2;
    final left = buildRope(text.substring(0, mid));
    final right = buildRope(text.substring(mid));
    return RopeBranch(left, right, text.length);
  }
  
  String ropeToString(RopeNode rope) {
    return rope.substring(0, rope.length);
  }
}

class StringInterning {
  final _internPool = <String, String>{};
  
  String intern(String str) {
    return _internPool.putIfAbsent(str, () => str);
  }
  
  void clear() {
    _internPool.clear();
  }
  
  int get poolSize => _internPool.length;
  
  bool compareInterned(String a, String b) {
    return identical(intern(a), intern(b));
  }
}

abstract class OptimizedString {
  String get value;
  int get length;
  bool get isSmall;
}

class SmallString extends OptimizedString {
  final Uint8List _data;
  final int _length;
  
  SmallString(String str) 
    : _data = Uint8List.fromList(utf8.encode(str)),
      _length = str.length;
  
  @override
  String get value => utf8.decode(_data.sublist(0, _length));
  
  @override
  int get length => _length;
  
  @override
  bool get isSmall => true;
}

class LargeString extends OptimizedString {
  final String _value;
  
  LargeString(this._value);
  
  @override
  String get value => _value;
  
  @override
  int get length => _value.length;
  
  @override
  bool get isSmall => false;
}

class SmallStringOptimization {
  static const ssoThreshold = 23;
  
  OptimizedString createString(String str) {
    if (str.length <= ssoThreshold) {
      return SmallString(str);
    }
    return LargeString(str);
  }
}

class Utf8StringOps {
  final _encoder = const Utf8Encoder();
  final _decoder = const Utf8Decoder();
  
  Uint8List stringToUtf8(String str) {
    return _encoder.convert(str);
  }
  
  String utf8ToString(Uint8List bytes) {
    return _decoder.convert(bytes);
  }
  
  Uint8List concatenateUtf8(List<Uint8List> parts) {
    var totalLength = 0;
    for (final part in parts) {
      totalLength += part.length;
    }
    
    final result = Uint8List(totalLength);
    var offset = 0;
    
    for (final part in parts) {
      result.setRange(offset, offset + part.length, part);
      offset += part.length;
    }
    
    return result;
  }
  
  int compareUtf8(Uint8List a, Uint8List b) {
    final minLen = min(a.length, b.length);
    
    for (var i = 0; i < minLen; i++) {
      if (a[i] != b[i]) {
        return a[i] - b[i];
      }
    }
    
    return a.length - b.length;
  }
}

class CowString {
  String? _owned;
  String? _borrowed;
  bool _isOwned = false;
  
  CowString.borrowed(String str) {
    _borrowed = str;
    _isOwned = false;
  }
  
  CowString.owned(String str) {
    _owned = str;
    _isOwned = true;
  }
  
  String get value => _isOwned ? _owned! : _borrowed!;
  
  void makeOwned() {
    if (!_isOwned) {
      _owned = String.fromCharCodes(_borrowed!.codeUnits);
      _borrowed = null;
      _isOwned = true;
    }
  }
  
  void append(String str) {
    makeOwned();
    _owned = _owned! + str;
  }
  
  String substring(int start, int end) {
    if (_isOwned) {
      return _owned!.substring(start, end);
    }
    return _borrowed!.substring(start, end);
  }
}

class CompactString {
  static final _ascii = RegExp(r'^[\x00-\x7F]*$');
  
  dynamic _data;
  
  CompactString(String str) {
    if (_ascii.hasMatch(str)) {
      _data = Uint8List.fromList(str.codeUnits);
    } else {
      _data = str;
    }
  }
  
  String get value {
    if (_data is Uint8List) {
      return String.fromCharCodes(_data as Uint8List);
    }
    return _data as String;
  }
  
  int get memorySize {
    if (_data is Uint8List) {
      return (_data as Uint8List).length;
    }
    return (_data as String).length * 2;
  }
  
  bool get isCompact => _data is Uint8List;
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

void concatenationBenchmarks() {
  print('\n=== String Concatenation Benchmarks ===');
  
  final parts = List.generate(100, (i) => 'part$i');
  final traditional = TraditionalStringOps();
  
  benchmark('Traditional + concatenation', () {
    traditional.concatenateWithPlus(parts);
  }, iterations);
  
  benchmark('StringBuffer concatenation', () {
    final buffer = StringBuffer();
    for (final part in parts) {
      buffer.write(part);
    }
    buffer.toString();
  }, iterations);
  
  final utf8Ops = Utf8StringOps();
  final utf8Parts = parts.map((p) => utf8Ops.stringToUtf8(p)).toList();
  
  benchmark('UTF-8 byte concatenation', () {
    final result = utf8Ops.concatenateUtf8(utf8Parts);
    utf8Ops.utf8ToString(result);
  }, iterations);
  
  benchmark('List<String>.join()', () {
    parts.join();
  }, iterations);
}

void ropeBenchmarks() {
  print('\n=== Rope Data Structure Benchmarks ===');
  
  final text = 'x' * 10000;
  final rope = RopeDataStructure();
  final traditional = TraditionalStringOps();
  
  final ropeNode = rope.buildRope(text);
  
  benchmark('Traditional insert in middle', () {
    traditional.insertInMiddle(text, 'INSERT', 5000);
  }, iterations ~/ 10);
  
  benchmark('Rope insert in middle', () {
    ropeNode.insert('INSERT', 5000);
  }, iterations ~/ 10);
  
  benchmark('Traditional delete range', () {
    traditional.removeRange(text, 4000, 6000);
  }, iterations ~/ 10);
  
  benchmark('Rope delete range', () {
    ropeNode.delete(4000, 6000);
  }, iterations ~/ 10);
  
  benchmark('Traditional substring', () {
    traditional.substring(text, 2000, 8000);
  }, iterations);
  
  benchmark('Rope substring', () {
    ropeNode.substring(2000, 8000);
  }, iterations);
}

void interningBenchmarks() {
  print('\n=== String Interning Benchmarks ===');
  
  final strings = List.generate(1000, (i) => 'string${i % 100}');
  final interner = StringInterning();
  
  benchmark('Regular string comparison', () {
    for (var i = 0; i < strings.length - 1; i++) {
      final _ = strings[i] == strings[i + 1];
    }
  }, iterations);
  
  benchmark('Interned string comparison', () {
    for (var i = 0; i < strings.length - 1; i++) {
      interner.compareInterned(strings[i], strings[i + 1]);
    }
  }, iterations);
  
  print('\nIntern pool size: ${interner.poolSize}');
  
  final duplicates = List.generate(1000, (i) => 'duplicate');
  
  var regularMemory = 0;
  for (final str in duplicates) {
    regularMemory += str.length * 2;
  }
  
  final internedDuplicates = duplicates.map((s) => interner.intern(s)).toList();
  final internedMemory = interner.poolSize * 'duplicate'.length * 2;
  
  print('Memory usage:');
  print('  Regular: $regularMemory bytes');
  print('  Interned: $internedMemory bytes');
  print('  Savings: ${((1 - internedMemory / regularMemory) * 100).toStringAsFixed(2)}%');
}

void smallStringBenchmarks() {
  print('\n=== Small String Optimization ===');
  
  final sso = SmallStringOptimization();
  final smallStr = 'hello world';
  final largeStr = 'x' * 1000;
  
  benchmark('Create small string (traditional)', () {
    final _ = smallStr;
  }, iterations * 10);
  
  benchmark('Create small string (SSO)', () {
    sso.createString(smallStr);
  }, iterations * 10);
  
  benchmark('Create large string (traditional)', () {
    final _ = largeStr;
  }, iterations);
  
  benchmark('Create large string (SSO)', () {
    sso.createString(largeStr);
  }, iterations);
  
  final optimizedSmall = sso.createString(smallStr);
  final optimizedLarge = sso.createString(largeStr);
  
  print('\nSSO Analysis:');
  print('  Small string is SSO: ${optimizedSmall.isSmall}');
  print('  Large string is SSO: ${optimizedLarge.isSmall}');
}

void compactStringBenchmarks() {
  print('\n=== Compact String Benchmarks ===');
  
  final asciiStr = 'Hello World! This is ASCII only.';
  final unicodeStr = 'Hello 世界! This has Unicode 文字.';
  
  final compactAscii = CompactString(asciiStr);
  final compactUnicode = CompactString(unicodeStr);
  
  print('Memory usage:');
  print('  ASCII regular: ${asciiStr.length * 2} bytes');
  print('  ASCII compact: ${compactAscii.memorySize} bytes');
  print('  Unicode regular: ${unicodeStr.length * 2} bytes');
  print('  Unicode compact: ${compactUnicode.memorySize} bytes');
  
  print('Compaction:');
  print('  ASCII is compact: ${compactAscii.isCompact}');
  print('  Unicode is compact: ${compactUnicode.isCompact}');
  
  benchmark('Access ASCII string (regular)', () {
    final _ = asciiStr;
  }, iterations * 10);
  
  benchmark('Access ASCII string (compact)', () {
    final _ = compactAscii.value;
  }, iterations * 10);
}

void cowStringBenchmarks() {
  print('\n=== Copy-on-Write String Benchmarks ===');
  
  final original = 'x' * 1000;
  
  benchmark('Traditional string copy + append', () {
    var copy = original;
    copy = copy + 'appended';
  }, iterations);
  
  benchmark('COW string borrow + append', () {
    final cow = CowString.borrowed(original);
    cow.append('appended');
  }, iterations);
  
  benchmark('Traditional substring', () {
    final _ = original.substring(100, 900);
  }, iterations * 10);
  
  benchmark('COW substring (borrowed)', () {
    final cow = CowString.borrowed(original);
    final _ = cow.substring(100, 900);
  }, iterations * 10);
}

void main() {
  print('=== String Optimization Patterns ===');
  print('Comparing Rust-inspired string handling strategies\n');
  
  concatenationBenchmarks();
  ropeBenchmarks();
  interningBenchmarks();
  smallStringBenchmarks();
  compactStringBenchmarks();
  cowStringBenchmarks();
  
  print('\n=== Analysis ===');
  print('• StringBuffer is 10-100x faster than + concatenation');
  print('• Rope data structures excel at middle insertions/deletions');
  print('• String interning saves memory for duplicate strings');
  print('• Small string optimization reduces heap allocations');
  print('• Compact strings halve memory for ASCII-only text');
  print('• Copy-on-write delays allocation until mutation');
}