import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:test_video_player/video_player_value.dart';

import 'colors.dart';
import 'epg.dart';

class CustomBetterPlayerMaterialVideoProgressBar extends StatefulWidget {
  const CustomBetterPlayerMaterialVideoProgressBar(
    this.controller,
    this.betterPlayerController, {
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    this.onTapDown,
    this.showHandle = true,
    this.radius,
    required this.width,
    this.height,
    this.start,
    this.stop,
    this.bottomSpacing,
    this.duration,
    this.enableProgressBarDrag,
    this.isFullScreen = true,
    required this.videoHeight,
    this.customHeight,
    this.chanId,
    this.vodEpgId,
    this.startPosition = 0,
    this.isVod = false,
    this.toggleThumbnail,
    this.currentEpg,
    Key? key,
  }) : super(key: key);

  final VideoController? controller;
  final Player? betterPlayerController;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragUpdate;
  final VoidCallback? onTapDown;
  final bool showHandle;
  final Radius? radius;
  final double width;
  final double? height;
  final double? bottomSpacing;
  final Duration? start;
  final Duration? stop;
  final Duration? duration;
  final bool? enableProgressBarDrag;
  final bool isFullScreen;
  final double? customHeight;
  final double videoHeight;
  final String? chanId;
  final String? vodEpgId;
  final int startPosition;
  final bool isVod;
  final EPG? currentEpg;
  final Function(bool showingThumbnail)? toggleThumbnail;

  @override
  _VideoProgressBarState createState() {
    return _VideoProgressBarState();
  }
}

