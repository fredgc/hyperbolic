// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutHyperbolic => 'About Hyperbolic';

  @override
  String get addFreeParameterTooltip => 'Add Free Parameter';

  @override
  String get appTitle => 'Hyperbolic Geometry Drawing Tool';

  @override
  String get appVersion => 'About Hyperbolic v2.0.0+5';

  @override
  String get cancel => 'Cancel';

  @override
  String get chooseAFile => 'Choose a File';

  @override
  String get clearCacheAndReload => 'Clear Cache & Reload App';

  @override
  String get closeTooltip => 'Close';

  @override
  String get colorForNewObjectsTooltip => 'Color for New Objects';

  @override
  String get confirmPropertiesTitle => 'Confirm Properties Before Saving';

  @override
  String get copyAsUrl => 'Copy as URL';

  @override
  String get delete => 'Delete';

  @override
  String get deleteLocalFileTooltip => 'Delete local file';

  @override
  String get deleteParameterTooltip => 'Delete parameter';

  @override
  String get deleteSelectedTooltip => 'Delete Selected';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get deselectTooltip => 'Deselect';

  @override
  String get discard => 'Discard';

  @override
  String get done => 'Done';

  @override
  String get downloadToFile => 'Download to file';

  @override
  String get drawingTitleLabel => 'Drawing Title';

  @override
  String get editDescription => 'Edit Description';

  @override
  String get editJsonSyntaxSubtitle =>
      'Correct syntax or structure errors below and click Validate & Load.';

  @override
  String get editJsonSyntaxTitle => 'Edit JSON Syntax';

  @override
  String get editPropertiesTitle => 'Edit Properties';

  @override
  String get enterValidJsonHint => 'Enter valid JSON drawing syntax...';

  @override
  String get errorLoadingFile => 'Error Loading File';

  @override
  String get expandErrorDetails => 'Expand Error Details';

  @override
  String failedToLoadFile(String name) {
    return 'Failed to load $name';
  }

  @override
  String get fileManagement => 'File Management';

  @override
  String get helpAndDocs => 'Help & Docs';

  @override
  String get helpAndGuidesTooltip => 'Help & Guides';

  @override
  String get helpControlsGuide => 'Controls & Tools Guide';

  @override
  String get helpDeveloperDocs => 'Developer Docs';

  @override
  String get helpMenu => 'Help Menu';

  @override
  String get helpObjectsGuide => 'Geometric Objects Guide';

  @override
  String get helpOverview => 'Help Overview';

  @override
  String get hyperbolicGeometry => 'Hyperbolic Geometry';

  @override
  String get hyperbolicObjects => 'Hyperbolic Objects';

  @override
  String get initializingApp => 'Initializing App...';

  @override
  String get initializingSettings => 'Initializing Settings...';

  @override
  String get languageAuto => 'Auto';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get legacyFileFormatMessage =>
      'This file is in an older hyperbolic format. It will be automatically upgraded when saved.';

  @override
  String get legacyFileFormatTitle => 'Legacy File Format';

  @override
  String loadingFile(String name) {
    return 'Loading $name...';
  }

  @override
  String get loadFromDrive => 'Load from Drive';

  @override
  String get lockTooltip => 'Lock';

  @override
  String get menuCloseMenu => 'Close Menu';

  @override
  String get menuCopy => 'Copy';

  @override
  String get menuCut => 'Cut';

  @override
  String get menuDelete => 'Delete';

  @override
  String get menuEdit => 'Edit';

  @override
  String get menuFile => 'File';

  @override
  String get menuLogOut => 'Log Out';

  @override
  String get menuNew => 'New';

  @override
  String get menuOpen => 'Open';

  @override
  String get menuPaste => 'Paste';

  @override
  String get menuRedo => 'Redo';

  @override
  String get menuReload => 'Reload';

  @override
  String get menuResetMobius => 'Reset Möbius Translation';

  @override
  String get menuResetView => 'Reset View';

  @override
  String get menuSave => 'Save';

  @override
  String get menuSaveAs => 'Save As';

  @override
  String get menuShare => 'Share';

  @override
  String get menuToggleAxes => 'Toggle Axes';

  @override
  String get menuTutorials => 'Tutorials';

  @override
  String get menuUndo => 'Undo';

  @override
  String get menuView => 'View';

  @override
  String get nameDrawingPrompt => 'Give your drawing a title before saving:';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameYourDrawing => 'Name Your Drawing';

  @override
  String get newDiagram => 'New Diagram';

  @override
  String get newFile => 'New File';

  @override
  String get newLocalFile => 'New Local File';

  @override
  String get noParametersMessage =>
      'No number objects in scene.\nClick + to add a free parameter or\nuse Measurement tools on canvas.';

  @override
  String get ok => 'OK';

  @override
  String get openDrawerTooltip => 'Open Menu';

  @override
  String get overview => 'Overview';

  @override
  String get parametersTitle => 'Parameters';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get promptAngleBisectorFirst => 'Select first point on ray 1';

  @override
  String get promptAngleBisectorSecond => 'Select point on ray 2';

  @override
  String get promptAngleBisectorVertex => 'Select angle vertex point';

  @override
  String get promptCircleCenter => 'Select center point (or click canvas)';

  @override
  String get promptCircleCircumference =>
      'Select point on circumference (or click canvas)';

  @override
  String get promptCircleRadiusNumber =>
      'Select a radius Number object in the panel';

  @override
  String get promptCompassCenter =>
      'Select center point for the compass circle';

  @override
  String get promptCompassFirst => 'Select first point of radius segment';

  @override
  String get promptCompassSecond => 'Select second point of radius segment';

  @override
  String get promptEquilateralFirst =>
      'Select first base vertex point (or click canvas)';

  @override
  String get promptEquilateralSecond =>
      'Select second base vertex point (or click canvas)';

  @override
  String get promptIntersectionFirst => 'Select first line or circle';

  @override
  String get promptIntersectionSecond => 'Select second line or circle';

  @override
  String get promptLineFirst =>
      'Select first point (or click canvas to place one)';

  @override
  String get promptLineSecond =>
      'Select second point (or click canvas to place one)';

  @override
  String get promptMeasureAngleFirst => 'Select first point on first leg';

  @override
  String get promptMeasureAngleSecond => 'Select point on second leg';

  @override
  String get promptMeasureAngleVertex => 'Select vertex point';

  @override
  String get promptMeasureDistFirst => 'Select first point';

  @override
  String get promptMeasureDistSecond => 'Select second point';

  @override
  String get promptMidpointFirst => 'Select first point or click a segment';

  @override
  String get promptMidpointSecond => 'Select second point';

  @override
  String get promptPerpendicularFirst => 'Select base line';

  @override
  String get promptPerpendicularSecond =>
      'Select point on or off the line (or click canvas)';

  @override
  String get promptPerpBisectorFirst => 'Select first point or click a segment';

  @override
  String get promptPerpBisectorSecond => 'Select second point';

  @override
  String get promptPoint =>
      'Click anywhere inside the Poincaré disk to place a point.';

  @override
  String get promptRayFirst => 'Select start point';

  @override
  String get promptRaySecond => 'Select direction point';

  @override
  String get promptSegmentFirst => 'Select first endpoint';

  @override
  String get promptSegmentSecond => 'Select second endpoint';

  @override
  String get redoTooltip => 'Redo';

  @override
  String get removeFromRecentTooltip => 'Remove from list of recent files';

  @override
  String get resetViewTooltip => 'Reset View';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get saveFailedMessage => 'The attempt to save failed.';

  @override
  String get saveFailedTitle => 'Save Failed';

  @override
  String get saveToDrive => 'Save to Drive';

  @override
  String get searchDriveHint => 'Search by title or query (e.g. owner:me)...';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get sliderDecreaseSpeedTooltip => 'Decrease speed';

  @override
  String get sliderIncreaseSpeedTooltip => 'Increase speed';

  @override
  String get switchLanguageTooltip => 'Switch Language';

  @override
  String get tabGoogleDrive => 'Google Drive';

  @override
  String get tabLocalData => 'Local Data';

  @override
  String get tabRecent => 'Recent';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get titleLabel => 'Title';

  @override
  String get toggleLockSelectedTooltip => 'Toggle Lock on Selected';

  @override
  String get toolbarAndSliders => 'Toolbar and Sliders';

  @override
  String get toolAngleBisector => 'Angle Bisector';

  @override
  String get toolCircle => 'Circle';

  @override
  String get toolCircleRadius => 'Circle (Radius)';

  @override
  String get toolCompass => 'Compass';

  @override
  String get toolEquilateralTriangle => 'Equilateral △';

  @override
  String get toolGroupCircles => 'Circles';

  @override
  String get toolGroupConstruct => 'Construct';

  @override
  String get toolGroupLines => 'Lines';

  @override
  String get toolGroupMeasure => 'Measure';

  @override
  String get toolGroupNavigate => 'Navigate';

  @override
  String toolGroupOptionsTooltip(String group) {
    return '$group options';
  }

  @override
  String get toolGroupPoints => 'Points';

  @override
  String get toolIntersection => 'Intersection';

  @override
  String get toolLine => 'Line';

  @override
  String get toolMeasureAngle => 'Angle';

  @override
  String get toolMeasureDistance => 'Distance';

  @override
  String get toolMidpoint => 'Midpoint';

  @override
  String get toolMoveDisk => 'Möbius Move';

  @override
  String get toolPanZoom => 'Pan & Zoom';

  @override
  String get toolPerpendicular => 'Perpendicular';

  @override
  String get toolPerpendicularBisector => 'Perp. Bisector';

  @override
  String get toolPoint => 'Point';

  @override
  String get toolRay => 'Ray';

  @override
  String get toolSegment => 'Segment';

  @override
  String get toolSelect => 'Select';

  @override
  String get tutorialBack => 'Back';

  @override
  String get tutorialCloseTooltip => 'Close Tutorial';

  @override
  String get tutorialContinue => 'Continue';

  @override
  String get tutorialDoItForMe => 'Do it for me';

  @override
  String get tutorialFinish => 'Finish';

  @override
  String get tutorialMinimizeTooltip => 'Minimize';

  @override
  String get tutorialResetStepTooltip => 'Reset Step';

  @override
  String tutorialStepCounter(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String tutorialStepCounterCompact(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String get typeLabel => 'Type';

  @override
  String get undoTooltip => 'Undo';

  @override
  String get unlockTooltip => 'Unlock';

  @override
  String get unsavedSceneMessage =>
      'The drawing has been modified.\nWould you like to save it?';

  @override
  String get unsavedSceneTitle => 'Unsaved Scene';

  @override
  String get uploadFromFile => 'Upload from file';

  @override
  String get userGuidesSection => 'User Guides';

  @override
  String get validateAndLoad => 'Validate & Load';

  @override
  String get toolMeasureCoordX => 'X Coordinate';

  @override
  String get toolMeasureCoordY => 'Y Coordinate';

  @override
  String get promptMeasureCoordX =>
      'Select a point to extract its X coordinate';

  @override
  String get promptMeasureCoordY =>
      'Select a point to extract its Y coordinate';
}
