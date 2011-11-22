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

@interface KBMultiColumnTextView : NSView <NSLayoutManagerDelegate, NSTextViewDelegate>
{
	NSLayoutManager *layoutManager;
	NSArray *textViews;
	NSColor *backgroundColor;
	CGFloat columnWidth;
	NSSize borderSize;
	Class textViewClass;
	id delegate;
	CGFloat scalePercent;
}

@property (copy) NSArray *textViews;

- (NSLayoutManager *)layoutManager;
- (NSTextStorage *)textStorage;
- (NSTextView *)firstTextView;
- (NSInteger)numberOfColumns;
- (void)setDelegate:(id)anObject;
- (id)delegate;
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;
- (void)setColumnWidth:(CGFloat)width;
- (CGFloat)columnWidth;
- (void)setBorderSize:(NSSize)size;
- (NSSize)borderSize;
- (void)setScalePercent:(CGFloat)percent;
- (CGFloat)scalePercent;
- (void)setTextViewClass:(Class)tvClass;
- (Class)textViewClass;

@end
