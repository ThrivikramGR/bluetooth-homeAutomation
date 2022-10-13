import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> switches = [
    "Switch 1",
    "Switch 2",
    "Switch 3",
    "Switch 4",
  ];

  void connectBluetooth() async {
    FlutterBlue flutterBlue = FlutterBlue.instance;
    bool isOn = await flutterBlue.isOn;

    List<BluetoothDevice> availableDevices = [];
    if (isOn) {
      flutterBlue.startScan(timeout: Duration(seconds: 1));
      flutterBlue.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.device.name != "" && !availableDevices.contains(r.device)) {
            availableDevices.add(r.device);
          }
        }
      });
      await Future.delayed(Duration(seconds: 2));
      availableDevices.forEach(
        (element) {
          print(element.name);
        },
      );
    }
  }

  @override
  void initState() {
    connectBluetooth();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Automation"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            switches.length,
            (index) => SwitchGroup(
              title: switches[index],
              position: index,
            ),
          ),
        ),
      ),
    );
  }
}

class SwitchGroup extends StatelessWidget {
  final String title;
  final int position;

  SwitchGroup({required this.title, required this.position});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
        ),
        Switch(value: true, onChanged: (bool val) {}),
      ],
    );
  }
}
