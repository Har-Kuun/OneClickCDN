### What is this?
This is a small tool that helps you to translate the OneClickCDN script to other languages.  You can also use it to translate other files or do other text replacements.

The original OneClickCDN script is written completely in English.  People may be interested to translate this script into other languages so that people not familiar with English can use it.  By using this small tool, everyone can translate the script to another language.

It is advised to use this small tool to translate, __instead of directly editing the original script file__.  The reason is that the original script file can be frequently updated.  Translating using this small tool ensures the best compatibility and makes your life easier for future changes.
Currently, the script has already been translated to Chinese Simplified (zh-CN).

### How to translate
There is a `template` file in this directory.  Simply download that file, and rename it to the language code that you are going to translate into.
For example, if I'd like to translate it into Espanol, I'd rename `template` file to `es`.  Let's call it a `language file`.

Then, you can start translating by editing the language file.  The language file consists of many lines, each line having a sentence that awaits translation.  A typical line in the language file looks like this:
```
Thank you|
```
The pipe symbol `|` separates the original text (on the left) and the translated text (on the right).  To translate, we just need to write the translated text following the pipe `|` sign.  For example, the above line should be translated like this.
```
Thank you|Gracias
```
It's OK to only translate parts of the original text.  After finishing, save the language file.

### How to generate translated script
You'll need to download a copy of the original `OneClickCDN.sh` script, and a copy of `generate_translated_script.sh`.  You'll need to know the absolute path to the original script file and the language file.
Then, run the `generate_translated_script.sh` script.
```
bash generate_translated_script.sh
```
The script will ask for locations of the original script file and the language file.  Then, it will start the translating process.  After a few seconds, a translated OneClickCDN script will be generated.
You'll be prompted with the location of the translated script.

### How to update translation
Every time the original OneClickCDN script is updated, the language `template` file will also be updated (at the end of the file) with added English strings.  You can safely add the new strings to your language file, and translate those new strings accordingly.

After that, simply run the `generate_translated_script.sh` script again to generate a new translated copy of OneClickCDN script.
