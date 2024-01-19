import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:retake_app/auth/auth_cookies.dart';
import 'package:retake_app/auth/no_multifactor.dart';
import 'package:retake_app/custom%20widgets/footer_menu_bar.dart';
import 'package:retake_app/auth/multi_factor_authentication.dart';


String globalCookies = '';
String globalDirectBearerToken = '';
NoMultifacfor nomfa = NoMultifacfor();
class AuthRequestButton extends StatefulWidget {
  const AuthRequestButton({Key? key}) : super(key: key);

  @override
  AuthRequest createState() => AuthRequest();
}

class AuthRequest extends State<AuthRequestButton> {
  String resultText = '';
  bool isLoading = false;
  var snackBar;
  late TextEditingController usernameController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }

  void onPressed() async {
    final navigator = Navigator.of(context);
    setState(() {
      FocusManager.instance.primaryFocus?.unfocus();
      isLoading = true;
    });

    final result = await auth(
      usernameController.text,
      passwordController.text,
    );

    setState(() {
      isLoading = false;
      resultText = result;
    });

    if (verifyResponse(result) == "multifactor") {
      navigator.pushReplacement(MaterialPageRoute(
          builder: (context) => const MultiFactorAuthButton()));
    }else if(verifyResponse(result) == "direct_access"){
      nomfa.noMfa();
      navigator.pushReplacement(MaterialPageRoute(builder: (context) => const FooterMenuBar()));
    }else{
      snackBar = const SnackBar(content: Text('Erro no login! \n Verifique seus dados ou sua conexão com a internet'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      alignment: Alignment.centerLeft,
      decoration:  BoxDecoration(
        image: DecorationImage(
          image: AssetImage(checkDevice()),
          fit: BoxFit.cover, // Ou outro ajuste adequado para a sua situação
        ),
      ),
      
      child: SingleChildScrollView(
        child:  Column(
        children: [
          Container(
            height: 50,
            width: 450,
            padding: EdgeInsets.only(left: 20, right: 20),
            child: TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.justify,
              decoration: const InputDecoration(
              hintText: 'Nome de Usuário', 
              hintStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
              
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
               height: 50,
            width: 450,
            padding: EdgeInsets.only(left: 20, right: 20),
            child: TextField(
              controller: passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Senha',
                hintStyle: TextStyle(color: Colors.white),   
                border: OutlineInputBorder()           
                ),
              obscureText: true, // Para ocultar a senha
            ),
          ),
          const SizedBox(height: 20,),
          ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
               backgroundColor: const Color.fromARGB(255, 31, 33, 38), 
              foregroundColor: const Color.fromARGB(255, 255, 255, 255),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                )
                
            ),
            child: const Text('LOGAR', style: TextStyle(fontFamily: 'TungstenBold', fontSize: 20),
            ),
            
          ),
          const SizedBox(height: 16),
          if (isLoading) const CircularProgressIndicator() else const Text(''),
          const SizedBox(height: 16),
        ],
      ),
      )
    ),
  );
}

  Future<String> auth(String userName, String password) async {
    final authCookies = AuthCookies();
    final cookies = await authCookies.cookiesAuth();
    final url = Uri.parse('https://auth.riotgames.com/api/v1/authorization');


    final Map<String, String> headers = {
      "cookie": cookies,
      "Content-Type": "application/json",
    };
    globalCookies = cookies;
    final body = {
      "type": "auth",
      "username": userName,
      "password": password,
      "remember": true,
      "language": "pt_BR",
    };

    try {
      final response = await http.put(
        Uri.parse(url.toString()),
        body: jsonEncode(body),
        headers: headers,
      );
      var authCookies = response.headers['set-cookie'];
      globalCookies = _extractDesiredCookieValues(authCookies.toString());
      if (response.statusCode == 200) {
        if(verifyResponse(response.body) == "direct_access"){
          globalDirectBearerToken = separateBearerToken(response.body);
        }
        return 'Sucesso  \n ${response.body}';
      }
       else {
        return '${response.statusCode} \n ${response.body}';
      }
    } catch (e) {
      return '$e';
    }
  }

  String verifyResponse(String response) {

    if(response.contains("multifactor")){
      return "multifactor";
    }else if(response.contains("access_token")){
      return "direct_access";
    }else{
      return "Houve";
    }
  }

  String getCookies() {
    return globalCookies;
  }

  String _extractDesiredCookieValues(String cookieString) {
    List<String> desiredCookies = [];

    RegExp desiredCookiePattern = RegExp(r'(clid|asid|__cf_bm|tdid)=([^;]+)');
    Iterable<Match> matches = desiredCookiePattern.allMatches(cookieString);

    for (Match match in matches) {
      desiredCookies.add("${match.group(1)}=${match.group(2)}");
    }

    return desiredCookies.join("; ");
  }

   String separateBearerToken(String code) {
    String inputString = code;
    String token = '';

    RegExp regExp = RegExp(r'=(.*?)&');
    Match? match = regExp.firstMatch(inputString);

    if (match != null) {
      String result = match.group(1)!;
      token = result;
      return token;
    } else {
      return '';
    }
  }

  String checkDevice(){
    return Platform.isWindows ?  'assets/images/desktop_background.jpg' : 'assets/images/mobile_background.jpg';
  }
}