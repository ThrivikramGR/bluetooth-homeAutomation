import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String DEVICE_ID = "ESP32-BLE-Server";
  static const String SERVICE_UUID = "2259af6f-3592-45db-b7dc-e0fc32c49e20";
  static const String CHARACTERISTIC_UUID =
      "55014dec-12b7-4724-b85d-fda69249d8fc";

  BleConState bleConState = BleConState.searching;
  FlutterBlue flutterBlue = FlutterBlue.instance;

  Future<void> trackConnectionState(BluetoothDevice device) async {
    while (true) {
      if (!(await flutterBlue.isOn)) {
        setState(() {
          bleConState = BleConState.off;
        });
        return;
      }
      if (await getConnectedDevice() == null) {
        setState(() {
          bleConState = BleConState.disconnected;
        });
        return;
      }

      await Future.delayed(Duration(seconds: 2));
    }
  }

  Future<void> disconnectDevice() async {
    BluetoothDevice? device = await getConnectedDevice();
    try {
      await device!.disconnect();
    } catch (e) {
      return;
    }
  }

  Future<BluetoothDevice?> getConnectedDevice() async {
    List<BluetoothDevice> connectedDevices = await flutterBlue.connectedDevices;
    for (BluetoothDevice device in connectedDevices) {
      if (device.name == DEVICE_ID) {
        return device;
      }
    }
    return null;
  }

  Future<void> initServiceCharacteristic(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString() == SERVICE_UUID) {
        List<BluetoothCharacteristic> characteristics = service.characteristics;
        for (BluetoothCharacteristic characteristic in characteristics) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            remoteCharacteristic = characteristic;
            trackConnectionState(device);
            HapticFeedback.heavyImpact();
            setState(() {
              bleConState = BleConState.connected;
            });
            //todo: read init value
            bool a = await remoteCharacteristic.setNotifyValue(true);
            print(a);
          }
        }
      }
    }
  }

  Future<void> waitForBleOn() async {
    bool offFlag = false;
    while (true) {
      if (await flutterBlue.isOn) {
        return;
      } else {
        if (!offFlag) {
          offFlag = true;
          setState(() {
            bleConState = BleConState.off;
          });
        }
      }
      await Future.delayed(Duration(seconds: 2));
    }
  }

  Future<void> initBLE() async {
    await waitForBleOn();
    BluetoothDevice? device = await getConnectedDevice();
    if (device != null) {
      initServiceCharacteristic(device);
    } else {
      setState(() {
        bleConState = BleConState.searching;
      });

      bool found = false;

      flutterBlue.startScan(timeout: Duration(seconds: 4)).then((value) {
        if (!found) {
          setState(() {
            bleConState = BleConState.notFound;
          });
        }
      });

      flutterBlue.scanResults.listen((List<ScanResult> results) async {
        for (ScanResult result in results) {
          if (result.device.name == DEVICE_ID) {
            connectBLEDevice(result.device);
            flutterBlue.stopScan();
            found = true;
            return;
          }
        }
      });
    }
  }

  late BluetoothCharacteristic remoteCharacteristic;

  void connectBLEDevice(BluetoothDevice device) async {
    setState(() {
      bleConState = BleConState.connecting;
    });
    await device.connect(autoConnect: false);
    initServiceCharacteristic(device);
  }

  @override
  void initState() {
    initBLE();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    if (bleConState == BleConState.connected) {
      disconnectDevice();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303234),
      appBar: AppBar(
        backgroundColor: Color(0xFF303234),
        title: Text(
          "Smart Remote",
          style: TextStyle(
            fontFamily: "Gilroy",
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          bleConState == BleConState.connected
              ? Container()
              : Container(
                  margin: EdgeInsets.fromLTRB(0, 25, 0, 80),
                  decoration: BoxDecoration(
                    color: Color(0xFF303234),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 0.5,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Status: ",
                        style: TextStyle(
                          fontFamily: "Gilroy",
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        () {
                          switch (bleConState) {
                            case BleConState.connected:
                              return "Connected";
                            case BleConState.connecting:
                              return "Connecting...";
                            case BleConState.searching:
                              return "Searching...";
                            case BleConState.off:
                              return "Bluetooth Off";
                            case BleConState.notFound:
                              return "Device not found";
                            case BleConState.disconnected:
                              return "Disconnected";
                          }
                        }(),
                        style: TextStyle(
                          fontFamily: "Gilroy",
                          fontSize: 18,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
          bleConState == BleConState.connected
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white70,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bedroom",
                          style: TextStyle(
                            fontFamily: "Gilroy",
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          //padding: EdgeInsets.symmetric(horizontal: 20),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          crossAxisCount: 2,
                          children: [
                            PersistentNeuTextButton(
                              text: Text(
                                "Main Light",
                                style: TextStyle(
                                  fontFamily: "Gilroy",
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              unPressIcon: Icon(
                                Icons.lightbulb_outline,
                                color: Colors.white,
                              ),
                              initState: true,
                              pressIcon: Icon(
                                Icons.lightbulb,
                                color: Colors.yellow,
                              ),
                              remoteCharacteristic: remoteCharacteristic,
                              relayNum: "0",
                            ),
                            PersistentNeuTextButton(
                              text: Text(
                                "Night Light",
                                style: TextStyle(
                                  fontFamily: "Gilroy",
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              unPressIcon: Icon(
                                Icons.light_outlined,
                                color: Colors.white,
                              ),
                              initState: true,
                              pressIcon: Icon(
                                Icons.light,
                                color: Colors.yellow,
                              ),
                              remoteCharacteristic: remoteCharacteristic,
                              relayNum: "1",
                            ),
                            PersistentNeuTextButton(
                              text: Text(
                                "Fan",
                                style: TextStyle(
                                  fontFamily: "Gilroy",
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              unPressIcon: Icon(
                                FontAwesomeIcons.fan,
                                size: 20,
                                color: Colors.white,
                              ),
                              initState: true,
                              pressIcon: Icon(
                                FontAwesomeIcons.fan,
                                size: 20,
                                color: Colors.yellow,
                              ),
                              remoteCharacteristic: remoteCharacteristic,
                              relayNum: "2",
                            ),
                            PersistentNeuTextButton(
                              text: Text(
                                "Plug 1",
                                style: TextStyle(
                                  fontFamily: "Gilroy",
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              unPressIcon: Icon(
                                Icons.electric_bolt,
                                color: Colors.white,
                              ),
                              initState: true,
                              pressIcon: Icon(
                                Icons.electric_bolt,
                                color: Colors.yellow,
                              ),
                              remoteCharacteristic: remoteCharacteristic,
                              relayNum: "3",
                            ),
                            // PersistentNeuTextButton(
                            //   text: Text(
                            //     "Plug 2",
                            //     style: TextStyle(
                            //       fontFamily: "Gilroy",
                            //       fontSize: 16,
                            //       color: Colors.white,
                            //     ),
                            //   ),
                            //   unPressIcon: Icon(
                            //     Icons.electric_bolt,
                            //     color: Colors.white,
                            //   ),
                            //   initState: true,
                            //   pressIcon: Icon(
                            //     Icons.electric_bolt,
                            //     color: Colors.yellow,
                            //   ),
                            //   remoteCharacteristic: remoteCharacteristic,
                            //   relayNum: "3",
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
          SizedBox(
            height: 80,
          ),
          bleConState == BleConState.connected
              ? NeuTextButton(
                  child: Text(
                    "Disconnect",
                    style: TextStyle(
                      fontFamily: "NunitoSans",
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    disconnectDevice();

                    HapticFeedback.heavyImpact();
                  },
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                )
              : NeuTextButton(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    child: Text(
                      "Refresh",
                      style: TextStyle(
                        fontFamily: "NunitoSans",
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  onPressed: () {
                    initBLE();
                    HapticFeedback.heavyImpact();
                  },
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
        ],
      ),
    );
  }
}

class NeuTextButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry? padding;
  NeuTextButton({required this.child, required this.onPressed, this.padding});

  @override
  State<NeuTextButton> createState() => _NeuTextButtonState();
}

class _NeuTextButtonState extends State<NeuTextButton> {
  bool pressState = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (TapDownDetails val) async {
        setState(() {
          pressState = true;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          pressState = false;
        });
      },
      onTapUp: (TapUpDetails val) {
        setState(() {
          pressState = false;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        curve: Curves.linear,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: Color(0xFF303234),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: pressState ? Colors.black87 : Colors.white38,
            width: 0.5,
          ),
          boxShadow: pressState
              ? []
              : [
                  BoxShadow(
                    offset: Offset(-9, -9),
                    color: Color(0x66494949),
                    blurRadius: 16,
                  ),
                  BoxShadow(
                    offset: Offset(9, 9),
                    color: Color(0x66000000),
                    blurRadius: 16,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

class PersistentNeuTextButton extends StatefulWidget {
  final BluetoothCharacteristic remoteCharacteristic;
  final bool initState;
  final String relayNum;
  final Text text;
  final Icon pressIcon;
  final Icon unPressIcon;
  PersistentNeuTextButton({
    required this.initState,
    required this.text,
    required this.pressIcon,
    required this.unPressIcon,
    required this.remoteCharacteristic,
    required this.relayNum,
  });

  @override
  State<PersistentNeuTextButton> createState() =>
      _PersistentNeuTextButtonState();
}

class _PersistentNeuTextButtonState extends State<PersistentNeuTextButton> {
  bool pressState = false;
  late Icon icon;

  @override
  void initState() {
    pressState = widget.initState;
    widget.remoteCharacteristic.value.listen((event) {
      if (String.fromCharCodes(event)[0] == widget.relayNum)
        setState(() {
          pressState = String.fromCharCodes(event)[1] == "1" ? true : false;
        });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          pressState = !pressState;
        });
        if (pressState)
          widget.remoteCharacteristic.write("${widget.relayNum}1".codeUnits);
        else
          widget.remoteCharacteristic.write("${widget.relayNum}0".codeUnits);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        curve: Curves.linear,
        decoration: BoxDecoration(
          color: Color(0xFF303234),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: pressState ? Colors.white70 : Colors.white12,
            width: pressState ? 2 : 0.5,
          ),
          boxShadow: pressState
              ? []
              : [
                  BoxShadow(
                    offset: Offset(-9, -9),
                    color: Color(0x66494949),
                    blurRadius: 16,
                  ),
                  BoxShadow(
                    offset: Offset(9, 9),
                    color: Color(0x66000000),
                    blurRadius: 16,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            widget.text,
            pressState ? widget.pressIcon : widget.unPressIcon,
          ],
        ),
      ),
    );
  }
}

enum BleConState {
  connected,
  connecting,
  searching,
  off,
  notFound,
  disconnected
}
