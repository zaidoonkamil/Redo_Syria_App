import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/styles/themes.dart';
import '../../../core/widgets/app_bar.dart';
import '../cubit/chat/controler.dart';

class Chat extends StatefulWidget {
  final int userId;
  const Chat({super.key, required this.userId});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  late ScrollController _scrollController;

  String _getFirstLetter(String? name) {
    if (name == null || name.trim().isEmpty) return '?';

    return name.trim()[0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(widget.userId),
      child: BlocListener<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          }
          if (state is ChatError) {

          }
        },
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    top: -100,
                    left: -100,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: -120,
                    right: -120,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: secondPrimaryColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      CustomAppBarBack(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: BlocBuilder<ChatCubit, ChatState>(
                            builder: (context, state) {
                              if (state is ChatConnecting ||state is ChatLoading) {
                                return const Center(child: CircularProgressIndicator(color: primaryColor,));
                              } else if (state is ChatLoaded) {
                                var messages = state.messages;
                                return ListView.builder(
                                  controller: _scrollController,
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final msg = messages[index];
                                    final isSender = msg['senderId'] == widget.userId;
                                    final senderName = msg['sender']?['name']?.toString() ?? '';
                                    return Align(
                                      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          isSender == false? Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: secondPrimaryColor,
                                                child: Text(
                                                  _getFirstLetter(senderName),
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                          ):Container(),
                                          Flexible(
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(vertical: 4),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isSender ? primaryColor : Colors.grey[300],
                                                borderRadius: isSender ?const BorderRadius.only(
                                                  topLeft: Radius.circular(14),
                                                  topRight: Radius.circular(14),
                                                  bottomLeft: Radius.circular(14),
                                                ):BorderRadius.only(
                                                  topLeft: Radius.circular(14),
                                                  topRight: Radius.circular(14),
                                                  bottomRight: Radius.circular(14),
                                                ),
                                              ),
                                              child: Text(
                                                msg['message'],
                                                style: TextStyle(
                                                  color: isSender ? Colors.white : Colors.black87,
                                                ),
                                                textAlign: TextAlign.end,
                                                softWrap: true,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 4,),
                                          isSender ? CircleAvatar(
                                            radius: 20,
                                            backgroundColor: secondPrimaryColor,
                                            child: Text(
                                              _getFirstLetter(senderName),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ) : Container(),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              } else if (state is ChatError) {
                                return Center(child: Text(state.message));
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      _MessageInput(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _MessageInput extends StatefulWidget {
  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final TextEditingController _controller = TextEditingController();

  void _send(BuildContext context) {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    context.read<ChatCubit>().sendMessage(text);
    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<ChatCubit>().messages.isNotEmpty) {
        final chatState = context.read<ChatCubit>();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: Colors.grey[200],
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: secondPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Transform.rotate(
                  angle: 3.1416,
                  child: const Icon(Iconsax.send_1),
                ),
                color: Colors.white,
                onPressed: () => _send(context),
              ),
            ),
            SizedBox(width: 8,),
            Expanded(
              child: TextField(
                controller: _controller,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  hintText: '... اكتب رسالتك',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

