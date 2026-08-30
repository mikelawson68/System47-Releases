#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>
#import <CoreGraphics/CoreGraphics.h>

@interface System47FullScreenDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSMutableArray<NSWindow *> *windows;
@property(nonatomic, strong) NSMutableArray<ScreenSaverView *> *views;
@property(nonatomic, strong) id eventMonitor;
@property(nonatomic) CFAbsoluteTime inputArmedAt;
@end

@interface System47SettingsDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) NSPopUpButton *idlePopup;
@property(nonatomic, strong) NSButton *audioButton;
@property(nonatomic, strong) NSMutableArray<NSDictionary *> *monitorRows;
@end

@implementation System47SettingsDelegate

- (NSString *)identifierForScreen:(NSScreen *)screen index:(NSInteger)index {
    NSNumber *number = screen.deviceDescription[@"NSScreenNumber"];
    return number ? number.stringValue : [NSString stringWithFormat:@"index-%ld", (long)index];
}

- (NSTextField *)label:(NSString *)text frame:(NSRect)frame bold:(BOOL)bold {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.stringValue = text; label.editable = NO; label.selectable = NO;
    label.bezeled = NO; label.drawsBackground = NO;
    label.font = bold ? [NSFont boldSystemFontOfSize:13] : [NSFont systemFontOfSize:13];
    return label;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    NSArray *screens = NSScreen.screens;
    CGFloat height = 255 + MAX((NSInteger)screens.count, 1) * 42;
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 760, height)
                                              styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                                                backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"System 47 Settings";
    NSView *content = self.window.contentView;
    [content addSubview:[self label:@"System 47 Full-Screen Saver" frame:NSMakeRect(24, height-48, 400, 25) bold:YES]];
    [content addSubview:[self label:@"Starts outside Apple’s legacy screen-saver sandbox." frame:NSMakeRect(24, height-73, 500, 22) bold:NO]];

    [content addSubview:[self label:@"Start after" frame:NSMakeRect(24, height-112, 90, 22) bold:YES]];
    self.idlePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(112, height-118, 180, 28) pullsDown:NO];
    NSArray *idleNames = @[@"5 seconds", @"1 minute", @"5 minutes", @"10 minutes", @"30 minutes", @"1 hour", @"3 hours"];
    NSArray *idleValues = @[@5, @60, @300, @600, @1800, @3600, @10800];
    [self.idlePopup addItemsWithTitles:idleNames];
    for (NSInteger i=0; i<idleValues.count; i++) self.idlePopup.itemArray[i].representedObject = idleValues[i];
    NSTimeInterval savedIdle = [[[NSUserDefaults alloc] initWithSuiteName:@"com.mewho.system47.fullscreen"] doubleForKey:@"idleSeconds"];
    NSInteger best = 3; for (NSInteger i=0; i<idleValues.count; i++) if ([idleValues[i] doubleValue] == savedIdle) best = i;
    [self.idlePopup selectItemAtIndex:best]; [content addSubview:self.idlePopup];

    self.audioButton = [NSButton checkboxWithTitle:@"Play original System 47 sound" target:nil action:nil];
    self.audioButton.frame = NSMakeRect(320, height-116, 300, 26);
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.mewho.system47.screensaver"];
    self.audioButton.state = [defaults objectForKey:@"audioEnabled"] ? ([defaults boolForKey:@"audioEnabled"] ? NSControlStateValueOn : NSControlStateValueOff) : NSControlStateValueOn;
    [content addSubview:self.audioButton];

    CGFloat y = height - 158;
    [content addSubview:[self label:@"Display" frame:NSMakeRect(24,y,220,22) bold:YES]];
    [content addSubview:[self label:@"Starting program" frame:NSMakeRect(250,y,205,22) bold:YES]];
    [content addSubview:[self label:@"Behavior" frame:NSMakeRect(470,y,220,22) bold:YES]];
    self.monitorRows = [NSMutableArray array];
    NSArray *programs = @[@"Star System", @"Sector Volume", @"Nav. Readings", @"NCC-1701-E", @"Zoom Scan", @"Sector Grid", @"Galaxy Quad. Map", @"Warp Speed"];
    y -= 38;
    NSInteger index = 0;
    for (NSScreen *screen in screens) {
        NSString *identifier = [self identifierForScreen:screen index:index];
        [content addSubview:[self label:[NSString stringWithFormat:@"%ld. %@", (long)index+1, screen.localizedName] frame:NSMakeRect(24,y+4,220,22) bold:NO]];
        NSPopUpButton *program = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(250,y,200,28) pullsDown:NO];
        [program addItemsWithTitles:programs];
        NSString *sceneKey = [@"scene." stringByAppendingString:identifier];
        [program selectItemAtIndex:[defaults objectForKey:sceneKey] ? MAX(0, MIN(7, [defaults integerForKey:sceneKey])) : index % 8];
        [content addSubview:program];
        NSPopUpButton *behavior = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(470,y,220,28) pullsDown:NO];
        [behavior addItemsWithTitles:@[@"Follow original cycle", @"Keep this program"]];
        NSString *rotateKey = [@"rotate." stringByAppendingString:identifier];
        BOOL follows = [defaults objectForKey:rotateKey] ? [defaults boolForKey:rotateKey] : YES;
        [behavior selectItemAtIndex:follows ? 0 : 1]; [content addSubview:behavior];
        [self.monitorRows addObject:@{@"id":identifier, @"program":program, @"behavior":behavior}];
        y -= 42; index++;
    }

    NSButton *save = [NSButton buttonWithTitle:@"Save" target:self action:@selector(save:)];
    save.frame = NSMakeRect(650, 20, 86, 32); save.keyEquivalent = @"\r"; [content addSubview:save];
    NSButton *preview = [NSButton buttonWithTitle:@"Preview" target:self action:@selector(preview:)];
    preview.frame = NSMakeRect(550, 20, 90, 32); [content addSubview:preview];
    [self.window center]; [self.window makeKeyAndOrderFront:nil]; [NSApp activateIgnoringOtherApps:YES];
}

