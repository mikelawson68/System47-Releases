#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>
#import <CoreGraphics/CoreGraphics.h>

@interface System47FullScreenDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSMutableArray<NSWindow *> *windows;
@property(nonatomic, strong) NSMutableArray<ScreenSaverView *> *views;
@property(nonatomic, strong) id eventMonitor;
@property(nonatomic, strong) NSTimer *dismissalTimer;
@property(nonatomic) CFAbsoluteTime inputArmedAt;
@property(nonatomic) NSPoint launchPointer;
@end

@interface System47SettingsDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) NSPopUpButton *idlePopup;
@property(nonatomic, strong) NSButton *audioButton;
@property(nonatomic, strong) NSButton *lockButton;
@property(nonatomic, strong) NSMutableArray<NSDictionary *> *monitorRows;
@end

@implementation System47SettingsDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

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
    [content addSubview:[self label:@"Runs as a lightweight background app; hold the pointer at top center for three seconds to start." frame:NSMakeRect(24, height-73, 700, 22) bold:NO]];

    [content addSubview:[self label:@"Start after" frame:NSMakeRect(24, height-112, 90, 22) bold:YES]];
    self.idlePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(112, height-118, 180, 28) pullsDown:NO];
    NSArray *idleNames = @[@"Never", @"1 minute", @"2 minutes", @"5 minutes", @"10 minutes", @"20 minutes", @"30 minutes", @"1 hour"];
    NSArray *idleValues = @[@0, @60, @120, @300, @600, @1200, @1800, @3600];
    [self.idlePopup addItemsWithTitles:idleNames];
    for (NSInteger i=0; i<idleValues.count; i++) self.idlePopup.itemArray[i].representedObject = idleValues[i];
    NSDictionary *settings = [NSUserDefaults.standardUserDefaults persistentDomainForName:@"com.mewho.system47.fullscreen"] ?: @{};
    id savedIdleObject = settings[@"idleSeconds"];
    NSTimeInterval savedIdle = savedIdleObject ? [savedIdleObject doubleValue] : 1200.0;
    NSInteger best = 5;
    for (NSInteger i=0; i<idleValues.count; i++) if ([idleValues[i] doubleValue] == savedIdle) best = i;
    [self.idlePopup selectItemAtIndex:best];
    [content addSubview:self.idlePopup];

    self.audioButton = [NSButton checkboxWithTitle:@"Play original System 47 sound" target:nil action:nil];
    self.audioButton.frame = NSMakeRect(320, height-116, 300, 26);
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.mewho.system47.screensaver"];
    self.audioButton.state = [defaults objectForKey:@"audioEnabled"] ? ([defaults boolForKey:@"audioEnabled"] ? NSControlStateValueOn : NSControlStateValueOff) : NSControlStateValueOn;
    [content addSubview:self.audioButton];

    self.lockButton = [NSButton checkboxWithTitle:@"Go to the macOS login screen when System 47 closes" target:nil action:nil];
    self.lockButton.frame = NSMakeRect(320, height-142, 390, 26);
    self.lockButton.state = [settings[@"lockOnExit"] boolValue] ? NSControlStateValueOn : NSControlStateValueOff;
    [content addSubview:self.lockButton];

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
    NSUserDefaults *defaultsStore = NSUserDefaults.standardUserDefaults;
    NSMutableDictionary *settings = [[defaultsStore persistentDomainForName:@"com.mewho.system47.fullscreen"] mutableCopy] ?: [NSMutableDictionary dictionary];
    settings[@"idleSeconds"] = self.idlePopup.selectedItem.representedObject;
    settings[@"lockOnExit"] = @(self.lockButton.state == NSControlStateValueOn);
    [defaultsStore setPersistentDomain:settings forName:@"com.mewho.system47.fullscreen"];
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.mewho.system47.screensaver"];
    [defaults setBool:self.audioButton.state == NSControlStateValueOn forKey:@"audioEnabled"];
    for (NSDictionary *row in self.monitorRows) {
        NSString *identifier = row[@"id"];
        [defaults setInteger:[row[@"program"] indexOfSelectedItem] forKey:[@"scene." stringByAppendingString:identifier]];
        [defaults setBool:[row[@"behavior"] indexOfSelectedItem] == 0 forKey:[@"rotate." stringByAppendingString:identifier]];
    }
    [defaults synchronize]; [defaultsStore synchronize];
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
        NSPanel *window = [[NSPanel alloc] initWithContentRect:frame
                                                     styleMask:NSWindowStyleMaskBorderless
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO
                                                        screen:screen];
        window.backgroundColor = NSColor.blackColor;
        window.level = NSScreenSaverWindowLevel;
        window.opaque = YES;
        window.acceptsMouseMovedEvents = YES;
        window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
                                    NSWindowCollectionBehaviorCanJoinAllApplications |
                                    NSWindowCollectionBehaviorFullScreenAuxiliary |
                                    NSWindowCollectionBehaviorStationary;
        ScreenSaverView *view = [[saverBundle.principalClass alloc]
                                 initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)
                                 isPreview:NO];
        window.contentView = view;
        [window setFrame:frame display:YES];
        [window orderFrontRegardless];
        [view startAnimation];
        [self.windows addObject:window];
        [self.views addObject:view];
    }

    [NSApp activateIgnoringOtherApps:YES];
    self.inputArmedAt = CFAbsoluteTimeGetCurrent() + 1.5;
    self.launchPointer = NSEvent.mouseLocation;
    // Screen Sharing continuously delivers pointer-motion events to the remote
    // Mac while a session is being observed. Treating mouseMoved as dismissal
    // input makes the saver flash once and immediately quit on remotely managed
    // Macs. Explicit input still dismisses the saver normally.
    NSEventMask mask = NSEventMaskMouseMoved | NSEventMaskLeftMouseDragged | NSEventMaskRightMouseDragged |
                       NSEventMaskOtherMouseDragged | NSEventMaskKeyDown | NSEventMaskLeftMouseDown |
                       NSEventMaskRightMouseDown | NSEventMaskOtherMouseDown | NSEventMaskScrollWheel;
    __weak typeof(self) weakSelf = self;
    self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:mask handler:^NSEvent *(NSEvent *event) {
        if (CFAbsoluteTimeGetCurrent() >= weakSelf.inputArmedAt) [NSApp terminate:nil];
        return event;
    }];
    self.dismissalTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *timer) {
        if (CFAbsoluteTimeGetCurrent() < weakSelf.inputArmedAt) return;
        NSPoint current = NSEvent.mouseLocation;
        CGFloat dx = current.x - weakSelf.launchPointer.x;
        CGFloat dy = current.y - weakSelf.launchPointer.y;
        if ((dx * dx) + (dy * dy) > 9.0) [NSApp terminate:nil];
    }];
    NSLog(@"SYSTEM47_FULLSCREEN_READY displays=%lu", (unsigned long)self.windows.count);
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if (self.eventMonitor) [NSEvent removeMonitor:self.eventMonitor];
    [self.dismissalTimer invalidate];
    for (ScreenSaverView *view in self.views) [view stopAnimation];
    for (NSWindow *window in self.windows) [window orderOut:nil];
    NSDictionary *settings = [NSUserDefaults.standardUserDefaults persistentDomainForName:@"com.mewho.system47.fullscreen"] ?: @{};
    if ([settings[@"lockOnExit"] boolValue]) {
        NSTask *lockTask = [[NSTask alloc] init];
        lockTask.executableURL = [NSURL fileURLWithPath:@"/usr/bin/pmset"];
        lockTask.arguments = @[@"displaysleepnow"];
        [lockTask launchAndReturnError:nil];
    }
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *mode = argc > 1 ? [NSString stringWithUTF8String:argv[1]] : @"--settings";
        NSApplication *application = NSApplication.sharedApplication;
        id delegate = [mode isEqualToString:@"--show"] ? [[System47FullScreenDelegate alloc] init] : [[System47SettingsDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
