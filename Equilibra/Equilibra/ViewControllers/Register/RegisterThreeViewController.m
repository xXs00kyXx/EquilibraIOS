//
//  RegisterThreeViewController.m
//  Equilibra
//
//  Created by Steeve Chopart on 2/17/14.
//  Copyright (c) 2014 Equilibra. All rights reserved.
//

#import "RegisterThreeViewController.h"
#import "RegisterTwoViewController.h"
#import "RegisterFourViewController.h"
#import "Settings.h"

@interface RegisterThreeViewController ()

@end

@implementation RegisterThreeViewController

@synthesize data = _data;
@synthesize goals = _goals;
@synthesize viewTitle = _viewTitle;
@synthesize goalLabel = _goalLabel;
@synthesize goalList = _goalList;
@synthesize submitButton = _submitButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Création des données de la liste d'objectifs
    _goals = @[@"Goal #1",
              @"Goal #2",
              @"Goal #3",
              @"Goal #4",
              @"Goal #5"];
    
    // On sélectionne la celulle via les données d'inscription
    [_goalList selectRow:[self getIndexFromTitle:_data.goal] inComponent:0 animated:TRUE];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    Settings*   settings = [Settings getInstance];
    
    // Initialisation du texte dans la langue paramétrée
    [_viewTitle setText:NSLocalizedStringFromTable(@"RegisterViewTitle", settings.language, @"")];
    [_goalLabel setText:NSLocalizedStringFromTable(@"RegisterGoalLabel", settings.language, @"")];
    [_submitButton setTitle:NSLocalizedStringFromTable(@"RegisterSubmitButtonLabel", settings.language, @"") forState:UIControlStateNormal];
}

- (NSInteger)getIndexFromTitle:(NSString *)title {
    NSInteger index;
    
    for (index = 0; index < _goals.count; ++index) {
        if ([_goals[index] isEqualToString:title])
            return index;
    }
    return (_goals.count / 2);
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _goals.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return _goals[row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 320;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Mise à jour et transfert des données d'inscription vers l'étape précédente ou suivante
    _data.goal = _goals[[_goalList selectedRowInComponent:0]];
    if ([[segue identifier] isEqualToString:@"toRegisterTwo"]) {
        RegisterTwoViewController *registerTwo = [segue destinationViewController];
        registerTwo.data = _data;
    }
    else if ([[segue identifier] isEqualToString:@"toRegisterFour"]) {
        RegisterFourViewController *registerFour = [segue destinationViewController];
        registerFour.data = _data;
    }
}

@end
