## ASMediaFocusManager
ASMediaFocusManager gives the ability to focus on any thumbnail image or video by a simple tap. The thumbnail image is automatically animated to a focused fullscreen image view or video player. Another tap on the 'Done' button shrinks (or defocuses) the image back to its initial position.

Each thumbnail image view may have its own transform, the focus and defocus animations take care of any initial transform.

Works on iPhone and iPad.

<div class="macbuildserver-block">
    <a class="macbuildserver-button" href="http://macbuildserver.com/project/github/build/?xcode_project=Example%2FASMediaFocusExemple.xcodeproj&amp;target=ASMediaFocusExemple&amp;repo_url=https%3A%2F%2Fgithub.com%2Fautresphere%2FASMediaFocusManager&amp;build_conf=Release" target="_blank"><img src="http://com.macbuildserver.github.s3-website-us-east-1.amazonaws.com/button_up.png"/></a><br/><sup><a href="http://macbuildserver.com/github/opensource/" target="_blank">by MacBuildServer</a></sup>
</div>

![](https://github.com/autresphere/ASMediaFocusManager/raw/master/Screenshots/video.gif) 

## Video
A video player is shown if the media is a video (supported extension are "mp4" and "mov"). The video player comes with its own controls made of a play/pause button, a slider and time labels. Scrubbing is also available.

![](https://github.com/autresphere/ASMediaFocusManager/raw/master/Screenshots/videoFocusOnVideo.gif)

![](https://github.com/autresphere/ASMediaFocusManager/raw/master/Screenshots/videoPlayer.png) 

## Orientation
The focused view is automatically adapted to the screen orientation even if your main view controller is portrait only.

Because orientation management was different on iOS 5, this class does not work on iOS 5 and below (although it should not be hard to adapt it).

## Image content modes
For now, only `UIViewContentModeScaleAspectFit` and `UIViewContentModeScaleAspectFill` are supported, but these modes are the most widely used.

In case of `UIViewContentModeScaleAspectFill`, the view is expanded in order to show the image in full.

![](https://github.com/autresphere/ASMediaFocusManager/raw/master/Screenshots/videoAspectFill.gif) 

If you want other content modes to be supported, please drop me a line. You can even try a pull request, which would be much appreciated!

## Image size
When focused, an image is shown fullscreen even if the image is smaller than the screen resolution. In this case no interactive zoom is available.

All Image sizes are supported.

## Exemple Project
See the contained example to get a sample of how `ASMediaFocusManager` can easily be integrated in your project.

To build the example, you first need to run `pod install` from the `Example` directory.

## Use It
The prefered way to integrate `ASMediaFocusManager` is through cocoapods as it is dependent on another pod for the video feature. Add `pod 'ASMediaFocusManager'` to your Podfile.

You can also copy the whole `ASMediaFocusManager` folder in your project, as well as `ASBPlayerScrubbing`.

Then in your project:

* Create a `ASMediaFocusManager`
* Implement its delegate `ASMediaFocusDelegate`.
The delegate returns mainly a media URL, a media title and a parent view controller. 
* Declare all your views that you want to be focusable by calling `[ASMediaFocusManager installOnViews:]`

###Implementing
In your View Controller where some image views need focus feature, add this code.

```objc
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mediaFocusManager = [[ASMediaFocusManager alloc] init];
    self.mediaFocusManager.delegate = self;
    // Tells which views need to be focusable. You can put your image views in an array and give it to the focus manager.
    [self.mediaFocusManager installOnViews:self.imageViews];
}
```

Here is an example of a delegate implementation. Please adapt the code to your context.
```objc

- (void)viewDidLoad
{
    ...
    self.mediaNames = @[@"1f.jpg", @"2f.jpg", @"3f.mp4", @"4f.jpg"];
    ...
}

#pragma mark - ASMediaFocusDelegate
// Returns the view controller in which the focus controller is going to be added.
// This can be any view controller, full screen or not.
- (UIViewController *)parentViewControllerForMediaFocusManager:(ASMediaFocusManager *)mediaFocusManager
{
    return self.parentViewController;
}

// Returns the URL where the media (image or video) is stored. The URL may be local (file://) or distant (http://).
- (NSURL *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager mediaURLForView:(UIView *)view
{
    NSInteger index;
    NSString *name;
    NSURL *url;

    // Here, medias are accessed through their name stored in self.mediaNames
    index = [self.imageViews indexOfObject:view];
    name = self.mediaNames[index];    
    url = [[NSBundle mainBundle] URLForResource:name withExtension:nil];
    
    return url;
}

// Returns the title for this media view. Return nil if you don't want any title to appear.
- (NSString *)mediaFocusManager:(ASMediaFocusManager *)mediaFocusManager titleForView:(UIView *)view
{
	return @"My title";
}


```

If you need to focus or defocus a view programmatically, you can call `startFocusingView` ()as long as the view is focusable) or `endFocusing`.

```objc
[self.mediaFocusManager startFocusingView:mediaView];
```

###Configure
Here is the things you can configure:

* focused background color 
* animation duration
* enable/disable elastic animation
* enable/disable zooming by pinch
* close focused view by tap, vertical swipe or through a "Done" button

### Hiding the status bar
On iOS 7, if you want to hide or show the status bar when a view is focused or defocused, you can use optional delegate methods `[ASMediaFocusManager mediaFocusManagerWillAppear:]` and `[ASMediaFocusManager mediaFocusManagerWillDisappear:]`.

Here is an example on how to hide and show the status bar. As the delegate methods are called inside an animation block, the status bar will be hidden or shown with animation.
```objc
- (void)mediaFocusManagerWillAppear:(ASMediaFocusManager *)mediaFocusManager
{
    self.statusBarHidden = YES;
	[self setNeedsStatusBarAppearanceUpdate];
}

- (void)mediaFocusManagerWillDisappear:(ASMediaFocusManager *)mediaFocusManager
{
    self.statusBarHidden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

// statusBarHidden is defined as a property.
@property (nonatomic, assign) BOOL statusBarHidden;

```


##Todo
* Allow the use of your own video control view.
* Add a play icon on video thumbnail
* Fix image jump on orientation change when fullscreen image is zoomed (only when parent ViewController supports UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown)
* Media browsing by horizontal swipe in fullscreen.
* Close focus view by vertical swipe like in facebook app (partly done thanks to @harishkashyap, Feb 09, 2015).
* ~~Improve the elastic (ie natural) effect on focus and defocus rotation.~~ (April 1, 2015)
* ~~Support movie media.~~ (April 1, 2015)
* ~~Hide accessory views (button and label) when view is zoomed.~~ (March 5, 2014)


## ARC
ASMediaFocusManager needs ARC.

## Licence
ASMediaFocusManager is available under the MIT license.

## Author
Philippe Converset, AutreSphere - pconverset@autresphere.com

[@Follow me on Twitter](http://twitter.com/autresphere)



