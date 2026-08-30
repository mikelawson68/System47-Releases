#import <ScreenSaver/ScreenSaver.h>
#import <AVFoundation/AVFoundation.h>
#import <WebKit/WebKit.h>
#import <Network/Network.h>
#import <objc/message.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>

@interface System47SchemeHandler : NSObject <WKURLSchemeHandler>
@end

@implementation System47SchemeHandler
- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)task {
    NSString *path = task.request.URL.path;
    if ([path hasPrefix:@"/"]) path = [path substringFromIndex:1];
    if (!path.length) path = @"index.html";
    NSURL *fileURL = [[NSBundle bundleForClass:NSClassFromString(@"System47ModernScreenSaverView")].resourceURL URLByAppendingPathComponent:path];
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    if (!data) {
        [task didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil]];
        return;
    }
    NSString *ext = fileURL.pathExtension.lowercaseString;
    NSDictionary *types = @{@"html": @"text/html", @"js": @"text/javascript", @"wasm": @"application/wasm", @"swf": @"application/x-shockwave-flash", @"css": @"text/css"};
    NSString *mime = types[ext] ?: @"application/octet-stream";
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:task.request.URL MIMEType:mime expectedContentLength:data.length textEncodingName:[ext isEqualToString:@"html"] || [ext isEqualToString:@"js"] ? @"utf-8" : nil];
    [task didReceiveResponse:response];
    [task didReceiveData:data];
    [task didFinish];
}
- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)task {}
@end

@interface System47ModernScreenSaverView : ScreenSaverView <AVAudioPlayerDelegate, WKNavigationDelegate>
@property(nonatomic, strong) AVAudioPlayer *audioPlayer;
@property(nonatomic, strong) NSTimer *soundTimer;
@property(nonatomic, strong) NSTimer *sceneTimer;
@property(nonatomic, strong) NSImage *sceneImage;
@property(nonatomic, strong) CALayer *sceneLayer;
@property(nonatomic, strong) CALayer *scanlineLayer;
@property(nonatomic, strong) NSWindow *settingsWindow;
@property(nonatomic, strong) NSMutableArray<NSDictionary *> *monitorControls;
@property(nonatomic, strong) NSPopUpButton *intervalControl;
@property(nonatomic, strong) NSPopUpButton *scaleControl;
@property(nonatomic, strong) NSButton *audioControl;
@property(nonatomic) NSInteger assignedDisplay;
@property(nonatomic) NSInteger currentScene;
@property(nonatomic) BOOL fillScreen;
@property(nonatomic) BOOL animationRunning;
@property(nonatomic) BOOL snapshotPending;
@property(nonatomic) CGFloat scanPhase;
@property(nonatomic) CGFloat pulsePhase;
@property(nonatomic, strong) WKWebView *webView;
@property(nonatomic, strong) System47SchemeHandler *schemeHandler;
@property(nonatomic, strong) nw_listener_t localServer;
@property(nonatomic) uint16_t localServerPort;
@property(nonatomic) int localServerSocket;
@end

@implementation System47ModernScreenSaverView

static __weak System47ModernScreenSaverView *System47AudioOwner;

static NSArray<NSString *> *System47Scenes(void) {
    return @[@"Star System", @"Sector Volume", @"Nav. Readings", @"NCC-1701-E",
             @"Zoom Scan", @"Sector Grid", @"Galaxy Quad. Map", @"Warp Speed"];
}

static NSArray<NSString *> *System47Sounds(void) {
    return @[@"2", @"9", @"10", @"11", @"12", @"13", @"77", @"98",
             @"137", @"138", @"139", @"232", @"242", @"247", @"322",
             @"349", @"376", @"455", @"456"];
}

static NSString * const System47Module = @"com.mewho.system47.screensaver";

