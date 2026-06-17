import 'package:flutter/material.dart';

class CardOfOrder extends StatelessWidget {
  const CardOfOrder({
    super.key,
    required this.name,
    required this.phone,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.name1,
    required this.phone1,
    required this.location1,
    required this.price,
    required this.deliveryPrice,
    required this.totalPrice,
    // required this.getOrderModel
  });

  final String name1;
  final String phone1;
  final String location1;
  final String name;
  final String phone;
  final String location;
  final String status;
  final String createdAt;
  final String price;
  final String deliveryPrice;
  final String totalPrice;

  // final dynamic getOrderModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          width: double.maxFinite,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(name1),
                  Spacer(),
                  Text('الاسم'),
                  Image.asset('assets/images/fluent_person-16-regular.png'),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(phone1),
                  Spacer(),
                  Text('رقم الهاتف'),
                  Image.asset('assets/images/solar_phone-outline (3).png'),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(location1),
                  Spacer(),
                  Text('الموقع'),
                  Image.asset('assets/images/mingcute_location-line (2).png'),
                ],
              ),
              SizedBox(height: 12),
              Container(width: double.maxFinite, height: 2, color: Colors.grey),
              SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          status == 'pending'
                              ? Colors.yellow.shade100
                              : status == 'Delivery'
                              ? Colors.blue.shade100
                              : status == 'completed'
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                    ),
                    child:
                        status == 'pending'
                            ? Text(
                              ' في الانتضار ',
                              style: TextStyle(color: Colors.yellow),
                            )
                            : status == 'Delivery'
                            ? Text(
                              ' قيد التوصيل ',
                              style: TextStyle(color: Colors.blue),
                            )
                            : status == 'completed'
                            ? Text(
                              ' مكتمل ',
                              style: TextStyle(color: Colors.green),
                            )
                            : Text(
                              ' ملغي ',
                              style: TextStyle(color: Colors.red),
                            ),
                  ),
                  Spacer(),
                  Text('حالة الطلب'),
                  Image.asset('assets/images/mingcute_sandglass-2-line.png'),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(name),
                  Spacer(),
                  Text('الاسم'),
                  Image.asset('assets/images/fluent_person-16-regular.png'),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(phone),
                  Spacer(),
                  Text('رقم الهاتف'),
                  Image.asset('assets/images/solar_phone-outline (3).png'),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(location),
                  Spacer(),
                  Text('الموقع'),
                  Image.asset('assets/images/mingcute_location-line (2).png'),
                ],
              ),
              SizedBox(height: 12),
              Container(width: double.maxFinite, height: 2, color: Colors.grey),
              SizedBox(height: 12),
              Row(
                children: [
                  Text('د.ع '),
                  Text(price),
                  Spacer(),
                  Text('سعر الطلب'),
                  Image.asset('assets/images/solar_box-outline.png'),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text('د.ع '),
                  Text(deliveryPrice),
                  Spacer(),
                  Text('سعر التوصيل'),
                  Image.asset(
                    'assets/images/healthicons_vespa-motorcycle-outline.png',
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(width: double.maxFinite, height: 2, color: Colors.grey),
              SizedBox(height: 12),
              Row(
                children: [
                  Text('د.ع '),
                  Text(totalPrice),
                  Spacer(),
                  Text('السعر الكلي'),
                  Image.asset('assets/images/grommet-icons_currency (1).png'),
                ],
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