class _VideoProgressBarState
    extends State<CustomBetterPlayerMaterialVideoProgressBar> {
  _VideoProgressBarState() {
    listener = () {
      if (mounted) {
        setState(() {});
      }
    };
  }

  late VoidCallback listener;
  late String thumbnailLink;
  bool showThumbnail = false;
  bool shouldExpandHandle = false;

  VideoController? get controller => widget.controller;

  Player? get betterPlayerController => widget.betterPlayerController;

  bool shouldPlayAfterDragEnd = false;
  Duration? lastSeek;
  Timer? _updateBlockTimer;

  double lineHeight = 0;
  late double width;
  late String baseUrl;
  bool photoHasError = false;
  Timer? refreshLiveMomentTimer;
  Duration dotPosition = Duration.zero;
  bool hasLoadedInitially = false;

  set _toggleThumbnail(bool newValue) {
    if (showThumbnail != newValue) {
      setState(
        () {
          showThumbnail = newValue;

          if (widget.toggleThumbnail != null) {
            widget.toggleThumbnail!(newValue);
          }
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    width = widget.width;
    baseUrl =
        'https://play.elemental.tv/v1/playlists/573f5a14761973ec1d502602/t.93247a695dea10a23e84414902f7d29001253d74c3/1.m3u8?begin=1696508100';
    lineHeight = widget.customHeight ?? 4.0;
    if (widget.showHandle) lineHeight = 11.0;
    controller!.notifier.addListener(listener);
  }

  @override
  void deactivate() {
    _cancelUpdateBlockTimer();
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
    if (controller != null) {
      final oldController = controller;
      oldController?.notifier.removeListener(listener);
    }
  }

  double _getXPosition(double width) {
    double playedPartPercent = _getValue().position.inMilliseconds /
        (widget.stop!.inMilliseconds - widget.start!.inMilliseconds);

    if (playedPartPercent.isNaN) {
      playedPartPercent = 0;
    }

    final double playedPart =
        playedPartPercent > 1 ? width : playedPartPercent * width;

    return playedPart;
  }

  @override
  Widget build(BuildContext context) {
    if (!showThumbnail) {
      hasLoadedInitially = false;
    }

    final bool enableProgressBarDrag = widget.enableProgressBarDrag ?? true;

    const double seekThumbnailWidth = 160;

    double getSeekThumbnailPosition =
        _getXPosition(width).abs() - (seekThumbnailWidth * 0.5);

    if (getSeekThumbnailPosition < 0) {
      getSeekThumbnailPosition = 0;
    }

    if (getSeekThumbnailPosition + seekThumbnailWidth > width) {
      getSeekThumbnailPosition = width - seekThumbnailWidth;
    }

    dotPosition = _getValue().position;

    return SizedBox(
      height: widget.videoHeight,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: widget.height,
              child: GestureDetector(
                onHorizontalDragStart: (DragStartDetails details) {
                  if (!enableProgressBarDrag) {
                    return;
                  }

                  if (widget.onDragStart != null) {
                    widget.onDragStart!();
                  }
                },
                onHorizontalDragUpdate: (DragUpdateDetails details) {
                  if (!enableProgressBarDrag) {
                    return;
                  }

                  _toggleThumbnail = true;

                  seekToRelativePosition(details.globalPosition);

                  if (widget.onDragUpdate != null) {
                    widget.onDragUpdate!();
                  }

                  setState(
                    () {
                      if (!shouldExpandHandle) {
                        shouldExpandHandle = true;
                      }
                    },
                  );
                },
                onHorizontalDragEnd: (DragEndDetails details) {
                  if (!enableProgressBarDrag) {
                    return;
                  }

                  lastSeek = dotPosition;
                  seekToLastSeek();

                  _setupUpdateBlockTimer();
                  _resetLiveMomentTimer();

                  if (widget.onDragEnd != null) {
                    widget.onDragEnd!();
                  }

                  setState(
                    () {
                      shouldExpandHandle = false;
                      _toggleThumbnail = false;
                    },
                  );
                },
                onTapDown: (TapDownDetails details) {
                  if (!enableProgressBarDrag) {
                    return;
                  }
                  seekToRelativePosition(details.globalPosition);

                  seekToLastSeek();
                  _setupUpdateBlockTimer();
                  if (widget.onTapDown != null) {
                    widget.onTapDown!();
                  }
                },
                child: Center(
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    width: widget.width,
                    color: Colors.transparent,
                    child: Stack(
                      fit: StackFit.passthrough,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          bottom: (widget.bottomSpacing != null)
                              ? widget.bottomSpacing
                              : widget.isFullScreen
                                  ? 5
                                  : 0,
                          right: 0,
                          child: CustomPaint(
                            key: const Key('CustomPaint'),
                            painter: _ProgressBarPainter(
                              shouldExpandHandle: shouldExpandHandle,
                              value: _getValue(),
                              colors: BetterPlayerProgressColors(),
                              showHandle: widget.showHandle,
                              radius: widget.radius,
                              start: widget.start,
                              stop: widget.stop,
                              duration: widget.duration,
                              height: lineHeight,
                              getWidth: (double givenWidth) {
                                width = givenWidth;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ),
              ),
            ),
          ),
          if (showThumbnail)
            AnimatedPositioned(
              duration: Duration.zero,
              left: getSeekThumbnailPosition,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.network(
                    'https://img.freepik.com/free-photo/wide-angle-shot-single-tree-growing-clouded-sky-during-sunset-surrounded-by-grass_181624-22807.jpg',
                    frameBuilder: (context, child, frame, _) {
                      if (frame == 0) {
                        hasLoadedInitially = true;
                        photoHasError = false;
                      }

                      return Container(
                        decoration: hasLoadedInitially
                            ? BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                ),
                              )
                            : null,
                        child: child,
                      );
                    },
                    errorBuilder: (_, __, ___) {
                      photoHasError = true;
                      return const SizedBox.shrink();
                    },
                    height: 100,
                    width: seekThumbnailWidth,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                  const SizedBox(height: 20),
                  if (!photoHasError && hasLoadedInitially)
                    Text(_getCurrentSeekDuration(dotPosition)),
                  const SizedBox(height: 50),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _setupUpdateBlockTimer() {
    _updateBlockTimer = Timer(const Duration(milliseconds: 1000), () {
      lastSeek = null;
      _cancelUpdateBlockTimer();
    });
  }

  void _cancelUpdateBlockTimer() {
    _updateBlockTimer?.cancel();
    _updateBlockTimer = null;
  }

  VideoPlayerValue _getValue() {
    final playerState = controller!.player.state;

    return VideoPlayerValue(
      duration: playerState.duration,
      position: lastSeek != null ? lastSeek! : playerState.position,
      initialized: true,
    );
  }

  void seekToLastSeek() async {
    final Duration? controllerDuration = controller?.player.state.duration;

    if (controllerDuration == null) {
      return;
    }

    if (lastSeek != null) {
      if (controllerDuration >= lastSeek!) {
        await betterPlayerController!.seek(lastSeek!);
      } else {
        if (controllerDuration.inSeconds <= 12) {
          await betterPlayerController!.seek(const Duration());
        } else {
          await betterPlayerController!.seek(
            controllerDuration - const Duration(seconds: 12),
          );
        }
      }
    }
    onFinishedLastSeek();
  }

  void seekToRelativePosition(Offset globalPosition) async {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject != null) {
      final box = renderObject as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;

      _resetLiveMomentTimer();

      if (relative > 0 && relative < 1) {
        final Duration position = Duration(
                milliseconds: (widget.stop!.inMilliseconds -
                    widget.start!.inMilliseconds)) *
            relative;

        final liveMoment = _getLiveMoment();

        if (isLiveEPG(widget.currentEpg) &&
            position.compareTo(liveMoment) >= 0) {
          lastSeek = liveMoment;
          refreshLiveMomentTimer = Timer.periodic(
            const Duration(seconds: 1),
            (timer) {
              final liveMoment = _getLiveMoment();
              if (position.compareTo(liveMoment) >= 0) {
                lastSeek = liveMoment;
              } else {
                lastSeek = position;
                timer.cancel();
              }
            },
          );
          return;
        }

        lastSeek = position;

        if (relative >= 1) {
          lastSeek = widget.duration;
        }
      }
    }
  }

  void onFinishedLastSeek() {
    if (shouldPlayAfterDragEnd) {
      shouldPlayAfterDragEnd = false;
      betterPlayerController?.play();
    }
  }

  Duration _getLiveMoment() {
    final stopTime = DateTime.fromMillisecondsSinceEpoch(
      (widget.currentEpg?.stop ?? 0) * 1000,
    );

    final currentDate = DateTime.now();

    final difference = stopTime.difference(currentDate);
    final wholeDuration = widget.stop! - widget.start!;
    const backendOffset = Duration(seconds: 31);

    return (wholeDuration - difference) - backendOffset;
  }

  void _resetLiveMomentTimer() {
    refreshLiveMomentTimer?.cancel();
    refreshLiveMomentTimer = null;
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.value,
    required this.colors,
    this.showHandle = false,
    this.radius = const Radius.circular(4.0),
    this.shouldExpandHandle = false,
    this.start,
    this.stop,
    this.duration,
    this.height = 4.0,
    required this.getWidth,
  });

  final VideoPlayerValue value;
  final BetterPlayerProgressColors colors;
  final bool showHandle;
  final Radius? radius;
  final Duration? start;
  final Duration? stop;
  final Duration? duration;
  final double height;
  final bool shouldExpandHandle;
  final Function(double width) getWidth;

  @override
  bool shouldRepaint(CustomPainter painter) => true;

  @override
  void paint(Canvas canvas, Size size) {
    // const height = 4.0;
    canvas.clipRect;
    getWidth(size.width);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height),
          Offset(size.width, size.height - height / 2),
        ),
        radius ?? const Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (!value.initialized) {
      return;
    }

    double playedPartPercent = value.position.inMilliseconds /
        (stop!.inMilliseconds - start!.inMilliseconds);
    if (playedPartPercent.isNaN) {
      playedPartPercent = 0;
    }
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;

    double realVideoPositionPercent;
    if (DateTime.now().millisecondsSinceEpoch >= stop!.inMilliseconds) {
      realVideoPositionPercent = 1;
    } else {
      realVideoPositionPercent =
          value.duration!.inMilliseconds / duration!.inMilliseconds;
    }

    final double realVideoPosition = realVideoPositionPercent > 1
        ? size.width
        : realVideoPositionPercent * size.width;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height),
          Offset(realVideoPosition, size.height - height / 2),
        ),
        radius ?? const Radius.circular(4.0),
      ),
      colors.bufferedPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height - height / 2),
          Offset(playedPart, size.height),
        ),
        radius ?? const Radius.circular(4.0),
      ),
      colors.playedPaint,
    );
    if (showHandle) {
      canvas.drawCircle(
        Offset(playedPart, size.height - height / 3),
        shouldExpandHandle ? height * 1.2 : height * 0.6,
        colors.handlePaint,
      );
    }
  }
}

String _getCurrentSeekDuration(Duration seekDuration) {
  final int hours = seekDuration.inHours;
  final String minutes =
      seekDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final String seconds =
      seekDuration.inSeconds.remainder(60).toString().padLeft(2, '0');

  String result = '$minutes:$seconds';

  if (hours != 0) {
    result = '$hours:$minutes:$seconds';
  }

  return result;
}

bool isLiveEPG(EPG? currentEpg) {
  if (currentEpg == null) {
    return false;
  }

  return currentEpg.start < comparisonCurrentTime &&
      currentEpg.stop > comparisonCurrentTime;
}

int get comparisonCurrentTime {
  return DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
