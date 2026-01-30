# Design: Optimize Logging

## Architecture Overview
This change introduces centralized logging configuration for the FastAPI backend application to control log verbosity and establish consistent logging patterns.

## Components

### 1. Logging Configuration Module
**Location**: `backend-fastapi/app/logging_config.py`

**Purpose**: Centralized logging setup with environment-aware configuration

**Key Decisions**:
- Use Python's standard `logging` module (no external dependencies)
- Support environment variable `LOG_LEVEL` for runtime configuration
- Default to INFO level for production, DEBUG for development
- Use structured log format with timestamp, level, module, and message

### 2. Log Statement Optimization
**Affected Files**:
- `backend-fastapi/app/routes.py` (6 logging statements)
- `backend-fastapi/seed_db.py` (1 print statement)
- `backend-fastapi/tests/n8n_test.py` (multiple print statements)

**Strategy**:
- **routes.py**: Keep essential logs, adjust levels appropriately
  - Keep ERROR logs for failures
  - Keep INFO logs for important business events (ticket creation, n8n success)
  - Demote or remove DEBUG log for webhook URL
  - Consider removing WARNING log for invalid urgency (FastAPI returns error anyway)
- **seed_db.py**: Keep print statement (one-time script output)
- **test files**: Keep print statements for test readability

### 3. Environment Configuration
**Variables**:
- `LOG_LEVEL`: Control log verbosity (DEBUG, INFO, WARNING, ERROR)
- Default: INFO for production, DEBUG for development

## Trade-offs

### Option 1: Aggressive Log Reduction (Chosen)
**Pros**:
- Cleaner production logs
- Reduced storage and processing costs
- Easier to spot important issues

**Cons**:
- May lose some debugging context
- Need to re-add logs if issues arise

### Option 2: Keep All Logs, Control with Levels
**Pros**:
- Maximum flexibility
- Can enable verbose logging when needed

**Cons**:
- More maintenance overhead
- Developers might forget to set proper levels

**Decision**: Choose Option 1 with sensible defaults that can be overridden via environment variables.

## Implementation Notes

### Log Level Guidelines
- **DEBUG**: Detailed information for diagnosing problems (webhook URLs, data details)
- **INFO**: Confirmation that things are working as expected (ticket saved, n8n success)
- **WARNING**: Something unexpected but the app continues (n8n connection failed but ticket saved)
- **ERROR**: Serious problem causing function failure (database save failed)

### Backward Compatibility
- Existing log statements remain functional
- New configuration is additive and backward compatible
- Shell scripts unchanged to maintain startup experience

## Security Considerations
- Ensure sensitive data (emails, customer info) is not logged at DEBUG level
- Review all log statements for potential PII exposure