import 'package:bloc/bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:rido_syria_app/core/network/remote/dio_helper.dart';

class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatConnecting extends ChatState {}

class ChatLoaded extends ChatState {
  final List messages;
  ChatLoaded(this.messages);
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}

class ChatCubit extends Cubit<ChatState> {
  final int userId;
  late IO.Socket socket;
  List messages = [];

  ChatCubit(this.userId) : super(ChatConnecting()) {
    initSocket();
  }

  void initSocket() {
    final nsp  = "$url/chat";

    socket = IO.io(
      nsp,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,

        'forceNew': true,
        'multiplex': false,
        'query': {'userId': userId.toString()},

        // 'auth': {'token': token},
      },
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('✅ Socket connected');
      socket.emit('getMessages', {'userId': userId, 'receiverId': null});
      emit(ChatLoading());
    });

    socket.onDisconnect((reason) {
      debugPrint('! socket disconnected: $reason');
    });

    socket.on('messagesLoaded', (data) {
      messages = List.from(data);
      emit(ChatLoaded(messages));
    });

    socket.on('newMessage', (data) {
      messages = List.from(messages)..add(data);
      emit(ChatLoaded(messages));
    });

    socket.onConnectError((err) => debugPrint('❌ Connect Error: $err'));
    socket.onError((err) => debugPrint('❌ Socket Error: $err'));
  }

  void sendMessage(String text, {int? receiverId}) {
    if (text.trim().isEmpty) return;

    final messageData = {
      'senderId': userId,
      'receiverId': receiverId,
      'message': text.trim(),
    };

    // // إضافة الرسالة محليًا فورًا
    // final localMessage = {
    //   'senderId': userId,
    //   'receiverId': receiverId,
    //   'message': text.trim(),
    //   'sender': {'id': userId, 'name': 'أنت', 'role': 'user'},
    //   'receiver': receiverId != null ? {'id': receiverId} : null,
    //   'createdAt': DateTime.now().toIso8601String(),
    // };
    //
    // messages = List.from(messages)..add(localMessage);
    // emit(ChatLoaded(messages));

    // إرسال الرسالة للسيرفر

    socket.emit('sendMessage', messageData);
  }

  @override
  Future<void> close() {
    socket.dispose();
    return super.close();
  }
}
