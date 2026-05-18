import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:synchronized/synchronized.dart';

void main() {
  runApp(const WorldEventNexusApp());
}

// ---------------------------------------------------------
// Theme & Constants
// ---------------------------------------------------------
class AppColors {
  static const Color obsidian = Color(0xFF121214);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color crimson = Color(0xFFFF3366);
  static const Color gold = Color(0xFFFFD700);
}

class WorldEventNexusApp extends StatelessWidget {
  const WorldEventNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World Event Nexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.obsidian,
        fontFamily: 'Courier',
      ),
      home: const NexusDashboard(),
    );
  }
}

// ---------------------------------------------------------
// Main Layout
// ---------------------------------------------------------
class NexusDashboard extends StatelessWidget {
  const NexusDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            GlobalPulse(),
            Divider(color: AppColors.cyan, height: 1, thickness: 1),
            Expanded(flex: 3, child: GeoRaid()),
            Divider(color: AppColors.cyan, height: 1, thickness: 1),
            Expanded(flex: 2, child: EngagementChat()),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Feature 1: The Global Pulse
// ---------------------------------------------------------
class GlobalPulse extends StatefulWidget {
  const GlobalPulse({super.key});

  @override
  State<GlobalPulse> createState() => _GlobalPulseState();
}

class _GlobalPulseState extends State<GlobalPulse>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final DateTime _targetTime;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _targetTime = DateTime.now().add(const Duration(minutes: 45));
    _ticker = createTicker((_) {
      final DateTime now = DateTime.now();
      if (now.isBefore(_targetTime)) {
        setState(() {
          _timeLeft = _targetTime.difference(now);
        });
      } else {
        setState(() {
          _timeLeft = Duration.zero;
        });
        _ticker.stop();
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String hours = twoDigits(d.inHours);
    final String minutes = twoDigits(d.inMinutes.remainder(60));
    final String seconds = twoDigits(d.inSeconds.remainder(60));
    final String ms = (d.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return "$hours:$minutes:$seconds:$ms";
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates high-frequency updates
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: AppColors.obsidian,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.05),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            const Text(
              "WORLD BOSS SPAWN",
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 14,
                letterSpacing: 4.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatDuration(_timeLeft),
              style: const TextStyle(
                color: AppColors.crimson,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Feature 2: The Geo-Raid
// ---------------------------------------------------------
class RaidSlot {
  final String? playerName;
  final bool isUser;
  RaidSlot({this.playerName, this.isUser = false});
  bool get isFilled => playerName != null;
}

class GeoRaid extends StatefulWidget {
  const GeoRaid({super.key});

  @override
  State<GeoRaid> createState() => _GeoRaidState();
}

class _GeoRaidState extends State<GeoRaid> {
  final ValueNotifier<List<RaidSlot>> _slotsNotifier =
      ValueNotifier<List<RaidSlot>>(
        List<RaidSlot>.generate(15, (_) => RaidSlot()),
      );
  Timer? _simulationTimer;
  final Random _rnd = Random();
  final List<String> _names = <String>[
    "ShadowBlade",
    "Xenon_PVP",
    "DarkKnight",
    "HealBot",
    "DPS_Max",
    "Tankerz",
    "NoobSlayer",
    "EpicLoot",
    "RaidMaster",
    "Ghost",
  ];
  final Lock _raidLock = Lock();

  @override
  void initState() {
    super.initState();
    _initSlots();
    _scheduleNextEvent();
  }

  void _initSlots() {
    final List<RaidSlot> slots = List<RaidSlot>.from(_slotsNotifier.value);
    int filled = 0;
    while (filled < 7) {
      final int idx = _rnd.nextInt(15);
      if (!slots[idx].isFilled) {
        slots[idx] = RaidSlot(playerName: _names[_rnd.nextInt(_names.length)]);
        filled++;
      }
    }
    _slotsNotifier.value = slots;
  }

  void _scheduleNextEvent() {
    _simulationTimer = Timer(
      const Duration(seconds: 5),
      _handleSimulationEvent,
    );
  }

  void _handleSimulationEvent() {
    if (!mounted) return;
    final List<RaidSlot> slots = List<RaidSlot>.from(_slotsNotifier.value);

    final int filledCount = slots.where((RaidSlot s) => s.isFilled && !s.isUser).length;
    bool shouldJoin = _rnd.nextBool();

    if (filledCount < 4) shouldJoin = true;
    if (filledCount > 13) shouldJoin = false;

    if (shouldJoin) {
      final List<int> emptyIndices = <int>[];
      for (int i = 0; i < slots.length; i++) {
        if (!slots[i].isFilled) emptyIndices.add(i);
      }
      if (emptyIndices.isNotEmpty) {
        final int idx = emptyIndices[_rnd.nextInt(emptyIndices.length)];
        slots[idx] = RaidSlot(playerName: _names[_rnd.nextInt(_names.length)]);
      }
    } else {
      final List<int> filledIndices = <int>[];
      for (int i = 0; i < slots.length; i++) {
        if (slots[i].isFilled && !slots[i].isUser) filledIndices.add(i);
      }
      if (filledIndices.isNotEmpty) {
        final int idx = filledIndices[_rnd.nextInt(filledIndices.length)];
        slots[idx] = RaidSlot();
      }
    }
    _slotsNotifier.value = slots;
    _scheduleNextEvent();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _slotsNotifier.dispose();
    super.dispose();
  }

  Future<void> _toggleJoin() async {
    await _raidLock.synchronized(() async {
      final List<RaidSlot> slots = List<RaidSlot>.from(_slotsNotifier.value);

      final int userIndex = slots.indexWhere((RaidSlot s) => s.isUser);

      if (userIndex != -1) {
        slots[userIndex] = RaidSlot();
      } else {
        final List<int> emptyIndices = <int>[];

        for (int i = 0; i < slots.length; i++) {
          if (!slots[i].isFilled) {
            emptyIndices.add(i);
          }
        }

        if (emptyIndices.isNotEmpty) {
          final int idx = emptyIndices.first;

          slots[idx] = RaidSlot(playerName: "YOU (Joined)", isUser: true);
        }
      }

      _slotsNotifier.value = slots;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<RaidSlot>>(
      valueListenable: _slotsNotifier,
      builder: (BuildContext context, List<RaidSlot> slots, Widget? child) {
        final int userIndex = slots.indexWhere((RaidSlot s) => s.isUser);
        final bool isFull = !slots.any((RaidSlot s) => !s.isFilled);

        String buttonText = "JOIN RAID";
        Color buttonColor = AppColors.cyan;
        if (userIndex != -1) {
          buttonText = "LEAVE RAID";
          buttonColor = AppColors.crimson;
        } else if (isFull) {
          buttonText = "RAID FULL";
          buttonColor = Colors.grey;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: <Widget>[
              const Text(
                "GEO-RAID LOBBY",
                style: TextStyle(
                  color: AppColors.gold,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 15,
                  itemBuilder: (BuildContext context, int index) {
                    final RaidSlot slot = slots[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: slot.isFilled
                            ? (slot.isUser
                                  ? AppColors.gold.withValues(alpha: 0.15)
                                  : AppColors.cyan.withValues(alpha: 0.08))
                            : Colors.transparent,
                        border: Border.all(
                          color: slot.isFilled
                              ? (slot.isUser ? AppColors.gold : AppColors.cyan)
                              : Colors.white12,
                          width: slot.isUser ? 1.5 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: slot.isUser
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        slot.isFilled ? slot.playerName! : "-",
                        style: TextStyle(
                          color: slot.isFilled
                              ? (slot.isUser ? AppColors.gold : Colors.white)
                              : Colors.white24,
                          fontWeight: slot.isUser
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor.withValues(alpha: 0.1),
                    foregroundColor: buttonColor,
                    side: BorderSide(color: buttonColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (isFull && userIndex == -1) ? null : _toggleJoin,
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// Feature 3: The Engagement Chat
// ---------------------------------------------------------
class ChatMessage {
  final String sender;
  final String text;
  final DateTime time;
  final bool isUser;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    this.isUser = false,
  });
}

class EngagementChat extends StatefulWidget {
  const EngagementChat({super.key});

  @override
  State<EngagementChat> createState() => _EngagementChatState();
}

class _EngagementChatState extends State<EngagementChat> {
  final ValueNotifier<List<ChatMessage>> _chatNotifier = ValueNotifier<List<ChatMessage>>(<ChatMessage>[]);
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  Timer? _chatTimer;
  final Random _rnd = Random();

  final List<String> _simulatedNames = <String>[
    "Mage4Lyfe",
    "WarriorX",
    "ElfArcher",
    "Gorgon",
    "HealerPro",
  ];
  final List<String> _simulatedMessages = <String>[
    "LFG Raid!",
    "Healer looking for group",
    "What's the drop rate?",
    "Buff please!",
    "Where is the boss spawning?",
    "Need more DPS",
    "Selling epic sword, PM me",
  ];

  @override
  void initState() {
    super.initState();
    _chatNotifier.value = <ChatMessage>[
      ChatMessage(
        sender: "System",
        text: "World Boss 'Gorgoroth' is awakening...",
        time: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      ChatMessage(
        sender: "System",
        text: "Global event will begin shortly.",
        time: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      ChatMessage(
        sender: "System",
        text: "Prepare your weapons.",
        time: DateTime.now(),
      ),
    ];

    _chatTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      _addMessage(
        ChatMessage(
          sender: _simulatedNames[_rnd.nextInt(_simulatedNames.length)],
          text: _simulatedMessages[_rnd.nextInt(_simulatedMessages.length)],
          time: DateTime.now(),
        ),
      );
    });
  }

  void _addMessage(ChatMessage msg) {
    _chatNotifier.value = <ChatMessage>[..._chatNotifier.value, msg];
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final String text = _textController.text.trim();
    if (text.isNotEmpty) {
      _addMessage(
        ChatMessage(
          sender: "Player (You)",
          text: text,
          time: DateTime.now(),
          isUser: true,
        ),
      );
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    _chatNotifier.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates chat scrolling
    return RepaintBoundary(
      child: Container(
        color: Colors.black12,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ValueListenableBuilder<List<ChatMessage>>(
                valueListenable: _chatNotifier,
                builder: (BuildContext context, List<ChatMessage> messages, Widget? child) {
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ChatMessage msg = messages[index];
                      final Color senderColor = msg.sender == "System"
                          ? AppColors.crimson
                          : (msg.isUser ? AppColors.cyan : AppColors.gold);

                      final String timeStr =
                          "[${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}]";

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Courier',
                              color: Colors.white70,
                            ),
                            children: <InlineSpan>[
                              TextSpan(
                                text: "$timeStr ",
                                style: const TextStyle(color: Colors.white38),
                              ),
                              TextSpan(
                                text: "<${msg.sender}> ",
                                style: TextStyle(
                                  color: senderColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: msg.text,
                                style: TextStyle(
                                  color: msg.isUser
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'Courier',
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter message...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black45,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: Colors.white12,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: Colors.white12,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: AppColors.cyan,
                          width: 1,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: AppColors.cyan,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
                    tooltip: 'Send',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
