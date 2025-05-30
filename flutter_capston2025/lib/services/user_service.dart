import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateNickname(String userUid, String nickname) async {
  await FirebaseFirestore.instance.collection('users').doc(userUid).update({
    'nickname': nickname,
  });
}
