class Search {
  final String text;
  final String type;

  Search({required this.text, required this.type});

  factory Search.fromJson(Map<String, dynamic> json) {
    return Search(text: json['text'], type: json['type']);
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'type': type};
  }
}
