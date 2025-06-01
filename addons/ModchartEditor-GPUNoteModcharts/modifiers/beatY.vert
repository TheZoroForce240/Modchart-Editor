if (_value_ != 0.0) {
    float fAccelTime = 0.2;
    float fTotalTime = 0.5;
    float fBeat = curBeat + fAccelTime;

    if (fBeat >= 0.0)
    {
        float evenBeat = mod(floor(fBeat), 2.0);

        fBeat -= floor(fBeat);
        fBeat += 1.0;
        fBeat -= floor(fBeat);

        if (fBeat < fTotalTime)
        {
            float fAmount = 0.0;
            if( fBeat < fAccelTime )
            {
                fAmount = 0.0 + (fBeat - 0.0) * ((1.0 - 0.0) / (fAccelTime - 0.0));
                fAmount *= fAmount;
            }
            else
            {
                fAmount = 1.0 + (fBeat - fAccelTime) * ((0.0 - 1.0) / (fTotalTime - fAccelTime));
                fAmount = 1.0 - (1.0 - fAmount) * (1.0 - fAmount);
            }

            if (evenBeat != 0.0)
                fAmount *= -1.0;

            y += 20.0 * fAmount * sin((curPos * 0.01) + (PI * 0.5)) * _value_;
        }
    }
}