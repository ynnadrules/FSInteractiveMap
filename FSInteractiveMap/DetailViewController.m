//
//  DetailViewController.m
//  FSInteractiveMap
//
//  Created by Arthur GUIBERT on 28/12/2014.
//  Copyright (c) 2014 Arthur GUIBERT. All rights reserved.
//

#import "DetailViewController.h"
#import "FSInteractiveMapView.h"

@interface DetailViewController ()

@property (nonatomic, weak) CAShapeLayer* oldClickedLayer;

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.title = self.detailItem;
        self.detailDescriptionLabel.text = @"";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    if([self.detailItem isEqualToString:@"Example 1"]) {
        [self initExample1];
    } else if([self.detailItem isEqualToString:@"Example 2"]) {
        [self initExample2];
    } else if([self.detailItem isEqualToString:@"Example 3"]) {
        [self initExample3];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Examples

- (void)initExample1
{
    NSDictionary* data = @{@"asia" : @12,
                           @"australia" : @2,
                           @"north_america" : @100,
                           @"south_america" : @14,
                           @"africa" : @5,
                           @"europe" : @20
                           };
    
    [self.mapView loadMap:@"world-continents-low" withData:data colorAxis:@[[UIColor lightGrayColor], [UIColor darkGrayColor]]];
    
    [self.mapView setClickHandler:^(NSString* identifier, CAShapeLayer* layer) {
        self.detailDescriptionLabel.text = [NSString stringWithFormat:@"Continent clicked: %@", identifier];
    }];
}

- (void)initExample2
{
    NSDictionary* data = @{@"fr" : @12,
                           @"it" : @2,
                           @"de" : @9,
                           @"pl" : @24,
                           @"uk" : @17
                           };
    
//    FSInteractiveMapView* map = [[FSInteractiveMapView alloc] initWithFrame:CGRectMake(-1, 64, self.view.frame.size.width + 2, 500)];
    [self.mapView loadMap:@"europe" withData:data colorAxis:@[[UIColor blueColor], [UIColor greenColor], [UIColor yellowColor], [UIColor redColor]]];
    
//    [self.view addSubview:map];
}

- (void)initExample3
{
//    FSInteractiveMapView* map = [[FSInteractiveMapView alloc] initWithFrame:CGRectMake(16, 96, self.view.frame.size.width - 32, 500)];
    [self.mapView loadMap:@"usa-low" withColors:nil];
    
    [self.mapView setClickHandler:^(NSString* identifier, CAShapeLayer* layer) {
        if(_oldClickedLayer) {
            _oldClickedLayer.zPosition = 0;
            _oldClickedLayer.shadowOpacity = 0;
        }
        
        _oldClickedLayer = layer;
        
        // We set a simple effect on the layer clicked to highlight it
        layer.zPosition = 10;
        layer.shadowOpacity = 0.5;
        layer.shadowColor = [UIColor blackColor].CGColor;
        layer.shadowRadius = 5;
        layer.shadowOffset = CGSizeMake(0, 0);
    }];
    
//    [self.view addSubview:map];
}

@end
