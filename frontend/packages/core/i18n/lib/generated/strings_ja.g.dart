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
	@override late final _TranslationsHomeJa home = _TranslationsHomeJa._(_root);
	@override late final _TranslationsCounterJa counter = _TranslationsCounterJa._(_root);
	@override late final _TranslationsCommonJa common = _TranslationsCommonJa._(_root);
	@override late final _TranslationsSettingsJa settings = _TranslationsSettingsJa._(_root);
	@override late final _TranslationsLanguageJa language = _TranslationsLanguageJa._(_root);
	@override late final _TranslationsGameJa game = _TranslationsGameJa._(_root);
	@override late final _TranslationsGenuiJa genui = _TranslationsGenuiJa._(_root);
	@override late final _TranslationsErrorJa error = _TranslationsErrorJa._(_root);
}

// Path: app
class _TranslationsAppJa extends TranslationsAppEn {
	_TranslationsAppJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Flutter デモ';
	@override String get name => 'Flutter ボイラープレート';
}

// Path: home
class _TranslationsHomeJa extends TranslationsHomeEn {
	_TranslationsHomeJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Flutter デモホームページ';
	@override String get message => 'ボタンを押した回数：';
}

// Path: counter
class _TranslationsCounterJa extends TranslationsCounterEn {
	_TranslationsCounterJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get increment => '増やす';
	@override String get decrement => '減らす';
	@override String get reset => 'リセット';
	@override late final _TranslationsCounterTooltipJa tooltip = _TranslationsCounterTooltipJa._(_root);
	@override String value({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n,
		zero: 'まだ押されていません',
		other: '{n}回',
	);
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

// Path: counter.tooltip
class _TranslationsCounterTooltipJa extends TranslationsCounterTooltipEn {
	_TranslationsCounterTooltipJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get increment => '増やす';
	@override String get decrement => '減らす';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Flutter デモ',
			'app.name' => 'Flutter ボイラープレート',
			'home.title' => 'Flutter デモホームページ',
			'home.message' => 'ボタンを押した回数：',
			'counter.increment' => '増やす',
			'counter.decrement' => '減らす',
			'counter.reset' => 'リセット',
			'counter.tooltip.increment' => '増やす',
			'counter.tooltip.decrement' => '減らす',
			'counter.value' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(n, zero: 'まだ押されていません', other: '{n}回', ), 
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
			'settings.title' => '設定',
			'settings.language' => '言語',
			'settings.theme' => 'テーマ',
			'settings.darkMode' => 'ダークモード',
			'settings.lightMode' => 'ライトモード',
			'settings.systemMode' => 'システム設定',
			'settings.changeLanguage' => '言語を変更',
			'language.en' => '英語',
			'language.ja' => '日本語',
			'game.title' => 'ゲーム',
			'game.start' => 'ゲーム開始',
			'game.pause' => '一時停止',
			'game.resume' => '再開',
			'game.gameOver' => 'ゲームオーバー',
			'game.score' => 'スコア: {n}',
			'game.restart' => 'リスタート',
			'game.loading' => 'ゲームを読み込み中...',
			'genui.title' => 'AIチャット',
			'genui.inputHint' => 'メッセージを入力...',
			'genui.send' => '送信',
			'genui.emptyState' => '会話を始めましょう',
			'genui.error' => 'メッセージの送信に失敗しました',
			'genui.processing' => '考え中...',
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
