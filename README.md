HandAnimation
=============

The goal of this project is to animate a 3D hand model on iOS using coordinate received 
from the Leap Motion device. 

This application works in conjunction with a Java Program responsible to collect 
information provided by the Leap Motion device in order to compute characterstics of the
hand and transmit these parameters to the iPad.
These parameters are sent trough UDP packet containing frames of coordinates formated in JSON. These parameters
are :

- Hand position
- Hand rotation
- Fingers flexion

The iOS program is responsible to parse theses UDP packets and animate the 3d hand model according decoded informations.

This project is devided in two parts:

- Java program that acts as a proxy to transmit coordinates on the iPad.
- 3D visualisation on iPad using the Cocos3D framework

Demo video : http://www.youtube.com/watch?v=VC02EVUijBE&feature=youtu.be


How to use
=============

The Java Program can be found on this repository:
https://github.com/kpython/HandAnimation_JavaLeapMotionProxy


This program could also operate separately without the java program. By sending UDP packets containing
frames of coordinate to the corresponding IP address of the iPad on port 7777, the hand model will be
automaticaly updated. See readme file to see the correct JSON format to use.


Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
All rights reserved
