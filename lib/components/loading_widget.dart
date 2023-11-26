import 'package:flutter/material.dart';

Widget loadingWidget(BuildContext context) {
  return const LoadingWidget(center: true);
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget(
      {this.height = 80,
      this.center = false,
      this.text = '',
      this.textColor,
      super.key});
  final double height;
  final bool center;
  final String text;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              if (text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    text,
                    style: TextStyle(color: textColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
