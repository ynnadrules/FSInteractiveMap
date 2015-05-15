//
//  FSInteractiveMapView.m
//  FSInteractiveMap
//
//  Created by Arthur GUIBERT on 23/12/2014.
//  Copyright (c) 2014 Arthur GUIBERT. All rights reserved.
//

#import "FSInteractiveMapView.h"
#import "FSSVG.h"

@interface FSInteractiveMapView ()

@property (nonatomic, strong) FSSVG* svg;
@property (nonatomic, strong) NSMutableArray* scaledPaths;

@end

@implementation FSInteractiveMapView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self) {
        [self setDefaultParameters];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setDefaultParameters];
    }
    return self;
}

- (void)setDefaultParameters
{
    self.fillColor = [UIColor colorWithWhite:0.85 alpha:1];
    self.strokeColor = [UIColor colorWithWhite:0.6 alpha:1];
}

- (NSMutableArray *)scaledPaths {
    if (!_scaledPaths) {
        _scaledPaths = [NSMutableArray array];
    }
    
    return _scaledPaths;
}

//- (CGSize)intrinsicContentSize {
//    CGFloat scaleHorizontal = CGRectGetWidth(self.frame) / CGRectGetWidth(self.svg.bounds);
//    CGFloat scaleVertical = CGRectGetHeight(self.frame) / CGRectGetHeight(self.svg.bounds);
//    
//    if (scaleHorizontal < scaleVertical) {
//        return CGSizeMake(<#CGFloat width#>, <#CGFloat height#>)
//    } else if (scaleVertical > scaleHorizontal) {
//        
//    } else {
//        
//    }
//
//    return CGSizeMake(CGRectGetWidth(self.svg.bounds) * scale, CGRectGetHeight(self.svg.bounds));
//}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
    
    if (layer == self.layer) {
        CGFloat scaleHorizontal = self.frame.size.width / self.svg.bounds.size.width;
        CGFloat scaleVertical = self.frame.size.height / self.svg.bounds.size.height;
        CGFloat scale = MIN(scaleHorizontal, scaleVertical);
        CGFloat xOffset = 0;
        CGFloat yOffset = 0;
        
        if (scale == scaleVertical) {
            xOffset = scale * CGRectGetWidth(self.frame) / 2.0f;
        } else {
            yOffset = scale * CGRectGetHeight(self.frame) / 2.0f;
        }
        
        CGAffineTransform scaleTransform = CGAffineTransformIdentity;
        scaleTransform = CGAffineTransformMakeScale(scale, scale);
        scaleTransform = CGAffineTransformTranslate(scaleTransform,-self.svg.bounds.origin.x + xOffset, -self.svg.bounds.origin.y + yOffset);
        
        [self.svg.paths enumerateObjectsUsingBlock:^(FSSVGPathElement *path, NSUInteger idx, BOOL *stop) {
            UIBezierPath *shapePath = [path.path copy];
            [shapePath applyTransform:scaleTransform];
            CAShapeLayer *shapeLayer = (CAShapeLayer *)layer.sublayers[idx];
            shapeLayer.path = shapePath.CGPath;
            self.scaledPaths[idx] = shapePath;
        }];
    }
}

#pragma mark - SVG map loading

- (void)loadMap:(NSString*)mapName withColors:(NSDictionary*)colorsDict
{
    _svg = [FSSVG svgWithFile:mapName];

    for (FSSVGPathElement* path in _svg.paths) {
        
        UIBezierPath *shapePath = [path.path copy];
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        
        // Setting CAShapeLayer properties
        shapeLayer.strokeColor = self.strokeColor.CGColor;
        shapeLayer.lineWidth = 0.5;
        
        if(path.fill) {
            if(colorsDict && [colorsDict objectForKey:path.identifier]) {
                UIColor* color = [colorsDict objectForKey:path.identifier];
                shapeLayer.fillColor = color.CGColor;
            } else {
                shapeLayer.fillColor = self.fillColor.CGColor;
            }
            
        } else {
            shapeLayer.fillColor = [[UIColor clearColor] CGColor];
        }
        
        [self.layer addSublayer:shapeLayer];
        [self.scaledPaths addObject:shapePath];
    }
}

