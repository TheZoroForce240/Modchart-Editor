if (_x_ != 0.0 || _y_ != 0.0 || _z_ != 0.0) {
    float newPos = 4.0 + (strumID) * ((-4.0 - 4.0) / (4.0));
    float dist = (112.0 * newPos * 0.5) - (112.0 * 0.5);
    x += dist;
    vec4 p = rotation3d(vec3(1.0, 0.0, 0.0), _x_ * rad) * 
            rotation3d(vec3(0.0, 1.0, 0.0), _y_ * rad) * 
            rotation3d(vec3(0.0, 0.0, 1.0), _z_ * rad) * 
            vec4(dist, 0.0, 0.0, 1.0);

    x -= p.x;
    y -= p.y;
    z -= p.z;

    if (_value_ == 1.0 || _value_ == 3.0) {
        angleX += _x_;
        angleY += _y_;
        angleZ += _z_;
    }

    if (_value_ == 2.0 || _value_ == 3.0) {
        incomingAngleX += _x_;
        incomingAngleY += _y_;
        incomingAngleZ += _z_;
    }
}