static NSTextField *System47Label(NSString *text, NSRect frame, BOOL bold) {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.stringValue = text;
    label.editable = NO;
    label.selectable = NO;
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.font = bold ? [NSFont boldSystemFontOfSize:13.0] : [NSFont systemFontOfSize:13.0];
    return label;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        self.animationTimeInterval = 1.0 / 30.0;
        self.wantsLayer = YES;
        self.layer.backgroundColor = NSColor.blackColor.CGColor;
        self.schemeHandler = [[System47SchemeHandler alloc] init];
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        SEL softwareCompositing = NSSelectorFromString(@"_setAcceleratedCompositingEnabled:");
        if ([configuration.preferences respondsToSelector:softwareCompositing]) {
            ((void (*)(id, SEL, BOOL))objc_msgSend)(configuration.preferences, softwareCompositing, NO);
        }
        [configuration.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
        [configuration setURLSchemeHandler:self.schemeHandler forURLScheme:@"system47"];
        self.webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
        self.webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.webView.navigationDelegate = self;
        self.webView.wantsLayer = YES;
        self.webView.layer.backgroundColor = NSColor.blackColor.CGColor;
        [self addSubview:self.webView];
        self.sceneLayer = [CALayer layer];
        self.sceneLayer.frame = self.bounds;
        self.sceneLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        self.sceneLayer.contentsGravity = kCAGravityResize;
        self.sceneLayer.backgroundColor = NSColor.blackColor.CGColor;
        self.sceneLayer.magnificationFilter = kCAFilterLinear;
        self.sceneLayer.hidden = YES;
        [self.layer addSublayer:self.sceneLayer];

        self.scanlineLayer = [CALayer layer];
        self.scanlineLayer.backgroundColor = [NSColor colorWithCalibratedRed:0.35 green:0.72 blue:1.0 alpha:0.14].CGColor;
        self.scanlineLayer.hidden = YES;
        [self.layer addSublayer:self.scanlineLayer];
    }
    return self;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [webView evaluateJavaScript:@"({ready:document.readyState,ruffle:typeof window.RufflePlayer,body:document.body.innerText,html:document.body.innerHTML.slice(0,300)})" completionHandler:^(id result, NSError *error) {
        NSLog(@"SYSTEM47_WEB_READY=%@ ERROR=%@", result, error);
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [webView evaluateJavaScript:@"(()=>{const p=document.querySelector('ruffle-player'); return {player:!!p,stage:document.getElementById('stage').children.length,pageError:document.documentElement.dataset.system47Error||'',shadowText:p&&p.shadowRoot?p.shadowRoot.innerText:'',shadow:p&&p.shadowRoot?p.shadowRoot.innerHTML.slice(-1600):'',isPlaying:p?p.isPlaying:null};})()" completionHandler:^(id result, NSError *error) {
            NSLog(@"SYSTEM47_PLAYER_STATE=%@ ERROR=%@", result, error);
        }];
    });
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"SYSTEM47_WEB_FAILED=%@", error);
}

- (NSInteger)displayIndex {
    if (self.isPreview) return 0;
    NSScreen *active = self.window.screen;
    NSUInteger index = [NSScreen.screens indexOfObjectIdenticalTo:active];
    return index == NSNotFound ? 0 : (NSInteger)index;
}

- (NSString *)displayIdentifierForScreen:(NSScreen *)screen fallback:(NSInteger)fallback {
    NSNumber *number = screen.deviceDescription[@"NSScreenNumber"];
    return number ? number.stringValue : [NSString stringWithFormat:@"index-%ld", (long)fallback];
}

- (NSScreen *)activeScreen {
    if (self.window.screen) return self.window.screen;
    NSArray<NSScreen *> *screens = NSScreen.screens;
    return screens.count ? screens[MIN((NSUInteger)MAX(self.assignedDisplay, 0), screens.count - 1)] : nil;
}

- (ScreenSaverDefaults *)system47Defaults {
    return [ScreenSaverDefaults defaultsForModuleWithName:System47Module];
}

