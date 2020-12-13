import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'dart:typed_data';
import 'package:pointycastle/ecc/api.dart';
import 'childnumber.dart';
import '../exceptions.dart';

import 'package:pointycastle/pointycastle.dart';

///
/// Static utilities used in BIP 32 Hierarchical Deterministic Wallets (HDW).
/// Ported from BitcoinJ-SV
///
class HDUtils {
//    static final Joiner PATH_JOINER = Joiner.on("/");
  static final _domainParams = ECDomainParameters('secp256k1');

  static HMac createHmacSha512Digest(Uint8List key) {
    var digest = SHA512Digest();
    var hMac = HMac(digest, digest.byteLength);
    hMac.init(KeyParameter(key));
    return hMac;
  }

  static Uint8List hmacSha512WithDigest(HMac hmacSha512, Uint8List data) {
    hmacSha512.reset();
    hmacSha512.update(data, 0, data.length);
    var out = Uint8List(64);
    hmacSha512.doFinal(out, 0);
    return out;
  }

  static Uint8List hmacSha512WithKey(Uint8List key, Uint8List data) {
    return hmacSha512WithDigest(createHmacSha512Digest(key), data);
  }

  static Uint8List toCompressed(Uint8List uncompressedPoint) {
    return _domainParams.curve.decodePoint(uncompressedPoint).getEncoded(true);
  }

  /// Append a derivation level to an existing path */
  static List<ChildNumber> append(
      List<ChildNumber> path, ChildNumber childNumber) {
    path.add(childNumber);
    return path;
  }

  /// Concatenate two derivation paths */
  static List<ChildNumber> concat(
      List<ChildNumber> path, List<ChildNumber> path2) {
    return path + path2;
  }

  /// Convert to a string path, starting with "M/" */
  static String formatPath(List<ChildNumber> path) {
    return path.fold('M', (prev, elem) => prev + '/' + elem.toString());
  }

  //
  // The path is a human-friendly representation of the deterministic path. For example:
  //
  // "44H / 0H / 0H / 1 / 1"
  //
  // Where a letter "H" means hardened key. Spaces are ignored.
  ///
  static List<ChildNumber> parsePath(String path) {
    if (!(path.startsWith('m') || path.startsWith('M'))) {
      throw InvalidPathException("Valid paths start with an 'm' or an 'M'");
    }

    path = path.toUpperCase();
    path = path.replaceAll("'", 'H');

    var parsedNodes = path.replaceFirst('M', '').split('/');
    var nodes = <ChildNumber>[];

    for (var n in parsedNodes) {
      n = n.replaceAll(' ', '');
      if (n.isEmpty) {
        continue;
      }
      var isHard = n.endsWith('H');
      if (isHard) {
        n = n.substring(0, n.length - 1);
      }
      var nodeNumber = int.parse(n);
      nodes.add(ChildNumber(nodeNumber, isHard));
    }

    return nodes;
  }
}
