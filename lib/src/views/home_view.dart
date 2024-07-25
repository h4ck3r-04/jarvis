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
  bool _isListening = false;
  bool _isAnimating = false;
  String _command = '';
  String _errorMessage = '';

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
      }),
    );
    if (available) {
      print('Speech recognition initialized successfully');
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

  Future<void> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      print('Microphone permission granted');
    } else {
      setState(() => _errorMessage = 'Microphone permission denied');
    }
  }

  void _toggleListening() async {
    if (_speech.isNotListening) {
      await _requestMicrophonePermission();
      _startListening();
    } else {
      _stopListening();
    }
  }

  void _startListening() async {
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) => setState(() {
        _command = result.recognizedWords;
        print('Recognized words: $_command');
        if (_command.toLowerCase().contains('hello')) {
          _startAnimation();
        }
      }),
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
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
                  _command,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
