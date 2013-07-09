//
//  ServerUDPSocketController.m
//  HandAnimation
//
//  Created by Kevin Python on 01.07.13.
//
//

#import "ServerUDPSocketController.h"
#import "GCDAsyncUdpSocket.h"



@implementation ServerUDPSocketController

GCDAsyncUdpSocket *udpSocket;


#define UDP_LOCAL_PORT 7777


- (void)logError:(NSString *)msg
{
    NSLog(@"ERROR : %@",msg);
}

- (void)logInfo:(NSString *)msg
{
    NSLog(@"%@",msg);
}

- (void)logMessage:(NSString *)msg
{
//    NSDate *date = [NSDate date];
//    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
//    [formater setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
}

-(id) initWithDelegate:(id<UpdateHandModel>)delegate
{
    self = [super init];
    if (self != nil)
    {
        self.delegate = delegate;
        [self initializeUDPSocket];
    }
    return self;
}

- (void)initializeUDPSocket
{
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    if (![udpSocket bindToPort:UDP_LOCAL_PORT error:&error]) {
        [self logError:[error localizedDescription]];
        return;
    }
    
    if (![udpSocket beginReceiving:&error]){
        [udpSocket close];
        [self logError:[error localizedDescription]];
        return;
    }
    NSLog(@"Socket creation successfull");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    // Print received frame
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg){
        NSString *host = nil;
        uint16_t port = 0;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
        [self logMessage:msg];
    } else
    {
        [self logError:@"Error converting received data into UTF-8 String"];
    }
    
    
    // Parse received frame
    NSError* error = nil;
    
    if (data) {
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                             options:kNilOptions
                                                               error:&error];
        
        int frameID = [[json objectForKey:@"FrameID"] integerValue];
        int timeStamp = [[json objectForKey:@"timestamp"] integerValue];
        
        
        NSArray* hands = [json objectForKey:@"hands"];
        
        NSDictionary* palmInfo = [hands objectAtIndex:0];
        
        NSArray* palmPosition = [palmInfo objectForKey:@"palmPosition"];
        NSArray* palmRotation = [palmInfo objectForKey:@"palmRotation"];
        NSArray* fingersFlexion = [palmInfo objectForKey:@"fingersFlexion"];     
        
        [self udpateHandPosition:palmPosition];
        [self udpateHandRotation:palmRotation];
        [self updateFingersFlexion:fingersFlexion];
                
        
    } else {
        // Handle Error
    }
}

-(void)udpateHandPosition:(NSArray*)palmPosition
{
    if ([self.delegate respondsToSelector:@selector(setHandLocation:)]){
        float xLoc = [[palmPosition objectAtIndex:0] floatValue];
        float yLoc = [[palmPosition objectAtIndex:1] floatValue];
        float zLoc = [[palmPosition objectAtIndex:2] floatValue];
        CC3Vector handLocation = cc3v(xLoc/25.0,yLoc/25.0,zLoc/25.0);
        [self.delegate setHandLocation:handLocation];
    }
}

-(void)udpateHandRotation:(NSArray*)palmRotation
{
    if ([self.delegate respondsToSelector:@selector(setHandRotation:)]){
        float xRot = [[palmRotation objectAtIndex:0] floatValue];
        float yRot = [[palmRotation objectAtIndex:1] floatValue];
        float zRot = [[palmRotation objectAtIndex:2] floatValue];
        // Y axis is modified due to different convention of axis rotation
        CC3Vector handRotation = cc3v(xRot,-yRot,zRot);
        [self.delegate setHandRotation:handRotation];
    }
}

-(void)updateFingersFlexion:(NSArray*)fingersFlexion{
    if ([self.delegate respondsToSelector:@selector(setFingerFlexion:withFactor:)]){
        float thumbFlexion = [[fingersFlexion objectAtIndex:0] floatValue];
        float indexFlexion = [[fingersFlexion objectAtIndex:1] floatValue];
        float middleFlexion = [[fingersFlexion objectAtIndex:2] floatValue];
        float ringFlexion = [[fingersFlexion objectAtIndex:3] floatValue];
        float pinkyFlexion = [[fingersFlexion objectAtIndex:4] floatValue];
        
        [self.delegate setFingerFlexion:FINGER_THUMB withFactor:thumbFlexion];
        [self.delegate setFingerFlexion:FINGER_INDEX withFactor:indexFlexion];
        [self.delegate setFingerFlexion:FINGER_MIDDLE withFactor:middleFlexion];
        [self.delegate setFingerFlexion:FINGER_RING withFactor:ringFlexion];
        [self.delegate setFingerFlexion:FINGER_PINKY withFactor:pinkyFlexion];
    }
}

@end