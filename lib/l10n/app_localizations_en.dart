// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'iAgree';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonIncrease => 'Increase';

  @override
  String get commonDecrease => 'Decrease';

  @override
  String participantInvited(String name) {
    return '$name, waiting';
  }

  @override
  String participantJoined(String name) {
    return '$name, joined';
  }

  @override
  String participantChoosing(String name, int percent) {
    return '$name, choosing, $percent percent';
  }

  @override
  String participantReady(String name) {
    return '$name, ready';
  }

  @override
  String agreementArcPeople(int positive, int total) {
    return '$positive/$total people';
  }

  @override
  String agreementArcSemantics(int percent, int total, int positive) {
    return 'Agreement $percent percent. $positive of $total people are in favor.';
  }

  @override
  String agreementArcSemanticsLove(
    int percent,
    int total,
    int positive,
    int love,
  ) {
    return 'Agreement $percent percent. $positive of $total people are in favor, $love of them really want it.';
  }

  @override
  String deckClosing(int minutes) {
    return 'Closing · $minutes min';
  }

  @override
  String deckClosingSemantics(int minutes) {
    return 'Closing in $minutes minutes';
  }

  @override
  String deckRatingSemantics(String rating) {
    return '$rating rating';
  }

  @override
  String get deckPriceLow => 'low price';

  @override
  String get deckPriceMid => 'medium price';

  @override
  String get deckPriceHigh => 'high price';

  @override
  String deckDistance(String distance) {
    return '$distance km';
  }

  @override
  String deckDistanceSemantics(String distance) {
    return '$distance kilometers';
  }

  @override
  String deckDurationHM(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String deckDurationH(int hours) {
    return '${hours}h';
  }

  @override
  String deckDurationM(int minutes) {
    return '${minutes}m';
  }

  @override
  String deckDurationHMSemantics(int hours, int minutes) {
    return '$hours hours $minutes minutes';
  }

  @override
  String deckDurationHSemantics(int hours) {
    return '$hours hours';
  }

  @override
  String deckDurationMSemantics(int minutes) {
    return '$minutes minutes';
  }

  @override
  String deckPhotoSemantics(int index, int total) {
    return 'Photo $index/$total';
  }

  @override
  String deckPosterSemantics(String name) {
    return '$name poster';
  }

  @override
  String get deckDetails => 'Details';

  @override
  String get deckDecisionOk => 'Okay';

  @override
  String get deckDecisionPass => 'Pass';

  @override
  String get deckDecisionLove => 'Love it';

  @override
  String get deckDecisionVeto => 'No way';

  @override
  String get deckBackSemantics => 'Back to room';

  @override
  String get deckUndoSemantics => 'Undo';

  @override
  String deckProgressSemantics(int position, int total) {
    return 'Card $position of $total';
  }

  @override
  String placeDistanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String placeDistanceMetersSemantics(int meters) {
    return '$meters meters';
  }

  @override
  String resultLovers1(String a) {
    return '$a loves it';
  }

  @override
  String resultLovers2(String a, String b) {
    return '$a and $b love it';
  }

  @override
  String resultLovers3(String a, String b, String c) {
    return '$a, $b and $c love it';
  }

  @override
  String resultLoversMore(String a, String b, int count) {
    return '$a, $b and $count more love it';
  }

  @override
  String voteOptionVotes(String name, int count, String names) {
    return '$name, $count votes: $names';
  }

  @override
  String voteOptionVotesLeading(String name, int count, String names) {
    return '$name, leading, $count votes: $names';
  }

  @override
  String voteOptionNoVotes(String name) {
    return '$name, no votes';
  }

  @override
  String get voteOptionMine => 'Your vote.';

  @override
  String get decisionUnanimous => 'You all agree.';

  @override
  String get decisionMajority => 'It\'s decided.';

  @override
  String get decisionDirections => 'Get directions';

  @override
  String get decisionShare => 'Share with the group';

  @override
  String decisionVotes(int votes, int total) {
    return 'Chosen with $votes/$total votes';
  }

  @override
  String get decisionCardOverline => 'Decision';

  @override
  String decisionCardSemantics(String name, String time) {
    return 'Decision: $name, $time';
  }

  @override
  String decisionParticipants(String names) {
    return 'Participants: $names';
  }

  @override
  String get authEmailTitle => 'Your email';

  @override
  String get authEmailSubtitle =>
      'We\'ll send you a 6-digit sign-in code. No password.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailSend => 'Send code';

  @override
  String get authEmailInvalid => 'Enter a valid email address.';

  @override
  String get authCodeTitle => 'Enter the code';

  @override
  String authCodeSubtitle(String email) {
    return 'We sent the code to $email.';
  }

  @override
  String get authChangeAddress => 'Change address';

  @override
  String get authCodeHint => 'No code? Check your spam folder too.';

  @override
  String authResendIn(String time) {
    return 'Resend · $time';
  }

  @override
  String get authResend => 'Resend';

  @override
  String get authOpenMail => 'Open Mail';

  @override
  String get authCodeWrong => 'That code isn\'t right. Try again.';

  @override
  String authCodeEmptySemantics(int length) {
    return 'Code field, $length digits';
  }

  @override
  String authCodeSemantics(String digits, int remaining) {
    return 'Code: $digits, $remaining digits left';
  }

  @override
  String get authProfileTitle => 'One last step';

  @override
  String get authProfileSubtitle =>
      'Your friends will see you in rooms with this name and photo.';

  @override
  String get authAddPhoto => 'Add photo';

  @override
  String get authOptional => 'Optional';

  @override
  String get authNameLabel => 'Your name';

  @override
  String get authNameFromApple =>
      'Came from your Apple account. Change it if you like.';

  @override
  String get authNameRequired => 'Enter your name.';

  @override
  String get authStart => 'Get started';

  @override
  String get authPhotoSoon => 'Photo picking is coming soon';

  @override
  String get authMailSoon => 'Opening Mail is coming soon';

  @override
  String get welcomeLinkSoon => 'This page is coming soon';

  @override
  String get welcomeTagline =>
      'Settle “where should we go?” together, without the argument.';

  @override
  String get welcomeApple => 'Continue with Apple';

  @override
  String get welcomeEmail => 'Continue with email';

  @override
  String welcomeTerms(String terms, String privacy) {
    return 'By continuing you agree to the $terms and $privacy.';
  }

  @override
  String get welcomeTermsLabel => 'Terms of Use';

  @override
  String get welcomePrivacyLabel => 'Privacy Policy';

  @override
  String get welcomeSceneTwoTitle => 'Where to?';

  @override
  String get welcomeSceneTwoBody =>
      'Swipe cards: Yes, Pass, Love it. The group\'s match shows up instantly.';

  @override
  String get welcomeSceneThreeTitle => 'Decide together.';

  @override
  String get welcomeSceneThreeBody =>
      'Start a room, invite your friends. Everyone picks, iAgree finds the common ground.';

  @override
  String get homeSignOut => 'Sign out';

  @override
  String get commonBack => 'Back';

  @override
  String get commonClose => 'Close';

  @override
  String get offlineBannerMessage =>
      'No connection. Your changes will be sent when you reconnect.';

  @override
  String get comingSoon => 'This screen is coming soon';

  @override
  String get homeTitle => 'My rooms';

  @override
  String get homeCreateRoom => 'Create room';

  @override
  String get homeProfile => 'Profile';

  @override
  String get homeOtherRooms => 'Other rooms';

  @override
  String get homePastDecisions => 'Past decisions';

  @override
  String get homeEmptyTitle => 'You have no rooms yet';

  @override
  String get homeEmptyBody =>
      'Start a room, invite your friends, decide together. If you got an invite, just tap the link.';

  @override
  String get homeLoadFailedTitle => 'Couldn’t load your rooms';

  @override
  String get homeLoadFailedBody => 'Check your connection and try again.';

  @override
  String get homeRetry => 'Try again';

  @override
  String get homeHeroResultsLabel => 'Results are in';

  @override
  String homeHeroResultsBody(int count) {
    return 'Everyone has picked. The top $count places are ready, vote on the final call.';
  }

  @override
  String get homeHeroVote => 'Vote';

  @override
  String get homeHeroTurnLabel => 'Your turn';

  @override
  String homeHeroTurnBody(int ready, int total) {
    return '$ready/$total people are done picking. It’s your turn.';
  }

  @override
  String get homeHeroPick => 'Pick';

  @override
  String get homeHeroWaitLabel => 'Waiting';

  @override
  String homeHeroWaitBody(int ready, int total) {
    return '$ready/$total people have picked. Results open when everyone is done.';
  }

  @override
  String get homeHeroOpen => 'Open room';

  @override
  String homeHeroMeta(String category, String when, int count) {
    return '$category · $when · $count people';
  }

  @override
  String homeRoomMeta(String category, String when) {
    return '$category · $when';
  }

  @override
  String get homeTagYourTurn => 'Your turn';

  @override
  String get homeTagResults => 'Results ready';

  @override
  String homeReadyCount(int ready, int total) {
    return '$ready/$total ready';
  }

  @override
  String homeAgreement(int percent) {
    return '$percent% match';
  }

  @override
  String homeRoomSemantics(String name, String meta, String status) {
    return '$name. $meta. $status';
  }

  @override
  String homePreviewSemantics(String name, int percent) {
    return '$name, $percent% match';
  }

  @override
  String get accountEdit => 'Edit';

  @override
  String get accountNotifications => 'Notifications';

  @override
  String get accountAppearance => 'Appearance';

  @override
  String get accountThemeSystem => 'System';

  @override
  String get accountThemeLight => 'Light';

  @override
  String get accountThemeDark => 'Dark';

  @override
  String get accountPrivacy => 'Privacy and terms';

  @override
  String get accountContact => 'Contact us';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteTitle => 'Delete your account?';

  @override
  String get accountDeleteMessage =>
      'Your rooms and past decisions will be permanently deleted. This can’t be undone.';

  @override
  String get accountDeleteConfirm => 'Delete account';

  @override
  String accountVersion(String version) {
    return 'iAgree $version';
  }

  @override
  String get createWhatTitle => 'What are you up to?';

  @override
  String get createThemesTitle => 'For today';

  @override
  String get createCategoriesTitle => 'Categories';

  @override
  String get createDetailsTitle => 'Where and when?';

  @override
  String get createWhere => 'Where';

  @override
  String get createWherePlaceholder => 'Choose a place';

  @override
  String get createWhereSheetTitle => 'Choose a district';

  @override
  String get createDistance => 'Distance';

  @override
  String createDistanceKm(int km) {
    return '$km km';
  }

  @override
  String get createWhen => 'When';

  @override
  String get createWhenNow => 'Now';

  @override
  String get createWhenTonight => 'Tonight';

  @override
  String get createWhenWeekend => 'This weekend';

  @override
  String get createWhenPickDate => 'Pick a date';

  @override
  String get createDateSheetTitle => 'Pick a date';

  @override
  String get createDateConfirm => 'Select';

  @override
  String get createBudget => 'Budget';

  @override
  String get createPlatform => 'Which platform?';

  @override
  String get createRoomName => 'Room name';

  @override
  String createRoomNameDefault(String when, String category) {
    return '$when $category';
  }

  @override
  String get createRoomNameRequired => 'Enter a room name.';

  @override
  String get createLocationRequired => 'Choose a place.';

  @override
  String get createPlatformRequired => 'Choose at least one platform.';

  @override
  String get createSubmit => 'Create room';

  @override
  String createPlaceTag(String place, int km) {
    return '$place · $km km';
  }

  @override
  String get createFailed => 'Couldn’t create the room. Try again.';

  @override
  String roomMembersSemantics(int count) {
    return '$count people in the room';
  }

  @override
  String get roomOnlyYouSemantics => 'Only you are in the room';

  @override
  String get roomInviteTitle => 'Invite your friends';

  @override
  String roomMembersTitle(int count) {
    return '$count people in the room';
  }

  @override
  String get roomLinkCopy => 'Copy';

  @override
  String get roomLinkCopied => 'Link copied';

  @override
  String roomLinkSemantics(String link) {
    return 'Invite link: $link';
  }

  @override
  String get roomShare => 'Share link';

  @override
  String get roomPickFirst => 'Let me pick first';

  @override
  String get roomStartPicking => 'Start picking';

  @override
  String get roomSettings => 'Room settings';

  @override
  String get roomRename => 'Rename room';

  @override
  String get roomRenameSave => 'Save';

  @override
  String get roomDelete => 'Delete room';

  @override
  String get roomDeleteTitle => 'Delete this room?';

  @override
  String get roomDeleteMessage =>
      'The room and everyone’s picks in it will be deleted. This can’t be undone.';

  @override
  String get roomDeleteConfirm => 'Delete room';

  @override
  String get createUseMyLocation => 'Use my location';

  @override
  String get createMyLocation => 'My location';

  @override
  String get createLocationDenied =>
      'Location access was denied. You can pick a district.';

  @override
  String get deckSubmitFailed => 'Couldn’t send your picks. Try again.';

  @override
  String get waitingReady => 'You’re all set';

  @override
  String waitingOthers(int count) {
    return '$count more picking';
  }

  @override
  String get waitingBack => 'Back to room';

  @override
  String get resultsTitle => 'Results';

  @override
  String get resultsHeading => 'Which one?';

  @override
  String get resultsVote => 'Cast my vote';

  @override
  String get resultsVoteFailed => 'Couldn’t send your vote. Try again.';

  @override
  String resultsWaiting(int count) {
    return '$count more to vote';
  }

  @override
  String get resultsNudge => 'Nudge';

  @override
  String get resultsNudged => 'Reminder sent';

  @override
  String get resultsYou => 'You';

  @override
  String decisionShareText(String place, String when) {
    return '$place · $when. We decided with iAgree.';
  }
}
