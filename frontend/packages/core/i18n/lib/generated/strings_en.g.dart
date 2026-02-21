///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final TranslationsAppEn app = TranslationsAppEn.internal(_root);
	late final TranslationsHomeEn home = TranslationsHomeEn.internal(_root);
	late final TranslationsCounterEn counter = TranslationsCounterEn.internal(_root);
	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
	late final TranslationsSettingsEn settings = TranslationsSettingsEn.internal(_root);
	late final TranslationsLanguageEn language = TranslationsLanguageEn.internal(_root);
	late final TranslationsGameEn game = TranslationsGameEn.internal(_root);
	late final TranslationsGenuiEn genui = TranslationsGenuiEn.internal(_root);
	late final TranslationsErrorEn error = TranslationsErrorEn.internal(_root);
}

// Path: app
class TranslationsAppEn {
	TranslationsAppEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Flutter Demo'
	String get title => 'Flutter Demo';

	/// en: 'Flutter Boilerplate'
	String get name => 'Flutter Boilerplate';
}

// Path: home
class TranslationsHomeEn {
	TranslationsHomeEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Flutter Demo Home Page'
	String get title => 'Flutter Demo Home Page';

	/// en: 'You have pushed the button this many times:'
	String get message => 'You have pushed the button this many times:';
}

// Path: counter
class TranslationsCounterEn {
	TranslationsCounterEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Increment'
	String get increment => 'Increment';

	/// en: 'Decrement'
	String get decrement => 'Decrement';

	/// en: 'Reset'
	String get reset => 'Reset';

	late final TranslationsCounterTooltipEn tooltip = TranslationsCounterTooltipEn.internal(_root);

	/// en: '(zero) {No pushes yet} (one) {{n} time} (other) {{n} times}'
	String value({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		zero: 'No pushes yet',
		one: '{n} time',
		other: '{n} times',
	);
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Error'
	String get error => 'Error';

	/// en: 'Success'
	String get success => 'Success';

	/// en: 'Warning'
	String get warning => 'Warning';

	/// en: 'Info'
	String get info => 'Info';

	/// en: 'Yes'
	String get yes => 'Yes';

	/// en: 'No'
	String get no => 'No';

	/// en: 'OK'
	String get ok => 'OK';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Next'
	String get next => 'Next';

	/// en: 'Finish'
	String get finish => 'Finish';

	/// en: 'Submit'
	String get submit => 'Submit';

	/// en: 'Search'
	String get search => 'Search';

	/// en: 'Clear'
	String get clear => 'Clear';

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'Retry'
	String get retry => 'Retry';
}

// Path: settings
class TranslationsSettingsEn {
	TranslationsSettingsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Dark Mode'
	String get darkMode => 'Dark Mode';

	/// en: 'Light Mode'
	String get lightMode => 'Light Mode';

	/// en: 'System'
	String get systemMode => 'System';

	/// en: 'Change Language'
	String get changeLanguage => 'Change Language';
}

// Path: language
class TranslationsLanguageEn {
	TranslationsLanguageEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'English'
	String get en => 'English';

	/// en: 'Japanese'
	String get ja => 'Japanese';
}

// Path: game
class TranslationsGameEn {
	TranslationsGameEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Game'
	String get title => 'Game';

	/// en: 'Start Game'
	String get start => 'Start Game';

	/// en: 'Pause'
	String get pause => 'Pause';

	/// en: 'Resume'
	String get resume => 'Resume';

	/// en: 'Game Over'
	String get gameOver => 'Game Over';

	/// en: 'Score: {n}'
	String get score => 'Score: {n}';

	/// en: 'Restart'
	String get restart => 'Restart';

	/// en: 'Loading game...'
	String get loading => 'Loading game...';
}

// Path: genui
class TranslationsGenuiEn {
	TranslationsGenuiEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'AI Chat'
	String get title => 'AI Chat';

	/// en: 'Type a message...'
	String get inputHint => 'Type a message...';

	/// en: 'Send'
	String get send => 'Send';

	/// en: 'Start a conversation'
	String get emptyState => 'Start a conversation';

	/// en: 'Failed to send message'
	String get error => 'Failed to send message';

	/// en: 'Thinking...'
	String get processing => 'Thinking...';
}

// Path: error
class TranslationsErrorEn {
	TranslationsErrorEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'An error occurred'
	String get generic => 'An error occurred';

	/// en: 'Network error'
	String get network => 'Network error';

	/// en: 'Not found'
	String get notFound => 'Not found';

	/// en: 'Unauthorized'
	String get unauthorized => 'Unauthorized';

	/// en: 'Forbidden'
	String get forbidden => 'Forbidden';

	/// en: 'Server error'
	String get serverError => 'Server error';

	/// en: 'Request timeout'
	String get timeout => 'Request timeout';
}

// Path: counter.tooltip
class TranslationsCounterTooltipEn {
	TranslationsCounterTooltipEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Increment'
	String get increment => 'Increment';

	/// en: 'Decrement'
	String get decrement => 'Decrement';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Flutter Demo',
			'app.name' => 'Flutter Boilerplate',
			'home.title' => 'Flutter Demo Home Page',
			'home.message' => 'You have pushed the button this many times:',
			'counter.increment' => 'Increment',
			'counter.decrement' => 'Decrement',
			'counter.reset' => 'Reset',
			'counter.tooltip.increment' => 'Increment',
			'counter.tooltip.decrement' => 'Decrement',
			'counter.value' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, zero: 'No pushes yet', one: '{n} time', other: '{n} times', ), 
			'common.save' => 'Save',
			'common.cancel' => 'Cancel',
			'common.delete' => 'Delete',
			'common.edit' => 'Edit',
			'common.confirm' => 'Confirm',
			'common.loading' => 'Loading...',
			'common.error' => 'Error',
			'common.success' => 'Success',
			'common.warning' => 'Warning',
			'common.info' => 'Info',
			'common.yes' => 'Yes',
			'common.no' => 'No',
			'common.ok' => 'OK',
			'common.close' => 'Close',
			'common.back' => 'Back',
			'common.next' => 'Next',
			'common.finish' => 'Finish',
			'common.submit' => 'Submit',
			'common.search' => 'Search',
			'common.clear' => 'Clear',
			'common.refresh' => 'Refresh',
			'common.retry' => 'Retry',
			'settings.title' => 'Settings',
			'settings.language' => 'Language',
			'settings.theme' => 'Theme',
			'settings.darkMode' => 'Dark Mode',
			'settings.lightMode' => 'Light Mode',
			'settings.systemMode' => 'System',
			'settings.changeLanguage' => 'Change Language',
			'language.en' => 'English',
			'language.ja' => 'Japanese',
			'game.title' => 'Game',
			'game.start' => 'Start Game',
			'game.pause' => 'Pause',
			'game.resume' => 'Resume',
			'game.gameOver' => 'Game Over',
			'game.score' => 'Score: {n}',
			'game.restart' => 'Restart',
			'game.loading' => 'Loading game...',
			'genui.title' => 'AI Chat',
			'genui.inputHint' => 'Type a message...',
			'genui.send' => 'Send',
			'genui.emptyState' => 'Start a conversation',
			'genui.error' => 'Failed to send message',
			'genui.processing' => 'Thinking...',
			'error.generic' => 'An error occurred',
			'error.network' => 'Network error',
			'error.notFound' => 'Not found',
			'error.unauthorized' => 'Unauthorized',
			'error.forbidden' => 'Forbidden',
			'error.serverError' => 'Server error',
			'error.timeout' => 'Request timeout',
			_ => null,
		};
	}
}
