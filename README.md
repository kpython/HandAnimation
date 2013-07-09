HandAnimation
=============

Hand Animation on iOS The goal of this project is to animate a 3D hand model on iOS using coordinate received 
from the Leap Motion device. Coordinates received from the Leap Motion device are received on a java program, 
formated in JSON and transmitted using a UDP socket. This UDP packet includes:

- Hand position
- Hand rotation
- Fingers flexion

The iOS program receives coordinates through UDP packets and animate the 3d hand model according decoded informations.

This project is devided in two parts:

- Java program that acts as a proxy to transmit coordinates on the iPad.
- 3D visualisation on iPad using the Cocos3D framework

For the Java program project see : https://github.com/kpython/HandAnimation_JavaLeapMotionProxy

Demo video : http://www.youtube.com/watch?v=VC02EVUijBE&feature=youtu.be
