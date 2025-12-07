import 'package:flutter_dotenv/flutter_dotenv.dart';

void testEnvVariables() {
  print('Testing environment variables:');
  print('WAPI_KEY: ${dotenv.env['WAPI_KEY']}');
  print('WAUTH_DOMAIN: ${dotenv.env['WAUTH_DOMAIN']}');
  print('AAPI_KEY: ${dotenv.env['AAPI_KEY']}');
  
  // Check if variables are loaded
  if (dotenv.env['WAPI_KEY'] != null) {
    print('✅ Environment variables loaded successfully!');
  } else {
    print('❌ Environment variables not loaded');
  }
}