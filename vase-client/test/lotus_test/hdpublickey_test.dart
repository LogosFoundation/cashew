import 'package:test/test.dart';

import 'package:vase/lotus/hdprivatekey.dart';
import 'package:vase/lotus/bip39/bip39.dart';
import 'package:vase/lotus/networks.dart';

const testSeed =
    'festival shrimp feel before tackle pyramid immense banner fire wash steel fiscal';
const firstKey = 'bitcoincash:qrnxtucw0nu882vqhaf6sje4hp9nhh7dgsnamm8e8m';

void main() {
  test('HDPublicKey generates correct xpub', () async {
    final seedHex = Mnemonic().toSeedHex(testSeed);
    final key = HDPrivateKey.fromSeed(seedHex, NetworkType.MAIN);

    expect(key.xpubkey, key.xpubkey);
    // Derivaiton works properly from both HDPublicKey and HDPrivateKey
    expect(key.hdPublicKey.deriveChildKey('m/44/145/0').xpubkey,
        key.deriveChildKey('m/44/145/0').xpubkey);
  });

  test('HDPublicKey generates correct sub addresses', () async {
    const testXpriv =
        'xprv9s21ZrQH143K2Lk5ufDonbZMPWntzAyL8wmP524A4Ex6EAnoep7JeNq6NQbYVv2WmXBjr38xMpmCP9pbNc7K7PgmRfasWE14Jcf4gLYzdxU';
    final key = HDPrivateKey.fromXpriv(testXpriv);
    // First account addresses
    final masterAccountKey = key.deriveChildKey("m/44'/145'/0'");
    final masterReceiveKey = masterAccountKey.deriveChildNumber(0).hdPublicKey;

    // First 10 keys from account 0
    const addresses = [
      'bitcoincash:qrnxtucw0nu882vqhaf6sje4hp9nhh7dgsnamm8e8m',
      'bitcoincash:qqjr6tclgs6awpvkar4tw8y6276hhhelcc37z4577h',
      'bitcoincash:qqs7sxex3kmewpwgf2qntfu5g68rg9f7c5lsug7zfv',
      'bitcoincash:qzswyh6c7qwshawpurgeg7s9ejtdpqgfpyw9unezs6',
      'bitcoincash:qph7p8a59z0tkgke3hm4n538az99xs5d7yem9ahhuh',
      'bitcoincash:qqtzzs5zdlzt4gcfvpvagfm3wr9y3uez55kkgs2n9z',
      'bitcoincash:qz2wp4e4r5tw64wjg5pkd84pj80jeutrhyx2jz8p3r',
      'bitcoincash:qr2xxm2jqtdzhjrau7k77j4md0yx5spddstvqclrrg',
      'bitcoincash:qr4vjy45c2ynx373anphps46jghd7kaktyhtspanvq',
      'bitcoincash:qppeh23mmq2k0jpjtte6069frmkdcgh8zc4wfjmd82'
    ];
    addresses.asMap().forEach((keyNumber, address) {
      expect(
          masterReceiveKey
              .deriveChildNumber(keyNumber)
              .publicKey
              .toAddress()
              .toCashAddress(),
          address,
          reason: 'Keynumber $keyNumber failed to check against test vectors');
    });

    final masterChangeKey = masterAccountKey.deriveChildNumber(1).hdPublicKey;
    const changeAddresses = [
      'bitcoincash:qq38hnvjfq9ftkwwtfukha8mu2wg026ldqn8wv9u6n',
      'bitcoincash:qpt23tmsyrkrgjlgp2agewhf77mfchj2h555sqhfz0',
      'bitcoincash:qz8qe5p5zjfkz63r9yyydw5ewwps74rg454clr9n8x',
      'bitcoincash:qr0al93f8xjx0egfx6wekp0wc6egvsvz6y5frq9hmx',
      'bitcoincash:qz4ra979la4qlvuqemqsmeunkuxcw785hqrmrv2mlm',
      'bitcoincash:qzz2j3v8jnws9jjvfv6evapder8x76w355ssf4r9tj',
      'bitcoincash:qqq357wsxuq2f6mq6vswqc4nxsnymtq0yg5pdcdqd3',
      'bitcoincash:qrj7ktwvcn0ahjps7tf0kdnwnlg8ue02aupph7pefa',
      'bitcoincash:qp690r5ws6xn6wl03jsa2gj8le9zs4r8qcmrpgn298',
      'bitcoincash:qpglyxgjazet9s7h2aafg48sfk52ln7gruequv0lga',
    ];
    changeAddresses.asMap().forEach((keyNumber, address) {
      expect(
          masterChangeKey
              .deriveChildNumber(keyNumber)
              .publicKey
              .toAddress()
              .toCashAddress(),
          address,
          reason: 'Keynumber $keyNumber failed to check against test vectors');
    });
  });
}
