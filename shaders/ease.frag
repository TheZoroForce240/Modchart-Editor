#pragma header

#define PI 3.141592653589793
#define PI2 PI / 2.0

#define EL 2.0 * PI / 0.45
#define B1 1.0 / 2.75
#define B2 2.0 / 2.75
#define B3 1.5 / 2.75
#define B4 2.5 / 2.75
#define B5 2.25 / 2.75
#define B6 2.625 / 2.75
#define ELASTIC_AMPLITUDE 1
#define ELASTIC_PERIOD 0.4

uniform float easeType;
uniform float flip;

float linear(float t) {
    return t;
}

float quadIn(float t) {
    return t * t;
}

float quadOut(float t) {
    return -t * (t - 2.0);
}

float quadInOut(float t) {
    return t <= 0.5 ? t * t * 2.0 : 1.0 - (--t) * t * 2.0;
}

float cubeIn(float t) {
    return t * t * t;
}

float cubeOut(float t) {
    return 1.0 + (--t) * t * t;
}

float cubeInOut(float t) {
    return t <= 0.5 ? t * t * t * 4.0 : 1.0 + (--t) * t * t * 4.0;
}

float quartIn(float t) {
    return t * t * t * t;
}

float quartOut(float t) {
    return 1.0 - (t -= 1) * t * t * t;
}

float quartInOut(float t) {
    return t <= 0.5 ? t * t * t * t * 8.0 : (1.0 - (t = t * 2.0 - 2.0) * t * t * t) / 2.0 + 0.5;
}

float quintIn(float t) {
    return t * t * t * t * t;
}

float quintOut(float t) {
    return (t = t - 1.0) * t * t * t * t + 1.0;
}

float quintInOut(float t) {
    return ((t *= 2.0) < 1.0) ? (t * t * t * t * t) / 2.0 : ((t -= 2.0) * t * t * t * t + 2.0) / 2.0;
}

/** @since 4.3.0 */
float smoothStepInOut(float t) {
    return t * t * (t * -2.0 + 3.0);
}

/** @since 4.3.0 */
float smoothStepIn(float t) {
    return 2.0 * smoothStepInOut(t / 2.0);
}

/** @since 4.3.0 */
float smoothStepOut(float t) {
    return 2.0 * smoothStepInOut(t / 2.0 + 0.5) - 1.0;
}

