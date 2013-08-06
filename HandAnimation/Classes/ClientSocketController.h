/**
 *  ClientSocketController.h
 *  HandAnimation
 *
 *  Created by Kevin Python on 14.06.13.
 *  Copyright 2013 College of Engineering and Architecture of Fribourg & Norhteastern University, Boston
 *  All rights reserved
 */

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "GCDAsyncUdpSocket.h"

@interface ClientSocketController : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate>
{
    NSNetServiceBrowser *netServiceBrowser;
	NSNetService *serverService;
	NSMutableArray *serverAddresses;
	GCDAsyncSocket *asyncSocket;
    GCDAsyncUdpSocket *udpSocket;
	BOOL connected;
}

@property (nonatomic,retain) UIAlertView* searchingServiceAlert;

- (void)browseBonjourServices;

@end
