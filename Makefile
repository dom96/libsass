CXX      ?= g++
CXXFLAGS = -Wall -O2 -fPIC
LDFLAGS  = -fPIC

PREFIX    = /usr/local
LIBDIR    = $(PREFIX)/lib

SASS_SASSC_PATH ?= sassc
SASS_SPEC_PATH ?= sass-spec
SASS_SPEC_SPEC_DIR ?= spec
SASSC_BIN = $(SASS_SASSC_PATH)/bin/sassc
RUBY_BIN = ruby

SOURCES = \
	ast.cpp \
	base64vlq.cpp \
	bind.cpp \
	constants.cpp \
	context.cpp \
	contextualize.cpp \
	copy_c_str.cpp \
	emscripten_wrapper.cpp \
	error_handling.cpp \
	eval.cpp \
	expand.cpp \
	extend.cpp \
	file.cpp \
	functions.cpp \
	inspect.cpp \
	output_compressed.cpp \
	output_nested.cpp \
	parser.cpp \
	prelexer.cpp \
	remove_placeholders.cpp \
	sass.cpp \
	sass_interface.cpp \
	sass2scss/sass2scss.cpp \
	source_map.cpp \
	to_c.cpp \
	to_string.cpp \
	units.cpp \
	utf8_string.cpp \
	util.cpp

OBJECTS = $(SOURCES:.cpp=.o)

all: static

debug: LDFLAGS := -g
debug: CXXFLAGS := -g -DDEBUG $(filter-out -O2,$(CXXFLAGS))
debug: static

debug-shared: LDFLAGS := -g
debug-shared: CXXFLAGS := -g -DDEBUG $(filter-out -O2,$(CXXFLAGS))
debug-shared: shared

static: libsass.a
shared: libsass.so

js: static
	emcc -O2 libsass.a -o libsass.js -s EXPORTED_FUNCTIONS="['_sass_compile_emscripten']" -s DISABLE_EXCEPTION_CATCHING=0

libsass.a: $(OBJECTS)
	$(AR) rvs $@ $(OBJECTS)

libsass.so: $(OBJECTS)
	$(CXX) -shared $(LDFLAGS) -o $@ $(OBJECTS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

%: %.o libsass.a
	$(CXX) $(CXXFLAGS) -o $@ $+ $(LDFLAGS)

install: libsass.a
	mkdir -p $(DESTDIR)$(LIBDIR)/
	install -pm0755 $< $(DESTDIR)$(LIBDIR)/$<

install-shared: libsass.so
	mkdir -p $(DESTDIR)$(LIBDIR)/
	install -pm0755 $< $(DESTDIR)$(LIBDIR)/$<

$(SASSC_BIN): libsass.a
	cd $(SASS_SASSC_PATH) && $(MAKE)

test: $(SASSC_BIN) libsass.a
	$(RUBY_BIN) $(SASS_SPEC_PATH)/sass-spec.rb -c $(SASSC_BIN) -s $(LOG_FLAGS) $(SASS_SPEC_PATH)/$(SASS_SPEC_SPEC_DIR)

test_build: $(SASSC_BIN) libsass.a
	$(RUBY_BIN) $(SASS_SPEC_PATH)/sass-spec.rb -c $(SASSC_BIN) -s --ignore-todo $(LOG_FLAGS) $(SASS_SPEC_PATH)/$(SASS_SPEC_SPEC_DIR)

test_issues: $(SASSC_BIN) libsass.a
	$(RUBY_BIN) $(SASS_SPEC_PATH)/sass-spec.rb -c $(SASSC_BIN) $(LOG_FLAGS) $(SASS_SPEC_PATH)/spec/issues

clean:
	rm -f $(OBJECTS) *.a *.so libsass.js


.PHONY: all debug debug-shared static shared bin install install-shared clean

