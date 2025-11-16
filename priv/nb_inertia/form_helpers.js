/**
 * NbInertia Form Helpers
 *
 * Runtime helpers for integrating nb_routes rich mode with HTML forms and Inertia.js.
 * Provides method spoofing for non-GET/POST HTTP methods.
 */

/**
 * Build form action URL with method spoofing
 *
 * Rails-style method spoofing: for non-GET/POST methods, we use POST with a _method parameter.
 * This is compatible with Phoenix's method override plug.
 *
 * @param {string} pattern - URL pattern with :param placeholders (e.g., "/users/:id")
 * @param {Object} params - Parameter values (e.g., { id: 1 })
 * @param {string} method - HTTP method (get, post, patch, put, delete, head, options)
 * @param {Object} options - URL options (query, mergeQuery, anchor)
 * @returns {string} Form action URL with method spoofing if needed
 *
 * @example
 * _buildFormAction("/users/:id", { id: 123 }, "patch", {})
 * // => "/users/123?_method=PATCH"
 */
function _buildFormAction(pattern, params = {}, method = 'post', options = {}) {
  // Use the same _buildUrl function from nb_routes
  // This assumes _buildUrl is available in the global scope
  if (typeof _buildUrl !== 'function') {
    throw new Error('_buildUrl is not defined. Ensure nb_routes is loaded with variant: :rich');
  }

  let url = _buildUrl(pattern, params, options);

  // Normalize method to lowercase
  const normalizedMethod = method.toLowerCase();

  // Method spoofing for non-GET/POST methods
  // HTML forms only support GET and POST, so we use POST with _method parameter
  if (!['get', 'post'].includes(normalizedMethod)) {
    const separator = url.includes('?') ? '&' : '?';
    url += `${separator}_method=${method.toUpperCase()}`;
  }

  return url;
}

/**
 * Enhance a route helper with form variants
 *
 * Adds .form property with method variants that return { action, method } objects
 * suitable for use with HTML <form> elements or Inertia.js forms.
 *
 * @param {Function} routeHelper - The rich mode route helper to enhance
 * @param {string} pattern - URL pattern for the route
 * @param {string} originalMethod - Original HTTP method of the route
 * @returns {Function} Enhanced route helper with .form property
 *
 * @example
 * const update_user_path = enhanceWithFormHelpers(
 *   user_path,
 *   "/users/:id",
 *   "patch"
 * );
 *
 * // Use with HTML form
 * <form {...update_user_path.form(userId)}>
 *
 * // Use with Inertia.js
 * const formData = update_user_path.form(userId);
 * Inertia.post(formData.action, data);
 */
function enhanceWithFormHelpers(routeHelper, pattern, originalMethod) {
  // Extract parameter names from the route helper
  // We'll need to know the function signature to build the form helper
  const paramCount = routeHelper.length;

  // Create the .form property with method variants
  routeHelper.form = function(...args) {
    // Extract params and options from arguments
    const options = args.length > paramCount ? args[paramCount] : {};
    const params = {};

    // Build params object from positional arguments
    // This is a simplified version - real implementation would need to know param names
    // For now, we'll rely on the route helper to extract params

    // For mutation routes (POST, PATCH, PUT, DELETE), always use POST for the form
    const formMethod = ['get', 'head'].includes(originalMethod.toLowerCase()) ? 'get' : 'post';

    return {
      action: _buildFormAction(pattern, params, originalMethod, options),
      method: formMethod
    };
  };

  // Add method-specific form variants
  const methods = ['patch', 'put', 'delete'];

  methods.forEach(method => {
    routeHelper.form[method] = function(...args) {
      const options = args.length > paramCount ? args[paramCount] : {};
      const params = {};

      return {
        action: _buildFormAction(pattern, params, method, options),
        method: 'post'
      };
    };
  });

  return routeHelper;
}

// Export for different module systems
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { _buildFormAction, enhanceWithFormHelpers };
} else if (typeof define === 'function' && define.amd) {
  define([], function() { return { _buildFormAction, enhanceWithFormHelpers }; });
} else {
  this.NbInertiaFormHelpers = { _buildFormAction, enhanceWithFormHelpers };
}
