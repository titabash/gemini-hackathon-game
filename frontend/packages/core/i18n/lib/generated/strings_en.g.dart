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
	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
	late final TranslationsAuthEn auth = TranslationsAuthEn.internal(_root);
	late final TranslationsOnboardingEn onboarding = TranslationsOnboardingEn.internal(_root);
	late final TranslationsSettingsEn settings = TranslationsSettingsEn.internal(_root);
	late final TranslationsLanguageEn language = TranslationsLanguageEn.internal(_root);
	late final TranslationsScenarioListEn scenarioList = TranslationsScenarioListEn.internal(_root);
	late final TranslationsScenarioDetailEn scenarioDetail = TranslationsScenarioDetailEn.internal(_root);
	late final TranslationsGameEn game = TranslationsGameEn.internal(_root);
	late final TranslationsGenuiEn genui = TranslationsGenuiEn.internal(_root);
	late final TranslationsTrpgEn trpg = TranslationsTrpgEn.internal(_root);
	late final TranslationsErrorEn error = TranslationsErrorEn.internal(_root);
}

// Path: app
class TranslationsAppEn {
	TranslationsAppEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Game Service'
	String get title => 'Game Service';

	/// en: 'Game Service'
	String get name => 'Game Service';
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

// Path: auth
class TranslationsAuthEn {
	TranslationsAuthEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Login'
	String get login => 'Login';

	/// en: 'Login with Email'
	String get loginWithEmail => 'Login with Email';

	/// en: 'Enter your email and we'll send you a verification code'
	String get loginDescription => 'Enter your email and we\'ll send you a verification code';

	/// en: 'Send Verification Code'
	String get sendCode => 'Send Verification Code';

	/// en: 'Back to Home'
	String get backToHome => 'Back to Home';

	/// en: 'Verify Code'
	String get verifyCode => 'Verify Code';

	/// en: 'Enter Verification Code'
	String get enterCode => 'Enter Verification Code';

	/// en: 'Enter the verification code sent to $email'
	String enterCodeDescription({required Object email}) => 'Enter the verification code sent to ${email}';

	/// en: 'Login'
	String get loginButton => 'Login';

	/// en: 'Resend Code'
	String get resendCode => 'Resend Code';

	/// en: 'Change Email'
	String get changeEmail => 'Change Email';

	/// en: 'Verification code sent to $email'
	String codeSent({required Object email}) => 'Verification code sent to ${email}';

	/// en: 'Verification code resent to $email'
	String codeResent({required Object email}) => 'Verification code resent to ${email}';

	/// en: 'Logged in successfully'
	String get loginSuccess => 'Logged in successfully';
}

// Path: onboarding
class TranslationsOnboardingEn {
	TranslationsOnboardingEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Set Up Your Profile'
	String get title => 'Set Up Your Profile';

	/// en: 'Choose a unique account name to get started'
	String get description => 'Choose a unique account name to get started';

	/// en: 'Account Name'
	String get accountName => 'Account Name';

	/// en: 'e.g. alice_smith'
	String get accountNameHint => 'e.g. alice_smith';

	/// en: '3-20 characters, lowercase letters, numbers, and underscores only'
	String get accountNameHelper => '3-20 characters, lowercase letters, numbers, and underscores only';

	/// en: 'Display Name'
	String get displayName => 'Display Name';

	/// en: 'e.g. Alice Smith'
	String get displayNameHint => 'e.g. Alice Smith';

	/// en: 'Optional. How others will see you'
	String get displayNameHelper => 'Optional. How others will see you';

	/// en: 'Complete Setup'
	String get complete => 'Complete Setup';

	/// en: 'Setting up...'
	String get completing => 'Setting up...';

	/// en: 'Account name is required'
	String get accountNameRequired => 'Account name is required';

	/// en: 'Must be at least 3 characters'
	String get accountNameTooShort => 'Must be at least 3 characters';

	/// en: 'Must be at most 20 characters'
	String get accountNameTooLong => 'Must be at most 20 characters';

	/// en: 'Only lowercase letters, numbers, and underscores allowed'
	String get accountNameInvalidFormat => 'Only lowercase letters, numbers, and underscores allowed';

