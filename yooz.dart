// Author : t.me/Salari_info
library yooz;

import 'dart:math';

class YouzParser {
  String input_data_string;
  String textError = "متاسفم، متوجه نشدم.";
  List<Map<String, dynamic>> patterns = [];
  Map<String, String> definitions = {};
  List<String> stopWords = [];
  List<String> randomMessage = [];
  List<Map<String, dynamic>> keywords = [];
  Map<String, dynamic> tempVars = {};
  Map<String, dynamic> collections = {};
  Map<String, dynamic> collection_patterns = {};
  Map<String, dynamic> lastMatchedPattern;

  void parse(String input) {
    discoverCollections(input);
    input_data_string = input;
    final definitionRegex = RegExp(r'#(\S+)\s*:\s*(.*?)\s*\.', multiLine: true);
    for (final match in definitionRegex.allMatches(input)) {
      final key = match.group(1)?.trim();
      final value = match.group(2)?.trim();
      if (key != null && value != null) {
        definitions[key] = value;
      }
    }

    final patternRegex =
        RegExp(r'\(\s*\+\s*(.*?)\s*-\s*(.*?)\s*\)', multiLine: true);
    for (final match in patternRegex.allMatches(input)) {
      final userPattern = match.group(1)?.trim();
      final bot = match.group(2)?.trim();
      String botmsg;
      if (bot.contains('ـ')){
        List<String> parts = bot.split('ـ');
        for (String part in parts) {
          
          randomMessage.add(part);
          var random = Random();
          int randomIndex = random.nextInt(randomMessage.length);
          botmsg = randomMessage[randomIndex];
        }
      }else {
        botmsg = bot;
      }

      var botResponses = [botmsg];

      if (userPattern != null && botResponses != null) {
        if (userPattern.startsWith('{')) {
          final keywords = userPattern
              .substring(1, userPattern.length - 1)
              .split('،')
              .map((keyword) => keyword.trim())
              .toList();
          this
              .keywords
              .add({'keywords': keywords, 'botResponses': botResponses});
        } else {
          patterns
              .add({'userPattern': userPattern, 'botResponses': botResponses});
        }
      }
    }

    final stopWordsRegex = RegExp(r'-\s*\{\s*(.*?)\s*\}', multiLine: true);
    for (final match in stopWordsRegex.allMatches(input)) {
      final words =
          match.group(1)?.split('،').map((word) => word.trim()).toList();
      if (words != null) {
        stopWords.addAll(words);
      }
    }
  }

  

  String getResponse(String userMessage) {
    final cleanedMessage = removeStopWords(userMessage);
    lastMatchedPattern = null;

    for (final pattern in patterns) {
      final userPattern = pattern['userPattern'] as String;
      final botResponses = pattern['botResponses'] as List<String>;
      final regexPattern = createRegex(userPattern);
      RegExpMatch matchReg = regexPattern.firstMatch(cleanedMessage);
      if (matchReg != null) {
        List<String> match = [matchReg.group(0), matchReg.group(1)];
        lastMatchedPattern = {
          'userPattern': userPattern,
          'botResponses': botResponses
        };
        final responses = botResponses;
        final response =
            responses[DateTime.now().millisecondsSinceEpoch % responses.length];
        if (response.endsWith('!>')) {
          final additionalResponse = getAdditionalResponses(
              response.substring(0, response.length - 99).trim(),
              cleanedMessage);
          return additionalResponse.replaceAll('!>', '');
        }
        return resolveResponse(response, match);
      }
    }

    final messageWords = cleanedMessage.split(' ');
    for (final keywordPattern in keywords) {
      final keywords = keywordPattern['keywords'] as List<String>;
      final botResponses = keywordPattern['botResponses'] as List<String>;
      if (containsKeywords(messageWords, keywords)) {
        lastMatchedPattern = {
          'keywords': keywords,
          'botResponses': botResponses
        };
        final response = botResponses[
            DateTime.now().millisecondsSinceEpoch % botResponses.length];
        if (response.endsWith('!>')) {
          return getAdditionalResponses(
              response.substring(0, response.length - 99).trim(),
              cleanedMessage);
        }
        return resolveResponse(response, null);
      }
    }

    return textError;
  }

  String removeStopWords(String message) {
    final words = message.split(' ');
    return words.where((word) => !stopWords.contains(word)).join(' ');
  }

  RegExp createRegex(String pattern) {
    return (RegExp(
        '^${pattern.replaceAll(RegExp(r'\\*([0-9]*)'), '(.*?)')}\$'));
  }