- (void)startLocalServer:(void (^)(void))completion {
    if (self.localServerSocket > 0 && self.localServerPort) { completion(); return; }
    int server = socket(AF_INET6, SOCK_STREAM, 0);
    int yes = 1;
    setsockopt(server, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
    setsockopt(server, SOL_SOCKET, SO_NOSIGPIPE, &yes, sizeof(yes));
    struct sockaddr_in6 address = {0};
    address.sin6_len = sizeof(address);
    address.sin6_family = AF_INET6;
    address.sin6_addr = in6addr_loopback;
    address.sin6_port = 0;
    if (server < 0 || bind(server, (struct sockaddr *)&address, sizeof(address)) != 0 || listen(server, 16) != 0) {
        if (server >= 0) close(server);
        NSLog(@"SYSTEM47_SERVER_FAILED errno=%d", errno);
        return;
    }
    socklen_t addressLength = sizeof(address);
    getsockname(server, (struct sockaddr *)&address, &addressLength);
    self.localServerSocket = server;
    self.localServerPort = ntohs(address.sin6_port);
    NSBundle *resourceBundle = [NSBundle bundleForClass:self.class];
    dispatch_queue_t queue = dispatch_queue_create("com.mewho.system47.local-server", DISPATCH_QUEUE_SERIAL);
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^{
        while (weakSelf && weakSelf.localServerSocket == server) {
            int client = accept(server, NULL, NULL);
            if (client < 0) break;
            setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &yes, sizeof(yes));
            char requestBytes[16384] = {0};
            ssize_t requestLength = recv(client, requestBytes, sizeof(requestBytes) - 1, 0);
            NSString *request = requestLength > 0 ? [[NSString alloc] initWithBytes:requestBytes length:(NSUInteger)requestLength encoding:NSUTF8StringEncoding] : @"";
            NSString *firstLine = [request componentsSeparatedByString:@"\r\n"].firstObject ?: @"";
            NSArray *parts = [firstLine componentsSeparatedByString:@" "];
            NSString *path = parts.count > 1 ? parts[1] : @"/index.html";
            path = [path componentsSeparatedByString:@"?"].firstObject;
            path = [path stringByRemovingPercentEncoding] ?: path;
            if ([path hasPrefix:@"/"]) path = [path substringFromIndex:1];
            if (!path.length) path = @"index.html";
            NSURL *fileURL = [resourceBundle.resourceURL URLByAppendingPathComponent:path];
            NSData *body = [NSData dataWithContentsOfURL:fileURL];
            NSString *ext = fileURL.pathExtension.lowercaseString;
            NSDictionary *types = @{@"html": @"text/html; charset=utf-8", @"js": @"text/javascript; charset=utf-8", @"wasm": @"application/wasm", @"swf": @"application/x-shockwave-flash", @"map": @"application/json"};
            NSString *status = body ? @"200 OK" : @"404 Not Found";
            if (!body) body = [@"Not Found" dataUsingEncoding:NSUTF8StringEncoding];
            NSString *header = [NSString stringWithFormat:@"HTTP/1.1 %@\r\nContent-Type: %@\r\nContent-Length: %lu\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n", status, types[ext] ?: @"application/octet-stream", (unsigned long)body.length];
            NSMutableData *response = [[header dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
            [response appendData:body];
            const uint8_t *bytes = response.bytes;
            NSUInteger remaining = response.length;
            while (remaining) {
                ssize_t sent = send(client, bytes, remaining, 0);
                if (sent <= 0) break;
                bytes += sent;
                remaining -= (NSUInteger)sent;
            }
            close(client);
        }
    });
    dispatch_async(dispatch_get_main_queue(), completion);
}

- (void)startAnimation {
    [self teardownPlayback];
    [super startAnimation];
    self.animationRunning = YES;
    self.assignedDisplay = [self displayIndex];
    ScreenSaverDefaults *programDefaults = [self system47Defaults];
    NSString *programIdentifier = [self displayIdentifierForScreen:[self activeScreen] fallback:self.assignedDisplay];
    NSString *programKey = [@"scene." stringByAppendingString:programIdentifier];
    NSString *lockKey = [@"rotate." stringByAppendingString:programIdentifier];
    NSInteger selectedProgram = [programDefaults objectForKey:programKey] ? [programDefaults integerForKey:programKey] : self.assignedDisplay % 8;
    BOOL followsOriginalCycle = [programDefaults objectForKey:lockKey] ? [programDefaults boolForKey:lockKey] : YES;
    BOOL audioEnabledForProgram = [programDefaults objectForKey:@"audioEnabled"] ? [programDefaults boolForKey:@"audioEnabled"] : YES;
    BOOL muted = self.assignedDisplay != 0 || !audioEnabledForProgram;
    [self startLocalServer:^{
        if (!self.animationRunning) return;
        NSURL *programURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://[::1]:%u/index.html?display=%ld&program=%ld&lock=%d&muted=%d", self.localServerPort, (long)self.assignedDisplay, (long)((selectedProgram % 8) + 1), followsOriginalCycle ? 0 : 1, muted ? 1 : 0]];
        [self.webView loadRequest:[NSURLRequest requestWithURL:programURL]];
        NSString *assignment = [NSString stringWithFormat:@"window.setDisplayAssignment(%ld,%ld); window.startSystem47();", (long)self.assignedDisplay, (long)MAX((NSInteger)NSScreen.screens.count, 1)];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (self.animationRunning) [self.webView evaluateJavaScript:assignment completionHandler:nil];
        });
    }];
    return;
    ScreenSaverDefaults *defaults = [self system47Defaults];
    NSString *identifier = [self displayIdentifierForScreen:[self activeScreen] fallback:self.assignedDisplay];
    NSString *sceneKey = [@"scene." stringByAppendingString:identifier];
    NSString *rotateKey = [@"rotate." stringByAppendingString:identifier];
    self.currentScene = [defaults objectForKey:sceneKey] ? [defaults integerForKey:sceneKey]
                                                       : self.assignedDisplay % System47Scenes().count;
    BOOL rotates = [defaults objectForKey:rotateKey] ? [defaults boolForKey:rotateKey] : YES;
    self.fillScreen = [defaults boolForKey:@"fillScreen"];
    [self startAssignedScene];
    if (rotates) {
        NSTimeInterval interval = [defaults doubleForKey:@"rotationInterval"];
        if (interval < 5.0) interval = 28.0;
        self.sceneTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self
            selector:@selector(advanceScene:) userInfo:nil repeats:YES];
    }
    BOOL audioEnabled = [defaults objectForKey:@"audioEnabled"] ? [defaults boolForKey:@"audioEnabled"] : YES;
    if (self.assignedDisplay == 0 && audioEnabled) {
        if (System47AudioOwner && System47AudioOwner != self) [System47AudioOwner teardownAudio];
        System47AudioOwner = self;
        [self scheduleNextSoundAfter:1.0];
    }
}

