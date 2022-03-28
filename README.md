# AstroImageClissifier
##Description:
    This utility command script help you to classify your RAW images, out
    of your APN SD card, into 4 folders: Biases, Darks, Flats and Lights.
    Then you can easily use those folder to process your image, like with
    Siril.
    You need to put all your image in the same folder named 'RAW', which
    need to be place inside your working directory, for instance named as
    you picture object 'Orion M42'.
 
Your folder architecture tree need to be like this:
 
    Before classification        After classification
                  |
  Orion M42              |         Orion M42
     |-> RAW              |        |-> Biases
      |-> IMG_0001.CR3      |        |    |-> IMG_0001.CR3
      | ...              |        |    | ...
      |-> IMG_0120.CR3      |        |    |-> IMG_0010.CR3
                  |        |
                  |        |-> Darks
                  |        |    |-> IMG_0011.CR3
                  |        |    | ...
                  |        |    |-> IMG_0020.CR3
                  |        |
                  |        |-> Flats
                  |        |    |-> IMG_0021.CR3
                  |        |    | ...
                  |        |    |-> IMG_0030.CR3
                  |        |
                  |        |-> Lights
                  |        |    |-> IMG_0031.CR3
                  |        |    | ...
                  |        |    |-> IMG_0120.CR3
                  |        |
                  |        |-> RAW
                  |        |    |-> Empty
 
##Option:
    -r : lunch the classification process. Add the path to the RAW images
    directory. You can add -Y to process directly the images.
    -u : undo the last process, move back the images and rotate them as 
    before. You can add -Y to undo directly the last action
    -t : show the volume of the .tmp files. You can clean up the
    files if they take too much space.
    -p : update parameters like classification folder names, maximum size
    and date of the temporary files, and the screen time for the action
    during the process.
    -h : show this help page.
 
##Exemples:
    sh AstroImageClissifier.sh -r Test -Y
    --> Lunch direclty the classification of the images in the folder 'Test'
 
    sh AstroImageClissifier.sh -u
    --> Undo the last classification process, with -Y you can skip the
        confirmation
