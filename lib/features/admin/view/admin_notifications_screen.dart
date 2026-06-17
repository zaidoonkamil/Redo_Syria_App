import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rido_syria_app/core/styles/themes.dart';
import 'package:rido_syria_app/core/widgets/CustomButton.dart';
import 'package:rido_syria_app/core/widgets/show_toast.dart';
import 'package:rido_syria_app/features/admin/cubit/cubit.dart';
import 'package:rido_syria_app/features/admin/cubit/states.dart';

import '../../../core/widgets/custom_text_field.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedRole;

  final List<String> _roles = ['user', 'driver'];


  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubitAdmin, AppStatesAdmin>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextField(
                        hintText: 'عنوان الإشعار',
                        controller: _titleController,
                        keyboardType: TextInputType.text,
                        suffixIcon:Icon(Iconsax.notification),
                        validate: (String? value) {
                          if (value!.isEmpty) {
                            return 'يرجى إدخال عنوان الإشعار';
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        hintText: 'نص الإشعار',
                        controller: _messageController,
                        keyboardType: TextInputType.text,
                        suffixIcon:Icon(Iconsax.text),
                        maxLines: 4,
                        validate: (String? value) {
                          if (value!.isEmpty) {
                            return 'يرجى إدخال نص الإشعار';
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'المستهدف (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('اختر المستهدف'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('الجميع'),
                          ),
                          ..._roles.map(
                                (role) => DropdownMenuItem<String?>(
                              value: role,
                              child: Text(_getRoleText(role)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedRole = value);
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  BlocConsumer<AppCubitAdmin, AppStatesAdmin>(
                    listener: (context, state) {
                      if (state is AdminSendNotificationSuccessState) {
                        _clearForm();
                        showSnackBarSuccess(text: 'تم إرسال الإشعار بنجاح', context: context);
                      } else if (state is AdminSendNotificationErrorState) {
                        showSnackBarError(text: 'خطأ في إرسال الإشعار', context: context);
                      }
                    },
                    builder: (context, state) {
                      return  state is AdminSendNotificationLoadingState
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: secondPrimaryColor,),
                      ) : CustomButton(
                          title: 'إرسال',
                          onPressed: (){
                          if (_formKey.currentState!.validate()) {
                            context.read<AppCubitAdmin>().sendNotification(
                              title: _titleController.text,
                              message: _messageController.text,
                              role: _selectedRole,
                            );
                          }
                      });
                      //   ElevatedButton(
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.blue,
                      //     foregroundColor: Colors.white,
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 20,
                      //       vertical: 12,
                      //     ),
                      //   ),
                      //   onPressed: state is AdminSendNotificationLoadingState ? null
                      //       : () {
                      //     if (_formKey.currentState!.validate()) {
                      //       context.read<AppCubitAdmin>().sendNotification(
                      //         title: _titleController.text,
                      //         message: _messageController.text,
                      //         role: _selectedRole,
                      //       );
                      //     }
                      //   },
                      //   child: state is AdminSendNotificationLoadingState
                      //       ? const SizedBox(
                      //     width: 20,
                      //     height: 20,
                      //     child: CircularProgressIndicator(strokeWidth: 2),
                      //   ) : const Text('إرسال'),
                      // );
                    },
                  ),
                ],
              ),
            ),
          )
          ],
          ),
        );
      },
    );
  }



  void _clearForm() {
    _titleController.clear();
    _messageController.clear();
    _selectedRole = null;
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'user':
        return 'المستخدمين';
      case 'driver':
        return 'الكباتن';
      default:
        return role;
    }
  }
}
