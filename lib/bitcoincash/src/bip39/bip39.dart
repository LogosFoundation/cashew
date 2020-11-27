import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

import 'package:pointycastle/key_derivators/api.dart';
import 'package:unorm_dart/unorm_dart.dart';
import 'package:pointycastle/api.dart';

import '../encoding/utils.dart';
import './wordlists/chinese_simplified.dart';
import './wordlists/chinese_traditional.dart';
import './wordlists/english.dart';
import './wordlists/french.dart';
import './wordlists/italian.dart';
import './wordlists/japanese.dart';
import './wordlists/korean.dart';
import './wordlists/spanish.dart';

// thanks to https:// github.com/yshrsmz/bip39-dart
// the source code come from here

/// The supported word lists for Bip39 mnemonics
enum Wordlist {
  CHINESE_SIMPLIFIED,
  CHINESE_TRADITIONAL,
  ENGLISH,
  FRENCH,
  ITALIAN,
  JAPANESE,
  KOREAN,
  SPANISH,
}

/// Byte buffer to represent a random seed
typedef RandomBytes = Uint8List Function(int size);

/// This class implements the Bip39 spec.
///
/// *See:* <The Bi>39 Spec](https:// github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
///
/// Mnemonic seeds provide a means to derive a private key from a standard, indexed dictionary
/// of words. This is a popular means for wallets to provide backup and recovery functionality
/// to users.
class Mnemonic {
  Wordlist DEFAULT_WORDLIST;

  static const int _SIZE_8BITS = 255;
  static const String _INVALID_ENTROPY = 'Invalid entroy';
  static const String _INVALID_MNEMONIC = 'Invalid mnemonic';
  static const String _INVALID_CHECKSUM = 'Invalid checksum';

  /// Construct a new Mnemonic instance
  ///
  /// [wordList] - Wordlist used to generic new mnemonics. Defaults to English
  Mnemonic({Wordlist wordList = Wordlist.ENGLISH}) {
    DEFAULT_WORDLIST = wordList;
  }

  /// Generates a random mnemonic.
  ///
  /// Defaults to 128-bits of entropy.
  /// By default it uses `Random.secure()` under the food to get random bytes,
  /// but you can swap RNG by providing [randomBytes].
  ///
  /// [strength] - Optional number of entropy bits
  ///
  /// [randomBytes] - A seed buffer of random data to provide entropy
  String generateMnemonic(
      {int strength = 128, RandomBytes randomBytes = _nextBytes}) {
    assert(strength % 32 == 0);

    final entropy = randomBytes(strength ~/ 8);

    return _entropyToMnemonic(entropy);
  }

  /// Converts [mnemonic] code to seed.
  ///
  /// [mnemonic] - An existing mnemonic string that will be deterministically converted into a seed.
  ///
  /// Returns a byte array containing the seed data
  Uint8List toSeed(String mnemonic, [String password = '']) {
    final mnemonicBuffer = utf8.encode(nfkd(mnemonic));
    final saltBuffer = utf8.encode(_salt(nfkd(password)));
    final pbkdf2 = KeyDerivator('SHA-512/HMAC/PBKDF2');

    pbkdf2.init(Pbkdf2Parameters(saltBuffer, 2048, 64));
    return pbkdf2.process(mnemonicBuffer);
  }

  /// Converts [mnemonic] code to seed, as hex string.
  ///
  /// [mnemonic] - An existing mnemonic string that will be deterministically converted into a seed.
  ///
  /// Returns a hex string containing the seed data
  String toSeedHex(String mnemonic, [String password = '']) {
    return toSeed(mnemonic, password).map((byte) {
      return byte.toRadixString(16).padLeft(2, '0');
    }).join('');
  }

  /// Checks a mnemonic string for validity against the known word list
  ///
  /// [mnemonic] - The mnemonic string to check for validity
  ///
  /// Returns *true* if the mnemonic is valid
  Future<bool> validateMnemonic(String mnemonic) async {
    try {
      await _mnemonicToEntropy(mnemonic);
    } catch (e) {
      return false;
    }
    return true;
  }

