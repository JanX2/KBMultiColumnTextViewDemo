//
//  MyDocument.m
//  MultiColumnTextExample
//
//  Created by Keith Blount on 07/06/2006.
//  Copyright __MyCompanyName__ 2006 . All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

- (id)init
{
	if (self = [super init])
	{
		textStorage = [[KBWordCountingTextStorage alloc] init];
		loadedText = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(statisticsDidChange:)
													 name:KBTextStorageStatisticsDidChangeNotification
												   object:textStorage];
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[textStorage release];
	[loadedText release];	// Just in case
	[super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	
	// Force the multi-column text view to fit its scroll view
	NSRect frame = [[mcTextView enclosingScrollView] bounds];
	frame.size.height -= [NSScroller scrollerWidth];
	[mcTextView setFrame:frame];
	
	[textStorage addLayoutManager:[mcTextView layoutManager]];
	
	if (loadedText != nil)
	{
		[textStorage replaceCharactersInRange:NSMakeRange(0,[textStorage length])
						 withAttributedString:loadedText];
		[loadedText release];
		loadedText = nil;
	}
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError
{
	// we only write one type - RTFD
	return [textStorage RTFDFileWrapperFromRange:NSMakeRange(0,[textStorage length]) documentAttributes:nil];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	NSDictionary *options = nil;
	
	if ([typeName isEqualToString:@"RTF Document"])
		options = [NSDictionary dictionaryWithObject:NSRTFTextDocumentType forKey:NSDocumentTypeDocumentAttribute];
	
	else if ([typeName isEqualToString:@"Microsoft Word Document"])
		options = [NSDictionary dictionaryWithObject:NSDocFormatTextDocumentType forKey:NSDocumentTypeDocumentAttribute];
	
	else if ([typeName isEqualToString:@"RTFD Document"])
		options = [NSDictionary dictionaryWithObject:NSRTFDTextDocumentType forKey:NSDocumentTypeDocumentAttribute];
	
	if (options != nil)
	{
		loadedText = [[NSAttributedString alloc] initWithData:data options:options documentAttributes:nil error:nil];
		
		// .doc files don't always load - sometimes they are .rtf files in disguise, so check for this:
		if ([typeName isEqualToString:@"Microsoft Word Document"] && !loadedText)
			loadedText = [[NSAttributedString alloc] initWithRTF:data documentAttributes:nil];
		
		return YES;
	}
	
	return NO;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError
{
	if ([typeName isEqualToString:@"RTFD Document"])
	{
		loadedText = [[NSAttributedString alloc] initWithRTFDFileWrapper:fileWrapper documentAttributes:nil];
		return YES;
	}
	
	return [self readFromData:[fileWrapper regularFileContents] ofType:typeName error:outError];
}

- (IBAction)orderFrontStatisticsPanel:(id)sender
{
	[statsPanel orderFront:nil];
}

- (void)statisticsDidChange:(NSNotification *)notification
{
	[wordField setIntegerValue:[textStorage wordCount]];
	[charField setIntegerValue:[textStorage length]];
}

@end
