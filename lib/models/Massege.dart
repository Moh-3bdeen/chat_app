class Message{
  late String message;
  late String senderId;
  late String receiverId;
  late String date;

  Message(this.message, this.senderId, this.receiverId, this.date);

  Message.fromJson(Map map){
    this.message = map["message"];
    this.senderId = map["senderId"];
    this.receiverId = map["receiverId"];
    this.date = map["date"];

  }
}