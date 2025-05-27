if (_value_ != 0.0) {
    if (mod(strumID, 2.0) == 0.0)
    {
        incomingAngleZ -= _value_ + (curPos * 0.015);
    }
    else
    {
        incomingAngleZ += _value_ + (curPos * 0.015);
    }
}