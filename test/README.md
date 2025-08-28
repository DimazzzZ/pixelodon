# Test Documentation

This document provides instructions for running tests in the Pixelodon project, including unit tests, widget tests, and integration tests.

## Quick Start

```bash
# Run all unit and widget tests
flutter test

# Run integration tests on iOS
flutter test integration_test -d ios

# Run integration tests on Android  
flutter test integration_test -d android

# Run specific test file
flutter test integration_test/home_functional_test.dart
```

## Test Structure

The project follows a comprehensive testing strategy with:

- **Unit Tests**: Test individual functions and classes
- **Widget Tests**: Test UI components in isolation
- **Integration Tests**: Test complete user scenarios

### Directory Structure

```
test/
├── test_support/           # Shared testing utilities
│   ├── app_pump.dart       # App initialization helpers
│   ├── finders.dart        # Typed UI element finders
│   ├── network_stubs.dart  # Mock network responses
│   └── robots/             # Page object pattern implementations
│       └── home_robot.dart # Home screen interaction robot
├── core/                   # Core functionality tests
├── features/               # Feature-specific tests
├── models/                 # Data model tests
├── services/               # Service layer tests
└── widgets/                # Widget-specific tests

integration_test/
└── home_functional_test.dart  # Comprehensive Home screen tests
```

## Test Utilities

### AppPump
Provides utilities for initializing the app with various configurations:

```dart
// Basic app setup
await AppPump.pumpApp(tester, MyWidget());

// Authenticated app with instance
await AppPump.pumpAuthenticatedApp(tester, MyWidget());

// With mocked services
await AppPump.pumpWithMockedTimeline(tester, MyWidget(), 
    mockTimelineService: mockService);
```

### Finders
Typed finders for stable element identification:

```dart
// Home screen elements
HomeFinders.homeScreen
HomeFinders.followingTab
HomeFinders.feedList

// Status elements
StatusFinders.statusCard('status_id')
StatusFinders.likeButton('status_id')

// General UI elements
AppFinders.loadingIndicator
AppFinders.errorBanner
```

### NetworkStubs
Mock network responses for deterministic testing:

```dart
final mockService = NetworkStubs.createMockTimelineService();

// Configure successful response
NetworkStubs.configureSuccessfulTimeline(mockService, 
    statuses: NetworkStubs.createMockStatuses(20));

// Configure error response
NetworkStubs.configureErrorTimeline(mockService, 
    errorMessage: 'Network error');

// Configure empty response
NetworkStubs.configureEmptyTimeline(mockService);
```

### HomeRobot
Page object for Home screen interactions:

```dart
final robot = await HomeRobot.openHome(tester);

await robot
    .expectHomeScreenVisible()
    .expectTabsVisible()
    .tapLocalTab()
    .waitForContentLoad()
    .expectAtLeastStatusItems(5)
    .pullToRefresh()
    .scrollToLoadMore();
```

## Integration Tests

### Home Screen Tests

The `home_functional_test.dart` covers comprehensive scenarios:

#### Initial Render & Data Load
- ✅ Shows skeleton/shimmer and resolves to content
- ✅ Shows empty state when API returns zero items
- ✅ Shows no active instance message when no instance selected

#### Error Handling & Retry
- ✅ Shows network error and allows retry
- ✅ Handles timeout errors gracefully

#### Pagination & Infinite Scroll
- ✅ Scrolling loads next page with loading indicator
- ✅ Prevents duplicate items during pagination

#### Pull-to-Refresh
- ✅ Resets to page 1 and refreshes content

#### Navigation
- ✅ Tapping status card navigates to details
- ✅ Status interactions work correctly

#### Tab Navigation
- ✅ Switching between Following, Local, and Federated tabs

#### Accessibility
- ✅ Key elements have proper semantics and labels
- ✅ No blocked focus paths exist

#### Theme Rendering
- ✅ Light mode renders without layout overflows
- ✅ Dark mode renders without layout overflows

#### Edge Cases & Error Recovery
- ✅ Handles rapid tab switching without crashes
- ✅ Recovers from network interruptions
- ✅ Handles empty refresh gracefully

#### Performance & Stability
- ✅ Handles large datasets without performance issues
- ✅ Maintains state during app lifecycle changes

