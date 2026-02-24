///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsJa extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsJa _root = this; // ignore: unused_field

	@override 
	TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsJa(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppJa app = _TranslationsAppJa._(_root);
	@override late final _TranslationsCommonJa common = _TranslationsCommonJa._(_root);
	@override late final _TranslationsAuthJa auth = _TranslationsAuthJa._(_root);
	@override late final _TranslationsOnboardingJa onboarding = _TranslationsOnboardingJa._(_root);
	@override late final _TranslationsSettingsJa settings = _TranslationsSettingsJa._(_root);
	@override late final _TranslationsLanguageJa language = _TranslationsLanguageJa._(_root);
	@override late final _TranslationsScenarioListJa scenarioList = _TranslationsScenarioListJa._(_root);
	@override late final _TranslationsScenarioDetailJa scenarioDetail = _TranslationsScenarioDetailJa._(_root);
	@override late final _TranslationsGameJa game = _TranslationsGameJa._(_root);
	@override late final _TranslationsGenuiJa genui = _TranslationsGenuiJa._(_root);
	@override late final _TranslationsTrpgJa trpg = _TranslationsTrpgJa._(_root);
	@override late final _TranslationsGameMenuJa gameMenu = _TranslationsGameMenuJa._(_root);
	@override late final _TranslationsErrorJa error = _TranslationsErrorJa._(_root);
}

// Path: app
class _TranslationsAppJa extends TranslationsAppEn {
	_TranslationsAppJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ゲームサービス';
	@override String get name => 'ゲームサービス';
}

// Path: common
class _TranslationsCommonJa extends TranslationsCommonEn {
	_TranslationsCommonJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get save => '保存';
	@override String get cancel => 'キャンセル';
	@override String get delete => '削除';
	@override String get edit => '編集';
	@override String get confirm => '確認';
	@override String get loading => '読み込み中...';
	@override String get error => 'エラー';
	@override String get success => '成功';
	@override String get warning => '警告';
	@override String get info => '情報';
	@override String get yes => 'はい';
	@override String get no => 'いいえ';
	@override String get ok => 'OK';
	@override String get close => '閉じる';
	@override String get back => '戻る';
	@override String get next => '次へ';
	@override String get finish => '完了';
	@override String get submit => '送信';
	@override String get search => '検索';
	@override String get clear => 'クリア';
	@override String get refresh => '更新';
	@override String get retry => '再試行';
}

// Path: auth
class _TranslationsAuthJa extends TranslationsAuthEn {
	_TranslationsAuthJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get login => 'ログイン';
	@override String get loginWithEmail => 'メールアドレスでログイン';
	@override String get loginDescription => 'メールアドレスを入力すると、認証コードをお送りします';
	@override String get sendCode => '認証コードを送信';
	@override String get backToHome => 'ホームに戻る';
	@override String get verifyCode => '認証コード確認';
	@override String get enterCode => '認証コードを入力';
	@override String enterCodeDescription({required Object email}) => '${email} に送信された認証コードを入力してください';
	@override String get loginButton => 'ログイン';
	@override String get resendCode => '認証コードを再送信';
	@override String get changeEmail => 'メールアドレスを変更';
	@override String codeSent({required Object email}) => '${email} に認証コードを送信しました';
	@override String codeResent({required Object email}) => '${email} に認証コードを再送信しました';
	@override String get loginSuccess => 'ログインしました';
}

