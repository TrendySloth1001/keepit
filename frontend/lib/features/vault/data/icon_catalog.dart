import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A single entry in the icon catalog.
///
/// `key` is what we persist inside the encrypted payload, so it must remain
/// stable across releases. The visual mapping (icon + tint) can change freely.
class CatalogIcon {
  const CatalogIcon({
    required this.key,
    required this.label,
    required this.icon,
    required this.tint,
    required this.group,
    this.aliases = const [],
  });

  final String key;
  final String label;
  final IconData icon;
  final Color tint;
  final IconGroup group;
  final List<String> aliases;

  bool matches(String q) {
    if (q.isEmpty) return true;
    final n = q.toLowerCase();
    if (label.toLowerCase().contains(n)) return true;
    if (key.contains(n)) return true;
    return aliases.any((a) => a.toLowerCase().contains(n));
  }
}

enum IconGroup {
  cloud,
  dev,
  finance,
  social,
  entertainment,
  productivity,
  shopping,
  travel,
  generic,
}

extension IconGroupX on IconGroup {
  String get label => switch (this) {
    IconGroup.cloud => 'Cloud & infra',
    IconGroup.dev => 'Developer',
    IconGroup.finance => 'Finance',
    IconGroup.social => 'Social',
    IconGroup.entertainment => 'Entertainment',
    IconGroup.productivity => 'Productivity',
    IconGroup.shopping => 'Shopping',
    IconGroup.travel => 'Travel',
    IconGroup.generic => 'Generic',
  };
}

class IconCatalog {
  IconCatalog._();

  static const generic = CatalogIcon(
    key: 'generic',
    label: 'Generic',
    icon: Icons.shield_outlined,
    tint: Color(0xFF0CAA6E),
    group: IconGroup.generic,
  );

  /// Looks up a catalog entry by key, falling back to [generic].
  static CatalogIcon resolve(String? key) {
    if (key == null || key.isEmpty) return generic;
    for (final c in all) {
      if (c.key == key) return c;
    }
    return generic;
  }

  /// Heuristic: guess the best icon for a vault item using its plaintext
  /// title (the only thing visible without decrypting the cipher blob).
  /// Used by list tiles so the home page can render brand icons before any
  /// blob is decrypted.
  static CatalogIcon guessFromTitle(String title) {
    final t = title.toLowerCase();
    for (final c in all) {
      if (c.key == 'generic') continue;
      if (t.contains(c.key)) return c;
      if (t.contains(c.label.toLowerCase())) return c;
      for (final a in c.aliases) {
        if (t.contains(a.toLowerCase())) return c;
      }
    }
    return generic;
  }

  static List<CatalogIcon> search(String query, {IconGroup? group}) {
    return all
        .where((c) => group == null || c.group == group)
        .where((c) => c.matches(query))
        .toList();
  }

