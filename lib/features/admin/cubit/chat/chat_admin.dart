import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../../core/network/remote/dio_helper.dart';

String socketUrl = url;

class AdminUsersState {}

class AdminUsersInitial extends AdminUsersState {}
class AdminUsersLoading extends AdminUsersState {}
class AdminUsersLoaded extends AdminUsersState {
  final List users;
  AdminUsersLoaded(this.users);
}
class AdminUsersError extends AdminUsersState {
  final String message;
  AdminUsersError(this.message);
}

class AdminUsersCubit extends Cubit<AdminUsersState> {
  List users = [];

  AdminUsersCubit() : super(AdminUsersLoading()) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {

    emit(AdminUsersLoading());
    try {
      final response = await Dio().get('$socketUrl/usersWithLastMessage');
      final List data = List.from(response.data);

      final Map<int, dynamic> usersMap = {};
      for (var u in data) {
        final user = u['user'];
        final lastMsg = u['lastMessage'];
        final userId = user['id'];
        if (!usersMap.containsKey(userId)) {
          usersMap[userId] = {
            'user': user,
            'lastMessage': lastMsg,
          };
        }
      }

      users = usersMap.values.toList();
      emit(AdminUsersLoaded(users));
    } catch (err) {
      debugPrint('❌ خطأ في جلب المستخدمين: $err');
      emit(AdminUsersError('فشل في جلب المستخدمين'));
    }
  }
}

/////////////////////////////////////

class AdminChatState {}

class AdminChatInitial extends AdminChatState {}

class AdminChatLoading extends AdminChatState {}

class AdminChatConnecting extends AdminChatState {}

class AdminChatLoaded extends AdminChatState {
  final List messages;
  AdminChatLoaded(this.messages);
}

class AdminChatError extends AdminChatState {
  final String message;
  AdminChatError(this.message);
}

class AdminChatCubit extends Cubit<AdminChatState> {
  final int adminId;
  final int userId;
  late IO.Socket socket;
  List messages = [];

  AdminChatCubit({
    required this.adminId,
    required this.userId,
  }) : super(AdminChatConnecting()) {
    initSocket();
  }

  void initSocket() {
    String socketUrl = "$url/chat";

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setQuery({
        'adminId': adminId.toString(),
        'userId': userId.toString(),
      })
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('✅ Admin Socket connected');
      socket.emit('getMessages', {
        'userId': userId,
        'receiverId': null,
        'limit': 30,
      });
      emit(AdminChatLoading());
    });

    socket.on('messagesLoaded', (data) {
      messages = List.from(data);
      emit(AdminChatLoaded(messages));
    });

    socket.on('newMessage', (data) {
      messages = List.from(messages)..add(data);
      emit(AdminChatLoaded(messages));
    });

    socket.onDisconnect((_) {
      debugPrint('⚠️ Admin Socket disconnected');
    });

    socket.onConnectError((err) {
      debugPrint('❌ Admin Connect Error: $err');
      emit(AdminChatError('فشل الاتصال بالسيرفر'));
    });

    socket.onError((err) {
      debugPrint('❌ Admin Socket Error: $err');
      emit(AdminChatError('خطأ في الاتصال: $err'));
    });
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final messageData = {
      'senderId': adminId,
      'receiverId': userId,
      'senderRole': 'admin',
      'message': text.trim(),
    };


    socket.emit('sendMessage', messageData);
  }

  @override
  Future<void> close() {
    socket.dispose();
    return super.close();
  }
}
