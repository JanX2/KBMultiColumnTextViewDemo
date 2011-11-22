//
//  MyDocument.h
//  MultiColumnTextExample
//
//  Created by Keith Blount on 07/06/2006.
//  Copyright __MyCompanyName__ 2006 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "KBMultiColumnTextView.h"
#import "KBWordCountingTextStorage.h"

@interface MyDocument : NSDocument
{
	IBOutlet KBMultiColumnTextView *mcTextView;
	IBOutlet NSPanel *statsPanel;
	IBOutlet NSTextField *wordField;
	IBOutlet NSTextField *charField;
	
	KBWordCountingTextStorage *textStorage;
	
	NSAttributedString *loadedText;
}
- (IBAction)orderFrontStatisticsPanel:(id)sender;
@end