  static const _aws = Color(0xFFFF9900);
  static const _azure = Color(0xFF0078D4);
  static const _gcp = Color(0xFF4285F4);
  static const _github = Color(0xFF24292E);
  static const _gitlab = Color(0xFFFC6D26);
  static const _netflix = Color(0xFFE50914);
  static const _spotify = Color(0xFF1DB954);
  static const _apple = Color(0xFF111111);
  static const _google = Color(0xFF4285F4);
  static const _microsoft = Color(0xFF5E5E5E);
  static const _stripe = Color(0xFF635BFF);
  static const _paypal = Color(0xFF003087);
  static const _bank = Color(0xFF1F4E8C);
  static const _crypto = Color(0xFFF7931A);
  static const _x = Color(0xFF111111);
  static const _meta = Color(0xFF1877F2);
  static const _ig = Color(0xFFE4405F);
  static const _yt = Color(0xFFFF0000);
  static const _slack = Color(0xFF4A154B);
  static const _discord = Color(0xFF5865F2);
  static const _figma = Color(0xFFF24E1E);
  static const _notion = Color(0xFF111111);
  static const _dropbox = Color(0xFF0061FF);
  static const _amazon = Color(0xFFFF9900);
  static const _shopify = Color(0xFF95BF47);
  static const _airbnb = Color(0xFFFF5A5F);
  static const _uber = Color(0xFF111111);
  static const _paytm = Color(0xFF00B9F5);
  static const _phonepe = Color(0xFF5F259F);
  static const _gpay = Color(0xFF1A73E8);
  static const _bhim = Color(0xFF1B5E20);
  static const _cred = Color(0xFF121212);
  static const _razorpay = Color(0xFF3395FF);
  static const _rupay = Color(0xFF0066B3);
  static const _flipkart = Color(0xFF2874F0);
  static const _myntra = Color(0xFFE5005B);
  static const _swiggy = Color(0xFFFF6D00);
  static const _zomato = Color(0xFFE23744);
  static const _ola = Color(0xFF1AB64F);
  static const _jio = Color(0xFF0F3CC9);
  static const _airtel = Color(0xFFE4002B);
  static const _sbi = Color(0xFF2E4AA0);
  static const _hdfc = Color(0xFF004C8F);
  static const _icici = Color(0xFFF58220);
  static const _axis = Color(0xFFAE285D);
  static const _kotak = Color(0xFFED1C24);