- (void)save:(id)sender {
    NSUserDefaults *settings = [[NSUserDefaults alloc] initWithSuiteName:@"com.mewho.system47.fullscreen"];
    [settings setDouble:[self.idlePopup.selectedItem.representedObject doubleValue] forKey:@"idleSeconds"];
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.mewho.system47.screensaver"];
    [defaults setBool:self.audioButton.state == NSControlStateValueOn forKey:@"audioEnabled"];
    for (NSDictionary *row in self.monitorRows) {
        NSString *identifier = row[@"id"];
        [defaults setInteger:[row[@"program"] indexOfSelectedItem] forKey:[@"scene." stringByAppendingString:identifier]];
        [defaults setBool:[row[@"behavior"] indexOfSelectedItem] == 0 forKey:[@"rotate." stringByAppendingString:identifier]];
    }
    [defaults synchronize]; [settings synchronize];
    self.window.title = @"System 47 Settings — Saved";
}

- (void)preview:(id)sender {
    [self save:nil];
    NSTask *task = [[NSTask alloc] init]; task.executableURL = [NSURL fileURLWithPath:NSBundle.mainBundle.executablePath];
    task.arguments = @[@"--show"]; [task launchAndReturnError:nil];
}
@end

@implementation System47FullScreenDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [NSApp setPresentationOptions:(NSApplicationPresentationAutoHideDock |
                                   NSApplicationPresentationAutoHideMenuBar |
                                   NSApplicationPresentationDisableAppleMenu |
                                   NSApplicationPresentationDisableProcessSwitching)];

    NSString *saverPath = [NSBundle.mainBundle.builtInPlugInsPath stringByAppendingPathComponent:@"System 47 Modern.saver"];
    NSBundle *saverBundle = [NSBundle bundleWithPath:saverPath];
    if (![saverBundle load] || !saverBundle.principalClass) {
        NSLog(@"SYSTEM47_FULLSCREEN_LOAD_FAILED=%@", saverPath);
        [NSApp terminate:nil];
        return;
    }

    self.windows = [NSMutableArray array];
    self.views = [NSMutableArray array];
    for (NSScreen *screen in NSScreen.screens) {
        NSRect frame = screen.frame;
        NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                       styleMask:NSWindowStyleMaskBorderless
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO
                                                          screen:screen];
        window.backgroundColor = NSColor.blackColor;
        window.level = NSScreenSaverWindowLevel;
        window.opaque = YES;
        window.acceptsMouseMovedEvents = YES;
        window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
                                    NSWindowCollectionBehaviorFullScreenAuxiliary |
                                    NSWindowCollectionBehaviorStationary;
        ScreenSaverView *view = [[saverBundle.principalClass alloc]
                                 initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)
                                 isPreview:NO];
        window.contentView = view;
        [window setFrame:frame display:YES];
        [window makeKeyAndOrderFront:nil];
        [view startAnimation];
        [self.windows addObject:window];
        [self.views addObject:view];
    }

    [NSApp activateIgnoringOtherApps:YES];
    self.inputArmedAt = CFAbsoluteTimeGetCurrent() + 1.5;
    // Screen Sharing continuously delivers pointer-motion events to the remote
    // Mac while a session is being observed. Treating mouseMoved as dismissal
    // input makes the saver flash once and immediately quit on remotely managed
    // Macs. Explicit input still dismisses the saver normally.
    NSEventMask mask = NSEventMaskKeyDown | NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown |
                       NSEventMaskOtherMouseDown | NSEventMaskScrollWheel;
    __weak typeof(self) weakSelf = self;
    self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:mask handler:^NSEvent *(NSEvent *event) {
        if (CFAbsoluteTimeGetCurrent() >= weakSelf.inputArmedAt) [NSApp terminate:nil];
        return event;
    }];
    NSLog(@"SYSTEM47_FULLSCREEN_READY displays=%lu", (unsigned long)self.windows.count);
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if (self.eventMonitor) [NSEvent removeMonitor:self.eventMonitor];
    for (ScreenSaverView *view in self.views) [view stopAnimation];
    for (NSWindow *window in self.windows) [window orderOut:nil];
}
@end