- (void)startAssignedScene {
    NSArray<NSString *> *scenes = System47Scenes();
    NSString *scene = scenes[(NSUInteger)self.currentScene % scenes.count];
    NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:scene withExtension:@"png"];
    self.sceneImage = url ? [[NSImage alloc] initWithContentsOfURL:url] : nil;
    NSRect proposed = NSMakeRect(0, 0, self.sceneImage.size.width, self.sceneImage.size.height);
    CGImageRef image = [self.sceneImage CGImageForProposedRect:&proposed context:nil hints:nil];
    self.sceneLayer.contents = image ? (__bridge id)image : nil;
    [self layoutSceneLayers];
}

- (void)layoutSceneLayers {
    CGFloat sourceWidth = MAX(self.sceneImage.size.width, 4.0);
    CGFloat sourceHeight = MAX(self.sceneImage.size.height, 3.0);
    CGFloat widthScale = NSWidth(self.bounds) / sourceWidth;
    CGFloat heightScale = NSHeight(self.bounds) / sourceHeight;
    CGFloat scale = self.fillScreen ? MAX(widthScale, heightScale) : MIN(widthScale, heightScale);
    NSSize size = NSMakeSize(sourceWidth * scale, sourceHeight * scale);
    NSRect stage = NSMakeRect(NSMidX(self.bounds) - size.width / 2.0,
                              NSMidY(self.bounds) - size.height / 2.0,
                              size.width, size.height);
    self.sceneLayer.frame = stage;
    CGFloat y = NSMinY(stage) + self.scanPhase * NSHeight(stage);
    self.scanlineLayer.frame = NSMakeRect(NSMinX(stage), y, NSWidth(stage), MAX(1.0, scale));
}

- (void)advanceScene:(NSTimer *)timer {
    self.currentScene = (self.currentScene + 1) % System47Scenes().count;
    [self startAssignedScene];
}

- (void)scheduleNextSoundAfter:(NSTimeInterval)delay {
    if (!self.animationRunning || System47AudioOwner != self) return;
    [self.soundTimer invalidate];
    self.soundTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self
        selector:@selector(playRandomSound:) userInfo:nil repeats:NO];
}

- (void)playRandomSound:(NSTimer *)timer {
    if (!self.animationRunning || System47AudioOwner != self) return;
    NSArray<NSString *> *sounds = System47Sounds();
    NSString *name = sounds[arc4random_uniform((uint32_t)sounds.count)];
    NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:name withExtension:@"mp3"];
    if (url) {
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        self.audioPlayer.delegate = self;
        self.audioPlayer.volume = 0.48;
        [self.audioPlayer play];
    }
    [self scheduleNextSoundAfter:3.0 + arc4random_uniform(6)];
}

