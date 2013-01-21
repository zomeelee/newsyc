//
//  HNAPISearch.m
//  newsyc
//
//  Created by Quin Hoxie on 6/2/11.
//

#import "HNAPISearch.h"
#import "HNKit.h"

@class HNEntry;

@interface HNAPISearch () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@end

@implementation HNAPISearch

@synthesize entries;
@synthesize responseData;
@synthesize searchType;
@synthesize session;

- (id)initWithSession:(HNSession *)session_ {
	if (self = [super init]) {
        session = session_;
		[self setSearchType:kHNSearchTypeInteresting];
	}
    
	return self;
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (responseData == nil) {
		responseData = [[NSMutableData alloc] init];
	}
    
	[responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [connection release];
	[responseData release];
	responseData = nil;
    
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"searchDone" object:nil userInfo:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [connection release];

	[self handleResponse];
}

- (void)handleResponse {
	self.entries = [NSMutableArray array];

    NSArray *rawResults = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:NULL];
    
	for (NSDictionary *result in rawResults) {
		NSDictionary *item = [self itemFromRaw:[result objectForKey:@"item"]];
		HNEntry *entry = [HNEntry session:session entryWithIdentifier:[item objectForKey:@"identifier"]];

        [entry loadFromDictionary:item complete:NO];
		[entries addObject:entry];
	}
    
    [responseData release];
	responseData = nil;

	NSDictionary *dictToBePassed = [NSDictionary dictionaryWithObject:entries forKey:@"array"];
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"searchDone" object:nil userInfo:dictToBePassed];	
}

- (NSDictionary *)itemFromRaw:(NSDictionary *)rawDictionary {
	NSMutableDictionary *item = [NSMutableDictionary dictionary];
	NSNumber *points = nil;
    NSNumber *comments = nil;
	NSString *title = nil;
    NSString *user = nil;
    NSNumber *identifier = nil;
    NSString *body = nil;
    NSString *date = nil;
    NSString *url = nil;

	points = [rawDictionary valueForKey:@"points"];
	comments = [rawDictionary valueForKey:@"num_comments"];
	title = [rawDictionary valueForKey:@"title"];
	user = [rawDictionary valueForKey:@"username"];
	identifier = [rawDictionary valueForKey:@"id"];
	body = [rawDictionary valueForKey:@"text"];
	date = [rawDictionary valueForKey:@"create_ts"];
	url = [rawDictionary valueForKey:@"url"];

	if ((NSNull *)user != [NSNull null]) [item setObject:user forKey:@"user"];
	if ((NSNull *)points != [NSNull null]) [item setObject:points forKey:@"points"];
	if ((NSNull *)title != [NSNull null]) [item setObject:title forKey:@"title"];
	if ((NSNull *)comments != [NSNull null]) [item setObject:comments forKey:@"numchildren"];
	if ((NSNull *)url != [NSNull null]) [item setObject:url forKey:@"url"];
	if ((NSNull *)date != [NSNull null]) [item setObject:date forKey:@"date"];
	if ((NSNull *)body != [NSNull null]) [item setObject:body forKey:@"body"];
	if ((NSNull *)identifier != [NSNull null]) [item setObject:identifier forKey:@"identifier"];
	return item;
}

- (void)performSearch:(NSString *)searchQuery {
	NSString *paramsString = nil;
	NSString *encodedQuery = [searchQuery stringByURLEncodingString];
	if (searchType == kHNSearchTypeInteresting) {
		paramsString = [NSString stringWithFormat:kHNSearchParamsInteresting, encodedQuery];
	} else {
		paramsString = [NSString stringWithFormat:kHNSearchParamsRecent, encodedQuery];
	}

	NSString *urlString = [NSString stringWithFormat:kHNSearchBaseURL, paramsString];
	NSURL *url = [NSURL URLWithString:urlString];

	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
	[request release];

	searchQuery = nil;
}

- (void)dealloc {
    [responseData release];
    [entries release];

    [super dealloc];
}

@end