static void RunWatcher(void) {
    NSString *executable = NSBundle.mainBundle.executablePath;
    __block NSTask *viewer = nil;
    __block BOOL launchedForThisIdlePeriod = NO;
    __block BOOL launchedFromCorner = NO;
    __block BOOL launchedFromSystem = NO;
    __block NSInteger cornerTicks = 0;
    __block CFAbsoluteTime viewerStartedAt = 0;
    NSUserDefaults *settings = [[NSUserDefaults alloc] initWithSuiteName:@"com.mewho.system47.fullscreen"];

    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                                       dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 0), NSEC_PER_SEC, NSEC_PER_SEC / 5);
    dispatch_source_set_event_handler(timer, ^{
        CFTimeInterval idle = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState,
                                                                     kCGAnyInputEventType);
        NSTimeInterval configured = [settings doubleForKey:@"idleSeconds"];
        NSTimeInterval threshold = configured >= 5.0 ? configured : 600.0;
        if (viewer && !viewer.running) viewer = nil;
        if (!launchedFromSystem && viewer && viewer.running && CFAbsoluteTimeGetCurrent() - viewerStartedAt > 2.0 && idle < 1.0) {
            [viewer terminate];
            viewer = nil;
        }
        BOOL systemRequested = [[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/com.mewho.system47.system-request"];
        if (systemRequested && !viewer && !launchedFromSystem) {
            viewer = [[NSTask alloc] init];
            viewer.executableURL = [NSURL fileURLWithPath:executable];
            viewer.arguments = @[@"--show"];
            [viewer launchAndReturnError:nil];
            viewerStartedAt = CFAbsoluteTimeGetCurrent();
            launchedFromSystem = YES;
        } else if (!systemRequested && launchedFromSystem) {
            if (viewer && viewer.running) [viewer terminate];
            viewer = nil;
            launchedFromSystem = NO;
        }

        CGEventRef locationEvent = CGEventCreate(NULL);
        CGPoint mouse = locationEvent ? CGEventGetLocation(locationEvent) : CGPointMake(-1000, -1000);
        if (locationEvent) CFRelease(locationEvent);
        CGDirectDisplayID displays[32]; uint32_t count = 0;
        CGGetActiveDisplayList(32, displays, &count);
        BOOL inBottomRightCorner = NO;
        for (uint32_t i = 0; i < count; i++) {
            CGRect bounds = CGDisplayBounds(displays[i]);
            if (mouse.x >= CGRectGetMaxX(bounds) - 4 && mouse.x <= CGRectGetMaxX(bounds) + 1 &&
                mouse.y >= CGRectGetMaxY(bounds) - 4 && mouse.y <= CGRectGetMaxY(bounds) + 1) {
                inBottomRightCorner = YES; break;
            }
        }
        if (inBottomRightCorner) cornerTicks++; else { cornerTicks = 0; launchedFromCorner = NO; }
        if (cornerTicks >= 2 && !launchedFromCorner && !viewer) {
            viewer = [[NSTask alloc] init];
            viewer.executableURL = [NSURL fileURLWithPath:executable];
            viewer.arguments = @[@"--show"];
            [viewer launchAndReturnError:nil];
            viewerStartedAt = CFAbsoluteTimeGetCurrent();
            launchedFromCorner = YES;
        }
        if (idle < threshold) launchedForThisIdlePeriod = NO;
        if (!launchedForThisIdlePeriod && !viewer && idle >= threshold) {
            viewer = [[NSTask alloc] init];
            viewer.executableURL = [NSURL fileURLWithPath:executable];
            viewer.arguments = @[@"--show"];
            [viewer launchAndReturnError:nil];
            viewerStartedAt = CFAbsoluteTimeGetCurrent();
            launchedForThisIdlePeriod = YES;
        }
    });
    dispatch_resume(timer);
    [[NSRunLoop currentRunLoop] run];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *mode = argc > 1 ? [NSString stringWithUTF8String:argv[1]] : @"--settings";
        BOOL watch = [mode isEqualToString:@"--watch"];
        if (watch) {
            RunWatcher();
            return 0;
        }
        NSApplication *application = NSApplication.sharedApplication;
        id delegate = [mode isEqualToString:@"--show"] ? [[System47FullScreenDelegate alloc] init] : [[System47SettingsDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
