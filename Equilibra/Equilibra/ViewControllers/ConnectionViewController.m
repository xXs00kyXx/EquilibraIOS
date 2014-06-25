//
//  ConnectionViewController.m
//  Equilibra
//
//  Created by Steeve Chopart on 2/17/14.
//  Copyright (c) 2014 Equilibra. All rights reserved.
//

#import "ConnectionViewController.h"
#import "MEDynamicTransition.h"
#import "UIViewController+ECSlidingViewController.h"
#import "GoogleOpenSource/GoogleOpenSource.h"
#import "GoogleOpenSource/GTLServicePlus.h"
#import "AppDelegate.h"
#import "WebServices.h"
#import "Dialog.h"
#import "UserData.h"
#import "Settings.h"
#import "CheckValue.h"

@interface ConnectionViewController ()

@property (nonatomic, strong) UIPanGestureRecognizer*   dynamicTransitionPanGesture;

@end

@implementation ConnectionViewController

@synthesize viewTitle = _viewTitle;
@synthesize usernameLabel = _usernameLabel;
@synthesize usernameInput = _usernameInput;
@synthesize passwordLabel = _passwordLabel;
@synthesize passwordInput = _passwordInput;
@synthesize rememberMeSwitch = _rememberMeSwitch;
@synthesize rememberMeLabel = _rememberMeLabel;
@synthesize connectButton = _connectButton;
@synthesize facebookButton = _facebookButton;
@synthesize twitterButton = _twitterButton;
@synthesize googleButton = _googleButton;
@synthesize googleSignInButton = _googleSignInButton;
@synthesize registerButton = _registerButton;
@synthesize forgotPasswordButton = _forgotPasswordButton;

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GPPSignIn *signIn = [GPPSignIn sharedInstance];

    signIn.delegate = self;
    [_googleSignInButton setImage:nil forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    Settings*   settings = [Settings getInstance];
    
    // Initialisation du texte dans la langue paramétrée
    [_viewTitle setText:NSLocalizedStringFromTable(@"ConnectionViewTitle", settings.language, @"")];
    [_usernameLabel setText:NSLocalizedStringFromTable(@"ConnectionUsernameLabel", settings.language, @"")];
    [_passwordLabel setText:NSLocalizedStringFromTable(@"ConnectionPasswordLabel", settings.language, @"")];
    [_rememberMeLabel setText:NSLocalizedStringFromTable(@"ConnectionRememberMeLabel", settings.language, @"")];
    [_connectButton setTitle:NSLocalizedStringFromTable(@"ConnectionConnectButtonLabel", settings.language, @"") forState:UIControlStateNormal];
    [_connectButton setTitle:NSLocalizedStringFromTable(@"ConnectionConnectButtonLabel", settings.language, @"") forState:UIControlStateNormal];
    [_connectButton setTitle:NSLocalizedStringFromTable(@"ConnectionConnectButtonLabel", settings.language, @"") forState:UIControlStateNormal];
    [_facebookButton setTitle:NSLocalizedStringFromTable(@"ConnectionFacebookButtonLabel", settings.language, @"") forState:UIControlStateNormal];
    [_twitterButton setTitle:NSLocalizedStringFromTable(@"ConnectionTwitterButtonLabel", settings.language, @"") forState:UIControlStateNormal];
    [_googleButton setTitle:NSLocalizedStringFromTable(@"ConnectionGoogleButtonLabel", settings.language, @"") forState:UIControlStateNormal];
    [_registerButton setTitle:NSLocalizedStringFromTable(@"ConnectionRegisterButtonLabel", settings.language, @"") forState:UIControlStateNormal];
    [_forgotPasswordButton setTitle:NSLocalizedStringFromTable(@"ConnectionForgotPasswordButtonLabel", settings.language, @"") forState:UIControlStateNormal];
    
    // Initialisation de la transition et du contrôle gestuel permettant d'ouvrir le menu en glissant le doigt de gauche à droite
    if ([(NSObject *)self.slidingViewController.delegate isKindOfClass:[MEDynamicTransition class]]) {
        MEDynamicTransition *dynamicTransition = (MEDynamicTransition *)self.slidingViewController.delegate;
        if (!self.dynamicTransitionPanGesture)
            self.dynamicTransitionPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:dynamicTransition action:@selector(handlePanGesture:)];
        
        [self.navigationController.view removeGestureRecognizer:self.slidingViewController.panGesture];
        [self.navigationController.view addGestureRecognizer:self.dynamicTransitionPanGesture];
    }
    else {
        [self.navigationController.view removeGestureRecognizer:self.dynamicTransitionPanGesture];
        [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    }
}

- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth
                   error: (NSError *) error
{
    if (error)
        NSLog(@"Received error %@ and auth object %@",error, auth);
    else {
        NSLog(@"Session Google opened");
        UserData*       userData = [UserData getInstance];
        GTLServicePlus* plusService = [[GTLServicePlus alloc] init];
        
        plusService.retryEnabled = YES;
        [plusService setAuthorizer:[GPPSignIn sharedInstance].authentication];
        
        GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];
        
        [plusService executeQuery:query
                completionHandler:^(GTLServiceTicket *ticket,
                                    GTLPlusPerson *person,
                                    NSError *error) {
                    if (error) {
                        GTMLoggerError(@"Error: %@", error);
                    }
                    else {
                        NSString *description = [NSString stringWithFormat:@"%@", person.displayName];
                        NSLog(@"%@", description);
                        
                        userData.firstName = person.name.givenName;
                        userData.lastName = person.name.familyName;
                        
                        NSData *avatarData = nil;
                        NSString *imageURLString = person.image.url;
                        NSLog(@"%@", imageURLString);
                        if (imageURLString) {
                            NSURL *imageURL = [NSURL URLWithString:imageURLString];
                            avatarData = [NSData dataWithContentsOfURL:imageURL];
                        }
                        
                        if (avatarData) {
                            NSLog(@"Data not nil");
                            userData.profilePicture = [[UIImageView alloc] initWithImage:[UIImage imageWithData:avatarData]];
                        }
                        
                    }
                }];
        
        userData.connected = TRUE;
        userData.accountType = GOOGLE;
        
        // Puis on redirige l'utilisateur sur la page d'accueil
        [self performSegueWithIdentifier:@"toHome" sender:self];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - IBActions

- (IBAction)menuButtonTapped:(id)sender {
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

- (IBAction)connectButtonTapped:(id)sender {
    
    CheckValue      *checker = [[CheckValue alloc] init];
    
    [checker checkUsername:_usernameInput.text];
    
    // Si l'username et le password est valide
    if ([checker checkUsername:_usernameInput.text] && [checker checkPassword:_passwordInput.text.lowercaseString]) {
        // On lance le webservice de connexion et on récupère la réponse du serveur
        WebServices *wbs = [[WebServices alloc] init];
        BOOL connected = [wbs WBSConnection:_usernameInput.text.lowercaseString withPassWord:_passwordInput.text];
    
        // Si la connexion a reussi
        if (connected) {
            // On stocke les informations de l'utilisateur
            UserData*   userData = [UserData getInstance];
            
            userData.connected = TRUE;
            userData.accountType = EQUILIBRA;
            userData.username = _usernameInput.text;
            // On affiche un dialogue
            [Dialog informDialog:@"Connection" :[NSString stringWithFormat:@"You are connected as %@!", userData.username] :nil];
            // On redirige l'utilisateur sur la page d'accueil
            [self performSegueWithIdentifier:@"toHome" sender:self];
        }
        // Si la connexion a échouée, on affiche un dialogue
        else
            [Dialog informDialog:@"Connection" :@"Bad credentials..." :nil];
    } else {

        [Dialog informDialog:@"Error" :[checker createMsgError:@[@"username"]]:nil];
    }
}

- (IBAction)facebookButtonTapped:(id)sender {
    // Si la session Facebook est déja ouverte, on l'a ferme
    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
        [FBSession.activeSession closeAndClearTokenInformation];
    // Sinon on en ouvre une avec les permissions basiques
    else {
        [FBSession openActiveSessionWithReadPermissions:@[@"basic_info", @"email", @"user_birthday"] allowLoginUI:YES
                                      completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
             AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
             [appDelegate sessionStateChanged:session state:state error:error];
         }];
    }
    // Puis on redirige l'utilisateur sur la page d'accueil
    [self performSegueWithIdentifier:@"toHome" sender:self];
}

- (IBAction)twitterButtonTapped:(id)sender {
    
}

- (IBAction)googleButtonTapped:(id)sender {

}

@end