// Path: onboarding
class _TranslationsOnboardingJa extends TranslationsOnboardingEn {
	_TranslationsOnboardingJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'プロフィール設定';
	@override String get description => 'ユニークなアカウント名を設定してはじめましょう';
	@override String get accountName => 'アカウント名';
	@override String get accountNameHint => '例: alice_smith';
	@override String get accountNameHelper => '3〜20文字、小文字英数字とアンダースコアのみ';
	@override String get displayName => '表示名';
	@override String get displayNameHint => '例: Alice Smith';
	@override String get displayNameHelper => '任意。他のユーザーに表示される名前です';
	@override String get complete => '設定を完了';
	@override String get completing => '設定中...';
	@override String get accountNameRequired => 'アカウント名は必須です';
	@override String get accountNameTooShort => '3文字以上で入力してください';
	@override String get accountNameTooLong => '20文字以内で入力してください';
	@override String get accountNameInvalidFormat => '小文字英数字とアンダースコアのみ使用できます';
	@override String get accountNameTemporary => 'アカウント名を設定してください';
	@override String get accountNameTaken => 'このアカウント名は既に使用されています';
	@override String get success => 'プロフィール設定が完了しました！';
}

// Path: settings
class _TranslationsSettingsJa extends TranslationsSettingsEn {
	_TranslationsSettingsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '設定';
	@override String get language => '言語';
	@override String get theme => 'テーマ';
	@override String get darkMode => 'ダークモード';
	@override String get lightMode => 'ライトモード';
	@override String get systemMode => 'システム設定';
	@override String get changeLanguage => '言語を変更';
}

// Path: language
class _TranslationsLanguageJa extends TranslationsLanguageEn {
	_TranslationsLanguageJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get en => '英語';
	@override String get ja => '日本語';
}

// Path: scenarioList
class _TranslationsScenarioListJa extends TranslationsScenarioListEn {
	_TranslationsScenarioListJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ゲーム一覧';
	@override String get empty => 'まだゲームがありません';
	@override String get emptyDescription => '新しいシナリオが追加されるまでお待ちください';
	@override String get error => 'ゲームの読み込みに失敗しました';
	@override String get logout => 'ログアウト';
}

// Path: scenarioDetail
class _TranslationsScenarioDetailJa extends TranslationsScenarioDetailEn {
	_TranslationsScenarioDetailJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get play => 'プレイする';
	@override String get startingGame => 'ゲームを開始中...';
	@override String get startError => 'ゲームの開始に失敗しました';
	@override String get description => '説明';
}

// Path: game
class _TranslationsGameJa extends TranslationsGameEn {
	_TranslationsGameJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ゲーム';
	@override String get start => 'ゲーム開始';
	@override String get pause => '一時停止';
	@override String get resume => '再開';
	@override String get gameOver => 'ゲームオーバー';
	@override String get score => 'スコア: {n}';
	@override String get restart => 'リスタート';
	@override String get loading => 'ゲームを読み込み中...';
	@override String get backToList => 'ゲーム一覧に戻る';
}

// Path: genui
class _TranslationsGenuiJa extends TranslationsGenuiEn {
	_TranslationsGenuiJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'AIチャット';
	@override String get inputHint => 'メッセージを入力...';
	@override String get send => '送信';
	@override String get emptyState => '会話を始めましょう';
	@override String get error => 'メッセージの送信に失敗しました';
	@override String get processing => '考え中...';
}

// Path: trpg
class _TranslationsTrpgJa extends TranslationsTrpgEn {
	_TranslationsTrpgJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get chooseAction => '行動を選択してください';
	@override String get freeInput => 'または自由に行動を記述...';
	@override String get clarifyTitle => 'GMから確認があります';
	@override String get clarifyHint => '回答を入力...';
	@override String get repairTitle => '矛盾が検出されました';
	@override String repairContradiction({required Object text}) => '問題: ${text}';
	@override String repairFix({required Object text}) => '修正案: ${text}';
	@override String get repairAccept => '修正を受け入れる';
	@override String get repairReject => '拒否する';
	@override String get continueButton => '続ける';
	@override String get inputHint => '何をしますか？';
	@override String get send => '送信';
	@override String get emptyState => '冒険が始まります...';
	@override String get processing => 'GMが考えています...';
	@override String get tapToContinue => 'タップして続ける';
	@override String get narrator => 'ナレーター';
	@override String get messageLog => 'メッセージログ';
	@override String turnSeparator({required Object n}) => 'ターン ${n}';
	@override String get you => 'あなた';
	@override String get gm => 'GM';
}

