TEST_CMD = nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }" -c "qa"

.PHONY: test
test:
	$(TEST_CMD)
