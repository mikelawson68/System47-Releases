#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>

static NSString *rendererPath(void) {
    NSString *systemPath = @"/Applications/System 47.app/Contents/MacOS/System47FullScreen";
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:systemPath]) return systemPath;
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Applications/System 47.app/Contents/MacOS/System47FullScreen"];
}
static BOOL inTopCenterHoldArea(NSPoint p, NSRect r) {
    CGFloat center = NSMidX(r);
    return p.x >= center - 30 && p.x <= center + 30 &&
           p.y >= NSMaxY(r) - 4 && p.y <= NSMaxY(r);
}

@interface Launcher : NSObject
@property NSTask *renderer;
@property BOOL holdLatched;
@property BOOL idleLatched;
@property NSTimeInterval holdStartedAt;
@property NSTimeInterval nextLaunch;
@property NSString *requestPath;
@property NSStatusItem *statusItem;
- (void)tick;
- (void)installMenuBarItem;
@end

@implementation Launcher
- (void)installMenuBarItem {
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"47";
    self.statusItem.button.toolTip = @"System 47";
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"System 47"];
    [menu addItemWithTitle:@"System 47 Settings…" action:@selector(openSettings:) keyEquivalent:@","];
    [menu addItemWithTitle:@"Start System 47 Now" action:@selector(startNow:) keyEquivalent:@""];
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItemWithTitle:@"Quit System 47 Background App" action:@selector(quit:) keyEquivalent:@"q"];
    for (NSMenuItem *item in menu.itemArray) item.target = self;
    self.statusItem.menu = menu;
}

- (void)openSettings:(id)sender {
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:rendererPath()];
    [task launchAndReturnError:nil];
}

- (void)startNow:(id)sender {
    [@"menu" writeToFile:self.requestPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)quit:(id)sender {
    [NSApp terminate:nil];
}

- (void)tick {
    @autoreleasepool {
        NSPoint p = NSEvent.mouseLocation;
        BOOL holding = NO;
        for (NSScreen *screen in NSScreen.screens) holding |= inTopCenterHoldArea(p, screen.frame);
        NSTimeInterval idle = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGAnyInputEventType);
        NSTimeInterval now = NSDate.timeIntervalSinceReferenceDate;
        NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.mewho.system47.fullscreen"];
        [prefs synchronize];
        id savedThreshold = [prefs objectForKey:@"idleSeconds"];
        double threshold = savedThreshold ? [savedThreshold doubleValue] : 1200.0;
        if (!isfinite(threshold) || threshold < 0) threshold = 1200.0;
        if (holding && self.holdStartedAt == 0) self.holdStartedAt = now;
        if (!holding) { self.holdStartedAt = 0; self.holdLatched = NO; }
        if (idle < 2) self.idleLatched = NO;
        BOOL requested = [[NSFileManager defaultManager] fileExistsAtPath:self.requestPath];
        if (requested) [[NSFileManager defaultManager] removeItemAtPath:self.requestPath error:nil];
        BOOL holdTrigger = holding && !self.holdLatched && self.holdStartedAt > 0 && now - self.holdStartedAt >= 3.0;
        BOOL idleTrigger = threshold > 0 && idle >= threshold && !self.idleLatched;
        if (self.renderer.running) {
            if (holding) self.holdLatched = YES;
            self.idleLatched = YES;
            self.nextLaunch = now + 2;
            return;
        }
        if (!(holdTrigger || idleTrigger || requested) || now < self.nextLaunch) return;
        self.holdLatched = holding;
        self.idleLatched = YES;
        self.nextLaunch = now + 3;
        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:rendererPath()];
        task.arguments = @[@"--show"];
        NSError *error = nil;
        if ([task launchAndReturnError:&error]) {
            self.renderer = task;
            NSLog(@"System47 launched: %@; displays=%lu", requested ? @"preview" : holdTrigger ? @"top-center hold" : @"idle timer", (unsigned long)NSScreen.screens.count);
        } else {
            NSLog(@"System47 launch failed: %@", error);
        }
    }
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        NSString *support = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/System47Launcher"];
        NSString *request = [support stringByAppendingPathComponent:@"preview-request"];
        if (argc > 1 && strcmp(argv[1], "--trigger") == 0) {
            return [@"preview" writeToFile:request atomically:YES encoding:NSUTF8StringEncoding error:nil] ? 0 : 1;
        }
        if (argc > 1 && strcmp(argv[1], "--check") == 0) {
            for (NSScreen *s in NSScreen.screens) {
                NSRect r = s.frame;
                if (!inTopCenterHoldArea(NSMakePoint(NSMidX(r),NSMaxY(r)-1),r) || inTopCenterHoldArea(NSMakePoint(NSMidX(r)+100,NSMaxY(r)-1),r)) return 1;
                NSLog(@"%@ top-center=(%.0f,%.0f)",s.localizedName, NSMidX(r),NSMaxY(r));
            }
            return NSScreen.screens.count ? 0 : 1;
        }
        Launcher *launcher = [[Launcher alloc] init];
        launcher.requestPath = request;
        [launcher installMenuBarItem];
        NSLog(@"System47 background app ready; three-second top-center hold and saved idle timer enabled");
        [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer *timer) { [launcher tick]; }];
        [NSApp run];
    }
    return 0;
}