- (void)loadMap:(NSString*)mapName withData:(NSDictionary*)data colorAxis:(NSArray*)colors
{
    [self loadMap:mapName withColors:[self getColorsForData:data colorAxis:colors]];
}

- (NSDictionary*)getColorsForData:(NSDictionary*)data colorAxis:(NSArray*)colors
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:[data count]];
    
    float min = MAXFLOAT;
    float max = -MAXFLOAT;
    
    for (id key in data) {
        NSNumber* value = [data objectForKey:key];
        
        if([value floatValue] > max)
            max = [value floatValue];
        
        if([value floatValue] < min)
            min = [value floatValue];
    }
    
    for (id key in data) {
        NSNumber* value = [data objectForKey:key];
        float s = ([value floatValue] - min) / (max - min);
        float segmentLength = 1.0 / ([colors count] - 1);
        int minColorIndex = MAX(floorf(s / segmentLength),0);
        int maxColorIndex = MIN(ceilf(s / segmentLength), [colors count] - 1);
        
        UIColor* minColor = colors[minColorIndex];
        UIColor* maxColor = colors[maxColorIndex];
        
        s -= segmentLength * minColorIndex;
        
        CGFloat maxColorRed = 0;
        CGFloat maxColorGreen = 0;
        CGFloat maxColorBlue = 0;
        CGFloat minColorRed = 0;
        CGFloat minColorGreen = 0;
        CGFloat minColorBlue = 0;
        
        [maxColor getRed:&maxColorRed green:&maxColorGreen blue:&maxColorBlue alpha:nil];
        [minColor getRed:&minColorRed green:&minColorGreen blue:&minColorBlue alpha:nil];
        
        UIColor* color = [UIColor colorWithRed:minColorRed * (1.0 - s) + maxColorRed * s
                                         green:minColorGreen * (1.0 - s) + maxColorGreen * s
                                          blue:minColorBlue * (1.0 - s) + maxColorBlue * s
                                         alpha:1];
        
        [dict setObject:color forKey:key];
    }
    
    return dict;
}

#pragma mark - Updating the colors and/or the data

- (void)setColors:(NSDictionary*)colorsDict
{
    for(int i=0;i<[_scaledPaths count];i++) {
        FSSVGPathElement* element = _svg.paths[i];
        
        if([self.layer.sublayers[i] isKindOfClass:CAShapeLayer.class] && element.fill) {
            CAShapeLayer* l = self.layer.sublayers[i];
            
            if(element.fill) {
                if(colorsDict && [colorsDict objectForKey:element.identifier]) {
                    UIColor* color = [colorsDict objectForKey:element.identifier];
                    l.fillColor = color.CGColor;
                } else {
                    l.fillColor = self.fillColor.CGColor;
                }
            } else {
                l.fillColor = [[UIColor clearColor] CGColor];
            }
        }
    }
}

- (void)setData:(NSDictionary*)data colorAxis:(NSArray*)colors
{
    [self setColors:[self getColorsForData:data colorAxis:colors]];
}

#pragma mark - Layers enumeration

- (void)enumerateLayersUsingBlock:(void (^)(NSString *, CAShapeLayer *))block
{
    for(int i=0;i<[_scaledPaths count];i++) {
        FSSVGPathElement* element = _svg.paths[i];
        
        if([self.layer.sublayers[i] isKindOfClass:CAShapeLayer.class] && element.fill) {
            CAShapeLayer* l = self.layer.sublayers[i];
            block(element.identifier, l);
        }
    }
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    
    for(int i=0;i<[_scaledPaths count];i++) {
        UIBezierPath* path = _scaledPaths[i];
        if ([path containsPoint:touchPoint])
        {
            FSSVGPathElement* element = _svg.paths[i];
            
            if([self.layer.sublayers[i] isKindOfClass:CAShapeLayer.class] && element.fill) {
                CAShapeLayer* l = self.layer.sublayers[i];
                
                if(_clickHandler) {
                    _clickHandler(element.identifier, l);
                }
            }
        }
    }
}

@end
