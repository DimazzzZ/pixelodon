class EnvConfig {
  const EnvConfig({
    required this.appName,
    required this.userAgent,
    required this.enableRealApis,
  });

  final String appName;
  final String userAgent;
  final bool enableRealApis;
}

// In a real app, load via flutter_dotenv or flavors. For this scaffold, defaults:
const env = EnvConfig(
  appName: 'Federated Client',
  userAgent: 'FederatedClient/0.1 (+https://example.org)',
  enableRealApis: false,
);

