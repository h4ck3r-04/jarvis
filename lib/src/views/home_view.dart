import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late WebViewController _controller;
  late stt.SpeechToText _speech;
  bool _isAnimating = false;
  String _transcription = '';
  String _errorMessage = '';
  bool _isActivated = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeechRecognition();
    _initializeWebView();
  }

  Future<void> _initializeSpeechRecognition() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech recognition status: $status'),
      onError: (errorNotification) => setState(() {
        _errorMessage =
            'Speech recognition error: ${errorNotification.errorMsg}';
        print(_errorMessage);
        _restartListening();
      }),
    );
    if (available) {
      print('Speech recognition initialized successfully');
      _startListening();
    } else {
      setState(() => _errorMessage = 'Speech recognition not available');
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadFlutterAsset('assets/blob.html');
  }

  void _startListening() async {
    await _requestMicrophonePermission();
    await _speech.listen(
      onResult: (result) => setState(() {
        if (!_isActivated &&
            result.recognizedWords.toLowerCase().contains('hello')) {
          _isActivated = true;
          _startAnimation();
          _transcription = '';
        } else if (_isActivated) {
          _transcription = result.recognizedWords;
        }
      }),
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 3),
    );
    print('Started listening');
  }

  void _restartListening() {
    Future.delayed(Duration(seconds: 1), () {
      if (_speech.isNotListening) {
        _startListening();
      }
    });
  }

  Future<void> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      print('Microphone permission granted');
    } else {
      setState(() => _errorMessage = 'Microphone permission denied');
    }
  }

  void _startAnimation() {
    if (!_isAnimating) {
      _controller.runJavaScript('startAnimation()');
      setState(() => _isAnimating = true);
      Future.delayed(Duration(seconds: 10), () {
        if (_isAnimating) {
          _stopAnimation();
        }
      });
    }
  }

  void _stopAnimation() {
    if (_isAnimating) {
      _controller.runJavaScript('stopAnimation()');
      setState(() => _isAnimating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isActivated ? _transcription : 'Say "Hello" to activate',
                  style: TextStyle(fontSize: 10.0, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: TextStyle(fontSize: 10.0, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
