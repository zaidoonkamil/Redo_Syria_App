import '../ navigation/navigation.dart';
import '../../features/auth/view/login.dart';
import '../network/local/cache_helper.dart';

String token='';
String id='';
String adminOrUser='' ;
String phoneWoner='7736699924' ;
String logo='logoredo.png' ;
String nameApp='ريــــــدو' ;
String googleMapKey='AIzaSyAE-sYS9P2UMiWL3MXRPdbO4uF3ScChPbw' ;


void signOut(context) {
  CacheHelper.removeData(
    key: 'token',
  ).then((value)
  {
    token='';
    adminOrUser='' ;
    id='' ;
    if (value)
    {
      CacheHelper.removeData(key: 'role',);
      CacheHelper.removeData(key: 'id',);
      navigateTo(context, const Login(),);
    }
  });
}
