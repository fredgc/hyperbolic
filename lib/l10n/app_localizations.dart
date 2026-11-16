import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('lt'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// Navigation title for About page
  ///
  /// In en, this message translates to:
  /// **'About Hyperbolic'**
  String get aboutHyperbolic;

  /// Tooltip for adding a new free numeric parameter
  ///
  /// In en, this message translates to:
  /// **'Add Free Parameter'**
  String get addFreeParameterTooltip;

  /// Main application title
  ///
  /// In en, this message translates to:
  /// **'Hyperbolic Geometry Drawing Tool'**
  String get appTitle;

  /// About menu entry title with version
  ///
  /// In en, this message translates to:
  /// **'About Hyperbolic v2.0.0+5'**
  String get appVersion;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Title of file chooser dialog
  ///
  /// In en, this message translates to:
  /// **'Choose a File'**
  String get chooseAFile;

  /// Button to clear browser cache and reload web app
  ///
  /// In en, this message translates to:
  /// **'Clear Cache & Reload App'**
  String get clearCacheAndReload;

  /// Tooltip for close buttons
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTooltip;

  /// Tooltip for default color picker in toolbar
  ///
  /// In en, this message translates to:
  /// **'Color for New Objects'**
  String get colorForNewObjectsTooltip;

  /// Title of dialog confirming file title and description before saving
  ///
  /// In en, this message translates to:
  /// **'Confirm Properties Before Saving'**
  String get confirmPropertiesTitle;

  /// Checkbox label to copy scene serialized as URL
  ///
  /// In en, this message translates to:
  /// **'Copy as URL'**
  String get copyAsUrl;

  /// Generic delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Tooltip for deleting a locally stored file
  ///
  /// In en, this message translates to:
  /// **'Delete local file'**
  String get deleteLocalFileTooltip;

  /// Tooltip for removing a numeric parameter
  ///
  /// In en, this message translates to:
  /// **'Delete parameter'**
  String get deleteParameterTooltip;

  /// Tooltip for deleting currently selected object
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelectedTooltip;

  /// Label for file description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// Tooltip to clear current selection
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get deselectTooltip;

  /// Button label to discard unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Done button label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Button to save drawing to a file download
  ///
  /// In en, this message translates to:
  /// **'Download to file'**
  String get downloadToFile;

  /// Input decoration label for drawing title
  ///
  /// In en, this message translates to:
  /// **'Drawing Title'**
  String get drawingTitleLabel;

  /// Menu item to edit drawing description
  ///
  /// In en, this message translates to:
  /// **'Edit Description'**
  String get editDescription;

  /// Subtitle instructions in JSON editor dialog
  ///
  /// In en, this message translates to:
  /// **'Correct syntax or structure errors below and click Validate & Load.'**
  String get editJsonSyntaxSubtitle;

  /// Title of JSON editor dialog
  ///
  /// In en, this message translates to:
  /// **'Edit JSON Syntax'**
  String get editJsonSyntaxTitle;

  /// Title of properties editing dialog
  ///
  /// In en, this message translates to:
  /// **'Edit Properties'**
  String get editPropertiesTitle;

  /// Hint text in JSON editor input field
  ///
  /// In en, this message translates to:
  /// **'Enter valid JSON drawing syntax...'**
  String get enterValidJsonHint;

  /// Header title when file loading fails
  ///
  /// In en, this message translates to:
  /// **'Error Loading File'**
  String get errorLoadingFile;

  /// Expansion tile label for technical error information
  ///
  /// In en, this message translates to:
  /// **'Expand Error Details'**
  String get expandErrorDetails;

  /// Error message when a file fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load {name}'**
  String failedToLoadFile(String name);

  /// Navigation item for file management guide
  ///
  /// In en, this message translates to:
  /// **'File Management'**
  String get fileManagement;

  /// Title of help and documentation screen
  ///
  /// In en, this message translates to:
  /// **'Help & Docs'**
  String get helpAndDocs;

  /// Tooltip for help popup menu button in app bar
  ///
  /// In en, this message translates to:
  /// **'Help & Guides'**
  String get helpAndGuidesTooltip;

  /// Menu item opening controls guide
  ///
  /// In en, this message translates to:
  /// **'Controls & Tools Guide'**
  String get helpControlsGuide;

  /// Menu item opening developer documentation
  ///
  /// In en, this message translates to:
  /// **'Developer Docs'**
  String get helpDeveloperDocs;

  /// Title of drawer help menu
  ///
  /// In en, this message translates to:
  /// **'Help Menu'**
  String get helpMenu;

  /// Menu item opening objects guide
  ///
  /// In en, this message translates to:
  /// **'Geometric Objects Guide'**
  String get helpObjectsGuide;

  /// Menu item opening help overview
  ///
  /// In en, this message translates to:
  /// **'Help Overview'**
  String get helpOverview;

  /// Navigation item for hyperbolic geometry overview
  ///
  /// In en, this message translates to:
  /// **'Hyperbolic Geometry'**
  String get hyperbolicGeometry;

  /// Navigation item for hyperbolic objects guide
  ///
  /// In en, this message translates to:
  /// **'Hyperbolic Objects'**
  String get hyperbolicObjects;

  /// Status text while application initializes
  ///
  /// In en, this message translates to:
  /// **'Initializing App...'**
  String get initializingApp;

  /// Status text while settings load
  ///
  /// In en, this message translates to:
  /// **'Initializing Settings...'**
  String get initializingSettings;

  /// Automatic system locale option
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get languageAuto;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// Notice when opening legacy scene files
  ///
  /// In en, this message translates to:
  /// **'This file is in an older hyperbolic format. It will be automatically upgraded when saved.'**
  String get legacyFileFormatMessage;

  /// Title of legacy file notification dialog
  ///
  /// In en, this message translates to:
  /// **'Legacy File Format'**
  String get legacyFileFormatTitle;

  /// Status message while loading a file
  ///
  /// In en, this message translates to:
  /// **'Loading {name}...'**
  String loadingFile(String name);

  /// Title of Google Drive load tab
  ///
  /// In en, this message translates to:
  /// **'Load from Drive'**
  String get loadFromDrive;

  /// Tooltip to lock an object
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lockTooltip;

  /// Tooltip to close menu drawer
  ///
  /// In en, this message translates to:
  /// **'Close Menu'**
  String get menuCloseMenu;

  /// Copy menu action
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get menuCopy;

  /// Cut menu action
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get menuCut;

  /// Delete menu action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get menuDelete;

  /// Edit top menu
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menuEdit;

  /// File top menu
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get menuFile;

  /// Log out from cloud services
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get menuLogOut;

  /// New drawing menu action
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get menuNew;

  /// Open drawing menu action
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get menuOpen;

  /// Paste menu action
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get menuPaste;

  /// Redo menu action
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get menuRedo;

  /// Reload current file menu action
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get menuReload;

  /// Menu action to reset hyperbolic translation
  ///
  /// In en, this message translates to:
  /// **'Reset Möbius Translation'**
  String get menuResetMobius;

  /// Menu action to reset Euclidean zoom and pan
  ///
  /// In en, this message translates to:
  /// **'Reset View'**
  String get menuResetView;

  /// Save drawing menu action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get menuSave;

  /// Save As drawing menu action
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get menuSaveAs;

  /// Share drawing menu action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get menuShare;

  /// Menu action to toggle Poincaré disk axes
  ///
  /// In en, this message translates to:
  /// **'Toggle Axes'**
  String get menuToggleAxes;

  /// Tutorials menu title
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get menuTutorials;

  /// Undo menu action
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get menuUndo;

  /// View top menu
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// Prompt message in name dialog
  ///
  /// In en, this message translates to:
  /// **'Give your drawing a title before saving:'**
  String get nameDrawingPrompt;

  /// Label for name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Title of name dialog
  ///
  /// In en, this message translates to:
  /// **'Name Your Drawing'**
  String get nameYourDrawing;

  /// Button to create a blank new diagram
  ///
  /// In en, this message translates to:
  /// **'New Diagram'**
  String get newDiagram;

  /// Button label to create a new file
  ///
  /// In en, this message translates to:
  /// **'New File'**
  String get newFile;

  /// Button label to create a new local file
  ///
  /// In en, this message translates to:
  /// **'New Local File'**
  String get newLocalFile;

  /// Placeholder message in empty parameters panel
  ///
  /// In en, this message translates to:
  /// **'No number objects in scene.\nClick + to add a free parameter or\nuse Measurement tools on canvas.'**
  String get noParametersMessage;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Tooltip for drawer hamburger menu icon
  ///
  /// In en, this message translates to:
  /// **'Open Menu'**
  String get openDrawerTooltip;

  /// Navigation item for overview guide
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// Title of numeric parameters panel
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get parametersTitle;

  /// Navigation title for Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Prompt for angle bisector first leg point
  ///
  /// In en, this message translates to:
  /// **'Select first point on ray 1'**
  String get promptAngleBisectorFirst;

  /// Prompt for angle bisector second leg point
  ///
  /// In en, this message translates to:
  /// **'Select point on ray 2'**
  String get promptAngleBisectorSecond;

  /// Prompt for angle bisector vertex point
  ///
  /// In en, this message translates to:
  /// **'Select angle vertex point'**
  String get promptAngleBisectorVertex;

  /// Prompt for circle center point
  ///
  /// In en, this message translates to:
  /// **'Select center point (or click canvas)'**
  String get promptCircleCenter;

  /// Prompt for circle circumference point
  ///
  /// In en, this message translates to:
  /// **'Select point on circumference (or click canvas)'**
  String get promptCircleCircumference;

  /// Prompt to pick a radius Number parameter
  ///
  /// In en, this message translates to:
  /// **'Select a radius Number object in the panel'**
  String get promptCircleRadiusNumber;

  /// Prompt for compass center point
  ///
  /// In en, this message translates to:
  /// **'Select center point for the compass circle'**
  String get promptCompassCenter;

  /// Prompt for compass radius first point
  ///
  /// In en, this message translates to:
  /// **'Select first point of radius segment'**
  String get promptCompassFirst;

  /// Prompt for compass radius second point
  ///
  /// In en, this message translates to:
  /// **'Select second point of radius segment'**
  String get promptCompassSecond;

  /// Prompt for equilateral triangle first vertex
  ///
  /// In en, this message translates to:
  /// **'Select first base vertex point (or click canvas)'**
  String get promptEquilateralFirst;

  /// Prompt for equilateral triangle second vertex
  ///
  /// In en, this message translates to:
  /// **'Select second base vertex point (or click canvas)'**
  String get promptEquilateralSecond;

  /// Prompt for first intersecting geometry
  ///
  /// In en, this message translates to:
  /// **'Select first line or circle'**
  String get promptIntersectionFirst;

  /// Prompt for second intersecting geometry
  ///
  /// In en, this message translates to:
  /// **'Select second line or circle'**
  String get promptIntersectionSecond;

  /// Prompt for first line point
  ///
  /// In en, this message translates to:
  /// **'Select first point (or click canvas to place one)'**
  String get promptLineFirst;

  /// Prompt for second line point
  ///
  /// In en, this message translates to:
  /// **'Select second point (or click canvas to place one)'**
  String get promptLineSecond;

  /// Prompt for measuring angle first leg point
  ///
  /// In en, this message translates to:
  /// **'Select first point on first leg'**
  String get promptMeasureAngleFirst;

  /// Prompt for measuring angle second leg point
  ///
  /// In en, this message translates to:
  /// **'Select point on second leg'**
  String get promptMeasureAngleSecond;

  /// Prompt for measuring angle vertex point
  ///
  /// In en, this message translates to:
  /// **'Select vertex point'**
  String get promptMeasureAngleVertex;

  /// Prompt for measuring distance first point
  ///
  /// In en, this message translates to:
  /// **'Select first point'**
  String get promptMeasureDistFirst;

  /// Prompt for measuring distance second point
  ///
  /// In en, this message translates to:
  /// **'Select second point'**
  String get promptMeasureDistSecond;

  /// Prompt for midpoint first point or segment
  ///
  /// In en, this message translates to:
  /// **'Select first point or click a segment'**
  String get promptMidpointFirst;

  /// Prompt for midpoint second point
  ///
  /// In en, this message translates to:
  /// **'Select second point'**
  String get promptMidpointSecond;

  /// Prompt for perpendicular line base line
  ///
  /// In en, this message translates to:
  /// **'Select base line'**
  String get promptPerpendicularFirst;

  /// Prompt for perpendicular passing point
  ///
  /// In en, this message translates to:
  /// **'Select point on or off the line (or click canvas)'**
  String get promptPerpendicularSecond;

  /// Prompt for perpendicular bisector first point
  ///
  /// In en, this message translates to:
  /// **'Select first point or click a segment'**
  String get promptPerpBisectorFirst;

  /// Prompt for perpendicular bisector second point
  ///
  /// In en, this message translates to:
  /// **'Select second point'**
  String get promptPerpBisectorSecond;

  /// Prompt when point tool is active
  ///
  /// In en, this message translates to:
  /// **'Click anywhere inside the Poincaré disk to place a point.'**
  String get promptPoint;

  /// Prompt for ray origin point
  ///
  /// In en, this message translates to:
  /// **'Select start point'**
  String get promptRayFirst;

  /// Prompt for ray direction point
  ///
  /// In en, this message translates to:
  /// **'Select direction point'**
  String get promptRaySecond;

  /// Prompt for segment first endpoint
  ///
  /// In en, this message translates to:
  /// **'Select first endpoint'**
  String get promptSegmentFirst;

  /// Prompt for segment second endpoint
  ///
  /// In en, this message translates to:
  /// **'Select second endpoint'**
  String get promptSegmentSecond;

  /// Tooltip for redo button
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redoTooltip;

  /// Tooltip for removing a recent file entry
  ///
  /// In en, this message translates to:
  /// **'Remove from list of recent files'**
  String get removeFromRecentTooltip;

  /// Tooltip for reset view button
  ///
  /// In en, this message translates to:
  /// **'Reset View'**
  String get resetViewTooltip;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Message displayed when saving fails
  ///
  /// In en, this message translates to:
  /// **'The attempt to save failed.'**
  String get saveFailedMessage;

  /// Title of save failed error dialog
  ///
  /// In en, this message translates to:
  /// **'Save Failed'**
  String get saveFailedTitle;

  /// Title of Google Drive save tab
  ///
  /// In en, this message translates to:
  /// **'Save to Drive'**
  String get saveToDrive;

  /// Search field hint in Google Drive tab
  ///
  /// In en, this message translates to:
  /// **'Search by title or query (e.g. owner:me)...'**
  String get searchDriveHint;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Tooltip for settings gear icon
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// Tooltip for slider left decrease arrow
  ///
  /// In en, this message translates to:
  /// **'Decrease speed'**
  String get sliderDecreaseSpeedTooltip;

  /// Tooltip for slider right increase arrow
  ///
  /// In en, this message translates to:
  /// **'Increase speed'**
  String get sliderIncreaseSpeedTooltip;

  /// Tooltip for language switcher popup button
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get switchLanguageTooltip;

  /// Google Drive tab label
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get tabGoogleDrive;

  /// Local Data tab label
  ///
  /// In en, this message translates to:
  /// **'Local Data'**
  String get tabLocalData;

  /// Recent files tab label
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get tabRecent;

  /// Navigation title for Terms of Service
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Label for title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// Tooltip to toggle lock on selected item
  ///
  /// In en, this message translates to:
  /// **'Toggle Lock on Selected'**
  String get toggleLockSelectedTooltip;

  /// Navigation item for controls and sliders guide
  ///
  /// In en, this message translates to:
  /// **'Toolbar and Sliders'**
  String get toolbarAndSliders;

  /// Tool label for angle bisector
  ///
  /// In en, this message translates to:
  /// **'Angle Bisector'**
  String get toolAngleBisector;

  /// Tool label for circle
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get toolCircle;

  /// Tool label for circle by radius
  ///
  /// In en, this message translates to:
  /// **'Circle (Radius)'**
  String get toolCircleRadius;

  /// Tool label for hyperbolic compass
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get toolCompass;

  /// Tool label for equilateral triangle
  ///
  /// In en, this message translates to:
  /// **'Equilateral △'**
  String get toolEquilateralTriangle;

  /// Toolbar group label for circles
  ///
  /// In en, this message translates to:
  /// **'Circles'**
  String get toolGroupCircles;

  /// Toolbar group label for constructions
  ///
  /// In en, this message translates to:
  /// **'Construct'**
  String get toolGroupConstruct;

  /// Toolbar group label for lines
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get toolGroupLines;

  /// Toolbar group label for measurements
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get toolGroupMeasure;

  /// Toolbar group label for navigation
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get toolGroupNavigate;

  /// Tooltip for toolbar group selection button
  ///
  /// In en, this message translates to:
  /// **'{group} options'**
  String toolGroupOptionsTooltip(String group);

  /// Toolbar group label for points
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get toolGroupPoints;

  /// Tool label for intersection
  ///
  /// In en, this message translates to:
  /// **'Intersection'**
  String get toolIntersection;

  /// Tool label for line
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get toolLine;

  /// Tool label for measuring angles
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get toolMeasureAngle;

  /// Tool label for measuring distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get toolMeasureDistance;

  /// Tool label for midpoint
  ///
  /// In en, this message translates to:
  /// **'Midpoint'**
  String get toolMidpoint;

  /// Tool label for Möbius disk translation
  ///
  /// In en, this message translates to:
  /// **'Möbius Move'**
  String get toolMoveDisk;

  /// Tool label for Euclidean pan and zoom
  ///
  /// In en, this message translates to:
  /// **'Pan & Zoom'**
  String get toolPanZoom;

  /// Tool label for perpendicular line
  ///
  /// In en, this message translates to:
  /// **'Perpendicular'**
  String get toolPerpendicular;

  /// Tool label for perpendicular bisector
  ///
  /// In en, this message translates to:
  /// **'Perp. Bisector'**
  String get toolPerpendicularBisector;

  /// Tool label for point
  ///
  /// In en, this message translates to:
  /// **'Point'**
  String get toolPoint;

  /// Tool label for ray
  ///
  /// In en, this message translates to:
  /// **'Ray'**
  String get toolRay;

  /// Tool label for segment
  ///
  /// In en, this message translates to:
  /// **'Segment'**
  String get toolSegment;

  /// Tool label for select tool
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get toolSelect;

  /// Tutorial back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tutorialBack;

  /// Tooltip for closing tutorial
  ///
  /// In en, this message translates to:
  /// **'Close Tutorial'**
  String get tutorialCloseTooltip;

  /// Tutorial continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get tutorialContinue;

  /// Tutorial do it for me automated step button
  ///
  /// In en, this message translates to:
  /// **'Do it for me'**
  String get tutorialDoItForMe;

  /// Tutorial finish button
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get tutorialFinish;

  /// Tooltip to minimize tutorial widget
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get tutorialMinimizeTooltip;

  /// Tooltip to reset current tutorial step
  ///
  /// In en, this message translates to:
  /// **'Reset Step'**
  String get tutorialResetStepTooltip;

  /// Tutorial step indicator
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String tutorialStepCounter(int current, int total);

  /// Compact tutorial step indicator
  ///
  /// In en, this message translates to:
  /// **'Step {current}/{total}'**
  String tutorialStepCounterCompact(int current, int total);

  /// Label for object type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// Tooltip for undo button
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoTooltip;

  /// Tooltip to unlock an object
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockTooltip;

  /// Confirmation message when leaving unsaved drawing
  ///
  /// In en, this message translates to:
  /// **'The drawing has been modified.\nWould you like to save it?'**
  String get unsavedSceneMessage;

  /// Title of unsaved changes confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Unsaved Scene'**
  String get unsavedSceneTitle;

  /// Button to upload drawing from a local file
  ///
  /// In en, this message translates to:
  /// **'Upload from file'**
  String get uploadFromFile;

  /// Header for user guides section in help drawer
  ///
  /// In en, this message translates to:
  /// **'User Guides'**
  String get userGuidesSection;

  /// Button to validate and load edited JSON
  ///
  /// In en, this message translates to:
  /// **'Validate & Load'**
  String get validateAndLoad;

  /// Tool label for measuring point X coordinate
  ///
  /// In en, this message translates to:
  /// **'X Coordinate'**
  String get toolMeasureCoordX;

  /// Tool label for measuring point Y coordinate
  ///
  /// In en, this message translates to:
  /// **'Y Coordinate'**
  String get toolMeasureCoordY;

  /// Prompt for measuring X coordinate of a point
  ///
  /// In en, this message translates to:
  /// **'Select a point to extract its X coordinate'**
  String get promptMeasureCoordX;

  /// Prompt for measuring Y coordinate of a point
  ///
  /// In en, this message translates to:
  /// **'Select a point to extract its Y coordinate'**
  String get promptMeasureCoordY;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'lt',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'lt':
      return AppLocalizationsLt();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