  /// Converts [entropy] to mnemonic code.
  String _entropyToMnemonic(Uint8List entropy) {
    if (entropy.length < 16) {
      throw ArgumentError(_INVALID_ENTROPY);
    }
    if (entropy.length > 32) {
      throw ArgumentError(_INVALID_ENTROPY);
    }
    if (entropy.length % 4 != 0) {
      throw ArgumentError(_INVALID_ENTROPY);
    }

    final entroypyBits = _bytesToBinary(entropy);
    final checksumBits = _deriveChecksumBits(entropy);

    final bits = entroypyBits + checksumBits;

    final regex = RegExp(r'.{1,11}', caseSensitive: false, multiLine: false);
    final chunks = regex
        .allMatches(bits)
        .map((match) => match.group(0))
        .toList(growable: false);

    final _wordRes = getWordlist(DEFAULT_WORDLIST);

    return chunks
        .map((binary) => _wordRes[_binaryToByte(binary)])
        .join(DEFAULT_WORDLIST == Wordlist.JAPANESE ? '\u3000' : ' ');
  }

  /// Converts [mnemonic] code to entropy.
  ///
  /// [mnemonic] - An existing mnemonic string that will be deterministically converted into a seed.
  Future<Uint8List> _mnemonicToEntropy(String mnemonic) async {
    final _wordRes = getWordlist(DEFAULT_WORDLIST);
    final words = nfkd(mnemonic).split(' ');

    if (words.length % 3 != 0) {
      throw ArgumentError(_INVALID_MNEMONIC);
    }

    // convert word indices to 11bit binary strings
    final bits = words.map((word) {
      final index = _wordRes.indexOf(word);
      if (index == -1) {
        throw ArgumentError(_INVALID_MNEMONIC);
      }

      return index.toRadixString(2).padLeft(11, '0');
    }).join('');

    // split the binary string into ENT/CS
    final dividerIndex = (bits.length / 33).floor() * 32;
    final entropyBits = bits.substring(0, dividerIndex);
    final checksumBits = bits.substring(dividerIndex);

    final regex = RegExp(r'.{1,8}');

    final entropyBytes = Uint8List.fromList(regex
        .allMatches(entropyBits)
        .map((match) => _binaryToByte(match.group(0)))
        .toList(growable: false));
    if (entropyBytes.length < 16) {
      throw StateError(_INVALID_ENTROPY);
    }
    if (entropyBytes.length > 32) {
      throw StateError(_INVALID_ENTROPY);
    }
    if (entropyBytes.length % 4 != 0) {
      throw StateError(_INVALID_ENTROPY);
    }

    final newCheckSum = _deriveChecksumBits(entropyBytes);
    if (newCheckSum != checksumBits) {
      throw StateError(_INVALID_CHECKSUM);
    }

    return entropyBytes;
  }

  static Uint8List _nextBytes(int size) {
    final rnd = Random.secure();
    final bytes = Uint8List(size);
    for (var i = 0; i < size; i++) {
      bytes[i] = rnd.nextInt(_SIZE_8BITS);
    }
    return bytes;
  }

  String _deriveChecksumBits(Uint8List entropy) {
    final ENT = entropy.length * 8;
    final CS = ENT ~/ 32;

    // final hash = sha256.newInstance().convert(entropy);
    var hash = sha256(entropy);
    return _bytesToBinary(Uint8List.fromList(hash)).substring(0, CS);
  }

  String _bytesToBinary(Uint8List bytes) {
    return bytes.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join('');
  }

  int _binaryToByte(String binary) {
    return int.parse(binary, radix: 2);
  }

  List<String> getWordlist(Wordlist wordlist) {
    switch (wordlist) {
      case Wordlist.CHINESE_SIMPLIFIED:
        return chineseSimplified;
      case Wordlist.CHINESE_TRADITIONAL:
        return chineseTraditional;
      case Wordlist.ENGLISH:
        return english;
      case Wordlist.FRENCH:
        return french;
      case Wordlist.ITALIAN:
        return italian;
      case Wordlist.JAPANESE:
        return japanese;
      case Wordlist.KOREAN:
        return korean;
      case Wordlist.SPANISH:
        return spanish;
      default:
        return english;
    }
  }

  String _salt(String password) {
    return 'mnemonic${password ?? ""}';
  }
}
