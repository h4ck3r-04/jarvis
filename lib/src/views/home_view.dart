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

  @override
  void initState() {
    super.initState();
    _initializePermissions();
    _speech = stt.SpeechToText();
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

  Future<void> _initializePermissions() async {
    // Request microphone permission
    await Permission.microphone.request();
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _command = val.recognizedWords;
            if (_command.toLowerCase().contains('jarvis')) {
              _startAnimation();
            }
          }),
        );
      }
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
    _stopAnimation();
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
      body: GestureDetector(
        onTap: () {}, // Absorb taps
        child: WebViewWidget(controller: _controller),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