// Path: gameMenu
class _TranslationsGameMenuJa extends TranslationsGameMenuEn {
	_TranslationsGameMenuJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get newGame => 'スタート';
	@override String get loadGame => 'ロード';
	@override String get backToTitle => 'もどる';
	@override String get savedSessions => 'セーブデータ';
	@override String get noData => 'NO DATA';
	@override String get noSavedSessions => 'セーブデータがありません';
	@override String turnNumber({required Object n}) => 'ターン ${n}';
	@override String lastPlayed({required Object time}) => '${time}';
}

// Path: error
class _TranslationsErrorJa extends TranslationsErrorEn {
	_TranslationsErrorJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get generic => 'エラーが発生しました';
	@override String get network => 'ネットワークエラー';
	@override String get notFound => '見つかりません';
	@override String get unauthorized => '認証エラー';
	@override String get forbidden => 'アクセス拒否';
	@override String get serverError => 'サーバーエラー';
	@override String get timeout => 'タイムアウト';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'ゲームサービス',
			'app.name' => 'ゲームサービス',
			'common.save' => '保存',
			'common.cancel' => 'キャンセル',
			'common.delete' => '削除',
			'common.edit' => '編集',
			'common.confirm' => '確認',
			'common.loading' => '読み込み中...',
			'common.error' => 'エラー',
			'common.success' => '成功',
			'common.warning' => '警告',
			'common.info' => '情報',
			'common.yes' => 'はい',
			'common.no' => 'いいえ',
			'common.ok' => 'OK',
			'common.close' => '閉じる',
			'common.back' => '戻る',
			'common.next' => '次へ',
			'common.finish' => '完了',
			'common.submit' => '送信',
			'common.search' => '検索',
			'common.clear' => 'クリア',
			'common.refresh' => '更新',
			'common.retry' => '再試行',
			'auth.login' => 'ログイン',
			'auth.loginWithEmail' => 'メールアドレスでログイン',
			'auth.loginDescription' => 'メールアドレスを入力すると、認証コードをお送りします',
			'auth.sendCode' => '認証コードを送信',
			'auth.backToHome' => 'ホームに戻る',
			'auth.verifyCode' => '認証コード確認',
			'auth.enterCode' => '認証コードを入力',
			'auth.enterCodeDescription' => ({required Object email}) => '${email} に送信された認証コードを入力してください',
			'auth.loginButton' => 'ログイン',
			'auth.resendCode' => '認証コードを再送信',
			'auth.changeEmail' => 'メールアドレスを変更',
			'auth.codeSent' => ({required Object email}) => '${email} に認証コードを送信しました',
			'auth.codeResent' => ({required Object email}) => '${email} に認証コードを再送信しました',
			'auth.loginSuccess' => 'ログインしました',
			'onboarding.title' => 'プロフィール設定',
			'onboarding.description' => 'ユニークなアカウント名を設定してはじめましょう',
			'onboarding.accountName' => 'アカウント名',
			'onboarding.accountNameHint' => '例: alice_smith',
			'onboarding.accountNameHelper' => '3〜20文字、小文字英数字とアンダースコアのみ',
			'onboarding.displayName' => '表示名',
			'onboarding.displayNameHint' => '例: Alice Smith',
			'onboarding.displayNameHelper' => '任意。他のユーザーに表示される名前です',
			'onboarding.complete' => '設定を完了',
			'onboarding.completing' => '設定中...',
			'onboarding.accountNameRequired' => 'アカウント名は必須です',
			'onboarding.accountNameTooShort' => '3文字以上で入力してください',
			'onboarding.accountNameTooLong' => '20文字以内で入力してください',
			'onboarding.accountNameInvalidFormat' => '小文字英数字とアンダースコアのみ使用できます',
			'onboarding.accountNameTemporary' => 'アカウント名を設定してください',
			'onboarding.accountNameTaken' => 'このアカウント名は既に使用されています',
			'onboarding.success' => 'プロフィール設定が完了しました！',
			'settings.title' => '設定',
			'settings.language' => '言語',
			'settings.theme' => 'テーマ',
			'settings.darkMode' => 'ダークモード',
			'settings.lightMode' => 'ライトモード',
			'settings.systemMode' => 'システム設定',
			'settings.changeLanguage' => '言語を変更',
			'language.en' => '英語',
			'language.ja' => '日本語',
			'scenarioList.title' => 'ゲーム一覧',
			'scenarioList.empty' => 'まだゲームがありません',
			'scenarioList.emptyDescription' => '新しいシナリオが追加されるまでお待ちください',
			'scenarioList.error' => 'ゲームの読み込みに失敗しました',
			'scenarioList.logout' => 'ログアウト',
			'scenarioDetail.play' => 'プレイする',
			'scenarioDetail.startingGame' => 'ゲームを開始中...',
			'scenarioDetail.startError' => 'ゲームの開始に失敗しました',
			'scenarioDetail.description' => '説明',
			'game.title' => 'ゲーム',
			'game.start' => 'ゲーム開始',
			'game.pause' => '一時停止',
			'game.resume' => '再開',
			'game.gameOver' => 'ゲームオーバー',
			'game.score' => 'スコア: {n}',
			'game.restart' => 'リスタート',
			'game.loading' => 'ゲームを読み込み中...',
			'game.backToList' => 'ゲーム一覧に戻る',
			'genui.title' => 'AIチャット',
			'genui.inputHint' => 'メッセージを入力...',
			'genui.send' => '送信',
			'genui.emptyState' => '会話を始めましょう',
			'genui.error' => 'メッセージの送信に失敗しました',
			'genui.processing' => '考え中...',
			'trpg.chooseAction' => '行動を選択してください',
			'trpg.freeInput' => 'または自由に行動を記述...',
			'trpg.clarifyTitle' => 'GMから確認があります',
			'trpg.clarifyHint' => '回答を入力...',
			'trpg.repairTitle' => '矛盾が検出されました',
			'trpg.repairContradiction' => ({required Object text}) => '問題: ${text}',
			'trpg.repairFix' => ({required Object text}) => '修正案: ${text}',
			'trpg.repairAccept' => '修正を受け入れる',
			'trpg.repairReject' => '拒否する',
			'trpg.continueButton' => '続ける',
			'trpg.inputHint' => '何をしますか？',
			'trpg.send' => '送信',
			'trpg.emptyState' => '冒険が始まります...',
			'trpg.processing' => 'GMが考えています...',
			'trpg.tapToContinue' => 'タップして続ける',
			'trpg.narrator' => 'ナレーター',
			'trpg.messageLog' => 'メッセージログ',
			'trpg.turnSeparator' => ({required Object n}) => 'ターン ${n}',
			'trpg.you' => 'あなた',
			'trpg.gm' => 'GM',
			'gameMenu.newGame' => 'スタート',
			'gameMenu.loadGame' => 'ロード',
			'gameMenu.backToTitle' => 'もどる',
			'gameMenu.savedSessions' => 'セーブデータ',
			'gameMenu.noData' => 'NO DATA',
			'gameMenu.noSavedSessions' => 'セーブデータがありません',
			'gameMenu.turnNumber' => ({required Object n}) => 'ターン ${n}',
			'gameMenu.lastPlayed' => ({required Object time}) => '${time}',
			'error.generic' => 'エラーが発生しました',
			'error.network' => 'ネットワークエラー',
			'error.notFound' => '見つかりません',
			'error.unauthorized' => '認証エラー',
			'error.forbidden' => 'アクセス拒否',
			'error.serverError' => 'サーバーエラー',
			'error.timeout' => 'タイムアウト',
			_ => null,
		};
	}
}