  String resolveResponse(String response, List<String> match) {
    String resolvedResponse = response;
    for (int i = 1; i < match.length; i++) {
      resolvedResponse = resolvedResponse.replaceAll('*$i', match[i].trim());
    }
    return resolvedResponse.replaceAllMapped(RegExp(r'#(\S+)'), (match) {
      return this.definitions[match.group(1)] ?? match.group(0);
    });
  }

  bool containsKeywords(List<String> messageWords, List<String> keywords) {
    return keywords.every((keyword) => messageWords.contains(keyword));
  }

  double random() {
    return Random().nextDouble();
  }

  String getAdditionalResponses(String initialResponse, String userMessage) {
    String additionalResponses = initialResponse;
    for (var pattern in this.patterns) {
      String userPattern = pattern['userPattern'];
      final botResponses = pattern['botResponses'];
      RegExp regexPattern = createRegex(userPattern);
      RegExpMatch matchReg = regexPattern.firstMatch(userMessage);
      if (matchReg != null) {
        List<String> match = [for (int i = 0; i <= matchReg.groupCount; i++) matchReg.group(i)];
        print(match);
  
        final responses = botResponses.cast<String>();
        final randomResponse = responses[random];
        additionalResponses += ' ' + resolveResponse(randomResponse, match);
      }
    }
    return additionalResponses;
  }
  

  bool _isTempVarDeclarationLine(String line) {
    line = line.trim();
    final wordsSeparated = line.split(' ');
    final firstWord = wordsSeparated[0];
    final firstChar = firstWord[0];
    final nextWord = wordsSeparated[1];
    return firstChar == '=' && nextWord == ':';
  }

  void defineTempVars(String text) {
    final lines = text.split('\n');
    for (var line in lines) {
      line = line.trim();
      final isDeclarationLine = _isTempVarDeclarationLine(line);
      if (isDeclarationLine) {
        final chunks = line.split(' ');
        final firstChunk = chunks[0];
        final lastChunk = chunks[2];
        final varName = firstChunk.substring(1);
        final value = lastChunk.trim();
        this.tempVars[varName] = value;
      }
    }
  }

  String replaceTempVars(String response) {
    final lines = response.split('\n');
    String resultText = '';
    for (var line in lines) {
      line = line.trim();
      final isDeclarationLine = _isTempVarDeclarationLine(line);
      if (!isDeclarationLine) {
        final chunks = line.split(' ');
        for (var chunk in chunks) {
          final firstChar = chunk[0];
          if (firstChar == '=') {
            final varName = chunk.substring(1);
            resultText += this.tempVars[varName] + ' ';
          } else {
            resultText += chunk + ' ';
          }
        }
      }
      resultText += '\n';
    }
    //console.log(result_text);
    return resultText;
  }

  bool _isAnswerPart(String line) {
    final firstChar = line[0];
    return firstChar == '-';
  }

  void discoverCollections(String input) {
    bool openParenthesis = false;
    String outsideText = '';
    int parenthesisDepth = 0;
  
    
    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      if (char == '(') {
        openParenthesis = true;
        parenthesisDepth++;
      } else if (char == ')') {
        parenthesisDepth--;
        if (parenthesisDepth == 0) {
          openParenthesis = false;
          continue;
        }
      }

      if (openParenthesis) {
        continue;
      } else {
        outsideText += char;
      }
    }

    List<String> lines = outsideText.trim().split('\n');

    for (String line in lines) {
      if (line.contains('{')) {
        int startIndex = line.indexOf('{');
        int endIndex = line.indexOf('}');
        String between = line.substring(startIndex + 1, endIndex);
        List<String> items = between.split('،');
        for (int i = 0; i < items.length; i++) {
          items[i] = items[i].trim();
        }
        String collectionName = line.substring(0, startIndex).trim();
        this.collections[collectionName] = items;
      }
    }
  }

  String checkForCollectionsPattern(String messageText) {
    List<String> chunks = messageText.trim().split(' ');
    Map<String, List<String>> collectionEntries = this.collections;
    String resultText = '';
  
    for (String chunk in chunks) {
      String isInCollections = '';
      for (String key in collectionEntries.keys) {
        if (key.contains(chunk)) {
          isInCollections = key;
          break;
        }
      }
      if (isInCollections.isNotEmpty) {
        resultText += '&' + isInCollections + ' ';
      } else {
        resultText += chunk + ' ';
      }
    }
  
    return resultText.trim();
  }
}
