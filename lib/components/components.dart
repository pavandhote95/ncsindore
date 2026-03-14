import 'package:cuickdevuser/components/constants.dart';
import 'package:flutter/material.dart';

import 'package:rflutter_alert/rflutter_alert.dart';

class CustomButton extends StatelessWidget {
  const CustomButton(
      {super.key,
      required this.buttonText,
      this.isOutlined = false,
      required this.onPressed,
      this.width = 300});

  final String buttonText;
  final bool isOutlined;
  final Function onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPressed();
      },
      child: Material(
        borderRadius: BorderRadius.circular(30),
        elevation: 4,
        child: Container(
          width: width,

          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kTextColor, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
        /*  decoration: BoxDecoration(
            color: isOutlined ? Colors.white : kTextColor,
            border: Border.all(color: kTextColor, width: 2.5),
            borderRadius: BorderRadius.circular(20),
          ),*/
          child: Center(
            child: Text(
              buttonText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                // color: isOutlined ? kTextColor : Colors.white,
                color: kTextColor ,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TopScreenImage extends StatelessWidget {
  const TopScreenImage({super.key, required this.screenImageName});
  final String screenImageName;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex:1,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.contain,
            image: AssetImage('assets/images/$screenImageName'),
          ),
        ),
      ),
    );
  }
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w400,
        fontFamily: 'Poppins'
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  CustomTextField({super.key, required this.textField});
  final TextField textField;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
        ),
        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            width: 1,
            color: kTextColor,
          ),
        ),
        child: Center(child: textField),
      ),
    );
  }
}

class CustomBottomScreen extends StatelessWidget {
  const CustomBottomScreen({
    super.key,
    required this.textButton,
    required this.question,
    this.heroTag = '',
    required this.buttonPressed,
    required this.questionPressed,
  });
  final String textButton;
  final String question;
  final String heroTag;
  final Function buttonPressed;
  final Function questionPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child: GestureDetector(
              onTap: () {
                questionPressed();
              },
              child: Text(question),
            ),
          ),
        ),
        SizedBox(
          height: 15,

        ),
        Align(
          alignment: Alignment.center,
          child: Hero(
            tag: heroTag,
            child: CustomButton(
              buttonText: textButton,
              width: 130,
              onPressed: () {
                buttonPressed();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class CustomBottomScreenQuestion extends StatelessWidget {
  const CustomBottomScreenQuestion({
    super.key,
    required this.question,
    this.heroTag = '',
    required this.buttonPressed,
    required this.questionPressed,
  });
  final String question;
  final String heroTag;
  final Function buttonPressed;
  final Function questionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child: GestureDetector(
              onTap: () {
                questionPressed();
              },
              child: Text(question),
            ),
          ),
        ),
      ],
    );
  }
}

Alert signUpAlert({
  required Function onPressed,
  required String title,
  required String desc,
  required String btnText,
  required BuildContext context,
}) {
  return Alert(
    context: context,
    title: title,
    desc: desc,
    buttons: [
      DialogButton(
        onPressed: () {
          onPressed();
        },
        width: 120,
        child: Text(
          btnText,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    ],
  );
}

Alert showAlert({
  required Function onPressed,
  required String title,
  required String desc,
  required BuildContext context,
}) {
  return Alert(
    context: context,
    type: AlertType.error,
    title: title,
    desc: desc,
    buttons: [
      DialogButton(
        onPressed: () {
          onPressed();
        },
        width: 120,
        child: const Text(
          "OK",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      )
    ],
  );
}
