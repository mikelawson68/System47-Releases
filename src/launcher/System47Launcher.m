#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>

static NSString *const Renderer = @"/Applications/System 47.app/Contents/MacOS/System47FullScreen";
static BOOL inCorner(NSPoint p, NSRect r) {
    return p.x >= NSMinX(r) && p.x <= NSMinX(r)+3 && p.y >= NSMinY(r) && p.y <= NSMinY(r)+3;
}

@interface Launcher : NSObject
@property NSTask *renderer;
@property BOOL cornerLatched;
@property BOOL idleLatched;
@property NSTimeInterval nextLaunch;
@property NSString *requestPath;
- (void)tick;
@end

@implementation Launcher
- (void)tick {
    @autoreleasepool {
        NSPoint p = NSEvent.mouseLocation;
        BOOL corner = NO;
        for (NSScreen *screen in NSScreen.screens) corner |= inCorner(p, screen.frame);
        NSTimeInterval idle = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGAnyInputEventType);
        NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.mewho.system47.fullscreen"];
        [prefs synchronize];
        double threshold = [prefs doubleForKey:@"idleSeconds"];
        if (!isfinite(threshold) || threshold < 0) threshold = 10800;
        if (!corner) self.cornerLatched = NO;
        if (idle < 2) self.idleLatched = NO;
        BOOL requested = [[NSFileManager defaultManager] fileExistsAtPath:self.requestPath];
        if (requested) [[NSFileManager defaultManager] removeItemAtPath:self.requestPath error:nil];
        BOOL cornerTrigger = corner && !self.cornerLatched;
        BOOL idleTrigger = threshold > 0 && idle >= threshold && !self.idleLatched;
        if (self.renderer.running) {
            if (corner) self.cornerLatched = YES;
            self.idleLatched = YES;
            self.nextLaunch = NSDate.timeIntervalSinceReferenceDate + 2;
            return;
        }
        if (!(cornerTrigger || idleTrigger || requested) || NSDate.timeIntervalSinceReferenceDate < self.nextLaunch) return;
        self.cornerLatched = corner;
        self.idleLatched = YES;
        self.nextLaunch = NSDate.timeIntervalSinceReferenceDate + 3;
        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:Renderer];
        task.arguments = @[@"--show"];
        NSError *error = nil;
        if ([task launchAndReturnError:&error]) {
            self.renderer = task;
            NSLog(@"System47 launched: %@; displays=%lu", requested ? @"verification" : cornerTrigger ? @"bottom-left corner" : @"idle timer", (unsigned long)NSScreen.screens.count);
        } else {
            NSLog(@"System47 launch failed: %@", error);
        }
    }
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
        NSString *support = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/System47Launcher"];
        NSString *request = [support stringByAppendingPathComponent:@"preview-request"];
        if (argc > 1 && strcmp(argv[1], "--trigger") == 0) {
            return [@"preview" writeToFile:request atomically:YES encoding:NSUTF8StringEncoding error:nil] ? 0 : 1;
        }
        if (argc > 1 && strcmp(argv[1], "--check") == 0) {
            for (NSScreen *s in NSScreen.screens) {
                NSRect r = s.frame;
                if (!inCorner(NSMakePoint(NSMinX(r)+1,NSMinY(r)+1),r) || inCorner(NSMakePoint(NSMinX(r)+10,NSMinY(r)+10),r)) return 1;
                NSLog(@"%@ bottom-left=(%.0f,%.0f)",s.localizedName, NSMinX(r),NSMinY(r));
            }
            return NSScreen.screens.count ? 0 : 1;
        }
        Launcher *launcher = [[Launcher alloc] init];
        launcher.requestPath = request;
        NSLog(@"System47 launcher ready; bottom-left hot corner and saved idle timer enabled");
        [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer *timer) { [launcher tick]; }];
        [NSApp run];
    }
    return 0;
}