- (void)teardownAudio {
    [self.soundTimer invalidate];
    self.soundTimer = nil;
    [self.audioPlayer stop];
    self.audioPlayer.delegate = nil;
    self.audioPlayer = nil;
    if (System47AudioOwner == self) System47AudioOwner = nil;
}

- (void)teardownPlayback {
    self.animationRunning = NO;
    [self.webView evaluateJavaScript:@"window.stopSystem47 && window.stopSystem47(); document.querySelectorAll('audio,video').forEach(e => { e.pause(); e.src=''; });" completionHandler:nil];
    [self.webView stopLoading];
    [self teardownAudio];
    [self.sceneTimer invalidate];
    self.sceneTimer = nil;
    self.sceneImage = nil;
}

- (void)stopAnimation {
    [self teardownPlayback];
    [super stopAnimation];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    if (!newWindow) [self teardownPlayback];
    [super viewWillMoveToWindow:newWindow];
}

- (void)removeFromSuperview {
    [self teardownPlayback];
    [super removeFromSuperview];
}

- (void)dealloc {
    [self teardownPlayback];
    if (self.localServer) nw_listener_cancel(self.localServer);
    if (self.localServerSocket > 0) close(self.localServerSocket);
}

- (void)animateOneFrame {
    if (self.webView) {
        if (!self.animationRunning || self.snapshotPending) return;
        self.snapshotPending = YES;
        WKSnapshotConfiguration *configuration = [[WKSnapshotConfiguration alloc] init];
        configuration.rect = self.webView.bounds;
        configuration.snapshotWidth = @(MAX(NSWidth(self.bounds), 1.0));
        __weak typeof(self) weakSelf = self;
        [self.webView takeSnapshotWithConfiguration:configuration completionHandler:^(NSImage *image, NSError *error) {
            weakSelf.snapshotPending = NO;
            if (!weakSelf.animationRunning || !image || error) return;
            NSRect proposed = NSMakeRect(0, 0, image.size.width, image.size.height);
            CGImageRef frame = [image CGImageForProposedRect:&proposed context:nil hints:nil];
            if (!frame) return;
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            weakSelf.sceneLayer.frame = weakSelf.bounds;
            weakSelf.sceneLayer.contentsGravity = kCAGravityResize;
            weakSelf.sceneLayer.contents = (__bridge id)frame;
            weakSelf.sceneLayer.hidden = NO;
            [CATransaction commit];
        }];
        return;
    }
    self.scanPhase = fmod(self.scanPhase + 0.0028, 1.0);
    self.pulsePhase = fmod(self.pulsePhase + 0.035, (CGFloat)(M_PI * 2.0));
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.sceneLayer.opacity = 0.97 + 0.03 * sin(self.pulsePhase);
    [self layoutSceneLayers];
    [CATransaction commit];
}

- (BOOL)hasConfigureSheet { return YES; }

