// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get aboutHyperbolic => 'Hyperbolic について';

  @override
  String get addFreeParameterTooltip => '自由パラメータを追加';

  @override
  String get appTitle => '双曲幾何作図ツール';

  @override
  String get appVersion => 'Hyperbolic v2.0.0+5 について';

  @override
  String get cancel => 'キャンセル';

  @override
  String get chooseAFile => 'ファイルを選択';

  @override
  String get clearCacheAndReload => 'キャッシュを消去して再読み込み';

  @override
  String get closeTooltip => '閉じる';

  @override
  String get colorForNewObjectsTooltip => '新規オブジェクトの色';

  @override
  String get confirmPropertiesTitle => '保存前にプロパティを確認';

  @override
  String get copyAsUrl => 'URLとしてコピー';

  @override
  String get delete => '削除';

  @override
  String get deleteLocalFileTooltip => 'ローカルファイルを削除';

  @override
  String get deleteParameterTooltip => 'パラメータを削除';

  @override
  String get deleteSelectedTooltip => '選択項目を削除';

  @override
  String get descriptionLabel => '説明';

  @override
  String get deselectTooltip => '選択解除';

  @override
  String get discard => '破棄';

  @override
  String get done => '完了';

  @override
  String get downloadToFile => 'ファイルにダウンロード';

  @override
  String get drawingTitleLabel => '作図タイトル';

  @override
  String get editDescription => '説明を編集';

  @override
  String get editJsonSyntaxSubtitle =>
      '以下の構文や構造のエラーを修正し、「検証して読み込む」をクリックしてください。';

  @override
  String get editJsonSyntaxTitle => 'JSON構文の編集';

  @override
  String get editPropertiesTitle => 'プロパティの編集';

  @override
  String get enterValidJsonHint => '有効な作図JSON構文を入力...';

  @override
  String get errorLoadingFile => 'ファイル読み込みエラー';

  @override
  String get expandErrorDetails => 'エラー詳細を展開';

  @override
  String failedToLoadFile(String name) {
    return '$name の読み込みに失敗しました';
  }

  @override
  String get fileManagement => 'ファイル管理';

  @override
  String get helpAndDocs => 'ヘルプとドキュメント';

  @override
  String get helpAndGuidesTooltip => 'ヘルプとガイド';

  @override
  String get helpControlsGuide => '操作・ツールガイド';

  @override
  String get helpDeveloperDocs => '開発者向けドキュメント';

  @override
  String get helpMenu => 'ヘルプメニュー';

  @override
  String get helpObjectsGuide => '幾何オブジェクトガイド';

  @override
  String get helpOverview => 'ヘルプ概要';

  @override
  String get hyperbolicGeometry => '双曲幾何学';

  @override
  String get hyperbolicObjects => '双曲幾何オブジェクト';

  @override
  String get initializingApp => 'アプリを初期化中...';

  @override
  String get initializingSettings => '設定を読み込み中...';

  @override
  String get languageAuto => '自動 (システム)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get legacyFileFormatMessage => 'このファイルは旧形式です。保存時に自動的に変換されます。';

  @override
  String get legacyFileFormatTitle => '旧ファイル形式';

  @override
  String loadingFile(String name) {
    return '$name を読み込み中...';
  }

  @override
  String get loadFromDrive => 'Google ドライブから読み込む';

  @override
  String get lockTooltip => 'ロック';

  @override
  String get menuCloseMenu => 'メニューを閉じる';

  @override
  String get menuCopy => 'コピー';

  @override
  String get menuCut => '切り取り';

  @override
  String get menuDelete => '削除';

  @override
  String get menuEdit => '編集';

  @override
  String get menuFile => 'ファイル';

  @override
  String get menuLogOut => 'ログアウト';

  @override
  String get menuNew => '新規';

  @override
  String get menuOpen => '開く';

  @override
  String get menuPaste => '貼り付け';

  @override
  String get menuRedo => 'やり直し';

  @override
  String get menuReload => '再読み込み';

  @override
  String get menuResetMobius => 'メビウス変換をリセット';

  @override
  String get menuResetView => 'ビューをリセット';

  @override
  String get menuSave => '保存';

  @override
  String get menuSaveAs => '名前を付けて保存';

  @override
  String get menuShare => '共有';

  @override
  String get menuToggleAxes => '軸の表示切替';

  @override
  String get menuTutorials => 'チュートリアル';

  @override
  String get menuUndo => '元に戻す';

  @override
  String get menuView => '表示';

  @override
  String get nameDrawingPrompt => '保存する前に作図のタイトルを入力してください：';

  @override
  String get nameLabel => '名前';

  @override
  String get nameYourDrawing => '作図に名前を付ける';

  @override
  String get newDiagram => '新規図面';

  @override
  String get newFile => '新規ファイル';

  @override
  String get newLocalFile => '新規ローカルファイル';

  @override
  String get noParametersMessage =>
      'シーンに数値オブジェクトがありません。\n+ をクリックして自由パラメータを追加するか、\nツールバーの測定ツールを使用してください。';

  @override
  String get ok => 'OK';

  @override
  String get openDrawerTooltip => 'メニューを開く';

  @override
  String get overview => '概要';

  @override
  String get parametersTitle => 'パラメータ';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get promptAngleBisectorFirst => '半直線1上の最初の点を選択';

  @override
  String get promptAngleBisectorSecond => '半直線2上の点を選択';

  @override
  String get promptAngleBisectorVertex => '角の頂点を選択';

  @override
  String get promptCircleCenter => '中心点を選択（またはキャンバスをクリック）';

  @override
  String get promptCircleCircumference => '円周上の点を選択（またはキャンバスをクリック）';

  @override
  String get promptCircleRadiusNumber => 'パネル内の半径数値オブジェクトを選択';

  @override
  String get promptCompassCenter => 'コンパス円の中心点を選択';

  @override
  String get promptCompassFirst => '半径線分の最初の点を選択';

  @override
  String get promptCompassSecond => '半径線分の2番目の点を選択';

  @override
  String get promptEquilateralFirst => '底辺の最初の頂点を選択（またはクリック）';

  @override
  String get promptEquilateralSecond => '底辺の2番目の頂点を選択（またはクリック）';

  @override
  String get promptIntersectionFirst => '1本目の直線または円を選択';

  @override
  String get promptIntersectionSecond => '2本目の直線または円を選択';

  @override
  String get promptLineFirst => '最初の点を選択（またはキャンバスをクリック）';

  @override
  String get promptLineSecond => '2番目の点を選択（またはキャンバスをクリック）';

  @override
  String get promptMeasureAngleFirst => '第1辺上の点を選択';

  @override
  String get promptMeasureAngleSecond => '第2辺上の点を選択';

  @override
  String get promptMeasureAngleVertex => '角の頂点を選択';

  @override
  String get promptMeasureDistFirst => '最初の点を選択';

  @override
  String get promptMeasureDistSecond => '2番目の点を選択';

  @override
  String get promptMidpointFirst => '最初の点を選択するか線分をクリック';

  @override
  String get promptMidpointSecond => '2番目の点を選択';

  @override
  String get promptPerpendicularFirst => '基準となる直線を選択';

  @override
  String get promptPerpendicularSecond => '直線上または外側の点を選択（またはクリック）';

  @override
  String get promptPerpBisectorFirst => '最初の点を選択するか線分をクリック';

  @override
  String get promptPerpBisectorSecond => '2番目の点を選択';

  @override
  String get promptPoint => 'ポアンカレ円盤内をクリックして点を配置します。';

  @override
  String get promptRayFirst => '始点を選択';

  @override
  String get promptRaySecond => '方向点を選択';

  @override
  String get promptSegmentFirst => '最初の端点を選択';

  @override
  String get promptSegmentSecond => '2番目の端点を選択';

  @override
  String get redoTooltip => 'やり直し';

  @override
  String get removeFromRecentTooltip => '最近使用した項目から削除';

  @override
  String get resetViewTooltip => 'ビューをリセット';

  @override
  String get retry => '再試行';

  @override
  String get save => '保存';

  @override
  String get saveFailedMessage => '保存処理に失敗しました。';

  @override
  String get saveFailedTitle => '保存失敗';

  @override
  String get saveToDrive => 'ドライブに保存';

  @override
  String get searchDriveHint => 'タイトルで検索 (例: owner:me)...';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsTooltip => '設定';

  @override
  String get sliderDecreaseSpeedTooltip => '速度を下げる';

  @override
  String get sliderIncreaseSpeedTooltip => '速度を上げる';

  @override
  String get switchLanguageTooltip => '言語を切り替え';

  @override
  String get tabGoogleDrive => 'Google ドライブ';

  @override
  String get tabLocalData => 'ローカルデータ';

  @override
  String get tabRecent => '最近使った項目';

  @override
  String get termsOfService => '利用規約';

  @override
  String get titleLabel => 'タイトル';

  @override
  String get toggleLockSelectedTooltip => '選択項目のロック切替';

  @override
  String get toolbarAndSliders => 'ツールバーとスライダー';

  @override
  String get toolAngleBisector => '角の二等分線';

  @override
  String get toolCircle => '円';

  @override
  String get toolCircleRadius => '円 (半径指定)';

  @override
  String get toolCompass => 'コンパス';

  @override
  String get toolEquilateralTriangle => '正三角形';

  @override
  String get toolGroupCircles => '円';

  @override
  String get toolGroupConstruct => '作図';

  @override
  String get toolGroupLines => '直線';

  @override
  String get toolGroupMeasure => '測定';

  @override
  String get toolGroupNavigate => 'ナビゲート';

  @override
  String toolGroupOptionsTooltip(String group) {
    return '$group のオプション';
  }

  @override
  String get toolGroupPoints => '点';

  @override
  String get toolIntersection => '交点';

  @override
  String get toolLine => '直線';

  @override
  String get toolMeasureAngle => '角度';

  @override
  String get toolMeasureDistance => '距離';

  @override
  String get toolMidpoint => '中点';

  @override
  String get toolMoveDisk => 'メビウス移動';

  @override
  String get toolPanZoom => '移動と拡大縮小';

  @override
  String get toolPerpendicular => '垂線';

  @override
  String get toolPerpendicularBisector => '垂直二等分線';

  @override
  String get toolPoint => '点';

  @override
  String get toolRay => '半直線';

  @override
  String get toolSegment => '線分';

  @override
  String get toolSelect => '選択';

  @override
  String get tutorialBack => '戻る';

  @override
  String get tutorialCloseTooltip => 'チュートリアルを閉じる';

  @override
  String get tutorialContinue => '続ける';

  @override
  String get tutorialDoItForMe => '代わりに実行';

  @override
  String get tutorialFinish => '完了';

  @override
  String get tutorialMinimizeTooltip => '最小化';

  @override
  String get tutorialResetStepTooltip => 'ステップをリセット';

  @override
  String tutorialStepCounter(int current, int total) {
    return 'ステップ $current / $total';
  }

  @override
  String tutorialStepCounterCompact(int current, int total) {
    return 'ステップ $current/$total';
  }

  @override
  String get typeLabel => '種類';

  @override
  String get undoTooltip => '元に戻す';

  @override
  String get unlockTooltip => 'ロック解除';

  @override
  String get unsavedSceneMessage => '作図が変更されています。\n保存しますか？';

  @override
  String get unsavedSceneTitle => '未保存の図面';

  @override
  String get uploadFromFile => 'ファイルから読み込む';

  @override
  String get userGuidesSection => 'ユーザーガイド';

  @override
  String get validateAndLoad => '検証して読み込む';

  @override
  String get toolMeasureCoordX => 'X 座標';

  @override
  String get toolMeasureCoordY => 'Y 座標';

  @override
  String get promptMeasureCoordX => '点を選択して X 座標を取得';

  @override
  String get promptMeasureCoordY => '点を選択して Y 座標を取得';
}
