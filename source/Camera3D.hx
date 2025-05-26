//
import Vec4;

class Camera3D {
    public var fov = 70.5; //matches closest to 2D
    public var position:Vec4;
    public var lookAt:Vec4;
    public var up:Vec4;

    public var negEye:Vec4;
    public var right:Vec4;
    public var upv:Vec4;
    public var forward:Vec4;

    public function new() {
        position = createVec4(0, 0, -1, 0);
        lookAt = createVec4(0, 0, 0, 0);
        up = createVec4(0, 1, 0, 0);
        negEye = createVec4(0, 0, 0, 0);
        right = createVec4(1, 0, 0, 0);
        upv = createVec4(0, 1, 0, 0);
        forward = createVec4(0, 0, 1, 0);

        updatePerspectiveMatrix();
        updateViewMatrix();
    }

    public var perspectiveMatrix:Array<Float> = [];
    public var viewMatrix:Array<Float> = [];

    public function updateViewMatrix() {
        forward.x = lookAt.x - position.x;
        forward.y = -lookAt.y - -position.y;
        forward.z = lookAt.z - position.z;
        forward.normalize();

        right.cross(up, forward);
        right.normalize();
        upv.cross(forward, right);
        negEye.x = -position.x;
        negEye.y = position.y;
        negEye.z = -position.z;
        negEye.w = -position.w;
        viewMatrix = 
        [
            right.x, upv.x, forward.x, 0,
            right.y, upv.y, forward.y, 0,
            right.z, upv.z, forward.z, 0,
            right.dot(negEye), upv.dot(negEye), forward.dot(negEye), 1
        ];
    }

    public function updatePerspectiveMatrix() {
        var focalLength = 1.0 * (1.0 / Math.tan(fov * 0.5 * (Math.PI/180)));
        perspectiveMatrix = 
        [
            focalLength, 0, 0, 0,
            0, focalLength, 0, 0,
            0, 0, 1.0, 1.0,
            0, 0, 0, 0
        ];
    }
}