import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../components/main_btn.dart';
import '../constants.dart';
import '../provider/pass_data.dart';
import 'home_screen.dart';

class LoginAndRegisterPage extends StatefulWidget {
  static const String id = "LoginAndRegisterPage";

  const LoginAndRegisterPage({Key? key}) : super(key: key);

  @override
  State<LoginAndRegisterPage> createState() => _LoginAndRegisterPageState();
}

class _LoginAndRegisterPageState extends State<LoginAndRegisterPage>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  late PageController _pageController;
  late TabController tabController;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailLoginController = TextEditingController();
  TextEditingController passwordLoginController = TextEditingController();

  TextEditingController emailSignupController = TextEditingController();
  TextEditingController passwordSignupController = TextEditingController();

  bool isVisibleLogin = false;
  bool isClickButton = false;
  bool isSelectedImage = false;
  bool isVisibleSignup = false;

  String? imageUrl;

  void addUser(String id, String name, String createdAt) {
    final user = <String, dynamic>{
      "userId": id,
      "name": name,
      "imageUrl": imageUrl,
      "createdAt": createdAt,
      "status": "Online",
    };

    _db.collection("Users").add(user).then(
        (DocumentReference doc) => print("user added with id: ${doc.id}"));
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    tabController.dispose();
    nameController.dispose();
    emailLoginController.dispose();
    passwordLoginController.dispose();
    emailSignupController.dispose();
    passwordSignupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.lightBlueAccent,
          bottom: const TabBar(
            tabs: [
              Tab(
                text: "Login",
              ),
              Tab(
                text: "Signup",
              ),
            ],
          ),
          title: const Center(child: Text("Login and Signup")),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Flexible(
                    child: Hero(
                      tag: 'logo',
                      child: SizedBox(
                        height: 250,
                        child: Image.asset('images/logo.png'),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 48.0,
                  ),
                  TextFormField(
                    controller: emailLoginController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: kTextFieldDecoration.copyWith(
                        hintText: 'Write your Email',
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.lightBlueAccent,
                        )),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  TextFormField(
                    controller: passwordLoginController,
                    obscureText: !isVisibleLogin,
                    decoration: kTextFieldDecoration.copyWith(
                      prefixIcon: const Icon(Icons.lock),
                      prefixIconColor: Colors.lightBlueAccent,
                      border: const UnderlineInputBorder(),
                      hintText: "Write your password",
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            isVisibleLogin = !isVisibleLogin;
                          });
                        },
                        icon: isVisibleLogin
                            ? const Icon(
                                Icons.visibility,
                                color: Colors.grey,
                              )
                            : const Icon(
                                Icons.visibility_off,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 24.0,
                  ),
                  MainBtn(
                    showProgress: isClickButton,
                    color: Colors.lightBlueAccent,
                    text: 'Login',
                    onPressed: () async {
                      if (emailLoginController.text.trim().isNotEmpty &&
                          passwordLoginController.text.trim().isNotEmpty) {
                        setState(() {
                          isClickButton = true;
                        });
                        try {
                          final newUser =
                              await _auth.signInWithEmailAndPassword(
                                  email: emailLoginController.text.trim(),
                                  password: passwordLoginController.text.trim());
                          // معنى mounted الفحص اذا المستخدم لس بنفس الواجهة او لا, عشان مينفذش كود انتقال وهو مش بالواجهة
                          if (newUser.user != null && mounted) {
                            Provider.of<PassAllData>(context, listen: false)
                                .setUserId(newUser.user!.uid);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('loged in  ${newUser.user!.email}'),
                              ),
                            );
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              HomePage.id,
                              (r) => false,
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fill all fields !'),
                          ),
                        );
                      }
                      setState(() {
                        isClickButton = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            //
            // Signup
            //
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ListView(
                children: <Widget>[
                  Hero(
                    tag: 'logo',
                    child: SizedBox(
                      height: 150,
                      child: Image.asset('images/logo.png'),
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  InkWell(
                    onTap: () async {
                      ImagePicker imagePicker = ImagePicker();
                      XFile? file = await imagePicker.pickImage(
                          source: ImageSource.gallery);
                      print("File path : ${file?.path}");
                      String uniqueImageName =
                          DateTime.now().millisecondsSinceEpoch.toString();

                      if (file != null) {
                        // get reference to storage root
                        Reference referenceRoot = FirebaseStorage.instance.ref();
                        Reference referenceDirImage = referenceRoot.child("images");
                        // create reference for image to be stored
                        Reference referenceImageUpload = referenceDirImage.child(uniqueImageName);

                        setState(() {
                          isClickButton = true;
                          isSelectedImage = true;
                        });
                        // Handle error
                        try {
                          // store the file
                          await referenceImageUpload.putFile(File(file!.path));
                            imageUrl = await referenceImageUpload.getDownloadURL();
                          setState(() {});
                        } catch (error) {
                          print(error.toString());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${error.toString()}'),
                            ),
                          );
                        }
                        setState(() {
                          isClickButton = false;
                          isSelectedImage = false;
                        });
                      }
                    },
                      child: imageUrl == null
                          ? CircleAvatar(
                              backgroundColor: Colors.lightBlueAccent,
                              radius: 56,
                              child: Center(
                                  child: isSelectedImage
                                      ? const CircularProgressIndicator(color: Colors.white,)
                                      : const Text(
                                          "Select\nimage",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        )),
                            )
                          : CircleAvatar(
                              radius: 64,
                              backgroundColor: Colors.grey.shade400,
                              backgroundImage: NetworkImage(imageUrl!),
                            ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  TextFormField(
                    controller: nameController,
                    keyboardType: TextInputType.name,
                    decoration: kTextFieldDecoration.copyWith(
                        hintText: 'Write your name',
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.lightBlueAccent,
                        )),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextFormField(
                    controller: emailSignupController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: kTextFieldDecoration.copyWith(
                        hintText: 'Write your Email',
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.lightBlueAccent,
                        )),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextFormField(
                    controller: passwordSignupController,
                    obscureText: !isVisibleSignup,
                    decoration: kTextFieldDecoration.copyWith(
                      prefixIcon: const Icon(Icons.lock),
                      prefixIconColor: Colors.lightBlueAccent,
                      border: const UnderlineInputBorder(),
                      hintText: "Write your password",
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            isVisibleSignup = !isVisibleSignup;
                          });
                        },
                        icon: isVisibleSignup
                            ? const Icon(
                                Icons.visibility,
                                color: Colors.grey,
                              )
                            : const Icon(
                                Icons.visibility_off,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  MainBtn(
                    showProgress: isClickButton,
                    color: Colors.lightBlueAccent,
                    text: 'Sign Up',
                    onPressed: () async {
                      setState(() {
                        isClickButton = true;
                      });
                      if (nameController.text.trim().isNotEmpty &&
                          emailSignupController.text.trim().isNotEmpty &&
                          passwordSignupController.text.trim().isNotEmpty) {
                        try {
                          final newUser = await _auth.createUserWithEmailAndPassword(
                                  email: emailSignupController.text.trim(),
                                  password: passwordSignupController.text.trim(),
                          );
                          if (newUser.user != null) {
                            Provider.of<PassAllData>(context, listen: false)
                                .setUserId(newUser.user!.uid);
                            addUser("${newUser.user?.uid}", nameController.text,
                                DateTime.now().toString());
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('loged in  ${newUser.user!.email}'),
                                ),
                              );
                              Navigator.pushReplacementNamed(
                                  context, HomePage.id);
                            }
                          }
                        } catch (e) {
                          print(e);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fill all fields !'),
                          ),
                        );
                      }
                      setState(() {
                        isClickButton = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    // Column(
    //   children: [
    //     Row(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         TabBar(
    //           labelColor: Colors.white,
    //           unselectedLabelColor: Colors.lightBlueAccent,
    //           indicator: BoxDecoration(
    //             borderRadius: BorderRadius.circular(120),
    //             color: Colors.lightBlueAccent,
    //           ),
    //           controller: tabController,
    //           isScrollable: true,
    //           labelPadding: const EdgeInsets.symmetric(
    //               horizontal: 48),
    //           tabs: const [
    //             Expanded(
    //               child: Tab(
    //                 child: Text("Login"),
    //               ),
    //             ),
    //             Expanded(
    //               child: Tab(
    //                 child: Text("SignUp"),
    //               ),
    //             ),
    //           ],
    //         ),
    //       ],
    //     ),
    //   ],
    // ),
  }
}
