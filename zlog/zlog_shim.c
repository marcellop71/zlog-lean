/*
 * zlog_shim.c - C shim for interfacing Lean with zlog library
 *
 * This file provides Lean-compatible FFI wrappers around zlog functions.
 * zlog must be installed on the system.
 */

#include <lean/lean.h>
#include <zlog.h>
#include <string.h>
#include <stdlib.h>

/* ============================================================================
 * Helper functions for Option types
 * In Lean 4, Option is an inductive with:
 *   - none: constructor 0, no fields
 *   - some a: constructor 1, one field
 * ============================================================================ */

static inline lean_obj_res mk_option_none(void) {
    return lean_box(0);  // none is scalar 0
}

static inline lean_obj_res mk_option_some(lean_obj_arg a) {
    lean_object *obj = lean_alloc_ctor(1, 1, 0);  // constructor 1, 1 object field, 0 scalar bytes
    lean_ctor_set(obj, 0, a);
    return obj;
}

/* ============================================================================
 * Initialization and Configuration
 * ============================================================================ */

/*
 * Initialize zlog from a configuration file
 * Returns: IO Bool (true on success, false on failure)
 */
LEAN_EXPORT lean_obj_res lean_zlog_init(b_lean_obj_arg config_path, lean_obj_arg world) {
    const char *path = lean_string_cstr(config_path);
    int result = zlog_init(path);
    return lean_io_result_mk_ok(lean_box((uint32_t)(result == 0 ? 1 : 0)));
}

/*
 * Initialize zlog from a configuration string
 * Returns: IO Bool (true on success, false on failure)
 */
LEAN_EXPORT lean_obj_res lean_zlog_init_from_string(b_lean_obj_arg config_string, lean_obj_arg world) {
    const char *config = lean_string_cstr(config_string);
    int result = zlog_init_from_string(config);
    return lean_io_result_mk_ok(lean_box((uint32_t)(result == 0 ? 1 : 0)));
}

/*
 * Reload zlog configuration from file
 * Returns: IO Bool (true on success, false on failure)
 */
LEAN_EXPORT lean_obj_res lean_zlog_reload(b_lean_obj_arg config_path, lean_obj_arg world) {
    const char *path = lean_string_cstr(config_path);
    int result = zlog_reload(path);
    return lean_io_result_mk_ok(lean_box((uint32_t)(result == 0 ? 1 : 0)));
}

/*
 * Finalize zlog and release resources
 */
LEAN_EXPORT lean_obj_res lean_zlog_fini(lean_obj_arg unit) {
    zlog_fini();
    return lean_io_result_mk_ok(lean_box(0));
}

/*
 * Get zlog version string
 */
LEAN_EXPORT lean_obj_res lean_zlog_version(lean_obj_arg unit) {
    const char *version = zlog_version();
    return lean_io_result_mk_ok(lean_mk_string(version));
}

/* ============================================================================
 * Category Management
 * ============================================================================ */

/*
 * External class for zlog_category_t pointers
 */
static void zlog_category_finalizer(void *ptr) {
    // zlog categories are managed by zlog internally, no need to free
    (void)ptr;
}

static lean_external_class *g_zlog_category_class = NULL;

static lean_external_class *get_zlog_category_class(void) {
    if (g_zlog_category_class == NULL) {
        g_zlog_category_class = lean_register_external_class(
            zlog_category_finalizer,
            NULL  // foreach callback not needed
        );
    }
    return g_zlog_category_class;
}

/*
 * Get a logging category by name
 * Returns: IO (Option Category) (some on success, none on failure)
 */
LEAN_EXPORT lean_obj_res lean_zlog_get_category(b_lean_obj_arg name, lean_obj_arg world) {
    const char *cname = lean_string_cstr(name);
    zlog_category_t *cat = zlog_get_category(cname);

    if (cat == NULL) {
        return lean_io_result_mk_ok(mk_option_none());
    }

    lean_object *cat_obj = lean_alloc_external(get_zlog_category_class(), (void*)cat);
    return lean_io_result_mk_ok(mk_option_some(cat_obj));
}

/*
 * Check if a log level is enabled for a category
 */
LEAN_EXPORT lean_obj_res lean_zlog_level_enabled(b_lean_obj_arg cat_obj, uint32_t level) {
    zlog_category_t *cat = (zlog_category_t *)lean_get_external_data(cat_obj);
    int enabled = zlog_level_enabled(cat, (int)level);
    return lean_box((uint32_t)(enabled ? 1 : 0));
}

/*
 * Switch the log level for a category
 * Returns: true on success, false on failure
 */
LEAN_EXPORT lean_obj_res lean_zlog_level_switch(b_lean_obj_arg cat_obj, uint32_t level) {
    zlog_category_t *cat = (zlog_category_t *)lean_get_external_data(cat_obj);
    int result = zlog_level_switch(cat, (int)level);
    return lean_box((uint32_t)(result == 0 ? 1 : 0));
}

/* ============================================================================
 * Logging Functions
 *
 * zlog signature:
 *   void zlog(zlog_category_t *category,
 *             const char *file, size_t filelen,
 *             const char *func, size_t funclen,
 *             long line, int level,
 *             const char *format, ...);
 * ============================================================================ */

/*
 * Log a message at a specific level
 */
