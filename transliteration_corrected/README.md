# transliteration

A simple transliteration package which convert "English" to 22 other languagues.

## Getting Started

This package uses Google's "Transliteration API" and makes API request in order to transliterate the given string to provided language.

Supported Languages are : AMHARIC, ARABIC, BENGALI, CHINESE, GREEK, GUJARATI, HINDI, KANNADA, MALAYALAM, MARATHI, NEPALI, ORIYA, PERSIAN, PUNJABI, RUSSIAN, SANSKRIT, SERBIAN, SINHALESE, TAMIL, TELUGU, TIGRINYA,URDU.

>Note : Since this language uses Transliteration API, only English Language can be used as a source language. 

Configuration : 

Make sure to add the following line to AndroidManifest.xml

`<application android:usesCleartextTraffic="true"/>`

add Internet Permission as well

`<uses-permission android:name="android.permission.INTERNET"/>`