# About Keepit

## Mission

Keepit is on a mission to restore privacy to digital life. We believe that your data should be truly yours—stored securely, controlled completely by you, and inaccessible to anyone else, including us.

## The Problem

Existing vault and password management solutions require you to trust a third party with your most sensitive information. Even with the best intentions, companies become targets for breaches, and centralized architectures create attractive targets for attackers.

## Our Solution

Keepit implements true end-to-end encryption, where:
- **Your device owns all encryption keys** - Not the backend, not the cloud, your device
- **The backend is an opaque store** - We cannot decrypt your data, even if we wanted to
- **All encryption happens client-side** - Before data ever leaves your device
- **The code is open source** - You can audit exactly what we're doing

## Core Principles

### 1. Privacy First
Privacy isn't a feature—it's the foundation. Every design decision starts with the question: "How does this affect user privacy?"

### 2. Zero-Knowledge Architecture
Our backend genuinely knows nothing about your data. We process only encrypted blobs, maintain only session information, and have no ability to access your vault contents.

### 3. Transparency
- Open-source codebase available for community audit
- Clear documentation of cryptographic methods
- No hidden tracking or analytics
- Formal security definitions for all operations

### 4. User Control
- Self-hostable (you can run your own backend)
- Export your data anytime
- Full audit trail of your account
- Account deletion removes all data permanently

## Technical Philosophy

We use:
- **Industry-standard cryptography**: AES-256-GCM, Argon2id, HKDF (no proprietary algorithms)
- **Well-tested libraries**: Leveraging battle-tested implementations
- **Formal definitions**: Every cryptographic operation has a clear mathematical definition
- **Defense in depth**: Multiple layers of security (encryption, authentication, rate limiting)

## Project Status

**Current Version**: 1.0.0-beta

- ✅ Backend (Node.js/Express): Production-ready
- ✅ Frontend (Flutter): Android-ready; iOS development underway
- ✅ Website: Documentation and landing page live
- 📋 Audit: Security audit scheduled for Q3 2026

## Who Should Use Keepit?

### Ideal for:
- Security professionals who want transparency
- Privacy advocates who refuse to compromise
- Businesses storing sensitive documents
- Anyone who values data sovereignty
- Developers who want to understand their tools

### Not ideal for:
- Users who want zero configuration (we require security-conscious setup)
- Cloud-first workflows requiring instant sync everywhere (we prioritize security over convenience)
- Users unwilling to manage their own encryption keys

## Contributing

Keepit welcomes contributions:
- **Code**: Submit pull requests; all contributions must maintain our security standards
- **Security Research**: Report vulnerabilities responsibly via security@keepit.app
- **Documentation**: Help us explain complex concepts clearly
- **Translations**: Help us reach a global audience

## Team

Keepit is developed by a small team passionate about privacy:
- **Nick** - Founder & Full-Stack Developer
- [Community Contributors]

## Roadmap

### Q2 2026
- ✅ Android MVP launch
- ✅ Backend v1 release
- ✅ Documentation suite

### Q3 2026
- iOS client launch
- Security audit completion
- Performance optimizations

### Q4 2026
- Web client (progressive web app)
- Sharing features with end-to-end guarantees
- Advanced key management

### 2027
- Multi-device synchronization
- Family accounts with granular sharing
- Enterprise features (audit logging, admin controls)

## Security

Security is not a feature we add—it's core to how we operate:

- **No telemetry**: We don't track usage or collect analytics
- **No ads**: We're not incentivized to monetize your data
- **No selling**: Your data is never shared with third parties
- **Responsible disclosure**: Report security issues confidentially

For detailed security information, see our [Security Practices](wiki/08-Security-Practices.md).

## Business Model

Keepit operates on a sustainable freemium model:

- **Free tier**: Personal vault with 5GB storage
- **Pro tier**: Unlimited storage, advanced features ($9.99/month or $79.99/year)
- **Enterprise**: Custom deployments, audit logging, support ($contact for pricing)

100% of profits are reinvested into security, privacy, and user experience improvements.

## License

Keepit is licensed under the **MIT License**, meaning:
- Free to use for any purpose
- Free to modify
- Free to distribute
- No attribution required (but appreciated)

See [LICENSE](../LICENSE) for full terms.

## Get In Touch

- **Website**: https://keepit.app
- **GitHub**: https://github.com/TrendySloth1001/keepit
- **Email**: hello@keepit.app
- **Twitter**: @keepit_app
- **Documentation**: [Wiki](wiki/)

## Acknowledgments

Keepit stands on the shoulders of giants:
- Cryptography community for battle-tested primitives
- Flutter team for excellent cross-platform framework
- Open-source community for incredible tools
- Our users for trusting us with their security

---

*Keepit: Your private vault. On your device. Your keys. Your data. Your control.*
