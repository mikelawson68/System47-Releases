#import <ScreenSaver/ScreenSaver.h>

@interface System47BridgeScreenSaverView : ScreenSaverView <NSWindowDelegate>
@property(nonatomic, strong) NSImage *previewImage;
@property(nonatomic, strong) ScreenSaverView *animatedPreview;
@property(nonatomic, strong) NSWindow *settingsSheet;
@end

@implementation System47BridgeScreenSaverView

- (NSURL *)companionApplicationURL {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSURL *appURL = [workspace URLForApplicationWithBundleIdentifier:@"com.mewho.system47.fullscreen"];
    if (appURL) return appURL;
    NSArray<NSString *> *candidates = @[
        @"/Applications/System 47.app",
        [NSHomeDirectory() stringByAppendingPathComponent:@"Applications/System 47.app"]
    ];
    for (NSString *candidate in candidates) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:candidate]) {
            return [NSURL fileURLWithPath:candidate];
        }
    }
    return nil;
}

- (void)installAnimatedPreviewIfAvailable {
    if (!self.isPreview || self.animatedPreview) return;
    NSURL *appURL = [self companionApplicationURL];
    if (!appURL) return;
    NSURL *saverURL = [appURL URLByAppendingPathComponent:@"Contents/PlugIns/System 47 Modern.saver"];
    NSBundle *saverBundle = [NSBundle bundleWithURL:saverURL];
    if (![saverBundle load] || !saverBundle.principalClass ||
        ![saverBundle.principalClass isSubclassOfClass:ScreenSaverView.class]) return;
    self.animatedPreview = [[saverBundle.principalClass alloc] initWithFrame:self.bounds isPreview:YES];
    self.animatedPreview.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:self.animatedPreview];
}

- (void)launchCompanionFullScreen {
    NSURL *appURL = [self companionApplicationURL];
    if (!appURL) return;
    NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];
    configuration.arguments = @[@"--show"];
    configuration.createsNewApplicationInstance = YES;
    [[NSWorkspace sharedWorkspace] openApplicationAtURL:appURL
                                           configuration:configuration
                                       completionHandler:^(NSRunningApplication *application, NSError *error) {
        if (error) NSLog(@"SYSTEM47_BRIDGE_LAUNCH_FAILED=%@", error);
    }];
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        self.animationTimeInterval = 1.0 / 10.0;
        NSURL *imageURL = [[NSBundle bundleForClass:self.class] URLForResource:@"Preview" withExtension:@"png"];
        self.previewImage = [[NSImage alloc] initWithContentsOfURL:imageURL];
        [self installAnimatedPreviewIfAvailable];
    }
    return self;
}

- (void)startAnimation {
    [super startAnimation];
    if (self.isPreview) {
        [self installAnimatedPreviewIfAvailable];
        [self.animatedPreview startAnimation];
    } else {
        [self launchCompanionFullScreen];
    }
    [self setNeedsDisplay:YES];
}

- (void)stopAnimation {
    if (self.isPreview) [self.animatedPreview stopAnimation];
    [super stopAnimation];
}

- (void)dealloc {
    if (self.isPreview) [self.animatedPreview stopAnimation];
}

- (void)drawRect:(NSRect)dirtyRect {
    [NSColor.blackColor setFill]; NSRectFill(self.bounds);
    if (self.animatedPreview) return;
    if (!self.previewImage) return;
    NSSize source = self.previewImage.size;
    CGFloat scale = MIN(NSWidth(self.bounds) / MAX(source.width, 1), NSHeight(self.bounds) / MAX(source.height, 1));
    NSSize size = NSMakeSize(source.width * scale, source.height * scale);
    NSRect destination = NSMakeRect(NSMidX(self.bounds)-size.width/2, NSMidY(self.bounds)-size.height/2, size.width, size.height);
    [self.previewImage drawInRect:destination fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0 respectFlipped:YES hints:nil];
}

- (BOOL)hasConfigureSheet { return YES; }

- (NSWindow *)configureSheet {
    self.settingsSheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,520,190)
                                                    styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                                                      backing:NSBackingStoreBuffered defer:NO];
    self.settingsSheet.title = @"System 47 Options";
    self.settingsSheet.delegate = self;
    NSTextField *title = [NSTextField labelWithString:@"System 47 Full-Screen Saver"];
    title.font = [NSFont boldSystemFontOfSize:16]; title.frame = NSMakeRect(24,130,430,25);
    [self.settingsSheet.contentView addSubview:title];
    NSTextField *detail = [NSTextField wrappingLabelWithString:@"Idle time, sound, and per-monitor program dropdowns are managed in the System 47 settings panel."];
    detail.frame = NSMakeRect(24,76,470,48); [self.settingsSheet.contentView addSubview:detail];
    NSButton *open = [NSButton buttonWithTitle:@"Open System 47 Settings" target:self action:@selector(openSettings:)];
    open.frame = NSMakeRect(210,22,205,34); [self.settingsSheet.contentView addSubview:open];
    NSButton *done = [NSButton buttonWithTitle:@"Done" target:self action:@selector(closeSettings:)];
    done.frame = NSMakeRect(425,22,72,34); done.keyEquivalent = @"\r";
    [self.settingsSheet.contentView addSubview:done];
    return self.settingsSheet;
}

- (void)closeSettings:(id)sender {
    if (self.settingsSheet.sheetParent) [self.settingsSheet.sheetParent endSheet:self.settingsSheet];
    [self.settingsSheet orderOut:nil];
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
    [self closeSettings:sender];
    return NO;
}

- (void)openSettings:(id)sender {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSURL *appURL = [self companionApplicationURL];
    if (appURL) {
        [workspace openApplicationAtURL:appURL configuration:[NSWorkspaceOpenConfiguration configuration] completionHandler:nil];
    }
}
@end
