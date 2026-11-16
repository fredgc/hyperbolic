// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import 'sign_in_button_stub.dart';
import "printer.dart";

Widget buildSignInButton({HandleSignInFn? onPressed}) {
  Log.drive.log("BLUE: Using the web render button.");
  return web.renderButton();
}