	/// en: 'Please choose a personalized account name'
	String get accountNameTemporary => 'Please choose a personalized account name';

	/// en: 'This account name is already taken'
	String get accountNameTaken => 'This account name is already taken';

	/// en: 'Profile setup complete!'
	String get success => 'Profile setup complete!';
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

// Path: scenarioList
class TranslationsScenarioListEn {
	TranslationsScenarioListEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Games'
	String get title => 'Games';

	/// en: 'No games available yet'
	String get empty => 'No games available yet';

	/// en: 'Check back later for new scenarios'
	String get emptyDescription => 'Check back later for new scenarios';

	/// en: 'Failed to load games'
	String get error => 'Failed to load games';

	/// en: 'Logout'
	String get logout => 'Logout';
}

// Path: scenarioDetail
class TranslationsScenarioDetailEn {
	TranslationsScenarioDetailEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Play Now'
	String get play => 'Play Now';

	/// en: 'Starting game...'
	String get startingGame => 'Starting game...';

	/// en: 'Failed to start the game'
	String get startError => 'Failed to start the game';

	/// en: 'Description'
	String get description => 'Description';
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

	/// en: 'Back to Games'
	String get backToList => 'Back to Games';
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

// Path: trpg
class TranslationsTrpgEn {
	TranslationsTrpgEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Choose your action'
	String get chooseAction => 'Choose your action';

	/// en: 'Or describe your own action...'
	String get freeInput => 'Or describe your own action...';

	/// en: 'Skill Check'
	String get rollCheck => 'Skill Check';

	/// en: 'Difficulty: $n'
	String rollDifficulty({required Object n}) => 'Difficulty: ${n}';

	/// en: 'On success: $text'
	String rollSuccess({required Object text}) => 'On success: ${text}';

	/// en: 'On failure: $text'
	String rollFailure({required Object text}) => 'On failure: ${text}';

	/// en: 'Roll the dice'
	String get rollButton => 'Roll the dice';

	/// en: 'The GM needs clarification'
	String get clarifyTitle => 'The GM needs clarification';

	/// en: 'Contradiction detected'
	String get repairTitle => 'Contradiction detected';

	/// en: 'Issue: $text'
	String repairContradiction({required Object text}) => 'Issue: ${text}';

	/// en: 'Proposed fix: $text'
	String repairFix({required Object text}) => 'Proposed fix: ${text}';

	/// en: 'Accept fix'
	String get repairAccept => 'Accept fix';

	/// en: 'Reject'
	String get repairReject => 'Reject';

	/// en: 'Continue'
	String get continueButton => 'Continue';

	/// en: 'What do you do?'
	String get inputHint => 'What do you do?';

	/// en: 'Send'
	String get send => 'Send';

	/// en: 'Your adventure begins...'
	String get emptyState => 'Your adventure begins...';

	/// en: 'The GM is thinking...'
	String get processing => 'The GM is thinking...';

	/// en: 'Tap to continue'
	String get tapToContinue => 'Tap to continue';

	/// en: 'Narrator'
	String get narrator => 'Narrator';

