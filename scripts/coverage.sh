#!/bin/bash
# Generate and display test coverage report

set -e

echo "🧪 Running tests with coverage..."
flutter test --coverage

echo ""
echo "📊 Generating coverage report..."

# Check if lcov is installed (macOS)
if command -v lcov &> /dev/null; then
    # Remove generated files from coverage
    lcov --remove coverage/lcov.info \
        '**/*.g.dart' \
        '**/*.freezed.dart' \
        '**/main.dart' \
        -o coverage/lcov_filtered.info

    # Generate HTML report
    genhtml coverage/lcov_filtered.info -o coverage/html

    echo ""
    echo "✅ Coverage report generated!"
    echo "📁 HTML report: coverage/html/index.html"
    echo ""

    # Display summary
    lcov --list coverage/lcov_filtered.info | tail -n 3

    # Open in browser (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo ""
        read -p "Open coverage report in browser? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open coverage/html/index.html
        fi
    fi
else
    echo "⚠️  lcov not installed. Install with: brew install lcov"
    echo "📄 Raw coverage data: coverage/lcov.info"
fi

echo ""
echo "Done! 🎉"
