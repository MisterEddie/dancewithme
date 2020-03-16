color getSilhouetteColor(KSkeleton skeleton) {
    float currSilhouetteR = 0;
    float currSilhouetteG = 0;
    float currSilhouetteB = 0;

    float percent = 0; //right hand
    float percent_2 = 0; //left hand
    float percent_3 = 0; //right knee
    float percent_4 = 0; //left knee
    
    KJoint[] joints = skeleton.getJoints();
    PVector limb_len = PVector.sub(joints[KinectPV2.JointType_HandTipRight].getPosition(), joints[KinectPV2.JointType_ElbowRight].getPosition());
    float add_length = pow(pow(limb_len.x, 2) + pow(limb_len.y, 2), 0.5); 

    float y_right_foot = joints[KinectPV2.JointType_FootRight].getY();
    float y_head = joints[KinectPV2.JointType_Head].getY();
    float y_right_hand = joints[KinectPV2.JointType_HandTipRight].getY();
    float y_left_hand = joints[KinectPV2.JointType_HandTipLeft].getY();
    float bod_range = y_right_foot - y_head + add_length; //add length is the length of the arm

    float x_base_spine = joints[KinectPV2.JointType_SpineBase].getX();
    float y_base_spine = joints[KinectPV2.JointType_SpineBase].getY();
    float x_right_knee = joints[KinectPV2.JointType_KneeRight].getX();
    float y_right_knee = joints[KinectPV2.JointType_KneeRight].getY();
    float x_left_knee = joints[KinectPV2.JointType_KneeLeft].getX();
    float y_left_knee = joints[KinectPV2.JointType_KneeLeft].getY();

    //right knee
    float x_vec_r = abs(x_right_knee - x_base_spine);
    float y_vec_r = abs(y_right_knee - y_base_spine);
    float degree = 90 - (atan(y_vec_r/x_vec_r))*180/3.14159;
    percent_3 = degree/90;

    //left knee
    float x_vec_l = abs(x_left_knee - x_base_spine);
    float y_vec_l = abs(y_left_knee - y_base_spine);
    float degree_2 = 90 - (atan(y_vec_l/x_vec_l))*180/3.14159;
    percent_4 = degree_2/90;

    //right hand
    if (y_right_hand <= y_head - add_length) {
      percent = 100;
    } else if (y_right_hand >= y_right_foot) {
      percent = 0;
    } else {
      float y_rel_right_hand = y_right_foot - y_right_hand;
      percent = y_rel_right_hand/bod_range;
    }

    //left hand
    if (y_left_hand <= y_head - add_length) {
      percent_2 = 100;
    } else if (y_left_hand >= y_right_foot) {
      percent_2 = 0;
    } else {
      float y_rel_left_hand = y_right_foot - y_left_hand;
      percent_2 = y_rel_left_hand/bod_range;
    }
    
    currSilhouetteR = percent*255;
    currSilhouetteG = percent_2*255;
    currSilhouetteB = (percent_3+percent_4)*255;
      
    return color(currSilhouetteR, currSilhouetteG, currSilhouetteB);
}