	/// en: 'Message Log'
	String get messageLog => 'Message Log';
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

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Game Service',
			'app.name' => 'Game Service',
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
			'auth.login' => 'Login',
			'auth.loginWithEmail' => 'Login with Email',
			'auth.loginDescription' => 'Enter your email and we\'ll send you a verification code',
			'auth.sendCode' => 'Send Verification Code',
			'auth.backToHome' => 'Back to Home',
			'auth.verifyCode' => 'Verify Code',
			'auth.enterCode' => 'Enter Verification Code',
			'auth.enterCodeDescription' => ({required Object email}) => 'Enter the verification code sent to ${email}',
			'auth.loginButton' => 'Login',
			'auth.resendCode' => 'Resend Code',
			'auth.changeEmail' => 'Change Email',
			'auth.codeSent' => ({required Object email}) => 'Verification code sent to ${email}',
			'auth.codeResent' => ({required Object email}) => 'Verification code resent to ${email}',
			'auth.loginSuccess' => 'Logged in successfully',
			'onboarding.title' => 'Set Up Your Profile',
			'onboarding.description' => 'Choose a unique account name to get started',
			'onboarding.accountName' => 'Account Name',
			'onboarding.accountNameHint' => 'e.g. alice_smith',
			'onboarding.accountNameHelper' => '3-20 characters, lowercase letters, numbers, and underscores only',
			'onboarding.displayName' => 'Display Name',
			'onboarding.displayNameHint' => 'e.g. Alice Smith',
			'onboarding.displayNameHelper' => 'Optional. How others will see you',
			'onboarding.complete' => 'Complete Setup',
			'onboarding.completing' => 'Setting up...',
			'onboarding.accountNameRequired' => 'Account name is required',
			'onboarding.accountNameTooShort' => 'Must be at least 3 characters',
			'onboarding.accountNameTooLong' => 'Must be at most 20 characters',
			'onboarding.accountNameInvalidFormat' => 'Only lowercase letters, numbers, and underscores allowed',
			'onboarding.accountNameTemporary' => 'Please choose a personalized account name',
			'onboarding.accountNameTaken' => 'This account name is already taken',
			'onboarding.success' => 'Profile setup complete!',
			'settings.title' => 'Settings',
			'settings.language' => 'Language',
			'settings.theme' => 'Theme',
			'settings.darkMode' => 'Dark Mode',
			'settings.lightMode' => 'Light Mode',
			'settings.systemMode' => 'System',
			'settings.changeLanguage' => 'Change Language',
			'language.en' => 'English',
			'language.ja' => 'Japanese',
			'scenarioList.title' => 'Games',
			'scenarioList.empty' => 'No games available yet',
			'scenarioList.emptyDescription' => 'Check back later for new scenarios',
			'scenarioList.error' => 'Failed to load games',
			'scenarioList.logout' => 'Logout',
			'scenarioDetail.play' => 'Play Now',
			'scenarioDetail.startingGame' => 'Starting game...',
			'scenarioDetail.startError' => 'Failed to start the game',
			'scenarioDetail.description' => 'Description',
			'game.title' => 'Game',
			'game.start' => 'Start Game',
			'game.pause' => 'Pause',
			'game.resume' => 'Resume',
			'game.gameOver' => 'Game Over',
			'game.score' => 'Score: {n}',
			'game.restart' => 'Restart',
			'game.loading' => 'Loading game...',
			'game.backToList' => 'Back to Games',
			'genui.title' => 'AI Chat',
			'genui.inputHint' => 'Type a message...',
			'genui.send' => 'Send',
			'genui.emptyState' => 'Start a conversation',
			'genui.error' => 'Failed to send message',
			'genui.processing' => 'Thinking...',
			'trpg.chooseAction' => 'Choose your action',
			'trpg.freeInput' => 'Or describe your own action...',
			'trpg.rollCheck' => 'Skill Check',
			'trpg.rollDifficulty' => ({required Object n}) => 'Difficulty: ${n}',
			'trpg.rollSuccess' => ({required Object text}) => 'On success: ${text}',
			'trpg.rollFailure' => ({required Object text}) => 'On failure: ${text}',
			'trpg.rollButton' => 'Roll the dice',
			'trpg.clarifyTitle' => 'The GM needs clarification',
			'trpg.repairTitle' => 'Contradiction detected',
			'trpg.repairContradiction' => ({required Object text}) => 'Issue: ${text}',
			'trpg.repairFix' => ({required Object text}) => 'Proposed fix: ${text}',
			'trpg.repairAccept' => 'Accept fix',
			'trpg.repairReject' => 'Reject',
			'trpg.continueButton' => 'Continue',
			'trpg.inputHint' => 'What do you do?',
			'trpg.send' => 'Send',
			'trpg.emptyState' => 'Your adventure begins...',
			'trpg.processing' => 'The GM is thinking...',
			'trpg.tapToContinue' => 'Tap to continue',
			'trpg.narrator' => 'Narrator',
			'trpg.messageLog' => 'Message Log',
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