- (NSWindow *)configureSheet {
    NSArray<NSScreen *> *screens = NSScreen.screens;
    CGFloat height = 245.0 + MAX((NSInteger)screens.count, 1) * 38.0;
    self.settingsWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 690, height)
        styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
        backing:NSBackingStoreBuffered defer:NO];
    self.settingsWindow.title = @"System 47 Settings";
    NSView *content = self.settingsWindow.contentView;
    self.monitorControls = [NSMutableArray array];
    ScreenSaverDefaults *defaults = [self system47Defaults];

    CGFloat y = height - 46.0;
    [content addSubview:System47Label(@"Display", NSMakeRect(24, y, 225, 22), YES)];
    [content addSubview:System47Label(@"Starting display program", NSMakeRect(260, y, 185, 22), YES)];
    [content addSubview:System47Label(@"Behavior", NSMakeRect(465, y, 175, 22), YES)];
    y -= 35.0;

    NSInteger index = 0;
    for (NSScreen *screen in screens) {
        NSString *identifier = [self displayIdentifierForScreen:screen fallback:index];
        NSString *name = screen.localizedName.length ? screen.localizedName : [NSString stringWithFormat:@"Display %ld", (long)index + 1];
        [content addSubview:System47Label([NSString stringWithFormat:@"%ld. %@", (long)index + 1, name], NSMakeRect(24, y + 3, 225, 22), NO)];

        NSPopUpButton *scene = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(260, y, 180, 28) pullsDown:NO];
        [scene addItemsWithTitles:System47Scenes()];
        NSString *sceneKey = [@"scene." stringByAppendingString:identifier];
        NSInteger selected = [defaults objectForKey:sceneKey] ? [defaults integerForKey:sceneKey] : index % 8;
        [scene selectItemAtIndex:MAX(0, MIN(selected, 7))];
        [content addSubview:scene];

        NSPopUpButton *behavior = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(465, y, 175, 28) pullsDown:NO];
        [behavior addItemsWithTitles:@[@"Follow original cycle", @"Keep this program"]];
        NSString *rotateKey = [@"rotate." stringByAppendingString:identifier];
        BOOL rotates = [defaults objectForKey:rotateKey] ? [defaults boolForKey:rotateKey] : YES;
        [behavior selectItemAtIndex:rotates ? 0 : 1];
        [content addSubview:behavior];
        [self.monitorControls addObject:@{@"id": identifier, @"scene": scene, @"behavior": behavior}];
        y -= 38.0;
        index++;
    }

    NSBox *line = [[NSBox alloc] initWithFrame:NSMakeRect(24, y - 3, 642, 1)];
    line.boxType = NSBoxSeparator;
    [content addSubview:line];
    y -= 43.0;
    [content addSubview:System47Label(@"Program timing", NSMakeRect(24, y + 3, 130, 22), NO)];
    self.intervalControl = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(155, y, 125, 28) pullsDown:NO];
    NSMenuItem *timingItem = [[NSMenuItem alloc] initWithTitle:@"Original SWF timing" action:nil keyEquivalent:@""];
    timingItem.representedObject = @0;
    [self.intervalControl.menu addItem:timingItem];
    self.intervalControl.enabled = NO;
    [content addSubview:self.intervalControl];

    [content addSubview:System47Label(@"Display scaling", NSMakeRect(310, y + 3, 115, 22), NO)];
    self.scaleControl = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(425, y, 215, 28) pullsDown:NO];
    [self.scaleControl addItemsWithTitles:@[@"Fit — preserve original proportions"]];
    self.scaleControl.enabled = NO;
    [content addSubview:self.scaleControl];
    y -= 39.0;

    self.audioControl = [NSButton checkboxWithTitle:@"Play original System 47 sounds on the primary display only"
        target:nil action:nil];
    self.audioControl.frame = NSMakeRect(24, y, 500, 24);
    self.audioControl.state = (![defaults objectForKey:@"audioEnabled"] || [defaults boolForKey:@"audioEnabled"]) ? NSControlStateValueOn : NSControlStateValueOff;
    [content addSubview:self.audioControl];

    NSButton *cancel = [NSButton buttonWithTitle:@"Cancel" target:self action:@selector(cancelSettings:)];
    cancel.frame = NSMakeRect(476, 18, 90, 32);
    cancel.keyEquivalent = @"\e";
    [content addSubview:cancel];
    NSButton *save = [NSButton buttonWithTitle:@"Save" target:self action:@selector(saveSettings:)];
    save.frame = NSMakeRect(576, 18, 90, 32);
    save.keyEquivalent = @"\r";
    [content addSubview:save];
    return self.settingsWindow;
}

- (void)saveSettings:(id)sender {
    ScreenSaverDefaults *defaults = [self system47Defaults];
    for (NSDictionary *row in self.monitorControls) {
        NSString *identifier = row[@"id"];
        NSPopUpButton *scene = row[@"scene"];
        NSPopUpButton *behavior = row[@"behavior"];
        [defaults setInteger:scene.indexOfSelectedItem forKey:[@"scene." stringByAppendingString:identifier]];
        [defaults setBool:(behavior.indexOfSelectedItem == 0) forKey:[@"rotate." stringByAppendingString:identifier]];
    }
    NSNumber *interval = self.intervalControl.selectedItem.representedObject;
    [defaults setInteger:interval.integerValue forKey:@"rotationInterval"];
    [defaults setBool:(self.scaleControl.indexOfSelectedItem == 1) forKey:@"fillScreen"];
    [defaults setBool:(self.audioControl.state == NSControlStateValueOn) forKey:@"audioEnabled"];
    [defaults synchronize];
    [NSApp endSheet:self.settingsWindow returnCode:NSModalResponseOK];
}

- (void)cancelSettings:(id)sender {
    [NSApp endSheet:self.settingsWindow returnCode:NSModalResponseCancel];
}

@end
