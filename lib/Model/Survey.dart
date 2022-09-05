import 'package:news/Helper/String.dart';

//category model fetch category data from server side
class Survey {
  String? id, question, status;
  List<Option>? optionDataList;

  Survey({
    this.id,
    this.question,
    this.status,
    this.optionDataList,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    var optionList = (json[OPTION] as List);
    List<Option> optionData = [];
    if (optionList == null || optionList.isEmpty)
      optionList = [];
    else
      optionData = optionList.map((data) => new Option.fromJson(data)).toList();

    return new Survey(
        id: json[ID],
        question: json[QUESTION],
        status: json[STATUS],
        optionDataList: optionData);
  }
}

class Option {
  String? id;
  String? options;
  String? counter;
  String? percentage;
  String? questionId;

  Option(
      {this.id, this.options, this.counter, this.percentage, this.questionId});

  factory Option.fromJson(Map<String, dynamic> json) {
    return new Option(
        id: json[ID],
        options: json[OPTIONS],
        counter: json[COUNTER],
        percentage: json[PERCENTAGE],
        questionId: json[QUESTION_ID]);
  }
}
