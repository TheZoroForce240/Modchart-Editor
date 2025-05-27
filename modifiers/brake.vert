if (_value_ != 0.0) {
    float yOffset = 0.0;

    float fYOffset = -curPos;
    float fEffectHeight = 600.0;
    float fScale = (fYOffset) * ((1.0) / (fEffectHeight)); //scale
    float fNewYOffset = fYOffset * fScale; 
    float fBrakeYAdjust = _value_ * (fNewYOffset - fYOffset);
    fBrakeYAdjust = clamp( fBrakeYAdjust, -400.0, 400.0 ); //clamp
    
    yOffset -= fBrakeYAdjust;

    curPos += yOffset;
}