import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_video_player/custom_better_player_material_progress_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Necessary initialization for package:media_kit.
  MediaKit.ensureInitialized();

  if (Platform.isAndroid) {
    if (await Permission.videos.isDenied ||
        await Permission.videos.isPermanentlyDenied) {
      final state = await Permission.videos.request();
      if (!state.isGranted) {
        await SystemNavigator.pop();
      }
    }
    if (await Permission.audio.isDenied ||
        await Permission.audio.isPermanentlyDenied) {
      final state = await Permission.audio.request();
      if (!state.isGranted) {
        await SystemNavigator.pop();
      }
    }
  } else {
    if (await Permission.storage.isDenied ||
        await Permission.storage.isPermanentlyDenied) {
      final state = await Permission.storage.request();
      if (!state.isGranted) {
        await SystemNavigator.pop();
      }
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyScreen(),
    );
  }
}

class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);

  @override
  State<MyScreen> createState() => MyScreenState();
}

class MyScreenState extends State<MyScreen> {
  // Create a [Player] to control playback.
  late final player = Player(
    configuration: const PlayerConfiguration(
      osc: true,
      libass: true,
      libassAndroidFont: '.ttf',
      logLevel: MPVLogLevel.trace,
    ),
  );

  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);
  final String url =
      'https://play.elemental.tv/v1/playlists/573f5a14761973ec1d502584/t.93247a695dea10a23e84414902f7d29001253d74c3/0.m3u8?begin=1696854300';
  List<VideoTrack> video = [];

  List<AudioTrack> audio = [];
  AudioTrack currentAudioTrack = AudioTrack.auto();

  List<SubtitleTrack> subtitle = [];
  SubtitleTrack currentSubTrack = SubtitleTrack.auto();

  @override
  void initState() {
    super.initState();
    // Play a [Media] or [Playlist].
    player.open(
      Media(url),
    );

    player.stream.tracks.listen(_listenForTrack);

    Future.delayed(
      const Duration(seconds: 2),
      () {
        player.seek(
          const Duration(
            minutes: 59,
          ),
        );
      },
    );
  }

  void _listenForTrack(Tracks tracks) {
    setState(() {
      video = tracks.video;
      audio = tracks.audio;
      subtitle = tracks.subtitle;
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width * 9.0 / 16.0,
            // Use [Video] widget to display video output.
            child: Video(
              controller: controller,
            ),
          ),
          Row(
            children: [
              SingleChildScrollView(
                child: SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      subtitle.length,
                      (index) {
                        final currentItem = subtitle.elementAt(index);

                        return InkWell(
                          onTap: () {
                            setState(
                              () {
                                currentSubTrack = currentItem;
                                player.setSubtitleTrack(currentItem);
                              },
                            );
                          },
                          child: Text(
                            '${currentItem.id} ${currentItem.codec} ${currentItem.title}',
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SingleChildScrollView(
                child: SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      audio.length,
                      (index) {
                        final currentItem = audio.elementAt(index);

                        return InkWell(
                          onTap: () {
                            setState(
                              () {
                                currentAudioTrack = currentItem;
                                player.setAudioTrack(currentAudioTrack);
                              },
                            );
                          },
                          child: Text(
                            '${currentItem.id} ${currentItem.codec} ${currentItem.language}',
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TestAnimationWidget extends StatefulWidget {
  const TestAnimationWidget({
    super.key,
    required this.passAnimationController,
    required this.child,
    this.controllerDuration,
    this.controllerLoweBound,
    this.controllerUppedBound,
  });

  final Function(AnimationController controller) passAnimationController;
  final Widget child;
  final Duration? controllerDuration;
  final double? controllerUppedBound;
  final double? controllerLoweBound;

  @override
  State<TestAnimationWidget> createState() => _TestAnimationWidgetState();
}

class _TestAnimationWidgetState extends State<TestAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: widget.controllerDuration,
      lowerBound: widget.controllerLoweBound ?? 0.0,
      upperBound: widget.controllerUppedBound ?? 1.0,
    );

    widget.passAnimationController(animationController);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    Key? key,
    required this.label,
    this.inputFormatters,
    this.textInputAction,
    this.keyboardType,
    this.onFocusChanged,
    this.onChanged,
    this.obscureText = false,
    this.isPassword = false,
    this.toggleVisibility,
    this.onEditingComplete,
    required this.hasError,
    this.isBorderPrimaryColor = false,
    this.maxLines = 1,
    this.backgroundColor,
    this.suffixIcon,
    this.textColor,
    this.prefixIcon,
    required this.getTextController,
    required this.getFocusNode,
  }) : super(key: key);

  final String label;
  final void Function(String)? onChanged;
  final void Function(bool)? onFocusChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool isPassword;
  final VoidCallback? toggleVisibility;
  final VoidCallback? onEditingComplete;
  final bool hasError;
  final bool isBorderPrimaryColor;
  final int? maxLines;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Function(TextEditingController textEditingController) getTextController;
  final Function(FocusNode focusNode) getFocusNode;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final FocusNode fieldFocusNode;
  late final TextEditingController fieldTextController;

  @override
  void initState() {
    fieldFocusNode = FocusNode();
    widget.getFocusNode(fieldFocusNode);

    fieldTextController = TextEditingController();
    widget.getTextController(fieldTextController);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color borderColor =
        widget.isBorderPrimaryColor ? theme.primaryColor : Colors.white;
    const Color errorColor = Colors.red;
    final Color currentColor = widget.hasError ? errorColor : borderColor;

    return Focus(
      onFocusChange: widget.onFocusChanged,
      child: TextFormField(
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(
          color: widget.textColor ?? currentColor,
        ),
        maxLines: widget.maxLines,
        focusNode: fieldFocusNode,
        onEditingComplete: widget.onEditingComplete,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        controller: fieldTextController,
        onChanged: widget.onChanged,
        obscureText: widget.obscureText,
        decoration: InputDecoration(
          fillColor: widget.backgroundColor,
          labelText: widget.label,
          labelStyle: TextStyle(
            color: currentColor,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 2,
              color:
                  widget.hasError ? errorColor : borderColor.withOpacity(0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 2,
              color: currentColor,
            ),
          ),
          prefixIcon: widget.prefixIcon,
          suffixIcon: GestureDetector(
            onTap: widget.toggleVisibility,
            child: widget.suffixIcon,
          ),
        ),
      ),
    );
  }
}
