const String _LOCAL_URL = 'https://localhost:7585';
const String _STAGING_URL =
    'https://api.icybeach-e08c4a1b.uksouth.azurecontainerapps.io';
const String _PRODUCTION_URL =
    'https://api.icybeach-e08c4a1b.uksouth.azurecontainerapps.io';

const String ENV = String.fromEnvironment('ENV', defaultValue: 'development');

const String BASE_URL = (ENV == 'production')
    ? _PRODUCTION_URL
    : (ENV == 'staging')
        ? _STAGING_URL
        : _LOCAL_URL;
