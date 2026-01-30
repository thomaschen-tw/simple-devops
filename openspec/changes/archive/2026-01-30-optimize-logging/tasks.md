# Implementation Tasks: Optimize Logging

## Task List

### 1. Create centralized logging configuration
- [ ] Create `backend-fastapi/app/logging_config.py` module
- [ ] Implement `setup_logging()` function with environment-aware configuration
- [ ] Support LOG_LEVEL environment variable (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- [ ] Define structured log format with timestamp, level, module, and message
- [ ] Set default level to INFO for production, DEBUG when LOG_LEVEL not set

**Validation**:
- Run application with different LOG_LEVEL values
- Verify log format matches specification
- Confirm DEBUG logs only appear when LOG_LEVEL=DEBUG

**Dependencies**: None

### 2. Integrate logging configuration in application startup
- [ ] Import and call `setup_logging()` in `backend-fastapi/app/main.py` before app initialization
- [ ] Ensure logging is configured before any other module imports

**Validation**:
- Start application and verify logging configuration is applied
- Check that log messages use the configured format
- Test with different LOG_LEVEL environment variables

**Dependencies**: Task 1

### 3. Review and optimize log statements in routes.py
- [ ] Review all 6 logging statements in `backend-fastapi/app/routes.py`
- [ ] Keep essential ERROR logs (database save failures)
- [ ] Keep INFO logs for business events (ticket saved, n8n success)
- [ ] Remove or simplify DEBUG log for webhook URL (line 249)
- [ ] Review WARNING log for invalid urgency (line 205) - consider removing since FastAPI returns error
- [ ] Update log messages to avoid logging full customer email/name in production

**Validation**:
- Run application with LOG_LEVEL=INFO and verify output is clean
- Run application with LOG_LEVEL=DEBUG and verify debugging info appears
- Create test tickets and verify appropriate log messages appear
- Confirm no sensitive data appears in INFO-level logs

**Dependencies**: Task 2

### 4. Add documentation for logging configuration
- [ ] Update `backend-fastapi/README.md` with LOG_LEVEL environment variable documentation
- [ ] Document available log levels and their purposes
- [ ] Provide examples of setting LOG_LEVEL in different environments

**Validation**:
- Review documentation for clarity and completeness
- Verify examples work as documented

**Dependencies**: Task 3

### 5. Test logging in different scenarios
- [ ] Test with LOG_LEVEL=INFO (production default)
- [ ] Test with LOG_LEVEL=DEBUG (development mode)
- [ ] Test with LOG_LEVEL=WARNING (minimal logging)
- [ ] Test ticket creation success path (verify INFO logs)
- [ ] Test ticket creation with n8n failure (verify WARNING logs)
- [ ] Test ticket creation with database failure (verify ERROR logs)

**Validation**:
- All scenarios produce expected log output
- No unnecessary verbose logs in INFO level
- Debug logs only appear at DEBUG level
- Critical errors are logged at ERROR level

**Dependencies**: Task 3

## Work Sequencing

**Sequential work**:
1. Task 1 → Task 2 → Task 3 → Task 4 (linear dependency)

**Parallelizable work**:
- Task 5 can be performed during/after Task 3 for validation

## Rollout Strategy

1. Implement logging configuration module (Task 1)
2. Integrate in application startup (Task 2)
3. Optimize existing log statements (Task 3)
4. Add documentation (Task 4)
5. Comprehensive testing (Task 5)

## Success Metrics

- Production logs are reduced by ~40-60% in volume
- All critical errors still logged at ERROR level
- Important business events logged at INFO level
- No sensitive customer data in INFO-level logs
- LOG_LEVEL environment variable controls verbosity as expected
