//
//  PokerCardView.m
//  TeachingPoker
//
//  Created by 谢乾坤 on 2/8/16.
//  Copyright © 2016 QiankunXie. All rights reserved.
//

#import "PokerCardView.h"

@interface PokerCardView()

@property (nonatomic) CGFloat faceCardScaleFactor;

@end

@implementation PokerCardView

#pragma mark - Properties

@synthesize faceCardScaleFactor = _faceCardScaleFactor;

#define DEFAULT_FACE_CARD_SCALE_FACTOR 0.90

- (CGFloat)faceCardScaleFactor {
    if (!_faceCardScaleFactor) _faceCardScaleFactor = DEFAULT_FACE_CARD_SCALE_FACTOR;
    return _faceCardScaleFactor;
}

- (void)setFaceCardScaleFactor:(CGFloat)faceCardScaleFactor {
    if (faceCardScaleFactor != _faceCardScaleFactor) {
        _faceCardScaleFactor = faceCardScaleFactor;
        [self setNeedsDisplay];
    }
}

- (void)setRank:(NSUInteger)rank {
    if (rank != _rank) {
        _rank = rank;
        [self setNeedsDisplay];
    }
}

- (void)setSuit:(NSString *)suit {
    if (![suit isEqualToString:_suit]) {
        _suit = suit;
        [self setNeedsDisplay];
    }
}

- (void)setFaceUp:(BOOL)faceUp {
    if (faceUp != _faceUp) {
        _faceUp = faceUp;
        [self setNeedsDisplay];
    }
}


#pragma mark - Drawing

#define CORNER_FONT_STANDARD_HEIGHT 180.0
#define CORNER_RADIUS 12.0

- (CGFloat)cornerScaleFactor {
    return self.bounds.size.height / CORNER_FONT_STANDARD_HEIGHT;
}

- (CGFloat)cornerRadius {
    return CORNER_RADIUS * [self cornerScaleFactor];
}

- (CGFloat)cornerOffset {
    return [self cornerRadius] / 3.0;
}

- (void)drawRect:(CGRect)rect {
    // draw the outside of the card (rounded rect)
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                           cornerRadius:[self cornerRadius]];
    
    // clip to the card and don't draw outside it
    [roundedRect addClip];
    
    // fill the card with a white background
    [[UIColor whiteColor] setFill]; // set the fill color to white
    UIRectFill(self.bounds);        // and fill the rounded rectangle with white
    
    // draw a line around the playing card
    [[UIColor blackColor] setStroke];
    [roundedRect stroke];
    
    // check if we are face up or face down
    if (self.faceUp) {
        // draw the face of the card
        UIImage *faceImage = [UIImage imageNamed:@"purplegator"];
        if (faceImage) {
            
            //CGRect
            CGRect newRect = CGRectMake(self.bounds.origin.x , self.bounds.origin.y + 10, self.bounds.size.width, self.bounds.size.width);
            
            // we have an image, so display the face image (King, Queen, etc)
            
//            CGRect imageRect = CGRectInset(self.bounds,                                                 // scale the rect down a bit
//                                           self.bounds.size.height * (1.0 - self.faceCardScaleFactor),   // scale it down
//                                           self.bounds.size.width * (1.0 - self.faceCardScaleFactor)); // sclae it down
            [faceImage drawInRect:newRect];
        }
        
        // draw the corners (♥8 in upper left and upside down in the right bottom)
        [self drawCorners];
    } else {
        [[UIImage imageNamed:@"cardback"] drawInRect:self.bounds];
    }
}

- (void)pushContextAndRotateUpsideDown {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, self.bounds.size.width, self.bounds.size.height);
    CGContextRotateCTM(context, M_PI);
}

- (void)popContext {
    CGContextRestoreGState(UIGraphicsGetCurrentContext());
}

- (NSString *)rankAsString {
    return @[@"?", @"A", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"J", @"Q", @"K"][self.rank];
}

- (void)drawCorners {
    // set the alignment to be centered
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    // define the font
    UIFont *cornerFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    // scale the font
    cornerFont = [cornerFont fontWithSize:cornerFont.pointSize * [self cornerScaleFactor]];
    
    // create the corner text
    NSAttributedString *cornerText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", [self rankAsString], self.suit]
                                                                     attributes:@{ NSFontAttributeName : cornerFont,
                                                                                   NSParagraphStyleAttributeName : paragraphStyle }];
    
    // create the rect for the text in the top-left cornet
    CGRect textBounds;
    textBounds.origin = CGPointMake([self cornerOffset], [self cornerOffset]);  // scaled
    textBounds.size = [cornerText size];
    
    // draw the text inside the rect
    [cornerText drawInRect:textBounds];
    
    // move the rect to the bottom-right and rotate it 180 degrees
    CGContextRef context = UIGraphicsGetCurrentContext(); // get context
    CGContextTranslateCTM(context, self.bounds.size.width, self.bounds.size.height); // move it to the bottom-right
    CGContextRotateCTM(context, M_PI); // and rotate it 180 degrees (pi)
    
    // draw the text inside the rect
    [cornerText drawInRect:textBounds];
}


#pragma mark - Initialization

- (void)setup {
    self.backgroundColor = nil;     // [UIColor clearColor] can also be used
    self.opaque = NO;
    self.contentMode = UIViewContentModeRedraw; // redraw whenever bounds change
}

- (void)awakeFromNib {
    [self setup];
}










@end
