//
//  GPSAssistDataHandler.m
//  DSC-HX5V GPSAssist Update
//

#import "GPSAssistDataHandler.h"
#import <CommonCrypto/CommonDigest.h>

static const double GpsAssistDataValidTime=86400;	//24hours
#define GPSASSISTDATAURL @"http://control.d-imaging.sony.co.jp/GPS/assistme.dat"
#define GPSASSISTDATAMD5URL @"http://control.d-imaging.sony.co.jp/GPS/assistme.md5"

@interface GPSAssistDataHandler(Private)
-(void)showErrorWithText:(NSString*)error;
-(void)downloadGpsAssistData;
-(void)downloadFailed;
-(NSString*)md5:(NSData*)data;
@end


@implementation GPSAssistDataHandler

-(id)init{
	if(self=[super init]){
		delegates=[[NSMutableSet alloc]init];
		downloadStep=DOWNLOAD_IDLE;
	}
	return self;
}

-(void)dealloc{
	[delegates release];
	[gpsAssistData release];
	[downloadDate release];
	[urlConnection release];
	[receivedData release];
	[super dealloc];
}

-(void)stop{
	[urlConnection cancel];
}

-(void)showErrorWithText:(NSString*)error{
	NSAlert *alert=[[NSAlert alloc]init];
	[alert setMessageText:error];
	[alert addButtonWithTitle:@"Close"];
	[alert runModal];
	[alert release];
}

-(void)getGpsAssistData:(id<GPSAssistDataHandlerDelegate>)delegate{
	//Check if we already have data that is still valid
	if(gpsAssistData!=nil && [[NSDate date] timeIntervalSinceDate:downloadDate]<GpsAssistDataValidTime){
		//data still valid, return it
		[delegate gpsAssistDataAvailable:gpsAssistData date:downloadDate];
	}else{
		//Need to re-download the data
		if(![delegates containsObject:delegate]){
			[delegates addObject:delegate];
		}
		[self downloadGpsAssistData];
	}
}

-(void)cancelGetGpsAssistData:(id<GPSAssistDataHandlerDelegate>)delegate{
	[delegates removeObject:delegate];
}

-(void)downloadGpsAssistData{
	if(downloadStep==DOWNLOAD_IDLE){
		// create the request
		downloadStep=DOWNLOAD_DATA;
		NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:GPSASSISTDATAURL]
												  cachePolicy:NSURLRequestUseProtocolCachePolicy
											  timeoutInterval:60.0];
		// create the connection with the request
		// and start loading the data
		urlConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
		if (urlConnection) {
			// Create the NSMutableData that will hold
			// the received data
			// receivedData is declared as a method instance elsewhere
			receivedData=[[NSMutableData data] retain];
		} else {
			[self downloadFailed];
		}
	}else{
		//Already downloading, no need to start another download
		
	}
}

-(void)downloadFailed{
	//Inform all delegates
	for(id<GPSAssistDataHandlerDelegate> delegate in delegates){
		[delegate gpsAssistDataFailed];
	}
	[delegates removeAllObjects];
	downloadStep=DOWNLOAD_IDLE;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
	
    // it can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    // receivedData is declared as a method instance elsewhere
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    // release the connection, and the data object
	[urlConnection release];
	urlConnection=nil;
    // receivedData is declared as a method instance elsewhere
    [receivedData release];
	receivedData=nil;
	downloadStep=DOWNLOAD_IDLE;
	
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	[self downloadFailed];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    // receivedData is declared as a method instance elsewhere
	if(downloadStep==DOWNLOAD_DATA){
		gpsAssistData=[receivedData retain];
		//Release everything from previous step
		[urlConnection release];
		urlConnection=nil;
		[receivedData release];
		receivedData=nil;
		
		//Now download the md5
		downloadStep=DOWNLOAD_MD5;
		NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:GPSASSISTDATAMD5URL]
												  cachePolicy:NSURLRequestUseProtocolCachePolicy
											  timeoutInterval:60.0];
		// create the connection with the request
		// and start loading the data
		urlConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
		if (urlConnection) {
			// Create the NSMutableData that will hold
			// the received data
			// receivedData is declared as a method instance elsewhere
			receivedData=[[NSMutableData data] retain];
		} else {
			downloadStep=DOWNLOAD_IDLE;
		}
	}else{
		//Must be download of MD5. The receivedData holds the md5 file now
		NSString *dataMD5 = [self md5:gpsAssistData];
		NSString *fullDownloadMD5 = [[[NSString alloc]initWithBytes:[receivedData bytes] length:[receivedData length] encoding:NSASCIIStringEncoding]autorelease];
		NSString *downloadMD5 = nil;
		if([fullDownloadMD5 length]>2*CC_MD5_DIGEST_LENGTH){
			downloadMD5=[fullDownloadMD5 substringToIndex:2*CC_MD5_DIGEST_LENGTH];
		}else if([fullDownloadMD5 length]==2*CC_MD5_DIGEST_LENGTH){
			downloadMD5=[NSString stringWithString:fullDownloadMD5];
		}else{
			[self downloadFailed];
		}
		if([dataMD5 isEqualToString:downloadMD5]){
			//Ok, gpsAssistData is updated. Inform delegates
			[downloadDate release];
			downloadDate=[[NSDate date]retain];
			for(id<GPSAssistDataHandlerDelegate> delegate in delegates){
				[delegate gpsAssistDataAvailable:gpsAssistData date:downloadDate];
			}
			[delegates removeAllObjects];
		}else{
			[self downloadFailed];
		}
		[urlConnection release];
		urlConnection=nil;
		[receivedData release];
		receivedData=nil;
		downloadStep=DOWNLOAD_IDLE;
	}
	
}

-(NSString*) md5:(NSData*)srcData{
	const void *data = [srcData bytes];
	
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	
	CC_MD5( data, [srcData length], result );
	
	return [NSString 
			stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1],
			result[2], result[3],
			result[4], result[5],
			result[6], result[7],
			result[8], result[9],
			result[10], result[11],
			result[12], result[13],
			result[14], result[15]
			];
}

@end
