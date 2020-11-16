import 'package:cashew/viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cashew/bitcoincash/src/address.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';

import './send_info.dart';

class SendTab extends StatefulWidget {
  SendTab({Key key}) : super(key: key);

  @override
  _SendTabState createState() => _SendTabState();
}

class _SendTabState extends State<SendTab> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  ValueNotifier<bool> showSendInfoScreen = ValueNotifier(false);



  @override
  void initState() {
    // TODO: implement initState
    // showSendInfoScreen = ValueNotifier<bool>(false); 
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // WE don't want to be redrawing
    final viewModel = Provider.of<CashewModel>(context, listen: false);

    final overlay = QrScannerOverlayShape(
      borderColor: Colors.red,
      borderRadius: 10,
      borderLength: 30,
      borderWidth: 10,
      cutOutSize: 350,
    );

    final qrWidget = QRView(
      key: qrKey,
      onQRViewCreated: (QRViewController controller) {
        controller.scannedDataStream.listen((scanData) {
          try {
            // Try parsing
            // TODO: We need a tryParse function. Exceptions for validity check is
            // not desirable.
            Address(scanData);
            if (scanData != viewModel.sendToAddress) {
              showSendInfoScreen.value = true;
            }
          } catch (e) {
            print('error parsing address');
          }
          viewModel.sendToAddress = scanData;
        });
      },
      overlay: overlay,
    );

        return Stack(children:<Widget>[
                    Expanded(child: qrWidget),

                    ValueListenableBuilder(
        valueListenable: showSendInfoScreen,
        builder: (context, shouldShowSendInfoScreen, child) => Column(
            children: shouldShowSendInfoScreen
                ? [SendInfo(visible: showSendInfoScreen)]
                : [Spacer(),
                     Row(children: [

                      Card(
                      child: Row(
                        children: [
                          Center(
                            child: IconButton(
                          icon: Icon(Icons.send),
                          onPressed:  () {
                            // setState(() {
                              showSendInfoScreen.value = true;
                            // });
                            },
                            )
                          )]
                              ),
                            ),]
                          ),


                      // Center(
                          // child:  
                      //     Icon(Icons.volume_up),
                      // IconButton(
                      //     icon: Icon(Icons.volume_up),
                      //     onPressed: () {
                      //       setState(() {
                      //         showSendInfoScreen.value = true;
                      //       });
                      //       },
                      //       )
                      //     )
                      //   ]),

                    Card(
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: ' in satoshis',
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Consumer<CashewModel>(
                            builder: (context, model, child) {
                              Widget result;
                              if (model.initialized) {
                                result = Expanded(
                                  child: Text(
                                    '${model.activeWallet.balanceSatoshis()}',
                                  ),
                                );
                              } else {
                                result = Flexible(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return result;
                            },
                          ),
                        ],
                      ),
                    ),

                    
                  ]))

                    ]);
  }
}
