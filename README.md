
# AstroImageClissifier

This utility was created by a curious beginner to help astrophotographers to
classify their photos before processing.
There are some security measures in the code to limit the risk of breakage in
case of misuse or problems in classification. However, any user will be
responsible for any damage or loss of photos in the process.

## Description:

This utility command script help you to classify your RAW images, out
of your APN SD card, into 4 folders: ***Biases***, ***Darks***, ***Flats*** and
***Lights***. Then you can easily use those folder to process your image, like
with ***Siril***.

You need to put all your image in the same folder named ***'RAW'***, which
need to be place inside your working directory, for instance named as
you picture object ***'Orion M42'***.
 
Your folder architecture tree need to be like this:

```
Before classification       |      After classification
                            |
    Orion M42               |         Orion M42
      |-> RAW               |            |-> Biases
        |-> IMG_0001.CR3    |            |    |-> IMG_0001.CR3
        | ...               |            |    | ...
        |-> IMG_0120.CR3    |            |    |-> IMG_0010.CR3
                            |            |
                            |            |-> Darks
                            |            |    |-> IMG_0011.CR3
                            |            |    | ...
                            |            |    |-> IMG_0020.CR3
                            |            |
                            |            |-> Flats
                            |            |    |-> IMG_0021.CR3
                            |            |    | ...
                            |            |    |-> IMG_0030.CR3
                            |            |
                            |            |-> Lights
                            |            |    |-> IMG_0031.CR3
                            |            |    | ...
                            |            |    |-> IMG_0120.CR3
                            |            |
                            |            |-> RAW
                            |            |    |-> Empty
```

## Options:

`-r`: lunch the classification process. Add the path to the RAW images directory.
You can add -Y to process directly the images.

`-u`: undo the last process, move back the images and rotate them as before.
You can add -Y to undo directly the last action

`-p`: update parameters like classification folder names, maximum size and date
of the temporary files, and the screen time for the action during the process.

`-t`: show the volume of the .tmp files. You can clean up the files if they take
too much space.

`-h`: show the help page (similar to this README.md file).

>Deleting temporary files will result in the inability to undo the last execution.
 
## Exemples:

`sh AstroImageClissifier.sh -r Orion 42`: launch the classification on the images of
the 'Orion 42' folder

`sh AstroImageClissifier.sh -u`: reversing the last classification process, the
images will be placed back in the ***'RAW'*** folder as before the classification.

`sh AstroImageClissifier.sh -p`: allows to check/change parameters such as:
folder names, classification characteristics, image orientation, etc.

`sh AstroImageClissifier.sh -t`: allows you to access the details of hidden
files, created during and for execution.