  static final List<CatalogIcon> all = [
    generic,

    // ── Cloud & infra ─────────────────────────────────────────────────────
    CatalogIcon(
      key: 'aws',
      label: 'AWS',
      icon: FontAwesomeIcons.aws,
      tint: _aws,
      group: IconGroup.cloud,
      aliases: ['amazon web services', 's3', 'ec2', 'iam'],
    ),
    CatalogIcon(
      key: 'gcp',
      label: 'Google Cloud',
      icon: FontAwesomeIcons.googleScholar,
      tint: _gcp,
      group: IconGroup.cloud,
      aliases: ['gcp', 'gce', 'gke'],
    ),
    CatalogIcon(
      key: 'azure',
      label: 'Microsoft Azure',
      icon: FontAwesomeIcons.microsoft,
      tint: _azure,
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'cloudflare',
      label: 'Cloudflare',
      icon: FontAwesomeIcons.cloudflare,
      tint: Color(0xFFF38020),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'digitalocean',
      label: 'DigitalOcean',
      icon: FontAwesomeIcons.digitalOcean,
      tint: Color(0xFF0080FF),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'linode',
      label: 'Linode',
      icon: FontAwesomeIcons.linode,
      tint: Color(0xFF00A95C),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'heroku',
      label: 'Heroku',
      icon: Icons.cloud_queue,
      tint: Color(0xFF430098),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'vercel',
      label: 'Vercel',
      icon: Icons.change_history,
      tint: Color(0xFF000000),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'netlify',
      label: 'Netlify',
      icon: Icons.cloud,
      tint: Color(0xFF00C7B7),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'firebase',
      label: 'Firebase',
      icon: Icons.local_fire_department,
      tint: Color(0xFFFFA000),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'supabase',
      label: 'Supabase',
      icon: Icons.bolt,
      tint: Color(0xFF3ECF8E),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'mongodb',
      label: 'MongoDB',
      icon: FontAwesomeIcons.leaf,
      tint: Color(0xFF47A248),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'postgres',
      label: 'Postgres',
      icon: Icons.dns_outlined,
      tint: Color(0xFF336791),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'redis',
      label: 'Redis',
      icon: Icons.memory,
      tint: Color(0xFFDC382D),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'mysql',
      label: 'MySQL',
      icon: Icons.storage,
      tint: Color(0xFF4479A1),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'docker',
      label: 'Docker',
      icon: FontAwesomeIcons.docker,
      tint: Color(0xFF2496ED),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'kubernetes',
      label: 'Kubernetes',
      icon: Icons.hub,
      tint: Color(0xFF326CE5),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'server',
      label: 'Server / SSH',
      icon: Icons.dns,
      tint: Color(0xFF3F8EFC),
      group: IconGroup.cloud,
      aliases: ['ssh', 'vps', 'host'],
    ),
    CatalogIcon(
      key: 'wifi',
      label: 'Wi-Fi',
      icon: Icons.wifi,
      tint: Color(0xFF1E78D6),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'router',
      label: 'Router',
      icon: Icons.router,
      tint: Color(0xFF3F8EFC),
      group: IconGroup.cloud,
    ),
    CatalogIcon(
      key: 'vpn',
      label: 'VPN',
      icon: Icons.vpn_lock,
      tint: Color(0xFF7C4DFF),
      group: IconGroup.cloud,
    ),

    // ── Developer ─────────────────────────────────────────────────────────
    CatalogIcon(
      key: 'github',
      label: 'GitHub',
      icon: FontAwesomeIcons.github,
      tint: _github,
      group: IconGroup.dev,
      aliases: ['pat', 'token'],
    ),
    CatalogIcon(
      key: 'gitlab',
      label: 'GitLab',
      icon: FontAwesomeIcons.gitlab,
      tint: _gitlab,
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'bitbucket',
      label: 'Bitbucket',
      icon: FontAwesomeIcons.bitbucket,
      tint: Color(0xFF0052CC),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'jira',
      label: 'Jira',
      icon: FontAwesomeIcons.jira,
      tint: Color(0xFF0052CC),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'openai',
      label: 'OpenAI',
      icon: Icons.auto_awesome,
      tint: Color(0xFF10A37F),
      group: IconGroup.dev,
      aliases: ['chatgpt'],
    ),
    CatalogIcon(
      key: 'anthropic',
      label: 'Anthropic',
      icon: Icons.psychology_alt,
      tint: Color(0xFFD4A27F),
      group: IconGroup.dev,
      aliases: ['claude'],
    ),
    CatalogIcon(
      key: 'huggingface',
      label: 'Hugging Face',
      icon: Icons.face_retouching_natural,
      tint: Color(0xFFFFD21E),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'npm',
      label: 'npm',
      icon: FontAwesomeIcons.npm,
      tint: Color(0xFFCB3837),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'pypi',
      label: 'PyPI',
      icon: FontAwesomeIcons.python,
      tint: Color(0xFF3776AB),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'docker_hub',
      label: 'Docker Hub',
      icon: FontAwesomeIcons.docker,
      tint: Color(0xFF2496ED),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'vscode',
      label: 'VS Code',
      icon: Icons.code,
      tint: Color(0xFF007ACC),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'jetbrains',
      label: 'JetBrains',
      icon: Icons.developer_mode,
      tint: Color(0xFF000000),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'linear',
      label: 'Linear',
      icon: Icons.linear_scale,
      tint: Color(0xFF5E6AD2),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'sentry',
      label: 'Sentry',
      icon: Icons.bug_report_outlined,
      tint: Color(0xFF362D59),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'datadog',
      label: 'Datadog',
      icon: Icons.pets,
      tint: Color(0xFF632CA6),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'pagerduty',
      label: 'PagerDuty',
      icon: Icons.notifications_active,
      tint: Color(0xFF06AC38),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'twilio',
      label: 'Twilio',
      icon: Icons.sms,
      tint: Color(0xFFF22F46),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'sendgrid',
      label: 'SendGrid',
      icon: Icons.mail_outline,
      tint: Color(0xFF1A82E2),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'mailgun',
      label: 'Mailgun',
      icon: Icons.alternate_email,
      tint: Color(0xFFC02126),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'ssh_key',
      label: 'SSH key',
      icon: Icons.terminal,
      tint: Color(0xFF111111),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'api_key',
      label: 'API key',
      icon: Icons.vpn_key_outlined,
      tint: Color(0xFF0CAA6E),
      group: IconGroup.dev,
    ),
    CatalogIcon(
      key: 'webhook',
      label: 'Webhook',
      icon: Icons.cable,
      tint: Color(0xFF6B7A75),
      group: IconGroup.dev,
    ),

    // ── Finance ───────────────────────────────────────────────────────────
    CatalogIcon(
      key: 'bank',
      label: 'Bank account',
      icon: Icons.account_balance,
      tint: _bank,
      group: IconGroup.finance,
      aliases: ['checking', 'savings'],
    ),
    CatalogIcon(
      key: 'sbi',
      label: 'SBI',
      icon: Icons.account_balance,
      tint: _sbi,
      group: IconGroup.finance,
      aliases: ['state bank of india'],
    ),
    CatalogIcon(
      key: 'hdfc',
      label: 'HDFC Bank',
      icon: Icons.account_balance,
      tint: _hdfc,
      group: IconGroup.finance,
      aliases: ['hdfc bank'],
    ),
    CatalogIcon(
      key: 'icici',
      label: 'ICICI Bank',
      icon: Icons.account_balance,
      tint: _icici,
      group: IconGroup.finance,
      aliases: ['icici bank'],
    ),
    CatalogIcon(
      key: 'axis',
      label: 'Axis Bank',
      icon: Icons.account_balance,
      tint: _axis,
      group: IconGroup.finance,
      aliases: ['axis bank'],
    ),
    CatalogIcon(
      key: 'kotak',
      label: 'Kotak',
      icon: Icons.account_balance,
      tint: _kotak,
      group: IconGroup.finance,
      aliases: ['kotak mahindra', 'kotak bank'],
    ),
    CatalogIcon(
      key: 'credit_card',
      label: 'Credit card',
      icon: Icons.credit_card,
      tint: Color(0xFF111111),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'rupay',
      label: 'RuPay',
      icon: Icons.credit_card,
      tint: _rupay,
      group: IconGroup.finance,
      aliases: ['ru pay'],
    ),
    CatalogIcon(
      key: 'visa',
      label: 'Visa',
      icon: FontAwesomeIcons.ccVisa,
      tint: Color(0xFF1A1F71),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'mastercard',
      label: 'Mastercard',
      icon: FontAwesomeIcons.ccMastercard,
      tint: Color(0xFFEB001B),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'amex',
      label: 'American Express',
      icon: FontAwesomeIcons.ccAmex,
      tint: Color(0xFF2E77BC),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'discover',
      label: 'Discover',
      icon: FontAwesomeIcons.ccDiscover,
      tint: Color(0xFFFF6000),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'paypal',
      label: 'PayPal',
      icon: FontAwesomeIcons.paypal,
      tint: _paypal,
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'stripe',
      label: 'Stripe',
      icon: FontAwesomeIcons.stripe,
      tint: _stripe,
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'upi',
      label: 'UPI',
      icon: Icons.account_balance_wallet,
      tint: Color(0xFF1E78D6),
      group: IconGroup.finance,
      aliases: ['upi id', 'upi pin'],
    ),
    CatalogIcon(
      key: 'paytm',
      label: 'Paytm',
      icon: Icons.account_balance_wallet,
      tint: _paytm,
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'phonepe',
      label: 'PhonePe',
      icon: Icons.smartphone,
      tint: _phonepe,
      group: IconGroup.finance,
      aliases: ['phone pe'],
    ),
    CatalogIcon(
      key: 'gpay',
      label: 'Google Pay',
      icon: Icons.payments_outlined,
      tint: _gpay,
      group: IconGroup.finance,
      aliases: ['google pay', 'g pay'],
    ),
    CatalogIcon(
      key: 'bhim',
      label: 'BHIM',
      icon: Icons.account_balance_wallet,
      tint: _bhim,
      group: IconGroup.finance,
      aliases: ['bhim upi'],
    ),
    CatalogIcon(
      key: 'cred',
      label: 'CRED',
      icon: Icons.credit_card,
      tint: _cred,
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'razorpay',
      label: 'Razorpay',
      icon: Icons.receipt,
      tint: _razorpay,
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'wise',
      label: 'Wise',
      icon: Icons.swap_horiz,
      tint: Color(0xFF9FE870),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'revolut',
      label: 'Revolut',
      icon: Icons.attach_money,
      tint: Color(0xFF111111),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'venmo',
      label: 'Venmo',
      icon: Icons.payments_outlined,
      tint: Color(0xFF008CFF),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'cashapp',
      label: 'Cash App',
      icon: Icons.attach_money,
      tint: Color(0xFF00C244),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'crypto',
      label: 'Crypto wallet',
      icon: FontAwesomeIcons.bitcoin,
      tint: _crypto,
      group: IconGroup.finance,
      aliases: ['bitcoin', 'btc', 'ethereum'],
    ),
    CatalogIcon(
      key: 'coinbase',
      label: 'Coinbase',
      icon: Icons.currency_bitcoin,
      tint: Color(0xFF0052FF),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'binance',
      label: 'Binance',
      icon: Icons.currency_exchange,
      tint: Color(0xFFF3BA2F),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'metamask',
      label: 'MetaMask',
      icon: FontAwesomeIcons.ethereum,
      tint: Color(0xFFF6851B),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'tax',
      label: 'Tax',
      icon: Icons.receipt_long,
      tint: Color(0xFF6B7A75),
      group: IconGroup.finance,
    ),
    CatalogIcon(
      key: 'investment',
      label: 'Investment',
      icon: Icons.trending_up,
      tint: Color(0xFF0CAA6E),
      group: IconGroup.finance,
    ),

    // ── Social ────────────────────────────────────────────────────────────
    CatalogIcon(
      key: 'google',
      label: 'Google',
      icon: FontAwesomeIcons.google,
      tint: _google,
      group: IconGroup.social,
      aliases: ['gmail', 'workspace'],
    ),
    CatalogIcon(
      key: 'gmail',
      label: 'Gmail',
      icon: Icons.mark_email_read_outlined,
      tint: Color(0xFFEA4335),
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'apple',
      label: 'Apple ID',
      icon: FontAwesomeIcons.apple,
      tint: _apple,
      group: IconGroup.social,
      aliases: ['icloud'],
    ),
    CatalogIcon(
      key: 'microsoft',
      label: 'Microsoft',
      icon: FontAwesomeIcons.microsoft,
      tint: _microsoft,
      group: IconGroup.social,
      aliases: ['outlook', '365'],
    ),
    CatalogIcon(
      key: 'x',
      label: 'X / Twitter',
      icon: FontAwesomeIcons.xTwitter,
      tint: _x,
      group: IconGroup.social,
      aliases: ['twitter'],
    ),
    CatalogIcon(
      key: 'facebook',
      label: 'Facebook',
      icon: FontAwesomeIcons.facebook,
      tint: _meta,
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'instagram',
      label: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      tint: _ig,
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'linkedin',
      label: 'LinkedIn',
      icon: FontAwesomeIcons.linkedin,
      tint: Color(0xFF0A66C2),
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'reddit',
      label: 'Reddit',
      icon: FontAwesomeIcons.reddit,
      tint: Color(0xFFFF4500),
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'tiktok',
      label: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      tint: Color(0xFF010101),
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'snapchat',
      label: 'Snapchat',
      icon: FontAwesomeIcons.snapchat,
      tint: Color(0xFFFFFC00),
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'pinterest',
      label: 'Pinterest',
      icon: FontAwesomeIcons.pinterest,
      tint: Color(0xFFBD081C),
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'whatsapp',
      label: 'WhatsApp',
      icon: FontAwesomeIcons.whatsapp,
      tint: Color(0xFF25D366),
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'telegram',
      label: 'Telegram',
      icon: FontAwesomeIcons.telegram,
      tint: Color(0xFF26A5E4),
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'signal',
      label: 'Signal',
      icon: Icons.chat_bubble_outline,
      tint: Color(0xFF3A76F0),
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'discord',
      label: 'Discord',
      icon: FontAwesomeIcons.discord,
      tint: _discord,
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'mastodon',
      label: 'Mastodon',
      icon: FontAwesomeIcons.mastodon,
      tint: Color(0xFF6364FF),
      group: IconGroup.social,
    ),
    CatalogIcon(
      key: 'threads',
      label: 'Threads',
      icon: FontAwesomeIcons.threads,
      tint: Color(0xFF000000),
      group: IconGroup.social,
    ),

    // ── Entertainment ─────────────────────────────────────────────────────
    CatalogIcon(
      key: 'netflix',
      label: 'Netflix',
      icon: Icons.movie_filter_outlined,
      tint: _netflix,
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'prime_video',
      label: 'Prime Video',
      icon: Icons.smart_display_outlined,
      tint: Color(0xFF00A8E1),
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'disney',
      label: 'Disney+',
      icon: Icons.castle,
      tint: Color(0xFF113CCF),
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'hulu',
      label: 'Hulu',
      icon: Icons.live_tv,
      tint: Color(0xFF1CE783),
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'hbo',
      label: 'HBO Max',
      icon: Icons.tv,
      tint: Color(0xFF7B2CBF),
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'spotify',
      label: 'Spotify',
      icon: FontAwesomeIcons.spotify,
      tint: _spotify,
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'apple_music',
      label: 'Apple Music',
      icon: Icons.music_note,
      tint: Color(0xFFFA243C),
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'youtube',
      label: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      tint: _yt,
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'twitch',
      label: 'Twitch',
      icon: FontAwesomeIcons.twitch,
      tint: Color(0xFF9146FF),
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'steam',
      label: 'Steam',
      icon: FontAwesomeIcons.steam,
      tint: Color(0xFF1B2838),
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'xbox',
      label: 'Xbox Live',
      icon: FontAwesomeIcons.xbox,
      tint: Color(0xFF107C10),
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'playstation',
      label: 'PlayStation',
      icon: FontAwesomeIcons.playstation,
      tint: Color(0xFF003087),
      group: IconGroup.entertainment,
    ),
    CatalogIcon(
      key: 'nintendo',
      label: 'Nintendo',
      icon: FontAwesomeIcons.gamepad,
      tint: Color(0xFFE60012),
      group: IconGroup.entertainment,
    ),

    // ── Productivity ──────────────────────────────────────────────────────
    CatalogIcon(
      key: 'slack',
      label: 'Slack',
      icon: FontAwesomeIcons.slack,
      tint: _slack,
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'notion',
      label: 'Notion',
      icon: Icons.menu_book_outlined,
      tint: _notion,
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'figma',
      label: 'Figma',
      icon: FontAwesomeIcons.figma,
      tint: _figma,
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'dropbox',
      label: 'Dropbox',
      icon: FontAwesomeIcons.dropbox,
      tint: _dropbox,
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'gdrive',
      label: 'Google Drive',
      icon: FontAwesomeIcons.googleDrive,
      tint: Color(0xFF1FA463),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'onedrive',
      label: 'OneDrive',
      icon: Icons.cloud_outlined,
      tint: Color(0xFF0078D4),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'icloud',
      label: 'iCloud',
      icon: Icons.cloud,
      tint: Color(0xFF3693F3),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'evernote',
      label: 'Evernote',
      icon: FontAwesomeIcons.evernote,
      tint: Color(0xFF00A82D),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'trello',
      label: 'Trello',
      icon: FontAwesomeIcons.trello,
      tint: Color(0xFF0079BF),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'asana',
      label: 'Asana',
      icon: Icons.task_alt,
      tint: Color(0xFFF06A6A),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'zoom',
      label: 'Zoom',
      icon: Icons.videocam_outlined,
      tint: Color(0xFF2D8CFF),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'meet',
      label: 'Google Meet',
      icon: Icons.video_call_outlined,
      tint: Color(0xFF00897B),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'teams',
      label: 'Microsoft Teams',
      icon: Icons.groups,
      tint: Color(0xFF6264A7),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'calendar',
      label: 'Calendar',
      icon: Icons.calendar_today,
      tint: Color(0xFF1E78D6),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'mail',
      label: 'Email',
      icon: Icons.alternate_email,
      tint: Color(0xFF6B7A75),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'phone',
      label: 'Phone',
      icon: Icons.phone,
      tint: Color(0xFF0CAA6E),
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'jio',
      label: 'Jio',
      icon: Icons.network_cell,
      tint: _jio,
      group: IconGroup.productivity,
    ),
    CatalogIcon(
      key: 'airtel',
      label: 'Airtel',
      icon: Icons.signal_cellular_4_bar,
      tint: _airtel,
      group: IconGroup.productivity,
    ),

    // ── Shopping ──────────────────────────────────────────────────────────
    CatalogIcon(
      key: 'amazon',
      label: 'Amazon',
      icon: FontAwesomeIcons.amazon,
      tint: _amazon,
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'flipkart',
      label: 'Flipkart',
      icon: Icons.shopping_cart,
      tint: _flipkart,
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'myntra',
      label: 'Myntra',
      icon: Icons.local_mall,
      tint: _myntra,
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'shopify',
      label: 'Shopify',
      icon: FontAwesomeIcons.shopify,
      tint: _shopify,
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'ebay',
      label: 'eBay',
      icon: FontAwesomeIcons.ebay,
      tint: Color(0xFFE53238),
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'etsy',
      label: 'Etsy',
      icon: FontAwesomeIcons.etsy,
      tint: Color(0xFFF1641E),
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'walmart',
      label: 'Walmart',
      icon: Icons.shopping_cart,
      tint: Color(0xFF0071CE),
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'target',
      label: 'Target',
      icon: Icons.adjust,
      tint: Color(0xFFCC0000),
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'bestbuy',
      label: 'Best Buy',
      icon: Icons.electrical_services,
      tint: Color(0xFF003B64),
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'doordash',
      label: 'DoorDash',
      icon: Icons.delivery_dining,
      tint: Color(0xFFFF3008),
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'ubereats',
      label: 'Uber Eats',
      icon: Icons.fastfood,
      tint: Color(0xFF06C167),
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'swiggy',
      label: 'Swiggy',
      icon: Icons.delivery_dining,
      tint: _swiggy,
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'zomato',
      label: 'Zomato',
      icon: Icons.restaurant,
      tint: _zomato,
      group: IconGroup.shopping,
    ),
    CatalogIcon(
      key: 'instacart',
      label: 'Instacart',
      icon: Icons.local_grocery_store,
      tint: Color(0xFF43B02A),
      group: IconGroup.shopping,
    ),

    // ── Travel ────────────────────────────────────────────────────────────
    CatalogIcon(
      key: 'uber',
      label: 'Uber',
      icon: FontAwesomeIcons.uber,
      tint: _uber,
      group: IconGroup.travel,
    ),
    CatalogIcon(
      key: 'ola',
      label: 'Ola',
      icon: Icons.local_taxi,
      tint: _ola,
      group: IconGroup.travel,
    ),
    CatalogIcon(
      key: 'lyft',
      label: 'Lyft',
      icon: Icons.local_taxi,
      tint: Color(0xFFFF00BF),
      group: IconGroup.travel,
    ),
    CatalogIcon(
      key: 'airbnb',
      label: 'Airbnb',
      icon: FontAwesomeIcons.airbnb,
      tint: _airbnb,
      group: IconGroup.travel,
    ),
    CatalogIcon(
      key: 'booking',
      label: 'Booking.com',
      icon: Icons.hotel,
      tint: Color(0xFF003580),
      group: IconGroup.travel,
    ),
    CatalogIcon(
      key: 'flight',
      label: 'Airline',
      icon: Icons.flight,
      tint: Color(0xFF1E78D6),
      group: IconGroup.travel,
    ),
    CatalogIcon(
      key: 'train',
      label: 'Train',
      icon: Icons.train,
      tint: Color(0xFFE08A1A),
      group: IconGroup.travel,
    ),
    CatalogIcon(
      key: 'car',
      label: 'Car / vehicle',
      icon: Icons.directions_car,
      tint: Color(0xFF6B7A75),
      group: IconGroup.travel,
    ),
    CatalogIcon(
      key: 'passport',
      label: 'Passport',
      icon: Icons.menu_book,
      tint: Color(0xFF1F4E8C),
      group: IconGroup.travel,
    ),
    CatalogIcon(
      key: 'license',
      label: 'License / ID',
      icon: Icons.badge_outlined,
      tint: Color(0xFF0CAA6E),
      group: IconGroup.travel,
    ),

    // ── Generic ───────────────────────────────────────────────────────────
    CatalogIcon(
      key: 'home',
      label: 'Home',
      icon: Icons.home_outlined,
      tint: Color(0xFF0CAA6E),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'work',
      label: 'Work',
      icon: Icons.work_outline,
      tint: Color(0xFF1F4E8C),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'school',
      label: 'School',
      icon: Icons.school_outlined,
      tint: Color(0xFFE08A1A),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'family',
      label: 'Family',
      icon: Icons.family_restroom,
      tint: Color(0xFFE4405F),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'health',
      label: 'Health',
      icon: Icons.favorite_border,
      tint: Color(0xFFE2483A),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'medical',
      label: 'Medical',
      icon: Icons.medical_services_outlined,
      tint: Color(0xFF1E78D6),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'fitness',
      label: 'Fitness',
      icon: Icons.fitness_center,
      tint: Color(0xFF111111),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'shield',
      label: 'Security',
      icon: Icons.shield_outlined,
      tint: Color(0xFF0CAA6E),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'lock',
      label: 'Lock',
      icon: Icons.lock_outline,
      tint: Color(0xFF6B7A75),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'key',
      label: 'Key',
      icon: Icons.vpn_key,
      tint: Color(0xFFE08A1A),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'star',
      label: 'Favorite',
      icon: Icons.star_outline,
      tint: Color(0xFFE08A1A),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'gift',
      label: 'Gift',
      icon: Icons.card_giftcard,
      tint: Color(0xFFE4405F),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'flag',
      label: 'Flag',
      icon: Icons.flag_outlined,
      tint: Color(0xFF1E78D6),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'pet',
      label: 'Pet',
      icon: Icons.pets,
      tint: Color(0xFF8B5A2B),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'note',
      label: 'Note',
      icon: Icons.sticky_note_2_outlined,
      tint: Color(0xFFE08A1A),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'document',
      label: 'Document',
      icon: Icons.description_outlined,
      tint: Color(0xFF6B7A75),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'idea',
      label: 'Idea',
      icon: Icons.lightbulb_outline,
      tint: Color(0xFFE08A1A),
      group: IconGroup.generic,
    ),
    CatalogIcon(
      key: 'wifi_password',
      label: 'Wi-Fi password',
      icon: Icons.network_wifi,
      tint: Color(0xFF1E78D6),
      group: IconGroup.generic,
    ),
  ];
}

/// Renders a catalog icon inside a tinted rounded square — used in tiles,
/// editors and the picker grid.
class VaultIcon extends StatelessWidget {
  const VaultIcon({
    super.key,
    required this.iconKey,
    this.size = 44,
    this.iconSize,
    this.radius = 12,
  });

  final String? iconKey;
  final double size;
  final double? iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final entry = IconCatalog.resolve(iconKey);
    final tint = entry.tint;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tint.withValues(alpha: 0.18), width: 1),
      ),
      alignment: Alignment.center,
      child: Icon(entry.icon, color: tint, size: iconSize ?? size * 0.5),
    );
  }
}
