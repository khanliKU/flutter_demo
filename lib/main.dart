import 'dart:ffi' as ffi;
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter_demo/my_random.dart';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:pointycastle/export.dart' as pCastle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import './devices.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WidgetsFlutterBinding.ensureInitialized();
    // Must add this line.
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      minimumSize: Size(360, 360),
      size: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: const MaterialColor(
          0xFF0067b9,
          {
            50: Color.fromRGBO(0x00, 0x67, 0xb9, .1),
            100: Color.fromRGBO(0x00, 0x67, 0xb9, .2),
            200: Color.fromRGBO(0x00, 0x67, 0xb9, .3),
            300: Color.fromRGBO(0x00, 0x67, 0xb9, .4),
            400: Color.fromRGBO(0x00, 0x67, 0xb9, .5),
            500: Color.fromRGBO(0x00, 0x67, 0xb9, .6),
            600: Color.fromRGBO(0x00, 0x67, 0xb9, .7),
            700: Color.fromRGBO(0x00, 0x67, 0xb9, .8),
            800: Color.fromRGBO(0x00, 0x67, 0xb9, .9),
            900: Color.fromRGBO(0x00, 0x67, 0xb9, 1),
          },
        ),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _displayValue = 0;
  late MyRandom _randomGenerator;
  double _sliderValue = 10.0 / 31.0;
  Uint8List _secretSeed = Uint8List(32);
  List<int> _cipherText = [];

  final TextEditingController _seedController = TextEditingController();
  final TextEditingController _plainTextController = TextEditingController();
  final TextEditingController _cipherTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    late ffi.DynamicLibrary dl;
    if (Platform.isAndroid) {
      dl = ffi.DynamicLibrary.open('libmy_random.so');
    } else if (Platform.isWindows) {
      dl = ffi.DynamicLibrary.open(path.join('my_random.dll'));
    }
    _randomGenerator = MyRandom(dl);
  }

  void _newRandom() {
    setState(() {
      _displayValue =
          _randomGenerator.myRandom(pow(2, _sliderValue * 31 + 1).ceil());
    });
  }

  @override
  Widget build(BuildContext context) {
    pCastle.SHA256Digest digest = pCastle.SHA256Digest();
    _secretSeed =
        digest.process(Uint8List(32)..buffer.asInt32List()[0] = _displayValue);
    _seedController.text = bytesToHex(_secretSeed);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Max Random: ${pow(2, _sliderValue * 31 + 1).ceil()}',
              ),
              Slider(
                value: _sliderValue,
                divisions: 31,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
              ),
              Text(
                '$_displayValue',
                style: Theme.of(context).textTheme.headline4,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Key: '),
                  Expanded(
                    flex: 10,
                    child: TextField(
                      controller: _seedController,
                      enabled: false,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saveSecret,
                    child: const Text('Save Key'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _loadSecret,
                    child: const Text('Load Key'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Plain text: '),
                  Expanded(
                    flex: 10,
                    child: TextField(
                      controller: _plainTextController,
                    ),
                  ),
                  ElevatedButton(
                      onPressed: _encryptText, child: const Text('Encrypt')),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Cipher text: '),
                  Expanded(
                    flex: 10,
                    child: TextField(
                      controller: _cipherTextController,
                      readOnly: true,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _decryptText,
                    child: const Text('Decrypt'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      onPressed: _encryptFile,
                      child: const Text('Encrypt file')),
                  ElevatedButton(
                      onPressed: _decryptFile,
                      child: const Text('Decrypt file')),
                ],
              ),
              const NearbyDevices(),
            ]
                .map((e) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: e,
                    ))
                .toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newRandom,
        tooltip: 'Generat Random',
        child: const Icon(Icons.casino),
      ),
    );
  }

  Future<void> _saveSecret() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'secret_key', value: _displayValue.toString());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved Key'),
        ),
      );
    }
  }

  Future<void> _loadSecret() async {
    const storage = FlutterSecureStorage();
    if (await storage.containsKey(key: 'secret_key')) {
      _displayValue = int.parse((await storage.read(key: 'secret_key'))!);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loaded Key'),
          ),
        );
      }
    }
  }

  Future<void> _encryptText() async {
    pCastle.PaddedBlockCipherImpl cipher = pCastle.PaddedBlockCipherImpl(
      pCastle.ISO7816d4Padding(),
      pCastle.CBCBlockCipher(pCastle.AESEngine()),
    );

    pCastle.PaddedBlockCipherParameters params =
        pCastle.PaddedBlockCipherParameters(
            pCastle.ParametersWithIV(
                pCastle.KeyParameter(_secretSeed), Uint8List(cipher.blockSize)),
            null);

    cipher.init(true, params);

    Uint8List plainText =
        Uint8List.fromList(_plainTextController.text.codeUnits);
    _cipherText = cipher.process(plainText);
    setState(() {
      _cipherTextController.text = bytesToHex(_cipherText, spaced: true);
    });
  }

  Future<void> _decryptText() async {
    pCastle.PaddedBlockCipherImpl cipher = pCastle.PaddedBlockCipherImpl(
      pCastle.ISO7816d4Padding(),
      pCastle.CBCBlockCipher(pCastle.AESEngine()),
    );

    pCastle.PaddedBlockCipherParameters params =
        pCastle.PaddedBlockCipherParameters(
            pCastle.ParametersWithIV(
                pCastle.KeyParameter(_secretSeed), Uint8List(cipher.blockSize)),
            null);

    cipher.init(false, params);

    try {
      Uint8List plainText = cipher.process(Uint8List.fromList(_cipherText));
      setState(() {
        _plainTextController.text = String.fromCharCodes(plainText);
      });
    } catch (e, s) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text('Error in deciphering:\n'
              '${e.toString()}'),
        ),
      );
    }
  }

  Future<void> _encryptFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      file.openRead();
      pCastle.PaddedBlockCipherImpl cipher = pCastle.PaddedBlockCipherImpl(
        pCastle.ISO7816d4Padding(),
        pCastle.CBCBlockCipher(pCastle.AESEngine()),
      );

      pCastle.PaddedBlockCipherParameters params =
          pCastle.PaddedBlockCipherParameters(
              pCastle.ParametersWithIV(pCastle.KeyParameter(_secretSeed),
                  Uint8List(cipher.blockSize)),
              null);

      cipher.init(true, params);

      Uint8List plainText = file.readAsBytesSync();
      try {
        Uint8List cipherText = cipher.process(plainText);

        String outputFileName = 'enc_${result.files.single.name}';
        if (Platform.isAndroid) {
          File outputFile = File(
              '${(await getExternalStorageDirectory())!.path}/$outputFileName');
          outputFile.openWrite();
          outputFile.writeAsBytesSync(cipherText);
          print(outputFile.path);
          //await Share.share('test');
          Share.shareFiles([outputFile.path]);
        } else if (Platform.isWindows) {
          String? outputFilePath = await FilePicker.platform.saveFile(
            dialogTitle: 'Please select an output file:',
            fileName: outputFileName,
          );
          if (outputFilePath == null) {
            // User canceled the picker
          } else {
            File outputFile = File(outputFilePath);
            outputFile.openWrite();
            outputFile.writeAsBytesSync(cipherText);
          }
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text('Error in encryption:\n'
                '${e.toString()}'),
          ),
        );
      }
    } else {
      // User canceled the picker
    }
  }

  Future<void> _decryptFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      file.openRead();
      pCastle.PaddedBlockCipherImpl cipher = pCastle.PaddedBlockCipherImpl(
        pCastle.ISO7816d4Padding(),
        pCastle.CBCBlockCipher(pCastle.AESEngine()),
      );

      pCastle.SHA256Digest digest = pCastle.SHA256Digest();
      Uint8List key = digest
          .process(Uint8List(32)..buffer.asInt32List()[0] = _displayValue);

      pCastle.PaddedBlockCipherParameters params =
          pCastle.PaddedBlockCipherParameters(
              pCastle.ParametersWithIV(
                  pCastle.KeyParameter(key), Uint8List(cipher.blockSize)),
              null);
      print(key);
      cipher.init(false, params);

      Uint8List cipherText = file.readAsBytesSync();
      try {
        Uint8List plainText = cipher.process(cipherText);
        String outputFileName = 'dec_${result.files.single.name}';
        if (Platform.isAndroid) {
          File outputFile = File(
              '${(await getExternalStorageDirectory())!.path}/$outputFileName');
          outputFile.openWrite();
          outputFile.writeAsBytesSync(plainText);
          print(outputFile.path);
          //await Share.share('test');
          Share.shareFiles([outputFile.path]);
        } else if (Platform.isWindows) {
          String? outputFilePath = await FilePicker.platform.saveFile(
            dialogTitle: 'Please select an output file:',
            fileName: outputFileName,
          );
          if (outputFilePath == null) {
            // User canceled the picker
          } else {
            File outputFile = File(outputFilePath);
            outputFile.openWrite();
            outputFile.writeAsBytesSync(plainText);
          }
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text('Error in deciphering:\n'
                '${e.toString()}'),
          ),
        );
      }
    } else {
      // User canceled the picker
    }
  }
}

String bytesToHex(List<int> bytes, {bool spaced = false}) {
  var result = StringBuffer();
  for (var part in bytes) {
    if (spaced && result.length > 0) {
      result.write(' ');
    }
    result.write(
        '${part < 16 ? '0' : ''}${part.toRadixString(16).toUpperCase()}');
  }
  return result.toString();
}
