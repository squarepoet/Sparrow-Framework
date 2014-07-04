//
//  Game.m
//  AppScaffold
//

#import "Game.h"

@implementation Game

- (id)init
{
    if ((self = [super init]))
    {
        // This is where the code of your game will start;
        // in this sample, we add just a simple quad to see if it works.

        SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
        quad.color = 0xff0000;
        quad.x = 50;
        quad.y = 50;
        [self addChild:quad];


        // Per default, this project compiles as an universal application. To change that, enter the
        // project info screen, and in the "General"-tab, find the setting "Deployment Info".
        //
        // Now choose the right setting in the "Devices" dropdown:
        //
        //   * iPhone      -> iPhone only App
        //   * iPad        -> iPad only App
        //   * iPhone/iPad -> Universal App
        //
        // The "Deployment target" setting must be at least "iOS 5.0" for Sparrow 2.
        // Always use the latest available version as the base SDK.
    }
    return self;
}

@end
