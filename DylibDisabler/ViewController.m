//
//  ViewController.m
//  DylibDisabler
//
//  Created by Pat Sluth on 2/10/2014.
//  Copyright (c) 2014 Pat Sluth. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
}

@property (weak, nonatomic) IBOutlet UITableView *tableview;

@property (strong, nonatomic) IBOutlet NSUserDefaults *userDefaults;
@property (strong, nonatomic) IBOutlet NSFileManager *fileManager;
@property (strong, nonatomic) IBOutlet NSMutableArray *dylibArray;

- (void)createControls;
- (void)loadDylibs;
- (void)updateCell:(UITableViewCell *)cell atIndex:(NSIndexPath *)indexPath;

@end

@implementation ViewController

#pragma mark ViewController Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableview.delegate = self;
    self.tableview.dataSource = self;
    
    [self createControls];
    [self loadDylibs];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return NO;
}

#pragma mark Public Methods

- (void)respring
{
	NSString *respringString = [self.userDefaults objectForKey:RESPRING_KEY];
    
	if ([respringString isEqualToString:RESPRING_YES]){
        system("killall -9 SpringBoard");
    }
}

#pragma mark Private Methods

- (void)createControls
{
	self.fileManager = [NSFileManager defaultManager];
	self.dylibArray = [[NSMutableArray alloc] init];
	self.userDefaults = [NSUserDefaults standardUserDefaults];
	[self.userDefaults setObject:RESPRING_NO forKey:RESPRING_KEY];
	[self.userDefaults synchronize];
}

- (void)loadDylibs
{
	NSError *dylibError = nil;
	NSArray *dylibContents = [self.fileManager contentsOfDirectoryAtPath:DYLIB_DIRECTORY error:&dylibError];
    
	if (dylibError){
        NSLog(@"DylibDisabler: Content Reading Erroing: %@", dylibError);
    }
	else {
		for (NSString *dylibName in dylibContents){
			if ([dylibName hasSuffix:@".dylib"] || [dylibName hasSuffix:@".disabled"]){
                [self.dylibArray addObject:dylibName];
            }
		}
        
		[self.dylibArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [self.tableview reloadData];
	}
}

- (void)updateCell:(UITableViewCell *)cell atIndex:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.dylibArray count]){
        NSRange dylibRandge = [[self.dylibArray objectAtIndex:indexPath.row] rangeOfString:@"."];
        
        NSString *dylibName = [[self.dylibArray objectAtIndex:indexPath.row]
                               substringWithRange:NSMakeRange(0, dylibRandge.location)];
        
        cell.textLabel.text = dylibName;
        
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        
        
        cell.detailTextLabel.textColor = ([[self.dylibArray objectAtIndex:indexPath.row]
                                           hasSuffix:@".dylib"] ? [UIColor darkGrayColor] : [UIColor redColor]);
        cell.detailTextLabel.text = ([[self.dylibArray objectAtIndex:indexPath.row]
                                      hasSuffix:@".dylib"] ? @"Enabled" : @"Disabled");
        cell.detailTextLabel.font = [UIFont systemFontOfSize:11.0f];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        cell.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark TableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 50.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dylibArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 15.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"DylibDisabler © EvilPenguin";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Dylib Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    cell.textLabel.text = @"";
    [self updateCell:cell atIndex:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete){
        if (indexPath.row < [self.dylibArray count]){
            
            NSRange dylibRandge = [[self.dylibArray objectAtIndex:indexPath.row] rangeOfString:@"."];
            NSString *dylibName = [[self.dylibArray objectAtIndex:indexPath.row] substringWithRange:NSMakeRange(0, dylibRandge.location)];
            
            NSString *dylibPath = [NSString stringWithFormat:@"%@/%@", DYLIB_DIRECTORY, [self.dylibArray objectAtIndex:indexPath.row]];
            NSString *plistPath = [NSString stringWithFormat:@"%@/%@.plist", DYLIB_DIRECTORY, dylibName];
            NSLog(@"Dylib path: %@ \n Dylib Plist path: %@", dylibPath, plistPath);
            
            NSError *dylibError = nil;
            [self.fileManager removeItemAtPath:dylibPath error:&dylibError];
            if (dylibError != nil) {
                NSLog(@"DylibDisabler Dylib Deletion Error: %@", dylibError.description);
            }
            
            NSError *plistError = nil;
            [self.fileManager removeItemAtPath:plistPath error:&plistError];
            
            if (plistError != nil){
                NSLog(@"DylibDisabler Plist Deletion Error: %@", dylibError.description);
            }
            
            if (dylibError == nil && plistError == nil){
                [self.userDefaults setObject:RESPRING_YES forKey:RESPRING_KEY];
                [self.userDefaults synchronize];
                
                [self.dylibArray removeObjectAtIndex:indexPath.row];
                [self.tableview deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                      withRowAnimation:UITableViewRowAnimationFade];
            }
        }
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.dylibArray count]) {
        
        NSRange dylibRandge = [[self.dylibArray objectAtIndex:indexPath.row] rangeOfString:@"."];
        NSString *dylibName = [[self.dylibArray objectAtIndex:indexPath.row] substringWithRange:NSMakeRange(0, dylibRandge.location)];
        NSString *newDylibName = [NSString stringWithFormat:@"%@.%@",
                                  dylibName,
                                  ([[self.dylibArray objectAtIndex:indexPath.row]
                                    hasSuffix:@".disabled"] ? @"dylib" : @"disabled")];
        
        NSError *error = nil;
        [self.fileManager moveItemAtPath:[NSString stringWithFormat:@"%@/%@", DYLIB_DIRECTORY, [self.dylibArray objectAtIndex:indexPath.row]]
                             toPath:[NSString stringWithFormat:@"%@/%@", DYLIB_DIRECTORY, newDylibName]
                              error:&error];
        
        if (error){
            NSLog(@"DylibDisabler Dylib E/D Error: %@", error);
        } else {
            [self.dylibArray removeObjectAtIndex:indexPath.row];
            [self.dylibArray insertObject:newDylibName atIndex:indexPath.row];
            [self.userDefaults setObject:RESPRING_YES forKey:RESPRING_KEY];
            [self.userDefaults synchronize];
        }
        
        [self updateCell:[tableView cellForRowAtIndexPath:indexPath] atIndex:indexPath];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [self.dylibArray removeAllObjects];
    self.dylibArray = nil;
}

@end
