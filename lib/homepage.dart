import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tellmebro/my_language.dart';
import 'package:translator/translator.dart';
import 'package:translator/src/langs/languages.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText speech = SpeechToText();
  Future<List<LocaleName>> localList;
  List<String> testlist = ['sfdsd', 'sfds sfsdf'];
  String _currentLocaleId = '';
  String dropdownValue = 'One';
  String wordSpoken = 'dsfasdf esfsdfsd sdfsdfsd  ';
  String translatedWords = '';
  String errorSpeech = '';
  bool hasSpeech = false;
  TextEditingController _textEditingController = new TextEditingController();
  final translator = GoogleTranslator();
  final flutterTts = FlutterTts();

  double level = 0.0;
  String _translateTo = 'en';

  @override
  void initState() {
    super.initState();
    initializeSpeachToText();
  }

  Future<void> initializeSpeachToText() async {
    hasSpeech = await speech.initialize(
        onError: onSpeechInitError, onStatus: statusListener);
    if (hasSpeech) {
      var currentLocale = await speech.systemLocale();
      setState(() {
        localList = speech.locales();
        _currentLocaleId = currentLocale.localeId;
      });
    }
  }

  onSpeechInitError(SpeechRecognitionError error) {}
  statusListener(String status) {
    print(status);
  }

  buttonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
            icon: Icon(Icons.play_arrow,
                color: (speech.isListening) ? Colors.black : Colors.red),
            onPressed: (speech.isListening) ? null : startListening),
        IconButton(icon: Icon(Icons.stop ,color: (!speech.isListening) ? Colors.black : Colors.red), onPressed: stopListening),
        IconButton(icon: Icon(Icons.cancel), onPressed: stopListening),
      ],
    );
  }

  resultArea() {
    return Column(
      children: <Widget>[
        Stack(
          children: [
            Container(
              height: 150,
              child: Center(
                  child: TextField(
                controller: _textEditingController,
                decoration: InputDecoration.collapsed(
                    hintText: (speech.isListening)
                        ? 'Listening...'
                        : 'Speak something bro.....'),
              ) //Text( wordSpoken!='' ? wordSpoken : 'Speak something bro..!'),
                  ),
            ),
            Positioned.fill(
              bottom: 10,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          blurRadius: .26,
                          spreadRadius: level * 1.5,
                          color: Colors.black.withOpacity(.05))
                    ],
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                  child: Icon(Icons.mic),
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  startListening() {
    wordSpoken = '';
    errorSpeech = '';
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 10),
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        partialResults: true);
  }

  void stopListening() {
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  resultListener(SpeechRecognitionResult result) {
    print("Speech Listner   " +
        "${result.recognizedWords} - ${result.finalResult}");
    setState(() {
      wordSpoken = "${result.recognizedWords} - ${result.finalResult}";
      _textEditingController.text = result.recognizedWords;
    });
  }

  soundLevelListener(double level) {
    setState(() {
      this.level = level;
    });
  }

  languageOption() {
    print("current Language Id $_currentLocaleId");

    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      FutureBuilder(
          future: localList,
          builder: (context, AsyncSnapshot<List<LocaleName>> snapshot) {
            if (snapshot.hasData) {
              print(snapshot.data.length);
              return DropdownButton(
                  value: _currentLocaleId,
                  items: snapshot.data
                      .map((locale) => DropdownMenuItem(
                          value: locale.localeId, child: Text(locale.name)))
                      .toList(),
                  onChanged: (selectedVal) => _languageChange(selectedVal));
            }
            return Text('Loading the languages...');
          }),
    ]);
  }

  _languageChange(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
  }

  translateBox() {
    return Column(
      children: <Widget>[
        Center(
          child: Text('To language ?'),
        ),
        DropdownButton(
            value: _translateTo,
            items: MyLanguages.getLanguages()
                .map((lang) => DropdownMenuItem(
                    value: lang.code, child: Text(lang.languageName)))
                .toList(),
            onChanged: (selectedVal) {
              setState(() {
                _translateTo = selectedVal;
              });
            }),
        Center(
            child: FlatButton(
                onPressed: transaltedText, child: Text('Ok, Translate'))),
        Container(
          height: 100,
          child: Text(translatedWords),
        ),
        IconButton(icon: Icon(Icons.volume_up), onPressed: () async {
             await flutterTts.setLanguage(_translateTo);
            var result = await flutterTts.speak(translatedWords);
            print("Result"+result);
        })
      ],
    );
  }

  transaltedText() {
    print(_textEditingController.text);
    MyLanguages.getLanguages();
    translatedWords = 'translating......';
    translator
        .translate(_textEditingController.text, to: _translateTo)
        .then((txt) {
      setState(() {
        translatedWords = txt;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tell me bro')),
      body: SingleChildScrollView(
          child: Column(
        children: [resultArea(), buttonRow(), languageOption(), translateBox()],
      )),
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
