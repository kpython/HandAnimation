/**
 *  HandLibrary.h
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 *  All rights reserved
 */

#ifndef HandAnimation_HandLibrary_h
#define HandAnimation_HandLibrary_h

typedef enum{
    LEFT = 0,
    RIGHT,
    UP,
    DOWN,
    IN,
    OUT
}MoveDirection;


// Pitch/Yaw/Roll are terms used in flight dynamics to express rotation in 3D. 
typedef enum{
    PITCH_CLOCKWISE = 0,    //Rotation on X-Axis
    PITCH_ANTICLOCKWISE,
    YAW_CLOCKWISE,          //Rotation on Y-Axis
    YAW_ANTICLOCKWISE,
    ROLL_CLOCKWISE,         //Rotation on Z-Axis
    ROLL_ANTICLOCKWISE
}RotateDirection;

typedef enum{
    FINGER_THUMB = 0,
    FINGER_INDEX,
    FINGER_MIDDLE,
    FINGER_RING,
    FINGER_PINKY
} HandFinger;

#endif
