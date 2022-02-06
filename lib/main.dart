import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiit/single_route_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_strategy/url_strategy.dart';

import 'package:hiit/hiit.dart';
import 'package:hiit/theme.dart' as theme;
import 'package:hiit/themed_timerpicker.dart';
import 'package:hiit/themed_numberpicker.dart';

late SharedPreferences preferences;

void main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  preferences = await SharedPreferences.getInstance();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runSingleRouteApp(
    title: 'HIIT Timer',
    theme: theme.light(),
    darkTheme: theme.dark(),
    themeMode: ThemeMode.system,
    home: const Home(),
  );
}

class Default {
  static const int warmup = 120;
  static const int work = 30;
  static const int rest = 90;
  static const int cooldown = 120;
  static const int sets = 8;
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late HIITTimer timer;
  late AnimationController _controller;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Color timerColor() {
    switch (timer.current.kind) {
      case IntervalKind.warmUp:
      case IntervalKind.coolDown:
        return theme.coolDownColor;
      case IntervalKind.work:
        return theme.workColor;
      case IntervalKind.rest:
        return theme.restColor;
      default:
        return theme.defaultColor;
    }
  }

  void _do<T>(Future<T> future) {
    setState(() {
      future.then((_) {});
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1);
    _controller.addListener(() => setState(() {}));

    timer = HIITTimer(
      (double value) {
        if (value > _controller.value) _controller.value = 1;

        _controller.animateTo(value, duration: const Duration(seconds: 1));
        setState(() {});
      },
      warmUpTime: Duration(seconds: preferences.getInt("warmup") ?? Default.warmup),
      workTime: Duration(seconds: preferences.getInt("work") ?? Default.work),
      restTime: Duration(seconds: preferences.getInt("rest") ?? Default.rest),
      coolDownTime: Duration(seconds: preferences.getInt("cooldown") ?? Default.cooldown),
      sets: preferences.getInt("sets") ?? Default.sets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: timerColor(),
      appBar: AppBar(
        title: Text(timer.titleText),
        centerTitle: true,
        leading: Container(), // hide drawer hamburger menu
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                  width: MediaQuery.of(context).size.shortestSide * 0.85,
                  height: MediaQuery.of(context).size.shortestSide * 0.85,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(timer.repText, style: Theme.of(context).textTheme.headline3),
                      Text(timer.current.remainingText, style: Theme.of(context).textTheme.headline1),
                      Text(timer.subtext, style: Theme.of(context).textTheme.headline3),
                    ],
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.shortestSide * 0.8,
                  height: MediaQuery.of(context).size.shortestSide * 0.8,
                  child: CircularProgressIndicator(
                    value: _controller.value,
                    backgroundColor: Color.lerp(
                      Theme.of(context).primaryColor,
                      Theme.of(context).colorScheme.secondary,
                      0.25,
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
        foregroundColor: Theme.of(context).primaryColor,
        shape: StadiumBorder(side: BorderSide(color: Theme.of(context).primaryColor, width: 3)),
        tooltip: timer.isRunning ? "Pause" : "Play",
        onPressed: () => setState(timer.playpause),
      ),
      bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.125,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: "Settings",
                      onPressed: () {
                        scaffoldKey.currentState?.openDrawer();
                        timer.isRunning = false;
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay),
                      tooltip: "Restart",
                      onPressed: () => setState(timer.restart),
                    ),
                  ],
                ),
              ],
            ),
          )),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            border: Border(right: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2)),
          ),
          child: ListView(
            children: [
              Container(
                color: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.all(25),
                child: ListTile(
                  leading: Icon(Icons.settings, color: Theme.of(context).primaryColor),
                  dense: true,
                  title:
                      Text('Settings', textScaleFactor: 1.5, style: TextStyle(color: Theme.of(context).primaryColor)),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.timer),
                dense: true,
                title: Text('Timer', textScaleFactor: 1.25),
              ),
              TimerInput(
                title: "Warm-Up Time",
                backgroundColor: Theme.of(context).primaryColor,
                accentColor: Theme.of(context).colorScheme.secondary,
                value: Duration(seconds: preferences.getInt("warmup") ?? Default.warmup),
                onConfirm: (duration) {
                  _do(preferences.setInt("warmup", duration.inSeconds));
                  timer.warmUpTime = duration;
                  timer.restart();
                },
              ),
              TimerInput(
                title: "Work Time",
                backgroundColor: Theme.of(context).primaryColor,
                accentColor: Theme.of(context).colorScheme.secondary,
                value: Duration(seconds: preferences.getInt("work") ?? Default.work),
                onConfirm: (duration) {
                  _do(preferences.setInt("work", duration.inSeconds));
                  timer.workTime = duration;
                  timer.restart();
                },
              ),
              TimerInput(
                title: "Rest Time",
                backgroundColor: Theme.of(context).primaryColor,
                accentColor: Theme.of(context).colorScheme.secondary,
                value: Duration(seconds: preferences.getInt("rest") ?? Default.rest),
                onConfirm: (duration) {
                  _do(preferences.setInt("rest", duration.inSeconds));
                  timer.restTime = duration;
                  timer.restart();
                },
              ),
              TimerInput(
                title: "Cool-Down Time",
                backgroundColor: Theme.of(context).primaryColor,
                accentColor: Theme.of(context).colorScheme.secondary,
                value: Duration(seconds: preferences.getInt("cooldown") ?? Default.cooldown),
                onConfirm: (duration) {
                  _do(preferences.setInt("cooldown", duration.inSeconds));
                  timer.coolDownTime = duration;
                  timer.restart();
                },
              ),
              NumberInput(
                title: "Number of Sets",
                label: "Sets",
                backgroundColor: Theme.of(context).primaryColor,
                accentColor: Theme.of(context).colorScheme.secondary,
                value: preferences.getInt("sets") ?? Default.sets,
                onConfirm: (value) {
                  _do(preferences.setInt("sets", value));
                  timer.sets = value;
                  timer.restart();
                },
              ),
              Divider(color: Theme.of(context).colorScheme.secondary),
              Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 1)),
                  child: const Text("Default Settings"),
                  onPressed: () {
                    _do(preferences.setInt("warmup", Default.warmup));
                    _do(preferences.setInt("work", Default.work));
                    _do(preferences.setInt("rest", Default.rest));
                    _do(preferences.setInt("cooldown", Default.cooldown));
                    _do(preferences.setInt("sets", Default.sets));
                    timer.warmUpTime = const Duration(seconds: Default.warmup);
                    timer.workTime = const Duration(seconds: Default.work);
                    timer.restTime = const Duration(seconds: Default.rest);
                    timer.coolDownTime = const Duration(seconds: Default.cooldown);
                    timer.sets = Default.sets;
                    timer.restart();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
