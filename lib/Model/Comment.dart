import 'package:news/Helper/String.dart';

//comment model fetch category data from server side
class Comment {
  String? id,
      message,
      profile,
      date,
      name,
      status,
      like,
      dislike,
      totalLikes,
      totalDislikes,
      userId;
  List<Reply>? replyComList;

  Comment(
      {this.id,
      this.message,
      this.profile,
      this.date,
      this.name,
      this.replyComList,
      this.status,
      this.like,
      this.dislike,
      this.totalLikes,
      this.totalDislikes,
      this.userId});

  factory Comment.fromJson(Map<String, dynamic> json) {
    var replyList = (json[REPLY] as List);
    List<Reply> replyData = [];
    if (replyList == null || replyList.isEmpty)
      replyList = [];
    else
      replyData = replyList.map((data) => new Reply.fromJson(data)).toList();
    return new Comment(
        id: json[ID],
        message: json[MESSAGE],
        profile: json[PROFILE],
        name: json[NAME],
        date: json[DATE],
        status: json[STATUS],
        replyComList: replyData,
        like: json[LIKE],
        dislike: json[DISLIKE],
        totalDislikes: json[TOTAL_DISLIKE],
        totalLikes: json[TOTAL_LIKE],
        userId: json[USER_ID]);
  }
}

class Reply {
  String? id,
      message,
      profile,
      date,
      name,
      userId,
      parentId,
      newsId,
      status,
      like,
      dislike,
      totalLikes,
      totalDislikes;

  Reply(
      {this.id,
      this.message,
      this.profile,
      this.date,
      this.name,
      this.userId,
      this.parentId,
      this.status,
      this.newsId,
      this.like,
      this.dislike,
      this.totalLikes,
      this.totalDislikes});

  factory Reply.fromJson(Map<String, dynamic> json) {
    return new Reply(
        id: json[ID],
        message: json[MESSAGE],
        profile: json[PROFILE],
        name: json[NAME],
        date: json[DATE],
        userId: json[USER_ID],
        parentId: json[PARENT_ID],
        newsId: json[NEWS_ID],
        status: json[STATUS],
        like: json[LIKE],
        dislike: json[DISLIKE],
        totalDislikes: json[TOTAL_DISLIKE],
        totalLikes: json[TOTAL_LIKE]);
  }
}
