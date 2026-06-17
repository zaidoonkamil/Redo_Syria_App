import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rido_syria_app/core/widgets/app_bar.dart';

import '../../../core/styles/themes.dart';
import '../cubit/cubit.dart';
import '../cubit/states.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => UserCubit()..getNotifications(context: context),
      child: BlocConsumer<UserCubit,UserStates>(
        listener: (context,state){},
        builder: (context,state){
          var cubit=UserCubit.get(context);
          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Scaffold(
                body: Column(
                  children: [
                    CustomAppBarBack(),
                    SizedBox(height: 20,),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: ConditionalBuilder(
                            condition: state is! GetNotificationsLoadingState,
                            builder: (c){
                              return ConditionalBuilder(
                                  condition: cubit.getNotificationsModel!.logs.isNotEmpty,
                                  builder: (c){
                                    return ListView.builder(
                                        itemCount: cubit.getNotificationsModel!.logs.length,
                                        itemBuilder: (context,index){
                                          DateTime dateTime = DateTime.parse(cubit.getNotificationsModel!.logs[index].createdAt.toString());
                                          String formattedDate = DateFormat('yyyy/M/d').format(dateTime);
                                          return Column(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 12),
                                                width: double.maxFinite,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: borderColor,
                                                    width: 1.0,
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                    color: containerColor
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            cubit.getNotificationsModel!.logs[index].title,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.black87,
                                                            ),
                                                            textAlign: TextAlign.end,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 4,),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            cubit.getNotificationsModel!.logs[index].message,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.black54,
                                                            ),
                                                            textAlign: TextAlign.end,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 6,),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            formattedDate,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: secondPrimaryColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 12,),
                                            ],
                                          );
                                        });
                                  },
                                  fallback: (c)=>Center(child: Text('لا يوجد بيانات ليتم عرضها')));
                            },
                            fallback: (c)=>Center(child: CircularProgressIndicator(color: secondPrimaryColor,))),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