/** @since 4.3.0 */
float smootherStepInOut(float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

/** @since 4.3.0 */
float smootherStepIn(float t) {
    return 2.0 * smootherStepInOut(t / 2.0);
}

/** @since 4.3.0 */
float smootherStepOut(float t) {
    return 2.0 * smootherStepInOut(t / 2.0 + 0.5) - 1.0;
}

float sineIn(float t) {
    return -cos(PI2 * t) + 1.0;
}

float sineOut(float t) {
    return sin(PI2 * t);
}

float sineInOut(float t) {
    return -cos(PI * t) / 2.0 + 0.5;
}

float bounceOut(float t) {
    if (t < B1)
        return 7.5625 * t * t;
    if (t < B2)
        return 7.5625 * (t - B3) * (t - B3) + 0.75;
    if (t < B4)
        return 7.5625 * (t - B5) * (t - B5) + 0.9375;
    return 7.5625 * (t - B6) * (t - B6) + 0.984375;
}

float bounceIn(float t) {
    return 1.0 - bounceOut(1.0 - t);
}

float bounceInOut(float t) {
    return t < 0.5
        ? (1.0 - bounceOut(1.0 - 2.0 * t)) / 2.0
        : (1.0 + bounceOut(2.0 * t - 1.0)) / 2.0;
}

float circIn(float t) {
    return -(sqrt(1.0 - t * t) - 1.0);
}

float circOut(float t) {
    return sqrt(1.0 - (t - 1.0) * (t - 1.0));
}

float circInOut(float t) {
    return t <= 0.5 ? (sqrt(1.0 - t * t * 4.0) - 1.0) / -2.0 : (sqrt(1.0 - (t * 2.0 - 2.0) * (t * 2.0 - 2.0)) + 1.0) / 2.0;
}

float expoIn(float t) {
    return pow(2.0, 10.0 * (t - 1.0));
}

float expoOut(float t) {
    return -pow(2.0, -10.0 * t) + 1.0;
}

float expoInOut(float t) {
    return t < 0.5 ? pow(2.0, 10.0 * (t * 2.0 - 1.0)) / 2.0 : (-pow(2.0, -10.0 * (t * 2.0 - 1.0)) + 2.0) / 2.0;
}

float backIn(float t) {
    return t * t * (2.70158 * t - 1.70158);
}

float backOut(float t) {
    return 1.0 - (--t) * (t) * (-2.70158 * t - 1.70158);
}

float backInOut(float t) {
    t *= 2.0;
    if (t < 1.0)
        return t * t * (2.70158 * t - 1.70158) / 2.0;
    t--;
    return (1.0 - (--t) * (t) * (-2.70158 * t - 1.70158)) / 2 + 0.5;
}

float elasticIn(float t) {
    return -(ELASTIC_AMPLITUDE * pow(2.0,
        10.0 * (t -= 1)) * sin((t - (ELASTIC_PERIOD / (2.0 * PI) * asin(1.0 / ELASTIC_AMPLITUDE))) * (2.0 * PI) / ELASTIC_PERIOD));
}

float elasticOut(float t) {
    return (ELASTIC_AMPLITUDE * pow(2.0,
        -10.0 * t) * sin((t - (ELASTIC_PERIOD / (2.0 * PI) * asin(1.0 / ELASTIC_AMPLITUDE))) * (2.0 * PI) / ELASTIC_PERIOD)
        + 1.0);
}

float elasticInOut(float t) {
    if (t < 0.5)
    {
        return -0.5 * (pow(2.0, 10.0 * (t -= 0.5)) * sin((t - (ELASTIC_PERIOD / 4.0)) * (2.0 * PI) / ELASTIC_PERIOD));
    }
    return pow(2.0, -10.0 * (t -= 0.5)) * sin((t - (ELASTIC_PERIOD / 4.0)) * (2.0 * PI) / ELASTIC_PERIOD) * 0.5 + 1.0;
}

float ease(float t) {

    if (easeType == 0.0) return linear(t);
    else if (easeType == 1.0) return quadIn(t);
    else if (easeType == 2.0) return quadOut(t);
    else if (easeType == 3.0) return quadInOut(t);
    else if (easeType == 4.0) return cubeIn(t);
    else if (easeType == 5.0) return cubeOut(t);
    else if (easeType == 6.0) return cubeInOut(t);
    else if (easeType == 7.0) return quartIn(t);
    else if (easeType == 8.0) return quartOut(t);
    else if (easeType == 9.0) return quartInOut(t);
    else if (easeType == 10.0) return quintIn(t);
    else if (easeType == 11.0) return quintOut(t);
    else if (easeType == 12.0) return quintInOut(t);
    else if (easeType == 13.0) return smoothStepIn(t);
    else if (easeType == 14.0) return smoothStepOut(t);
    else if (easeType == 15.0) return smoothStepInOut(t);
    else if (easeType == 16.0) return smootherStepIn(t);
    else if (easeType == 17.0) return smootherStepOut(t);
    else if (easeType == 18.0) return smootherStepInOut(t);
    else if (easeType == 19.0) return sineIn(t);
    else if (easeType == 20.0) return sineOut(t);
    else if (easeType == 21.0) return sineInOut(t);
    else if (easeType == 22.0) return bounceIn(t);
    else if (easeType == 23.0) return bounceOut(t);
    else if (easeType == 24.0) return bounceInOut(t);
    else if (easeType == 25.0) return circIn(t);
    else if (easeType == 26.0) return circOut(t);
    else if (easeType == 27.0) return circInOut(t);
    else if (easeType == 28.0) return expoIn(t);
    else if (easeType == 29.0) return expoOut(t);
    else if (easeType == 30.0) return expoInOut(t);
    else if (easeType == 31.0) return backIn(t);
    else if (easeType == 32.0) return backOut(t);
    else if (easeType == 33.0) return backInOut(t);
    else if (easeType == 34.0) return elasticIn(t);
    else if (easeType == 35.0) return elasticOut(t);
    else if (easeType == 36.0) return elasticInOut(t);

    return linear(t);
}


vec4 getColor(vec2 uv, float curValue) {
    vec4 col = vec4(0.0, 0.0, 0.0, 0.0);
    if (abs(uv.y - curValue) < 0.1) {
        col = vec4(1.0, 1.0, 1.0, 1.0);
    }
    return col;
}

void main()
{
    vec2 uv = openfl_TextureCoordv;
    if (flip == 1.0) {
        uv.y = -uv.y + 1.0;
    }
    uv.y -= 0.5;
    uv.y *= 1.2;
    uv.y += 0.5;
    float curValue = ease(uv.x);
    vec4 color = getColor(uv, curValue);

    color += getColor(uv + vec2(0.01, 0.01), curValue);
    color += getColor(uv + vec2(0.01, -0.01), curValue);
    color += getColor(uv + vec2(-0.01, -0.01), curValue);
    color += getColor(uv + vec2(-0.01, 0.01), curValue);

    color += getColor(uv + vec2(0.0, 0.01), curValue);
    color += getColor(uv + vec2(0.0, -0.01), curValue);
    color += getColor(uv + vec2(0.01, 0.0), curValue);
    color += getColor(uv + vec2(-0.01, 0.0), curValue);


	gl_FragColor = color / 9.0;
}