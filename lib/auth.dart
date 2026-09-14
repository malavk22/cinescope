import 'dart:convert';
import 'package:crypto/crypto.dart';

// Passwords are stored as a salted SHA-256 hash, never as plain text.
String hashPassword(String username, String password) =>
    sha256.convert(utf8.encode("$username:$password")).toString();