## Running Tests

### Prerequisites

1. Flutter SDK installed and configured
2. iOS Simulator (for iOS tests) or Android Emulator (for Android tests)
3. Xcode (for iOS) or Android Studio (for Android)

### Environment Setup

Before running tests, ensure dependencies are installed:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Unit and Widget Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/feed/home_test.dart

# Run tests in watch mode (reruns on file changes)
flutter test --watch
```

### Integration Tests

Integration tests require a device or simulator:

```bash
# List available devices
flutter devices

# Run on iOS Simulator
flutter test integration_test -d ios

# Run on Android Emulator
flutter test integration_test -d android

# Run on specific device
flutter test integration_test -d <device_id>

# Run specific integration test
flutter test integration_test/home_functional_test.dart -d ios
```

### Test Debugging

For debugging test failures:

```bash
# Enable verbose output
flutter test --verbose

# Run single test
flutter test integration_test/home_functional_test.dart --name "shows skeleton/shimmer and resolves to content"

# Debug with additional logging
flutter test integration_test --debug
```

## Writing Tests

### Best Practices

1. **Use Page Object Pattern**: Leverage robots for complex interactions
2. **Mock External Dependencies**: Use NetworkStubs for API calls
3. **Write Descriptive Test Names**: Clearly describe what is being tested
4. **Group Related Tests**: Use `group()` to organize test scenarios
5. **Handle Async Operations**: Use proper waiting strategies
6. **Test Both Happy and Error Paths**: Cover success and failure scenarios
7. **Verify Accessibility**: Include semantic checks in UI tests

### Example Test Structure

```dart
group('Feature Name', () {
  late MockService mockService;
  
  setUp(() {
    mockService = createMockService();
  });

  group('Scenario Group', () {
    testWidgets('should do something when condition', (tester) async {
      // Arrange
      configureSuccessfulResponse(mockService);
      
      // Act
      final robot = await Robot.open(tester, mockService: mockService);
      
      // Assert
      await robot
          .expectInitialState()
          .performAction()
          .expectResultState();
    });
  });
});
```

### Flake-Free Testing

To avoid flaky tests:

1. **Use Robust Waiting**: `pumpUntilFound()`, `pumpAndSettleSafely()`
2. **Avoid Fixed Delays**: Use condition-based waiting instead of `sleep()`
3. **Mock Time-Dependent Operations**: Use deterministic responses
4. **Handle Animation States**: Wait for animations to complete
5. **Reset State Between Tests**: Ensure clean test environment

### CI/CD Integration

For continuous integration:

```yaml
# Example GitHub Actions workflow
- name: Run Unit Tests
  run: flutter test --coverage

- name: Run Integration Tests iOS
  run: flutter test integration_test -d ios

- name: Run Integration Tests Android  
  run: flutter test integration_test -d android
```

## Troubleshooting

### Common Issues

#### Tests Timeout
- Increase timeout values in test configuration
- Check for infinite loops in pump operations
- Verify mock responses are configured correctly

#### Widget Not Found
- Verify widget keys are properly set
- Check if widget is actually rendered
- Use `finder.evaluate().isEmpty` to debug

#### Mock Not Working
- Ensure mock service is properly configured
- Verify provider overrides are applied
- Check mock method signatures match expectations

#### Device Connection Issues
- Restart simulators/emulators
- Check `flutter devices` output
- Verify platform-specific setup

### Debug Commands

```bash
# Check test environment
flutter doctor

# Verify device connectivity
flutter devices

# Run tests with debug info
flutter test --verbose --debug

# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Performance Considerations

- **Parallel Test Execution**: Use `--concurrency` flag for unit tests
- **Selective Test Running**: Use tags or name patterns for focused testing  
- **Mock Heavy Operations**: Network calls, file I/O, expensive computations
- **Optimize Test Data**: Use minimal data sets that still provide coverage

## Contributing

When adding new tests:

1. Follow the existing patterns and directory structure
2. Update this README if adding new test utilities
3. Ensure tests are platform-agnostic where possible
4. Add appropriate documentation and comments
5. Verify tests pass on both Android and iOS

## Resources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Test Coverage](https://docs.flutter.dev/testing/code-coverage)
