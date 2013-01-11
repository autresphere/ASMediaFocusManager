## ASMediaFocusManager
ASMediaFocusManager gives the ability to focus on any image by a simple tap. The image is automatically animated to a focused fullscreen image view. Another tap on the focused view shrinks the image back to its initial position.

![](https://github.com/autresphere/ASMediaFocusManager/raw/master/Screenshots/iPhone1.jpg) 
![](https://github.com/autresphere/ASMediaFocusManager/raw/master/Screenshots/iPhone2.jpg) 
![](https://github.com/autresphere/ASMediaFocusManager/raw/master/Screenshots/iPhone3.jpg)

## Orientation
The focused view is automatically adapted to the screen orientation even if your main view controller is portrait only.

Because orientation management is different between iOS 5 and 6, this class is for iOS 6 only (although it should not be hard to adapt it to iOS 5).
## Use It
* Create a ASMediaFocusManager
* Implement its delegate
* Declare all your views that you want to be focusable by calling `[ASMediaFocusManager installOnViews:]`

## ARC
ASMediaFocusManager needs ARC.

## Licence
ASMediaFocusManager is available under the MIT license. See the LICENSE file for more info.