LEAN_EXPORT lean_obj_res lean_zlog_log(b_lean_obj_arg cat_obj, uint32_t level,
                                        b_lean_obj_arg file, uint32_t line,
                                        b_lean_obj_arg func, b_lean_obj_arg msg) {
    zlog_category_t *cat = (zlog_category_t *)lean_get_external_data(cat_obj);
    const char *file_str = lean_string_cstr(file);
    const char *func_str = lean_string_cstr(func);
    const char *msg_str = lean_string_cstr(msg);

    zlog(cat, file_str, strlen(file_str), func_str, strlen(func_str),
         (long)line, (int)level, "%s", msg_str);

    return lean_io_result_mk_ok(lean_box(0));
}

/*
 * Log hex/binary data
 */
LEAN_EXPORT lean_obj_res lean_zlog_hex(b_lean_obj_arg cat_obj, uint32_t level,
                                        b_lean_obj_arg file, uint32_t line,
                                        b_lean_obj_arg func, b_lean_obj_arg data) {
    zlog_category_t *cat = (zlog_category_t *)lean_get_external_data(cat_obj);
    const char *file_str = lean_string_cstr(file);
    const char *func_str = lean_string_cstr(func);

    lean_sarray_object *arr = lean_to_sarray(data);
    size_t len = lean_sarray_size(data);
    const uint8_t *buf = lean_sarray_cptr(data);

    hzlog(cat, file_str, strlen(file_str), func_str, strlen(func_str),
          (long)line, (int)level, buf, len);

    return lean_io_result_mk_ok(lean_box(0));
}

/* ============================================================================
 * Default Category API (dzlog)
 *
 * dzlog signature:
 *   void dzlog(const char *file, size_t filelen,
 *              const char *func, size_t funclen,
 *              long line, int level,
 *              const char *format, ...);
 * ============================================================================ */

/*
 * Initialize default category logging
 * Returns: IO Bool
 */
LEAN_EXPORT lean_obj_res lean_dzlog_init(b_lean_obj_arg config_path, b_lean_obj_arg category, lean_obj_arg world) {
    const char *path = lean_string_cstr(config_path);
    const char *cat = lean_string_cstr(category);
    int result = dzlog_init(path, cat);
    return lean_io_result_mk_ok(lean_box((uint32_t)(result == 0 ? 1 : 0)));
}

/*
 * Set the default category
 * Returns: IO Bool
 */
LEAN_EXPORT lean_obj_res lean_dzlog_set_category(b_lean_obj_arg category, lean_obj_arg world) {
    const char *cat = lean_string_cstr(category);
    int result = dzlog_set_category(cat);
    return lean_io_result_mk_ok(lean_box((uint32_t)(result == 0 ? 1 : 0)));
}

/*
 * Check if a level is enabled for the default category
 * Returns: IO Bool
 * Note: zlog doesn't have dzlog_level_enabled, so we always return true
 */
LEAN_EXPORT lean_obj_res lean_dzlog_level_enabled(uint32_t level, lean_obj_arg world) {
    (void)level;
    // Default category doesn't have a level_enabled check in zlog API
    // Always return true and let the logging handle filtering
    return lean_io_result_mk_ok(lean_box(1));
}

/*
 * Log to the default category
 */
LEAN_EXPORT lean_obj_res lean_dzlog_log(uint32_t level, b_lean_obj_arg file,
                                         uint32_t line, b_lean_obj_arg func,
                                         b_lean_obj_arg msg) {
    const char *file_str = lean_string_cstr(file);
    const char *func_str = lean_string_cstr(func);
    const char *msg_str = lean_string_cstr(msg);

    dzlog(file_str, strlen(file_str), func_str, strlen(func_str),
          (long)line, (int)level, "%s", msg_str);

    return lean_io_result_mk_ok(lean_box(0));
}

/* ============================================================================
 * Mapped Diagnostic Context (MDC)
 * ============================================================================ */

/*
 * Put a key-value pair into MDC
 */
LEAN_EXPORT lean_obj_res lean_zlog_put_mdc(b_lean_obj_arg key, b_lean_obj_arg value) {
    const char *key_str = lean_string_cstr(key);
    const char *value_str = lean_string_cstr(value);
    int result = zlog_put_mdc(key_str, value_str);
    return lean_io_result_mk_ok(lean_box((uint32_t)(result == 0 ? 1 : 0)));
}

/*
 * Get a value from MDC by key
 */
LEAN_EXPORT lean_obj_res lean_zlog_get_mdc(b_lean_obj_arg key) {
    const char *key_str = lean_string_cstr(key);
    char *value = zlog_get_mdc(key_str);

    if (value == NULL) {
        return lean_io_result_mk_ok(mk_option_none());
    }

    lean_object *result = mk_option_some(lean_mk_string(value));
    return lean_io_result_mk_ok(result);
}

/*
 * Remove a key from MDC
 */
LEAN_EXPORT lean_obj_res lean_zlog_remove_mdc(b_lean_obj_arg key) {
    const char *key_str = lean_string_cstr(key);
    zlog_remove_mdc(key_str);
    return lean_io_result_mk_ok(lean_box(0));
}

/*
 * Clean all MDC data
 */
LEAN_EXPORT lean_obj_res lean_zlog_clean_mdc(lean_obj_arg unit) {
    zlog_clean_mdc();
    return lean_io_result_mk_ok(lean_box(0));
}

/* ============================================================================
 * Utility Functions
 * ============================================================================ */

/*
 * Display profiling information
 */
LEAN_EXPORT lean_obj_res lean_zlog_profile(lean_obj_arg unit) {
    zlog_profile();
    return lean_io_result_mk_ok(lean_box(0));
}
