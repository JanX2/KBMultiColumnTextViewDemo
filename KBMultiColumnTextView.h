//
//  KBMultiColumnTextView.h
//  -----------------------
//
//  Created by Keith Blount on 29/03/2006.
//  Copyright 2006 Keith Blount. All rights reserved.
//
//	A view that shows a text storage as multiple columns (like Tofu).
//

#import <Cocoa/Cocoa.h>

extern NSString *KBMultiColumnTextViewDidAddColumnNotification;
extern NSString *KBMultiColumnTextViewDidRemoveColumnNotification;

@interface KBMultiColumnTextView : NSView
{
	NSLayoutManager *layoutManager;
	NSArray *textViews;
	NSColor *backgroundColor;
	float columnWidth;
	NSSize borderSize;
	Class textViewClass;
	id delegate;
	float scalePercent;
}

- (NSLayoutManager *)layoutManager;
- (NSTextStorage *)textStorage;
- (NSArray *)textViews;
- (NSTextView *)firstTextView;
- (int)numberOfColumns;
- (void)setDelegate:(id)anObject;
- (id)delegate;
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;
- (void)setColumnWidth:(float)width;
- (float)columnWidth;
- (void)setBorderSize:(NSSize)size;
- (NSSize)borderSize;
- (void)setScalePercent:(float)percent;
- (float)scalePercent;
- (void)setTextViewClass:(Class)tvClass;
- (Class)textViewClass;

@end
