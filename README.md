# FillOutForms

This program let's you automate filling out multiple different paper forms.</br>
Drag and drop a spreadsheet file containing the text to be printed onto the program (only ODS, XLS and XLSX supported thus far), and specify a folder which contains the form's formatting.<br>
The output of the program is the PDF file which the user has to print manually.

## Usage

Instead of dragging and dropping the spreadsheet onto the .desktop file, you can also execute the program with:
```bash
./gui.sh TheSpreadsheet.xlsx
```
or:
```bash
bash gui.sh TheSpreadsheet.xlsx
```

Don't touch ``backend.sh``. It is meant to be executed by ``gui.sh`` and not by the user, although I do plan to make a CLI version of the program.

Also, the program will prompt you to choose between filling out forms one by one and filling them all at once. If you have a potato PC or need to use it while the program is working, choose the one-by-one option.

## Limitations:

- Only one font can be used to print on all forms
- The program doesn't allow printing on pre-printed forms. If you want to print on pre-printed forms, replace the form image with a same-sized blank image.
- If text with newlines is set to be verticaly aligned, the alignment will only affect the first line.
- The program can't process the newline in a spreadsheet's cell as a newline. For now, in the spreadsheet type '\\\\n' (with double backslashes) for a newline.

All of the mentioned is on my to-fix list.</br>
The following is also on my to-do list for this project:
- Instead of the end user adding the image to the formatting folder and editting the format.txt file by hand, make a GUI that lets you import the background image and click on the desired coordinate on which the program will print the needed text.
- Make it easier to fill check boxes
- Make the program be able to load non-raster forms, instead of having the background image be a raster image. Also the output PDF also should be non-raster
- Print the forms directly using a printer
- Add support for importing CSV files
- Find a non-bloated alternative for LibreOffice that converts ODS files to CSV
- Make a CLI version
- Add support for other operating systems

## Dependencies

This program was made on Debian 11 and uses Debian's official packages. I'm not 100% sure if it's going to work on other distros or with different packages' versions. Tried on Ubuntu 22.10 and realized the text align in the finished PDF is incorrect. Will fix and add support for many Linux distros soon.

The packages that are used are:</br>
Bash 5.1</br>
Zenity 3.32</br>
img2pdf 0.4</br>
ImageMagick 6.9</br>
csvtool 2.4</br>
LibreOffice 7.0</br>
xls2csv Catdoc Version 0.95</br>
xlsx2csv 0.7</br>

LibreOffice, xls2csv and xlsx2csv don't need to be installed at the same time,
but only the one that's going to extract the CSV file (LibreOffice extracts .ODS files).

## Error checking

The program goes through error checking and input validations.<br>
Many of them are the following:
- Checking and preventing code injections inside the format.txt file, e.g. ``$(beep)`` would produce a beep and ``$USER`` would print out the USER variable's value.
- The program has a limit ``( 25*$(nproc) )`` to how many subproceses (that each fill out one specific form) can be executed at once. When all the running subprocesses are finished, the next group is executed.
  - The subprocesses check between commands if Zenity's progress window's "Cancel" was pressed and stop if so for faster termination. (obviously takes longer if all-at-once was checked)
- Checking for errors from many commands (that shouldn't produce errors) and terminates if one of the commands don't return 0
- Since it processes the forms in ``/dev/shm``, it searches for a non-existing folder and creates it for the processing. This way, the end user can have multiple instances of the program work at once without interfering with each other.
---
The program comes without any warranty so use it at your own risk.<br>
English is not my native language. I apologize for any grammatical errors.
