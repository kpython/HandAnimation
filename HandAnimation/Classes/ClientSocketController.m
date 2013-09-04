/**
 *  ClientSocketController.m
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 *  All rights reserved
 */

#import "ClientSocketController.h"
#import "FrameParser.h"
#import "Recorder.h"
#import "Player.h"

@implementation ClientSocketController{
    NSTimer* noServiceFoundTimer;
}


#define TIMEOUT_SERVICE_SEARCH 5.0
#define UDP_LOCAL_PORT 7777

- (id)init
{
    self = [super init];
    if (self){
        [self initializeUDPSocket];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeConnection:) name:@"closeConnection" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connect:) name:@"connect" object:nil];
    }
    return self;
}

#define SERVICE_TYPE @"_handTracking._tcp"
#define SERVICE_DOMAIN @"local."
- (void)browseBonjourServices
{
    NSLog(@"start browsing");
    // Start browsing for handTracking services
	netServiceBrowser = [[NSNetServiceBrowser alloc] init];
	[netServiceBrowser setDelegate:self];
	[netServiceBrowser searchForServicesOfType:SERVICE_TYPE inDomain:SERVICE_DOMAIN];
    [self showSearchingAlert];
    noServiceFoundTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_SERVICE_SEARCH
                                                           target:self
                                                         selector:@selector(noServiceFoundTimerFired)
                                                         userInfo:nil
                                                          repeats:NO];
}

- (void)showSearchingAlert{
    self.searchingServiceAlert = [[[UIAlertView alloc] initWithTitle:@"Searching for hand tracking services" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil] autorelease];
    [self.searchingServiceAlert show];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.center = CGPointMake(self.searchingServiceAlert.bounds.size.width / 2, self.searchingServiceAlert.bounds.size.height - 50);
    [indicator startAnimating];
    [self.searchingServiceAlert addSubview:indicator];
}

- (void)noServiceFoundTimerFired{
    [self dismissSearchingAlert];
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"No service found"
                                                      message:@"No handTracking service has been found on local network"
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];
    noServiceFoundTimer = nil;
}

- (void)dismissSearchingAlert{
    // Remove searching alert
    if (self.searchingServiceAlert != nil && [self.searchingServiceAlert isVisible]) {
        [self.searchingServiceAlert dismissWithClickedButtonIndex:0 animated:YES];
    }
}

- (void)dismissNoServiceFoundTimer{
    // Disable no service found alert
    if (noServiceFoundTimer != nil){
        if (noServiceFoundTimer.isValid) {
            [noServiceFoundTimer invalidate];
            noServiceFoundTimer = nil;
        }
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender didNotSearch:(NSDictionary *)errorInfo
{
	NSLog(@"DidNotSearch: %@", errorInfo);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender
           didFindService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	NSLog(@"DidFindService: %@", [netService name]);
	

    // Connect to the first service we find
    NSLog(@"Resolving...");
    serverService = netService;
    [serverService setDelegate:self];
    [serverService resolveWithTimeout:5.0];
    
    // Retaining serverService is mandatory for unknown reason
    [serverService retain];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)sender
         didRemoveService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	NSLog(@"DidRemoveService: %@", [netService name]);
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)sender
{
	NSLog(@"DidStopSearch");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	NSLog(@"DidNotResolve");
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	NSLog(@"DidResolve: %@", [sender addresses]);
    serverAddresses = [[sender addresses] mutableCopy];
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self connectToNextAddress];
}


// Note: GCDAsyncSocket automatically handles IPv4 & IPv6 transparently.
- (void)connectToNextAddress
{
	BOOL done = NO;
	
	while (!done && ([serverAddresses count] > 0))
        {
		NSData *addr;
		
		// Iterate forwards
        addr = [serverAddresses objectAtIndex:0];
        [serverAddresses removeObjectAtIndex:0];
		
		NSLog(@"Attempting connection to %@", addr);
		
		NSError *err = nil;
		if ([asyncSocket connectToAddress:addr error:&err])
        {
			done = YES;
        }
		else
        {
			NSLog(@"Unable to connect to %@", addr.description);
        }
    }
	
	if (!done)
    {
		NSLog(@"Unable to connect to any resolved address");
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    [self dismissNoServiceFoundTimer];
    [self dismissSearchingAlert];
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Connection successful"
                                                      message:[NSString stringWithFormat:@"Socket did connect to host: %@ Port: %hu", host, port]
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];
	connected = YES;
    
    // Read data until "\n" 
    [sock readDataToData:[GCDAsyncSocket LFData] withTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Disconnection"
                                                      message:[NSString stringWithFormat:@"Socket did disconnect with error: %@", err.localizedDescription]
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];
}

- (void)initializeUDPSocket
{
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    if (![udpSocket bindToPort:UDP_LOCAL_PORT error:&error]) {
        NSLog(@"%@",[error localizedDescription]);
        return;
    }
    
    if (![udpSocket beginReceiving:&error]){
        [udpSocket close];
        NSLog(@"%@",[error localizedDescription]);
        return;
    }
    NSLog(@"UDP Socket creation successfull");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    if (![[Player sharedInstance] isPlaying]){
        [[FrameParser sharedInstance] parseFrame:data];
    }
    
    if ([[Recorder sharedInstance] isRecording]) {
        [[Recorder sharedInstance] writeToDisk:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    }
}

//- (void)closeConnection:(NSNotification*)info{
//    NSLog(@"Connection closed");
//    [asyncSocket disconnect];
//}

- (void)connect:(NSNotification*)info{
    [self browseBonjourServices];
}


@end
